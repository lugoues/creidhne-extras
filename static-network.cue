package creidhne_extras

import (
	"list"
	"math"
	"net"
	"strconv"
	"strings"

	c "github.com/lugoues/creidhne"
)

// #StaticNetworkMixin is "DNS in CUE": a DNS-less internal network plus
// a static address book injected into its member containers. It exists
// because aardvark's upstream forwarding cannot be disabled without
// disabling DNS entirely; here names resolve through /etc/hosts instead.
//
// A quadlet-level mixin: members are keys into units.containers, and it
// injects each member's attachment, hosts book, and a ContainerName
// default (quadlet's own systemd-<stem>, so membership never renames a
// container); `\(x.#containerName)` in configs resolves through the book
// exactly as it would through DNS.
//
//	firecrawl: creidhne.#Quadlet & ce.#StaticNetworkMixin & {
//	    name: "firecrawl"
//	    #static: {
//	        subnet: "10.30.0.0/24"
//	        members: {
//	            dashboard: _
//	            api:       _
//	            redis: {ip: "10.30.0.40"} // pin an address explicitly
//	        }
//	    }
//	    units: containers: {
//	        dashboard: Container: {Image: "..."}
//	        api: Container: {Image: "...", Environment: [
//	            "REDIS=redis://\(units.containers.redis.#containerName):6379",
//	        ]}
//	        redis: Container: {Image: "..."}
//	    }
//	}
#StaticNetworkMixin: {
	name: c.#UnitName

	#static: {
		// One IPv4 CIDR, any prefix length; offsets are bounds-checked.
		subnet: string
		// Handle of the placed network unit (file <quadlet>-<networkName>.network).
		networkName: string | *"static"
		// First host offset auto-assigned; the gateway takes low addresses.
		start: int & >1 | *10

		// members are keys into units.containers (additional containers
		// only: the primary #container has no key to inject by). Omit the
		// field entirely and every container in the quadlet is a member;
		// list members explicitly to select a subset. IPs are
		// auto-assigned by sorted key order, so renaming or inserting
		// keys renumbers; pin ip: to opt a member out of auto-assignment.
		members?: [Key=string]: {
			ip?: string
		}
	}

	// The normalized member set: explicit members, or every container.
	_members: {
		if #static.members != _|_ {#static.members}
		if #static.members == _|_ {for k, _ in units.containers {(k): {}}}
	}

	_keys: list.SortStrings([for k, _ in _members {k}])
	_idx: {for i, k in _keys {(k): i}}

	_octets: net.ToIP4(strings.Split(#static.subnet, "/")[0])
	_prefix: strconv.Atoi(strings.Split(#static.subnet, "/")[1])
	_baseN:  _octets[0]*16777216 + _octets[1]*65536 + _octets[2]*256 + _octets[3]
	_ip: {
		// Bounded to the subnet's host range (capacity minus broadcast).
		#off: int & >0 & <(math.Exp2(32-_prefix) - 1)
		_n:   _baseN + #off
		out:  "\(_n div 16777216).\((_n div 65536) mod 256).\((_n div 256) mod 256).\(_n mod 256)"
	}
	_ipOf: {for k, m in _members {
		if m.ip != _|_ {(k): m.ip}
		if m.ip == _|_ {(k): (_ip & {#off: #static.start + _idx[k]}).out}
	}}

	// Injected ContainerName defaults: quadlet's own runtime default,
	// systemd-<stem>, with the stem read back from #ref (its one visible
	// carrier), so joining the network never changes a runtime name. The
	// book must not read the computed #containerName (its optional-probing
	// disjunction freezes evalv3 across mutually-booked members, at any
	// level); with the default injected the field is always effectively
	// present, the book reads it safely, and user overrides win by normal
	// default semantics.
	_defName: {for k, _ in _members {
		(k): "systemd-" + strings.TrimSuffix(units.containers[k].#ref, ".container")
	}}

	// The address book every member receives: effective runtime names.
	_book: [for k, _ in _members {"\(units.containers[k].Container.ContainerName):\(_ipOf[k])"}]

	// Misplaced knobs are otherwise silent (closedness cannot reject
	// definition fields): fail the build when they sit on the unit
	// instead of inside Container.
	// Open literal: see reverse-proxy.cue, closed registrations veto each other.
	#checks: {
		"static-network/knob-placement": {
			assert: len([for k, _ in _members if units.containers[k].#extraNetworks != _|_ || units.containers[k].#extraHosts != _|_ {k}]) == 0
			why: "#extraNetworks/#extraHosts go inside Container (next to Network/AddHost), not on the unit"
		}
		...
	}

	units: {
		networks: {
			// #InternalNetworkSpec guarantees, plus DisableDNS: this mixin's
			// premise, the hosts book replaces aardvark entirely.
			(#static.networkName): #InternalNetworkSpec & {
				Network: {
					DisableDNS: true
					Subnet: [#static.subnet]
					...
				}
				...
			}
			...
		}
		containers: {
			// Constrain, never insert: the pattern applies the injection to
			// members and no-ops for other containers. A comprehension over
			// the member keys would be self-referential when the domain is
			// units.containers itself (omitted members).
			[Key=string]: {
				if _members[Key] != _|_ {
					Container: {
						// The mixin owns Network and AddHost (injected lists
						// cannot merge with user lists); extras go through
						// these, declared beside the lists they extend
						// (definition fields: closedness-exempt, export-dropped).
						#extraNetworks?: [...(c.#NetworkMode | c.#NetworkSelf | c.#ContainerSelf)]
						#extraHosts?: [...c.#HostMapping]
						ContainerName: *_defName[Key] | string
						// Nested lists, spliced by crei's flattening: an eager
						// list.Concat would force _book while these containers
						// are being constructed, a structural cycle.
						Network: [
							units.networks[#static.networkName].#self & {ip: _ipOf[Key]},
							if units.containers[Key].Container.#extraNetworks != _|_ {units.containers[Key].Container.#extraNetworks},
						]
						// Knob guards use absolute paths: a lexical reference
						// into this literal fails to resolve when the unit is
						// embedded into the manifest (data: u).
						AddHost: [
							_book,
							if units.containers[Key].Container.#extraHosts != _|_ {units.containers[Key].Container.#extraHosts},
						]
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

	// Open at the top: #Quadlet enforces the quadlet's field set.
	...
}
