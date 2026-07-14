package creidhne_extras

import (
	"list"
	"strings"

	c "github.com/lugoues/creidhne"
)

// #ReverseProxySpec is the per-service reverse-proxy pattern: a dedicated
// "pair" network shared only by one service and the proxy. Podman networks
// have no peer isolation (every peer sees every peer), so isolation comes
// from one network per exposed service.
//
// The spec places the pair network itself at the networkName handle
// (default: units.networks.proxy); container attachment and labels stay
// explicit. Unify it at the quadlet level so it reads the quadlet's name:
//
//	grafana: creidhne.#Quadlet & ce.#TraefikProxySpec & {
//	    name: "grafana"
//	    #exposes: {port: 3000, rule: "Host(`grafana.example.lan`)"}
//	    units: #container: Container: {
//	        Network: [units.networks.proxy.#self]
//	        Label: [#exposes.#label] // nested label block, splices flat
//	    }
//	}
//
//	traefik: creidhne.#Quadlet & {
//	    units: #container: Container: {
//	        Network: [grafana.units.networks.proxy.#self] // one per service
//	    }
//	}
//
// The pair network carries a "creidhne.pair=<pair>" marker label: exactly two
// containers (the service and the proxy) should ever attach to it. A future
// crei lint rule can verify that cardinality from the graph; the marker is
// the whole contract, so the check needs no knowledge of this helper.
#ReverseProxySpec: {
	// name unifies with the quadlet's name when mixed into a #Quadlet.
	name: c.#UnitName

	#exposes: {
		// pair is the marker value on the pair network.
		pair: string | *name
		// networkName is the pair network's handle: the units.networks key,
		// so the file is "<quadlet>-<networkName>.network". The runtime name
		// is quadlet's default (or a NetworkName decoration); labels read it
		// through the canonical #network.#networkName, so it cannot drift.
		networkName: string | *"proxy"
		// Extra netavark options, appended after the fixed isolate.
		extraOptions?: [...c.#KeyValue]

		// _network is the pair network's unit body, placed by the spec at
		// units.networks.proxy. Internal/DisableDNS/isolate are the hardened
		// guarantees and cannot be overridden; everything else stays open for
		// placement-site decoration (units: networks: proxy: {Network: ...}).
		_network: {
			Network: {
				// Container-to-container only: no DNS, no gateway, no NAT, no
				// cross-network traffic (strict needs netavark >= 1.7).
				DisableDNS: true
				Internal:   true
				Options: list.Concat([
					["isolate=strict"],
					[if extraOptions != _|_ for o in extraOptions {o}],
				])
				Label: ["creidhne.pair=\(pair)"]
				...
			}
			...
		}

		// #network aliases the placed unit: #exposes.#network.#self and
		// #networkName resolve against the real network.
		#network: units.networks[networkName]

		// Open: proxy-specific layers (#TraefikProxySpec) extend this struct.
		// Those layers are closed, so user-side typos are still rejected.
		...
	}

	// The spec places the pair network itself at the networkName handle.
	units: {
		networks: {
			"\(#exposes.networkName)": #exposes._network
			...
		}
		...
	}

	// Open at the top: this spec unifies with #Quadlet, which stays closed
	// and enforces the quadlet's own field set (units, name).
	...
}

// #TraefikProxySpec layers the traefik label DSL on the pair-network pattern.
// Splice #exposes.#label into the container's Label list.
// traefik.docker.network points traefik at the pair network even when the
// container sits on several networks; without it traefik picks an arbitrary
// IP (intermittent 502s).
#TraefikProxySpec: #ReverseProxySpec & {
	name: c.#UnitName
	// Declared for lexical visibility inside #exposes (conjuncts of a
	// unification do not share identifiers).
	units: _

	// Mixing this spec in declares intent to expose: fail the build when the
	// config was never filled instead of rendering a bare pair network.
	#checks: "traefik-proxy/exposes": {
		require: [#exposes.port, #exposes.rule]
		why: "mixing #TraefikProxySpec requires #exposes: {port, rule}"
	}

	#exposes: {
		// Inherited generic inputs, re-listed so this closed layer admits
		// them; networkName stays non-optional so #label can reference it.
		pair?:       string
		networkName: string
		extraOptions?: [...c.#KeyValue]
		// router keys the traefik router and service.
		router: string | *name

		// Backend port the container listens on.
		port!: int & >0 & <65536
		// Router rule, e.g. "Host(`grafana.example.lan`)". No single quotes:
		// the emitted label is single-quoted so rules with spaces survive
		// quadlet's word-splitting.
		rule!: string & !~"'"
		// Router entrypoints (e.g. ["websecure"]); omitted: traefik default.
		entrypoints?: [...string]
		// Appended verbatim: middlewares, TLS options, ...
		extraLabels?: [...c.#KeyValue]

		#label: list.Concat([
			[
				"traefik.enable=true",
				"'traefik.http.routers.\(router).rule=\(rule)'",
				"traefik.http.services.\(router).loadbalancer.server.port=\(port)",
				"traefik.docker.network=\(units.networks[networkName].#networkName)",
			],
			[if entrypoints != _|_ {
				"traefik.http.routers.\(router).entrypoints=" + strings.Join(entrypoints, ",")
			}],
			[if extraLabels != _|_ for l in extraLabels {l}],
		])
	}

	// Open at the top, like #ReverseProxySpec: #Quadlet enforces closedness.
	...
}
