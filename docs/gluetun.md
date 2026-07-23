# `#GluetunMixin`

Per-consumer VPN egress: a gluetun container on its own isolated client
network, placed as additional units of the consuming quadlet
(`<name>-vpn.container/.network/.build`). The egress-side twin of the
[pair network](reverse-proxy.md): a shared VPN network makes every
consumer a peer of every other consumer, so each quadlet gets its own.

Killswitch by construction: clients are internal-only with a single
default route through the VPN container (metric-200, installed per client
by netavark), so a dead tunnel is no egress, not leaked egress. A
preflight strips the self-referencing route from the VPN container
itself, drops LAN-bound forwards, and installs the tun0 NAT post-rules.

## Usage

Composes with the other mixins; attachment rides existing channels:

```cue
firecrawl: creidhne.#Quadlet & ce.#TraefikProxyMixin & ce.#StaticNetworkMixin & ce.#GluetunMixin & {
    name: "firecrawl"
    #static: subnet: "10.30.0.0/24"
    #gluetun: {
        network:  subnet: "10.20.0.0/24"
        provider: "mullvad"
        countries: ["Sweden"]
        image:    "docker.io/qmcgaw/gluetun:v3.40"
        port_forwarding: false
        private_key: secrets.mullvad_wg_key
        addresses:   secrets.mullvad_wg_addresses
        auth_config: secrets.gluetun_auth
        uplink: internet_egress
    }
    units: containers: api: Container: {
        Image: "docker.io/fc-api"
        DNS: [#gluetun.#dns]
        #extraNetworks: [#gluetun.#network.#self]
    }
}
```

## Inputs (`#gluetun`)

| Field | Type | Default | Purpose |
| --- | --- | --- | --- |
| `network.subnet` | `net.IPCIDR` | required | Client network CIDR (VPN container at the first static offset) |
| `network.members` | `[...string]` | none | Static client names, addressed after the VPN container (the port-forward callback pattern; see below) |
| `network.dynamic_start` | `int` | `5` | First dynamic offset; raise when members outgrow the reserve |
| `provider` | `string` | required | gluetun `VPN_SERVICE_PROVIDER` |
| `countries` | `[...string]` | required | `SERVER_COUNTRIES`, comma-joined |
| `port_forwarding` | `bool` | `false` | `PORT_FORWARD_ONLY` + `VPN_PORT_FORWARDING` |
| `private_key`, `addresses` | `#SecretName` | required | WireGuard key and addresses, from the secrets registry |
| `auth_config?` | `#SecretName` | none | Control-server auth (`HTTP_CONTROL_SERVER_AUTH_DEFAULT_ROLE`); omit when nothing talks to gluetun's control server |
| `uplink` | quadlet | required | The quadlet this VPN tunnels through; the mixin derives its network handle, service ordering, and cidr (`FIREWALL_OUTBOUND_SUBNETS`) |
| `image` | image ref | required | The gluetun image the build wraps; any tag or digest reference |
| `lan_blocks` | `[...string]` | RFC1918+link-local | Nets the preflight refuses to forward into; overriding replaces the list (append host-specific blocks like the default podman bridge gateway) |

### WireGuard tuning (each emits its env only when set)

