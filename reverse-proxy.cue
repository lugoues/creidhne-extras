package creidhne_extras

import (
	"list"
	"strings"

	c "github.com/lugoues/creidhne"
)

// #ReverseProxyMixin is the per-service reverse-proxy pattern: a dedicated
// "pair" network shared only by one service and the proxy. Podman networks
// have no peer isolation (every peer sees every peer), so isolation comes
// from one network per exposed service.
//
// The mixin places the pair network itself at the networkName handle
// (default: units.networks.proxy); container attachment and labels stay
// explicit. Unify it at the quadlet level so it reads the quadlet's name:
//
//	grafana: creidhne.#Quadlet & ce.#TraefikProxyMixin & {
//	    name: "grafana"
//	    #exposes: routes: {
//	        web: {port: 3000, rule: "Host(`grafana.example.lan`)"}
//	        api: {port: 3001, rule: "Host(`api.grafana.example.lan`)"}
//	    }
//	    units: #container: Container: {
//	        Network: [units.networks.proxy.#self]
//	        Label: [#exposes.#label] // every route; or per route:
//	                                 // [#exposes.routes.web.#label]
//	    }
//	}
//
//	traefik: creidhne.#Quadlet & {
//	    units: #container: Container: {
//	        Network: [grafana.units.networks.proxy.#self] // one per service
//	    }
//	}
//
// The pair network carries a "creidhne.pair=<pair>" marker label: the owning
// quadlet's units (one or several route-serving containers) plus exactly one
// external attacher, the proxy. crei's graph rules enforce it (crei lint /
// validate); the marker is the whole contract, so the check needs no
// knowledge of this helper.
#ReverseProxyMixin: {
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

		// _network is the pair network's unit body, placed by the mixin at
		// units.networks.proxy: #InternalNetworkSpec guarantees plus the
		// pair marker; everything else stays open for placement-site
		// decoration (units: networks: proxy: {Network: ...}).
		//
		// No DisableDNS, reluctantly: it exists for isolation, not hygiene.
		// aardvark forwards non-container queries to the host's resolvers,
		// so DNS is an egress side-channel through an otherwise Internal
		// network, and DisableDNS is the only per-network off-switch. But
		// combined with Internal, podman < 6 omits the network's gateway
		// address and traefik's docker client fails on Gateway "<nil>",
		// never configuring the backend (podman#28705, fixed by #28711).
		// The side-channel stays open until podman 6 is the floor.
		_network: #InternalNetworkSpec & {
			if extraOptions != _|_ {#extraOptions: extraOptions}
			Network: {
				Label: ["creidhne.pair=\(pair)"]
				...
			}
			...
		}

		// #network aliases the placed unit: #exposes.#network.#self and
		// #networkName resolve against the real network.
		#network: units.networks[networkName]

		// Open: proxy-specific layers (#TraefikProxyMixin) extend this struct.
		// Those layers are closed, so user-side typos are still rejected.
		...
	}

	// The mixin places the pair network itself at the networkName handle.
	units: {
		networks: {
			"\(#exposes.networkName)": #exposes._network
			...
		}
		...
	}

	// Open at the top: this mixin unifies with #Quadlet, which stays closed
	// and enforces the quadlet's own field set (units, name).
	...
}

