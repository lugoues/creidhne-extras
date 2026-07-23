package creidhne_extras

import (
	"list"
	"net"
	"strings"

	c "github.com/lugoues/creidhne"
)

// #GluetunMixin is per-consumer VPN egress: a gluetun container on its own
// isolated client network, the egress-side twin of the pair network (a
// shared VPN network makes every consumer a peer of every other consumer).
//
// The client network is Internal and DNS-less with a single default route
// pointing at the VPN container (metric 200, installed per-client by
// netavark); gluetun also joins the uplink network for its own tunnel
// egress. A preflight strips the self-referencing route from gluetun
// itself and writes the post-rules gluetun applies after building its own
// firewall (pre-entrypoint iptables calls would be flushed by it): tun0
// NAT, LAN-destination drops, and the client forward policy.
// Killswitch by construction: clients have no other route, so a dead
// tunnel is no egress, not leaked egress.
//
//	firecrawl: creidhne.#Quadlet & ce.#StaticNetworkMixin & ce.#GluetunMixin & {
//	    name: "firecrawl"
//	    #static: subnet: "10.30.0.0/24"
//	    #gluetun: {
//	        network:  subnet: "10.20.0.0/24"
//	        provider: "mullvad"
//	        countries: ["Sweden"]
//	        port_forwarding: false
//	        private_key: secrets.mullvad_wg_key
//	        addresses:   secrets.mullvad_wg_addresses
//	        auth_config: secrets.gluetun_auth
//	        uplink: internet_egress
//	    }
//	    units: containers: api: {
//	        Unit: {Requires: [#gluetun.#service], After: [#gluetun.#service]}
//	        Container: {
//	            Image: "docker.io/fc-api"
//	            DNS: [#gluetun.#dns]
//	            #extraNetworks: [#gluetun.#network.#self]
//	        }
//	    }
//	}
//
// The mixin places the VPN as additional units of the consuming quadlet
// (<name>-vpn.container/.network/.build) and exposes handles; attachment
// rides existing channels (the static mixin's #extraNetworks, or the
// primary #container's own Network list). A user-literal
// `units.networks.vpn.#self` in an additional container's Network list
// freezes under the cue 0.17 evaluator; the handle + channel path is the
// one proven in production.
#GluetunMixin: {
	name:  c.#UnitName
	units: _

	#gluetun: {
		// handle keys the placed units: units.networks.<handle>,
		// units.containers.<handle>, units.builds.<handle>; files are
		// "<quadlet>-<handle>.*".
		handle: string | *"vpn"
		// gluetun VPN_SERVICE_PROVIDER and SERVER_COUNTRIES.
		provider: string
		countries: [...string]
		// Provider port forwarding (PORT_FORWARD_ONLY + VPN_PORT_FORWARDING).
		port_forwarding: bool | *false
		// The gluetun image the build wraps; any reference works (tag or
		// digest). Required: pin per instance.
		image: c.#ImageName

		// Podman secret handles from the project's secrets registry, unified
		// with their env targets below. Flat fields, deliberately: a nested
		// `secrets:` struct here would lexically shadow the project's
		// conventional `secrets` registry at every instantiation site.
		private_key: c.#SecretName
		addresses:   c.#SecretName
		// Control-server auth (HTTP_CONTROL_SERVER_AUTH_DEFAULT_ROLE).
		// Optional: instances that never talk to gluetun's control server
		// (e.g. no port forwarding) can omit it.
		auth_config?: c.#SecretName

		// The uplink quadlet this VPN tunnels through: pass the whole
		// quadlet value (uplink: internet_egress); the mixin derives its
		// network handle, service ordering, and cidr
		// (FIREWALL_OUTBOUND_SUBNETS) from it.
		uplink:         _
		_uplinkNet:     uplink.units.#network.#self
		_uplinkService: uplink.units.#container.#service
		_uplinkCIDR:    uplink.units.#network.Network.Subnet[0]

		// Handles for consumers, mirroring #exposes.#network: attach via the
		// static mixin's #extraNetworks channel (or the primary #container's
		// own Network list) and point DNS at the VPN container.
		//
		//	Container: {
		//	    DNS: [#gluetun.#dns]
		//	    #extraNetworks: [#gluetun.#network.#self]
		//	}
		#network: units.networks.vpn
		#dns:     _subnet.byName.vpn

		// #ip is the same address under its other hat: the VPN container's
		// IP on the client network, for non-DNS uses (probe targets,
		// firewall rules, interpolated config).
		#ip: _subnet.byName.vpn

		// #service is the VPN container's systemd service: order clients
		// behind it (Requires + After) so they never start ahead of their
		// only route and resolver.
		#service: units.containers.vpn.#service

		// --- wireguard tuning (each emits its env only when set) ---
		// WIREGUARD_PUBLIC_KEY: a podman secret, wired below.
		public_key?: c.#SecretName
		// WIREGUARD_PRESHARED_KEY: a podman secret, wired below.
		preshared_key?: c.#SecretName
		// WIREGUARD_ALLOWED_IPS, joined with ",". Upstream default: 0.0.0.0/0,::/0.
		allowed_ips?: [...string]
		// WIREGUARD_ENDPOINT_IP / _PORT: pin a specific server.
		endpoint_ip?:   string
		endpoint_port?: int & >0 & <65536
		// WIREGUARD_IMPLEMENTATION.
		implementation?: "auto" | "kernelspace" | "userspace"
		// WIREGUARD_MTU (tunnel-inner; the client network's mtu is separate).
		mtu?: int & >0 & <=1440
		// WIREGUARD_PERSISTENT_KEEPALIVE_INTERVAL, e.g. "25s".
		keepalive?: string & =~"^[0-9]+(ns|us|ms|s|m|h)$"

		// --- port forwarding details (with port_forwarding: true) ---
		// VPN_PORT_FORWARDING_PORTS_COUNT (up to 5 for ProtonVPN).
		forward_ports_count?: int & >0
		// VPN_PORT_FORWARDING_LISTENING_PORTS: redirect incoming traffic to
		// these ports. Not for torrent clients.
		forward_listening_ports?: [...int & >0 & <65536]
		// VPN_PORT_FORWARDING_PROVIDER: custom forwarding code, useful with
		// the custom provider.
		forward_provider?: "private internet access" | "perfect privacy" | "privatevpn" | "protonvpn"
		// VPN_PORT_FORWARDING_STATUS_FILE (default /tmp/gluetun/forwarded_port).
		forward_status_file?: string
		// VPN_PORT_FORWARDING_UP_COMMAND / _DOWN_COMMAND.
		forward_up_command?:   string
		forward_down_command?: string
		// VPN_UP_COMMAND / VPN_DOWN_COMMAND ({{VPN_INTERFACE}} available).
		vpn_up_command?:   string
		vpn_down_command?: string

		// --- escape hatches for everything else gluetun accepts ---
		// Appended to Environment verbatim.
		extra_env: [...c.#KeyValue] | *[]
		// Appended to Secret verbatim: registry entries already unified with
		// their consumption fields, e.g.
		// [secrets.openvpn_user & {type: "env", target: "OPENVPN_USER"}].
		extra_secrets: [...] | *[]

		// The client network's address plan (mirrors #StaticNetworkMixin's
		// #static): subnet plus optional static members for the port-forward
		// callback pattern. The vpn network has no DNS and dynamic client
		// addresses, so a gluetun command that must call a client
		// (VPN_PORT_FORWARDING_UP_COMMAND posting the port to a torrent
		// client's API) has nothing stable to dial. members get addresses
		// from the same subnet plan as the vpn container; #ips exposes them
		// for config-time interpolation, the client pins its attachment with
		// them, and the vpn container gets an AddHost book so in-container
		// tools can use the names too.
		//
		//	#gluetun: {
		//	    network: {subnet: "10.20.0.0/24", members: ["qbit"]}
		//	    forward_up_command: "curl -s http://\(#gluetun.#ips.qbit):8080/api/v2/app/setPreferences ..."
		//	}
		//	units: containers: qbit: Container: {
		//	    #extraNetworks: [#gluetun.#network.#self & {ip: #gluetun.#ips.qbit}]
		//	}
		network: {
			// One IPv4 CIDR for the client network.
			subnet: string & net.IPCIDR
			// Static client names, addressed in author order after the vpn
			// container; append-only, like #StaticNetworkMixin's members.
			members: [...string] | *[]
			// First dynamic offset; raise consciously when members outgrow
			// the reserve (#Subnet.#fits fails loudly): changing it shifts
			// IPRange, which recreates the network.
			dynamic_start: int | *5
		}

		// name -> assigned address, for pins and interpolation.
		#ips: {for k, v in _subnet.byName if k != "vpn" {(k): v}}

		// Networks the preflight refuses to forward client traffic into.
		// Overriding replaces the list: include these again and append
		// host-specific blocks (e.g. the default podman bridge gateway).
		lan_blocks: [...string] | *["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16", "169.254.0.0/16"]
	}

	// Address plan: VPN container at the first static offset, clients
	// dynamic from .5.
	// The quadlet's own name, aliased before unit literals shadow `name`.
	_qname: name

	// Keep the VPN container off #StaticNetworkMixin's all-mode sweep (its
	// Network list is owned here). Inert when the static mixin is absent.
	// Open literals: a closed contribution would veto the static mixin's
	// own #static fields (the #checks-registration lesson).
	#static: {
		#exclude: {
			vpn: true
			...
		}
		...
	}

	_subnet: #Subnet & {
		#cidr: #gluetun.network.subnet

		// +0 collapses the input's star-default: unifying it directly with
		// #Subnet's own *10 default is two marked defaults, unresolvable.
		dynamicStart: #gluetun.network.dynamic_start + 0
		static: list.Concat([["vpn"], #gluetun.network.members])
	}

	_pf: [if #gluetun.port_forwarding {"on"}, "off"][0]

	units: {
		networks: {
			vpn: {

				// #dns is the client contract: the VPN container's address,
				// serving as both gateway (via the network route) and DNS. On
				// the network unit so attachers reference it beside #self
				// (units.networks.vpn.#dns); the mixin's own fields are not
				// lexically visible inside the consuming quadlet's literal.
				#dns: _subnet.byName.vpn
				Network: {
					NetworkDeleteOnStop: true
					Internal:            true
					DisableDNS:          true
					Subnet: [_subnet.cidr]
					IPRange: [_subnet.ipRange]
					// Marker for graph rules: this network's attachers are the
					// VPN container plus its clients.
					Label: ["creidhne.egress=\(name)"]
					Options: [
						"isolate=true",
						"no_default_route=1",
					]
					PodmanArgs: [
						// Every client gets its default route via the VPN
						// container; the preflight removes this route from the
						// VPN container itself.
						"--route 0.0.0.0/0,\(_subnet.byName.vpn),200",
						"--opt metric=200",
						"--opt mtu=1380",
					]
					...
				}
				...
			}
			...
		}

		builds: {
			vpn: {
				Build: {
					BuildArg: ["IMAGE=\(#gluetun.image)"]
					...
				}

				ContainerFile: #"""
					ARG IMAGE
					FROM ${IMAGE}

					RUN apk add --no-cache \
						nftables \
						jq bind-tools

					COPY . /
					ENTRYPOINT ["/preflight.sh"]
					"""#

				Context: {
					// Placeholder so the path exists in the image; the preflight
					// overwrites it at start (works because this container is
					// deliberately not ReadOnly).
					"iptables/post-rules.txt": """

						"""
					"preflight.sh": {
						mode:    "0777"
						content: #"""
						#!/bin/sh
						set -e
						# gluetun preflight: strip podman's self-referencing default route.
						# The network-wide --route 0.0.0.0/0,<vpn-ip> is meant for CLIENTS.
						# Gluetun IS that address, so it must not keep the route, and unlike
						# a pure forwarder it originates traffic (the WireGuard tunnel), so
						# the source-based rules pointing at table 200 must go too.

						VPN_IF=$(ip -j -4 addr show | jq --arg gateway_ip ${GATEWAY_IP} -r '.[] | select(.addr_info[].local == $gateway_ip) | .ifname')
						[ -n "$VPN_IF" ] || { echo "FATAL: no interface with ${GATEWAY_IP}" >&2; exit 1; }

						# every local v4 address, so we catch the DHCP'd uplink IP too
						ip -o -4 addr show | awk '{split($4,a,"/"); print a[1]}' | grep -v '^127\.' | \
						while read -r ip; do
							ip rule del from "$ip" lookup 200 2>/dev/null || true
						done

						ip route del default via ${GATEWAY_IP} dev "$VPN_IF" metric 200 2>/dev/null || true
						ip route flush table 200 2>/dev/null || true

						ip route show default | grep -q . || { echo "FATAL: no default route left"; exit 1; }
						echo "PREFLIGHT OK: $(ip route show default)"

						# Everything firewall-shaped goes through post-rules: gluetun
						# flushes the tables while building its own firewall, so rules
						# added here directly would not survive. LAN drops come first;
						# a client packet routed out tun0 toward a LAN destination
						# must die before the blanket tun0 ACCEPT.
						{
							echo "iptables -t nat -A POSTROUTING -o tun0 -j MASQUERADE"
							for net in \#(strings.Join(#gluetun.lan_blocks, " ")); do
								echo "iptables -A FORWARD -i $VPN_IF -d $net -j DROP"
							done
							echo "iptables -A FORWARD -i $VPN_IF ! -o tun0 -m state ! --state RELATED,ESTABLISHED -j DROP"
							echo "iptables -A FORWARD -i $VPN_IF -o tun0 -j ACCEPT"
							echo "iptables -A FORWARD -i tun0 -o $VPN_IF -m state --state RELATED,ESTABLISHED -j ACCEPT"
						} > /iptables/post-rules.txt

						exec /gluetun-entrypoint
						"""#
					}
					...
				}
				...
			}
			...
		}

		containers: {
			vpn: {
				Unit: {
					Requires: [#gluetun._uplinkService]
					After: [#gluetun._uplinkService]
					...
				}

				Container: {
					Image: units.builds.vpn.#self

					UserNS: "auto"

					AddCapability: ["CHOWN", "DAC_OVERRIDE", "FOWNER", "NET_ADMIN", "NET_RAW"]
					DropCapability: ["ALL"]
					AddDevice: ["/dev/net/tun"]
					NoNewPrivileges: true

					Sysctl: [
						"net.ipv4.ip_forward=1",
						"net.ipv4.ip_unprivileged_port_start=0",
						// v4-only stack:
						"net.ipv6.conf.all.disable_ipv6=1",
					]

					Network: [
						units.networks.vpn.#self & {ip: _subnet.byName.vpn},
						#gluetun._uplinkNet,
					]

					Tmpfs: [{
						path: "/tmp/gluetun"
						options: ["noexec", "nosuid", "size=50m", "mode=0777"]
					}]

					// Static clients resolvable by name inside gluetun.
					AddHost: [for k in #gluetun.network.members {"\(k):\(_subnet.byName[k])"}]

					// Nested lists, spliced by crei's flattening.
					Secret: [
						[
							#gluetun.private_key & {
								type:   "env"
								target: "WIREGUARD_PRIVATE_KEY"
							},
							#gluetun.addresses & {
								type:   "env"
								target: "WIREGUARD_ADDRESSES"
							},
						],
						[if #gluetun.auth_config != _|_ {
							#gluetun.auth_config & {
								type:   "env"
								target: "HTTP_CONTROL_SERVER_AUTH_DEFAULT_ROLE"
							}
						}],
						[if #gluetun.public_key != _|_ {
							#gluetun.public_key & {
								type:   "env"
								target: "WIREGUARD_PUBLIC_KEY"
							}
						}],
						[if #gluetun.preshared_key != _|_ {
							#gluetun.preshared_key & {
								type:   "env"
								target: "WIREGUARD_PRESHARED_KEY"
							}
						}],
						#gluetun.extra_secrets,
					]

					Environment: [
						[
							"FIREWALL_OUTBOUND_SUBNETS=\(#gluetun._uplinkCIDR)",
							"GATEWAY_IP=\(_subnet.byName.vpn)",
							"PORT_FORWARD_ONLY=\(_pf)",
							"SERVER_COUNTRIES=\(strings.Join(#gluetun.countries, ","))",
							"VPN_PORT_FORWARDING=\(_pf)",
							"VPN_SERVICE_PROVIDER=\(#gluetun.provider)",
							"VPN_TYPE=wireguard",
						],
						[
							if #gluetun.allowed_ips != _|_ {"WIREGUARD_ALLOWED_IPS=\(strings.Join(#gluetun.allowed_ips, ","))"},
							if #gluetun.endpoint_ip != _|_ {"WIREGUARD_ENDPOINT_IP=\(#gluetun.endpoint_ip)"},
							if #gluetun.endpoint_port != _|_ {"WIREGUARD_ENDPOINT_PORT=\(#gluetun.endpoint_port)"},
							if #gluetun.implementation != _|_ {"WIREGUARD_IMPLEMENTATION=\(#gluetun.implementation)"},
							if #gluetun.mtu != _|_ {"WIREGUARD_MTU=\(#gluetun.mtu)"},
							if #gluetun.keepalive != _|_ {"WIREGUARD_PERSISTENT_KEEPALIVE_INTERVAL=\(#gluetun.keepalive)"},
							if #gluetun.forward_ports_count != _|_ {"VPN_PORT_FORWARDING_PORTS_COUNT=\(#gluetun.forward_ports_count)"},
							if #gluetun.forward_listening_ports != _|_ {"VPN_PORT_FORWARDING_LISTENING_PORTS=\(strings.Join([for p in #gluetun.forward_listening_ports {"\(p)"}], ","))"},
							if #gluetun.forward_provider != _|_ {"VPN_PORT_FORWARDING_PROVIDER=\(#gluetun.forward_provider)"},
							if #gluetun.forward_status_file != _|_ {"VPN_PORT_FORWARDING_STATUS_FILE=\(#gluetun.forward_status_file)"},
							if #gluetun.forward_up_command != _|_ {"VPN_PORT_FORWARDING_UP_COMMAND=\(#gluetun.forward_up_command)"},
							if #gluetun.forward_down_command != _|_ {"VPN_PORT_FORWARDING_DOWN_COMMAND=\(#gluetun.forward_down_command)"},
							if #gluetun.vpn_up_command != _|_ {"VPN_UP_COMMAND=\(#gluetun.vpn_up_command)"},
							if #gluetun.vpn_down_command != _|_ {"VPN_DOWN_COMMAND=\(#gluetun.vpn_down_command)"},
						],
						#gluetun.extra_env,
					]

					Notify: "healthy"

					HealthCmd:         "CMD-SHELL /gluetun-entrypoint healthcheck"
					HealthInterval:    "30s"
					HealthRetries:     3
					HealthStartPeriod: "120s"
					HealthOnFailure:   "kill"
					...
				}

				Service: {
					Restart:      "on-failure"
					Type:         "notify"
					NotifyAccess: "all"
					...
				}
				...
			}
			...
		}
		...
	}
	...
}