| Field | gluetun env |
| --- | --- |
| `public_key?` (`#SecretName`) | `WIREGUARD_PUBLIC_KEY`, as a podman secret |
| `preshared_key?` (`#SecretName`) | `WIREGUARD_PRESHARED_KEY`, as a podman secret |
| `allowed_ips?` (`[...string]`) | `WIREGUARD_ALLOWED_IPS`, comma-joined |
| `endpoint_ip?`, `endpoint_port?` | `WIREGUARD_ENDPOINT_IP` / `_PORT` |
| `implementation?` (enum) | `WIREGUARD_IMPLEMENTATION` |
| `mtu?` (`<=1440`) | `WIREGUARD_MTU` (tunnel-inner; the network's mtu option is separate) |
| `keepalive?` (duration) | `WIREGUARD_PERSISTENT_KEEPALIVE_INTERVAL` |

### Port-forwarding details (with `port_forwarding: true`)

| Field | gluetun env |
| --- | --- |
| `forward_ports_count?` | `VPN_PORT_FORWARDING_PORTS_COUNT` (up to 5 on ProtonVPN) |
| `forward_listening_ports?` | `VPN_PORT_FORWARDING_LISTENING_PORTS` (not for torrent clients) |
| `forward_provider?` (enum) | `VPN_PORT_FORWARDING_PROVIDER` |
| `forward_status_file?` | `VPN_PORT_FORWARDING_STATUS_FILE` |
| `forward_up_command?`, `forward_down_command?` | `VPN_PORT_FORWARDING_UP_COMMAND` / `_DOWN_COMMAND` |
| `vpn_up_command?`, `vpn_down_command?` | `VPN_UP_COMMAND` / `VPN_DOWN_COMMAND` |

### Everything else

- `extra_env: [...#KeyValue]` — appended to `Environment=` verbatim, for
  any gluetun option not modeled above.
- `extra_secrets: [...]` — appended to `Secret=`: registry entries with
  their consumption fields, e.g.
  `[secrets.openvpn_user & {type: "env", target: "OPENVPN_USER"}]`.

## Handles (the client contract)

- `#gluetun.#network` — the placed client network unit; attach via the
  static mixin's `#extraNetworks: [#gluetun.#network.#self]` (or the
  primary `#container`'s own `Network:` list).
- `#gluetun.#dns` — the VPN container's address: gateway (via the
  network route) and DNS for every client (`DNS: [#gluetun.#dns]`).
- `#gluetun.#ip` — the same address under its other hat, for non-DNS
  uses (probe targets, firewall rules, interpolated config).
- `#gluetun.#service` — the VPN container's systemd service; order
  clients behind it (`Requires` + `After`).

Do not write `units.networks.vpn.#self` directly in an additional
container's `Network:` list: that reference freezes under the cue 0.17
evaluator. The handle + channel path above is the production-proven one.

## Interplay

- **Static mixin**: the VPN container auto-excludes itself from the
  all-mode sweep (`#static.#exclude`), so `#static: subnet:` alone works
  alongside this mixin.
- The client network carries a `creidhne.egress=<name>` marker for
  future graph rules (attachers = the VPN container plus its clients).
- Startup ordering: the VPN container Requires/After the uplink's
  service; clients get only the auto-wired network-unit dependency. A
  client starting before the VPN blackholes (killswitch), it does not
  leak.

## Port-forward callback

The VPN network has no DNS and hands clients dynamic addresses, so a
gluetun command that must call a client has nothing stable to dial. Name
the client under `network.members`, and it gets a fixed address from the
same plan as the VPN container, exposed as `#gluetun.#ips.<name>`:

```cue
#gluetun: {
    network: {subnet: "10.20.0.0/24", members: ["qbit"]}
    port_forwarding:    true
    forward_up_command: "curl -s http://\(#gluetun.#ips.qbit):8080/api/v2/app/setPreferences -d 'json={\"listen_port\": {{PORTS}}}'"
}
units: containers: qbit: Container: {
    #extraNetworks: [#gluetun.#network.#self & {ip: #gluetun.#ips.qbit}]
}
```

The address is interpolated into the command at eval time (no runtime DNS
needed), the client pins its attachment with the same value, and the VPN
container also gets an `AddHost=qbit:<ip>` entry so in-container tools
resolve the name. gluetun's `{{PORTS}}` template survives (different
brace convention). This fires on every port-forward change including
down/re-up, which a file handoff would miss.

## Traps

- Each instance is its own WireGuard device: N consuming quadlets on one
  provider consume N device slots.
- The VPN container is deliberately **not** `ReadOnly`: the preflight
  rewrites `/iptables/post-rules.txt` at start. Hardening it breaks the
  rules silently.
- `lan_blocks` overriding replaces the default list; include the RFC1918
  ranges again when appending.