// #TraefikProxyMixin layers the traefik label DSL on the pair-network pattern.
// Each #exposes.routes entry is one router/service; all routes share the
// quadlet's single pair network. Splice #exposes.#label (every route) or a
// route's own #label into the container's Label list.
// traefik.docker.network points traefik at the pair network even when the
// container sits on several networks; without it traefik picks an arbitrary
// IP (intermittent 502s).
//
// A route's `protocol` picks the label family. "tcp" routes traefik as a raw
// splice, for protocols it cannot parse; they need their own entrypoint,
// since raw TCP carries nothing to demultiplex a shared port on, and
// HostSNI(`*`) as the rule when there is no TLS to read an SNI from:
//
//	socks_proxy: creidhne.#Quadlet & ce.#TraefikProxyMixin & {
//	    name: "socks-proxy"
//	    #exposes: routes: socks: {
//	        protocol: "tcp"
//	        port:     1080
//	        rule:     "HostSNI(`*`)"
//	        entrypoints: ["socks"]
//	    }
//	}
//
// Backends behind a tcp route see traefik's address, not the client's:
// traefik can send PROXY protocol (a loadbalancer.proxyProtocol.version
// extraLabel) but only if the backend reads it. Client-IP ACLs in the backend
// stop working the moment it moves behind a tcp route; move them to a
// tcp ipallowlist middleware or the entrypoint's bind address.
#TraefikProxyMixin: #ReverseProxyMixin & {
	name: c.#UnitName
	// Declared for lexical visibility inside #exposes (conjuncts of a
	// unification do not share identifiers).
	units: _

	// _labelPools: every Label list in the quadlet (containers and pods,
	// primary and additional), nested splices intact; the checks scan them.
	_labelPools: list.Concat([
		[for _, u in units.containers if u.Container.Label != _|_ {u.Container.Label}],
		[for _, u in units.pods if u.Pod.Label != _|_ {u.Pod.Label}],
		[if units.#container != _|_ if units.#container.Container.Label != _|_ {units.#container.Container.Label}],
		[if units.#pod != _|_ if units.#pod.Pod.Label != _|_ {units.#pod.Pod.Label}],
	])

	// Mixing this in declares intent to expose: fail the build when no
	// route was filled instead of rendering a bare pair network, and force
	// every route's required fields even before its label is placed.
	// Registered through an open literal: a mixin's #checks registration is
	// definition-nested and therefore closed, so two mixins' single-key
	// registrations on one quadlet would veto each other without the `...`.
	#checks: {
		"traefik-proxy/exposes": {
			assert: len(#exposes.routes) > 0
			require: list.Concat([
				[for _, r in #exposes.routes if r._own {r.port}],
				[for _, r in #exposes.routes {r.rule}],
			])
			why: "mixing #TraefikProxyMixin requires at least one #exposes.routes entry"
		}
		// The routes only take effect where their labels land: require the
		// shared discovery label on at least one container or pod. Lazy
		// two-level scan (Label nests exactly one level per the schema):
		// list.FlattenN freezes here, eagerly evaluating lists that
		// reference this same instance (#exposes.#label) into elements that
		// never resolve. The unification guards double as type filters, so
		// #Rendered structs in the pools never hit a mixed-type comparison.
		// Equality guards, not unification: iterating a nested label splice
		// yields a phantom schema element (#LabelValue | [...]) that UNIFIES
		// with any label string, so the unification guard is satisfied by
		// ANY nested splice (e.g. another mixin's labels) even when the
		// traefik label was never placed - the check silently passes on
		// misconfigured quadlets. == is false for the non-concrete phantom,
		// so it filters cleanly; (e & [...]) stays as the list type filter.
		"traefik-proxy/label-placed": {
			assert: len(list.Concat([
				[for pool in _labelPools for e in pool if e == "traefik.enable=true" {e}],
				[for pool in _labelPools for e in pool if (e & [...]) != _|_ for x in e if x == "traefik.enable=true" {x}],
			])) > 0
			why: "splice #exposes.#label (or a route's #label) into a container or pod Label list; without it traefik never discovers the service"
		}
		// A tcp router without entrypoints attaches to every entrypoint, and
		// a raw-TCP catch-all (HostSNI(`*`)) there competes for web/websecure
		// traffic. #checks (not a required-field marker) so it fires on every
		// command, render included, with this message. Counted with positive
		// `!= _|_` guards: an absent-field access inside a guard is an error
		// that silently skips the element, so "is absent" cannot be asked
		// directly — instead every tcp route must appear in the
		// has-entrypoints count.
		"traefik-proxy/tcp-entrypoints": {
			assert: len([for _, r in #exposes.routes if r._proto == "tcp" {r.port}]) ==
				len([for _, r in #exposes.routes if r._proto == "tcp" if r.entrypoints != _|_ if len(r.entrypoints) > 0 {r.port}])
			why: "a tcp route needs its own entrypoints (raw TCP cannot share a port); list them explicitly, even if that is every entrypoint"
		}
		...
	}

	#exposes: {
		// Inherited generic inputs, re-listed so this closed layer admits
		// them; networkName stays non-optional so labels can reference it.
		pair?:       string
		networkName: string
		extraOptions?: [...c.#KeyValue]

		// Shared labels, emitted once per placement.
		_shared: [
			"traefik.enable=true",
			"traefik.docker.network=\(units.networks[networkName].#networkName)",
		]

		// routes: one router per key; all share the pair network. A route
		// owns a same-named service by default; point service at another
		// route's router to share one (2 routers, 1 service).
		routes: [Route=string]: {
			// protocol selects the traefik label family: "http" for HTTP
			// routers and services, "tcp" for the raw-TCP ones (SOCKS, redis,
			// syslog, anything traefik should splice rather than parse).
			// Every knob below spells the same way in both families, so the
			// family is the only difference and one prefix carries it.
			//
			// No "udp", deliberately: udp routers take no rule at all, which
			// contradicts this struct's required `rule`. That wants its own
			// shape, not a third value here.
			protocol: *"http" | "tcp"

			// _proto collapses protocol's star-default to a concrete string,
			// the #serviceName trick below. Interpolations and comprehensions
			// read this, never `protocol` directly: unifying two marked
			// defaults is unresolvable.
			_proto: "\(protocol)"

			// router keys the traefik router; unique per quadlet.
			router: string | *"\(name)-\(Route)"
			// service the router binds to. Explicit always: traefik only
			// auto-links when the container defines exactly one service, so
			// multi-route containers die with "too many services". Share
			// another route's service (2 routers, 1 service) via its
			// canonical handle: service: routes.web.#serviceName.
			service: string | *router
			// #serviceName is the resolved service name, the reference
			// handle other routes share by. The interpolation is
			// load-bearing: it collapses the input's star-default into a
			// concrete string; referencing `service` or `router` directly
			// would unify two star-defaults, which CUE cannot resolve.
			#serviceName: "\(service)"
			_own:         service == router

			// Backend port the container listens on; required exactly when
			// this route owns its service.
			port?: int & >0 & <65536
			if _own {
				port!: int & >0 & <65536
			}

			// Router rule, e.g. "Host(`grafana.example.lan`)". No single
			// quotes: the emitted label is single-quoted so rules with
			// spaces survive quadlet's word-splitting.
			rule!: string & !~"'"
			// TCP routers match on an entirely different vocabulary, and an
			// HTTP-shaped rule there is a silent no-match rather than an
			// error: traefik loads the router and it simply never fires.
			// Require one of the TCP matchers (HostSNI, HostSNIRegexp,
			// ClientIP, ALPN) to appear (contains, not anchored, so
			// composition with &&/||/! still passes). Non-TLS TCP
			// specifically needs HostSNI(`*`).
			if _proto == "tcp" {
				rule: =~"(HostSNI(Regexp)?|ClientIP|ALPN)\\("
			}
			// Router entrypoints (e.g. ["websecure"]); omitted: traefik
			// default. Required (non-empty) for tcp routes, enforced by the
			// traefik-proxy/tcp-entrypoints check.
			entrypoints?: [...string]
			// Router priority; omitted: traefik's rule-length default.
			priority?: int & >0
			// Middleware names applied to this router, in order. The
			// definitions themselves are user-named: declare them in
			// extraLabels. TCP routers accept only the tcp middlewares
			// (ipallowlist, inflightconn).
			middlewares?: [...string]
			// Appended verbatim: middleware definitions, TLS options, ...
			extraLabels?: [...c.#KeyValue]

			_core: list.Concat([
				[
					"'traefik.\(_proto).routers.\(router).rule=\(rule)'",
					"traefik.\(_proto).routers.\(router).service=\(#serviceName)",
				],
				[if _own {
					"traefik.\(_proto).services.\(#serviceName).loadbalancer.server.port=\(port)"
				}],
				[if entrypoints != _|_ {
					"traefik.\(_proto).routers.\(router).entrypoints=" + strings.Join(entrypoints, ",")
				}],
				[if priority != _|_ {
					"traefik.\(_proto).routers.\(router).priority=\(priority)"
				}],
				[if middlewares != _|_ {
					"traefik.\(_proto).routers.\(router).middlewares=" + strings.Join(middlewares, ",")
				}],
				[if extraLabels != _|_ for l in extraLabels {l}],
			])

			// #label is this route standalone (per-container placement).
			#label: list.Concat([_shared, _core])
		}

		// #label aggregates every route for the single-container case.
		#label: list.Concat([_shared, for _, r in routes {r._core}])
	}

	// Open at the top, like #ReverseProxyMixin: #Quadlet enforces closedness.
	...
}
