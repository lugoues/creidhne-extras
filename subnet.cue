package creidhne_extras

import (
	"list"
	"math"
	"net"
)

// #Subnet plans a subnet's address layout: gateway, a fixed static block,
// and the dynamic range, ready to wire into a .network unit. The static
// reserve [staticStart, dynamicStart) is fixed, so adding a host never
// changes ipRange (a changed range means recreating the network); statics
// overflowing the reserve fail the build (#fits) instead of shifting it.
//
//	_subnets: lan: ce.#Subnet & {
//	    #cidr: "10.20.0.0/24"
//	    static: ["hosta", "hostb"]
//	}
//
//	units: networks: lan: Network: {
//	    Subnet:  [_subnets.lan.cidr]
//	    Gateway: [_subnets.lan.gateway]
//	    IPRange: [_subnets.lan.ipRange]
//	}
//	// pins: #static: members: hosta: ip: _subnets.lan.byName.hosta
//
// Declare instances under a hidden or definition field (as above): a
// project-wide `[_]: creidhne.#Quadlet` pattern would otherwise sweep the
// helper up and reject it against the quadlet's closed field set.
//
// Requires the cue 0.17 evaluator (crei >= v2.6.0) for net.ParseCIDR/AddIP.
#Subnet: {
	#cidr:  string & net.IPCIDR
	_p:     net.ParseCIDR(#cidr)
	_hosts: math.Exp2(32-_p.prefix_len) - 2

	// Static hosts, assigned increasing IPs from staticStart in author
	// order. Append-only: inserting mid-list renumbers everything after.
	static: [...string]
	static:       list.UniqueItems()
	staticStart:  int & >1 | *2
	dynamicStart: int & <=_hosts | *10

	#fits: true
	#fits: staticStart+len(static) <= dynamicStart

	// hostname -> assigned IP.
	byName: {for i, h in static {(h): net.AddIP(_p.prefix_addr, staticStart+i)}}

	gateway:    net.AddIP(_p.prefix_addr, 1)
	rangeStart: net.AddIP(_p.prefix_addr, dynamicStart)
	rangeEnd:   net.AddIP(_p.broadcast_addr, -1)
	ipRange:    "\(rangeStart)-\(rangeEnd)"
	cidr:       #cidr
}
