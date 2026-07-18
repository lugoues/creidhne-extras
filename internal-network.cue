package creidhne_extras

import (
	"list"

	c "github.com/lugoues/creidhne"
)

// #InternalNetworkSpec hardens a network unit for container-to-container
// use. Guarantees, not defaults (overriding any of them is a conflict):
//
//   - Internal: no gateway routing, no NAT, never an egress path
//   - isolate=strict: no cross-network traffic at all (netavark >= 1.7;
//     netavark >= 2.0 defaults to it)
//   - NetworkDeleteOnStop: removed when the network's own unit stops.
//     Attachers depend on the network unit, so systemd stops them first
//     and removal runs against an empty network; stopping a consuming
//     service alone never touches the network.
//
// No DisableDNS, reluctantly: peers resolve each other through aardvark,
// which also forwards non-container queries to the host's resolvers, an
// egress side-channel through an otherwise Internal network. Killing it
// requires resolving names another way; #StaticNetworkMixin is that full
// treatment ("DNS in CUE").
//
// A unit-level spec: unify it with a network unit and decorate in place.
//
//	units: networks: internal: ce.#InternalNetworkSpec & {
//	    #extraOptions: ["mtu=1400"]
//	    Network: Subnet: ["10.60.0.0/24"]
//	}
#InternalNetworkSpec: {
	// Extra netavark options, appended after the fixed isolate.
	#extraOptions?: [...c.#KeyValue]

	Network: {
		Internal:            true
		NetworkDeleteOnStop: true
		Options: list.Concat([
			["isolate=strict"],
			[if #extraOptions != _|_ for o in #extraOptions {o}],
		])
		...
	}
	...
}
