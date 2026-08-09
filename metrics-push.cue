package creidhne_extras

import (
	c "github.com/lugoues/creidhne"
)

// #MetricsPushMixin: pair-network path for services that PUSH OTLP metrics to
// the host collector instead of exposing a prometheus scrape target.
//
// #MetricsExporterMixin is the scrape case and cannot cover this one: it
// hard-requires at least one #metrics.jobs entry, and the connection runs the
// other way round. Some services refuse to serve /metrics at all - rustfs
// closed the PR that added one ("we have decided not to provide an active
// scraping endpoint for metrics in RustFS", rustfs/rustfs#3082) - so OTLP push
// is the only path, and the service dials the collector rather than the
// reverse.
//
// Same creidhne.pair contract as the traefik/docktail/metrics-exporter mixins:
// one pair network per stack, the collector as its single external attacher.
//
// The mixin has nothing to configure - it is the pair network and that is all.
// #metrics_push is declared at the placement site only so the identifier is
// lexically visible further down (conjuncts of a unification do not share
// identifiers); the collector's address comes from its own #endpoint.
//
//	rustfs: c.#Quadlet & #MetricsPushMixin & {
//	    name: "rustfs"
//	    #metrics_push: _
//	    units: #container: Container: {
//	        Environment: ["RUSTFS_OBS_ENDPOINT=\(otel_collector.#endpoint)"]
//	        Network: [..., #metrics_push.#network.#self]
//	    }
//	}
//
// Collector side (otel-collector.cue): list the stack's #metrics_push in the
// collector's #pushed, which attaches the pair network and nothing else.
//
//	otel_collector: #pushed: [rustfs.#metrics_push]
//
// #pushed rather than #ship_networks deliberately: #ship_networks is the
// collector's egress, the networks it reaches OUT over to ship telemetry.
// A pair network here is ingress, a path a service dials IN on. Both end up
// in the same Network list, but overloading the egress field to carry ingress
// makes each one's purpose unreadable at the call site.
#MetricsPushMixin: {
	// name unifies with the quadlet's name when mixed into a #Quadlet.
	name: c.#UnitName
	// Declared for lexical visibility inside #metrics_push (conjuncts of a
	// unification do not share identifiers).
	units: _

	#metrics_push: {
		// pair is the marker value on the pair network. Suffixed so other
		// pair networks on the same quadlet keep distinct markers.
		pair: string | *"\(name)-metrics-push"
		// networkName is the pair network's handle: the units.networks key,
		// so the file is "<quadlet>-metrics-push.network".
		networkName: string | *"metrics-push"
		// Extra netavark options, appended after the fixed isolate.
		extraOptions?: [...c.#KeyValue]

		// No endpoint field, deliberately: the collector publishes its own
		// address as #endpoint and consumers read it there. Holding it here
		// instead would put a pointer back at the collector inside the value
		// the collector itself reads through #pushed, closing an evaluation
		// loop through Container.Network. Keeping this struct collector-
		// agnostic is what makes it as safe to pass around as #metrics.

		// The pair network's unit body, placed at units.networks[networkName].
		_network: #InternalNetworkSpec & {
			if extraOptions != _|_ {#extraOptions: extraOptions}
			Network: {
				Label: ["creidhne.pair=\(pair)"]
				...
			}
			...
		}

		// _nn collapses networkName's star-default into a concrete string
		// (load-bearing interpolation; see the docktail mixin).
		_nn: "\(networkName)"

		// #network aliases the placed unit: #metrics_push.#network.#self
		// resolves against the real network.
		#network: units.networks[_nn]

		// Open: placement-site decoration stays possible.
		...
	}

	// The mixin places the pair network itself at the networkName handle.
	units: {
		networks: {
			"\(#metrics_push.networkName)": #metrics_push._network
			...
		}
		...
	}

	// Open at the top: this mixin unifies with #Quadlet, which stays closed
	// and enforces the quadlet's own field set (units, name).
	...
}
