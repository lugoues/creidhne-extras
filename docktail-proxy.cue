package creidhne_extras

import (
	"list"
	"strings"

	c "github.com/lugoues/creidhne"
)

// #DocktailProxyMixin: pair-network isolation for docktail-exposed services.
// Sibling of #TraefikProxyMixin, but self-contained on its own handle
// (#tailnet) and its own pair network (units.networks.docktail) so both
// mixins can coexist on one quadlet: two pair networks, one external
// attacher each, so the creidhne.pair one-attacher contract holds for both.
//
// Services only, deliberately: docktail services are tailnet Services
// (svc: VIPs with their own names), which fit the per-service reverse-proxy
// scheme. Tailscale Funnel does not - it is node-scoped (answers as the
// HOST's ts.net hostname, and its default :443 collides with traefik's
// tailscale_ip:443 publish), so public exposure is out of scope here; a
// hand-rolled docktail.funnel.* label via extraLabels or a per-service
// tsnet sidecar are the escape hatches.
//
//	hermes: c.#Quadlet & ce.#TraefikProxyMixin & ce.#DocktailProxyMixin & {
//	    name: "hermes"
//	    #exposes: routes: web: {port: 8080, rule: "Host(`hermes.lugoues.dev`)"}
//	    #tailnet: services: hermes: {port: 8080}
//	    units: #container: Container: {
//	        Network: [.., #exposes.#network.#self, #tailnet.#network.#self]
//	        Label: [#exposes.#label, #tailnet.#label]
//	    }
//	}
//
//	docktail: units: #container: Container: Network: [
//	    hermes.#tailnet.#network.#self, // one per exposed service
//	]
#DocktailProxyMixin: {
	// name unifies with the quadlet's name when mixed into a #Quadlet.
	name: c.#UnitName
	// Declared for lexical visibility inside #tailnet (conjuncts of a
	// unification do not share identifiers).
	units: _

	// _labelPools: every Label list in the quadlet, nested splices intact;
	// the checks scan them (same shape as the traefik mixin's).
	_dtLabelPools: list.Concat([
		[for _, u in units.containers if u.Container.Label != _|_ {u.Container.Label}],
		[for _, u in units.pods if u.Pod.Label != _|_ {u.Pod.Label}],
		[if units.#container != _|_ if units.#container.Container.Label != _|_ {units.#container.Container.Label}],
		[if units.#pod != _|_ if units.#pod.Pod.Label != _|_ {units.#pod.Pod.Label}],
	])

	#checks: {
		"docktail-proxy/services": {
			assert: len(#tailnet.services) > 0
			require: [for _, s in #tailnet.services {s.port}]
			why: "mixing #DocktailProxyMixin requires at least one #tailnet.services entry"
		}
		// Equality guard, not unification: iterating a nested label splice
		// yields a phantom schema element (#LabelValue | [...]) that UNIFIES
		// with any label string and would satisfy the scan spuriously; == is
		// false for it (non-concrete), so it filters cleanly.
		"docktail-proxy/label-placed": {
			assert: len(list.Concat([
				[for pool in _dtLabelPools for e in pool if e == "docktail.service.enable=true" {e}],
				[for pool in _dtLabelPools for e in pool if (e & [...]) != _|_ for x in e if x == "docktail.service.enable=true" {x}],
			])) > 0
			why: "splice #tailnet.#label into a container or pod Label list; without it docktail never discovers the service"
		}
		...
	}

	#tailnet: {
		// pair is the marker value on the pair network. Suffixed so a
		// traefik pair network on the same quadlet keeps a distinct marker.
		pair: string | *"\(name)-docktail"
		// networkName is the pair network's handle: the units.networks key,
		// so the file is "<quadlet>-docktail.network".
		networkName: string | *"docktail"
		// Extra netavark options, appended after the fixed isolate.
		extraOptions?: [...c.#KeyValue]

		// Comma-joined into docktail.tags: tailscale service tags for every
		// service on this quadlet (docktail reconciles them as the source of
		// truth). Omitted: docktail's DEFAULT_SERVICE_TAGS applies.
		tags?: [...string]
		// Appended verbatim to #label: docktail.service.direct, or a
		// hand-rolled docktail.funnel.* set if a host-level funnel is truly
		// wanted (never funnel-port 443: it collides with traefik's
		// tailscale_ip:443 publish).
		extraLabels?: [...c.#KeyValue]

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
		// (same load-bearing interpolation as the traefik mixin's
		// #serviceName): indexing units.networks by the raw defaulted string
		// leaves the lookup unresolved on crei's render path.
		_nn: "\(networkName)"

		// #network aliases the placed unit: #tailnet.#network.#self and
		// #networkName resolve against the real network.
		#network: units.networks[_nn]

		// Shared labels, emitted once per placement. The network label is
		// the analog of traefik.docker.network: with a multi-homed
		// container, docktail must resolve the backend IP on the pair
		// network. The interpolation is inlined, not shared through a hidden
		// field: a hidden-field reference inside a label list stays
		// incomplete on crei's render path (cue 0.17 evaluator quirk).
		_shared: list.Concat([
			[
				"docktail.service.enable=true",
				"docktail.service.network=\(units.networks[_nn].#networkName)",
			],
			[if tags != _|_ {"docktail.tags=" + strings.Join(tags, ",")}],
		])

		// services: one tailscale service per key. docktail's multi-service
		// labels are positional (docktail.service.* for the first,
		// docktail.service.<N>.* after): keys are emitted in sorted order.
		// Which service lands unindexed is semantically irrelevant (tags and
		// network are inherited from it, and both are emitted quadlet-wide
		// here); sorting just keeps the rendering deterministic.
		services: [Service=string]: {
			// service is the tailscale service name; defaults to the key.
			service: string | *Service
			// Backend container port docktail proxies to.
			port!: int & >0 & <65536
			// Shown in the tailscale admin panel (needs API credentials).
			// No single quotes: the emitted label is single-quoted so
			// descriptions with spaces survive quadlet's word-splitting.
			description?: string & !~"'"
			// Backend protocol; omitted: docktail's smart default
			// (https when port is 443, else http).
			protocol?: "http" | "https" | "tcp"
			// Tailscale-facing port; omitted: 443 for https, else 80.
			servicePort?: int & >0 & <65536
			// Tailscale-facing protocol; omitted: docktail's smart default.
			serviceProtocol?: "http" | "https" | "tcp"
		}

		_ordered: list.SortStrings([for k, _ in services {k}])

		// #label aggregates every service for the single-container case.
		#label: list.Concat(list.Concat([
			[_shared],
			[for i, k in _ordered
				let s = services[k]
				let p = [if i == 0 {"docktail.service."}, "docktail.service.\(i)."][0] {
					list.Concat([
						[
							"\(p)name=\(s.service)",
							"\(p)port=\(s.port)",
						],
						[if s.description != _|_ {"'\(p)description=\(s.description)'"}],
						[if s.protocol != _|_ {"\(p)protocol=\(s.protocol)"}],
						[if s.servicePort != _|_ {"\(p)service-port=\(s.servicePort)"}],
						[if s.serviceProtocol != _|_ {"\(p)service-protocol=\(s.serviceProtocol)"}],
					])
				}],
			[[if extraLabels != _|_ for l in extraLabels {l}]],
		]))

		// Open: placement-site decoration stays possible.
		...
	}

	// The mixin places the pair network itself at the networkName handle.
	units: {
		networks: {
			"\(#tailnet.networkName)": #tailnet._network
			...
		}
		...
	}

	// Open at the top: this mixin unifies with #Quadlet, which stays closed
	// and enforces the quadlet's own field set (units, name).
	...
}
