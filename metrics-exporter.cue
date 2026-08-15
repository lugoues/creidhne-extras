package creidhne_extras

import (
	c "github.com/lugoues/creidhne"
)

// #MetricsExporterMixin: pair-network isolation for service-owned prometheus
// exporters (nut_exporter, postgres_exporter, ...). Machine-scoped exporters
// (node, smartctl) stay sidecars in the otel-collector quadlet; a
// service-scoped exporter lives with its service and this mixin gives the
// collector a scrape path without a shared metrics network: one pair network
// per stack, otel-collector as its single external attacher (the same
// creidhne.pair contract as the traefik/docktail mixins).
//
//	nut: c.#Quadlet & ce.#MetricsExporterMixin & {
//	    name: "nut"
//	    #metrics: jobs: ups: {
//	        target: "\(units.containers.exporter.#containerName):9199"
//	    }
//	    units: containers: exporter: Container: Network: [
//	        #network.#self,          // reach upsd
//	        #metrics.#network.#self, // be reachable by the collector
//	    ]
//	}
//
// Collector side (otel-collector.cue): add the stack's #metrics to #scraped;
// that wires both the scrape job and the network attachment.
//
//	otel_collector: #scraped: [nut.#metrics]
#MetricsExporterMixin: {
	// name unifies with the quadlet's name when mixed into a #Quadlet.
	name: c.#UnitName
	// Declared for lexical visibility inside #metrics (conjuncts of a
	// unification do not share identifiers).
	units: _

	#checks: {
		"metrics-exporter/jobs": {
			assert: len(#metrics.jobs) > 0
			require: [for _, j in #metrics.jobs {j.target}]
			why: "mixing #MetricsExporterMixin requires at least one #metrics.jobs entry"
		}
		...
	}

	#metrics: {
		// pair is the marker value on the pair network. Suffixed so other
		// pair networks on the same quadlet keep distinct markers.
		pair: string | *"\(name)-metrics"
		// networkName is the pair network's handle: the units.networks key,
		// so the file is "<quadlet>-metrics.network".
		networkName: string | *"metrics"
		// Extra netavark options, appended after the fixed isolate.
		extraOptions?: [...c.#KeyValue]

		// jobs: one prometheus scrape job per exporter in the stack. The
		// exporter container must join #metrics.#network so the collector
		// can reach the target (crei's pair lint covers the collector side;
		// the service side is on you).
		jobs: [Job=string]: {
			// job_name in the collector's prometheus receiver; the quadlet
			// prefix keeps it unique across stacks.
			job: string | *"\(name)-\(Job)"
			// "host:port" - reference the exporter statically from inside
			// the quadlet, e.g.
			// "\(units.containers.exporter.#containerName):\(#port)".
			target!: string & =~"^[^:]+:[0-9]+$"
			// Scrape cadence; match it to how fast the source changes.
			interval: string | *"30s"
			// Metrics path; omitted: prometheus default /metrics.
			path?: string & =~"^/"
			// Query parameters appended to the scrape URL. Multi-target
			// exporters (prometheus-nut-exporter, blackbox, snmp) take the
			// thing they probe this way, and it cannot be folded into path:
			// prometheus puts path into url.Path and params into RawQuery, so
			// a "?" in path is escaped to %3F and never parsed as a query.
			//
			//	params: target: ["ups.example.net:3493"]
			params?: [string]: [...string]
			// Static labels stamped on every series this job scrapes. The
			// per-instance pattern for exporters that serve one instance per
			// scrape invocation (DRuggeri nut_exporter: one UPS per scrape,
			// selected by params) - one job per instance, labeled so series
			// are distinguishable by more than job name:
			//
			//	jobs: primary: {
			//	    target: "...:9199", path: "/ups_metrics"
			//	    params: ups: ["primary"]
			//	    labels: ups: "primary"
			//	}
			labels?: [string]: string
		}

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

		// #network aliases the placed unit: #metrics.#network.#self resolves
		// against the real network.
		#network: units.networks[_nn]

		// Open: placement-site decoration stays possible.
		...
	}

	// The mixin places the pair network itself at the networkName handle.
	units: {
		networks: {
			"\(#metrics.networkName)": #metrics._network
			...
		}
		...
	}

	// Open at the top: this mixin unifies with #Quadlet, which stays closed
	// and enforces the quadlet's own field set (units, name).
	...
}
