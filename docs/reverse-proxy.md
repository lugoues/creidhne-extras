# Reverse-proxy pair networks

`#ReverseProxyMixin` and `#TraefikProxyMixin` implement the per-service proxy
pattern: every exposed service gets a dedicated "pair" network shared only
with the reverse proxy. Podman networks have no peer isolation (every peer
on a network sees every peer), so isolation comes from one network per
exposed service.

Both are magic-free value helpers: they only compute a network unit body and
a label list; every placement stays explicit and visible in your quadlet.

## Usage

Unify the mixin at the quadlet level so it reads the quadlet's `name`:

```cue
grafana: creidhne.#Quadlet & ce.#TraefikProxyMixin & {
    name: "grafana"
    #exposes: routes: {
        web: {port: 3000, rule: "Host(`grafana.example.lan`)", entrypoints: ["websecure"]}
        api: {port: 3001, rule: "Host(`api.grafana.example.lan`)"}
    }
    units: #container: Container: {
        Image:   "docker.io/grafana/grafana:11"
        Network: [units.networks.proxy.#self]
        Label:   [#exposes.#label] // every route; splices flat
    }
}

traefik: creidhne.#Quadlet & {
    name: "traefik"
    units: #container: Container: {
        Image:   "docker.io/traefik:v3"
        Network: [grafana.units.networks.proxy.#self] // one line per service
    }
}
```

Renders:

```ini
# grafana-proxy.network
[Network]
Options=isolate=strict
Internal=true
Label=creidhne.pair=grafana

# grafana.container
[Container]
Image=docker.io/grafana/grafana:11
Network=grafana-proxy.network
Label=traefik.enable=true
Label=traefik.docker.network=systemd-grafana-proxy
Label='traefik.http.routers.grafana-web.rule=Host(`grafana.example.lan`)'
Label=traefik.http.services.grafana-web.loadbalancer.server.port=3000
Label=traefik.http.routers.grafana-web.entrypoints=websecure
Label='traefik.http.routers.grafana-api.rule=Host(`api.grafana.example.lan`)'
Label=traefik.http.services.grafana-api.loadbalancer.server.port=3001

# traefik.container
[Container]
Image=docker.io/traefik:v3
Network=grafana-proxy.network
```

## What the pattern fixes

1. `traefik.docker.network` reads the placed unit's canonical
   `#networkName` (quadlet's `systemd-<stem>` default, or any `NetworkName:`
   decoration), so it can never drift or be hand-typed wrong (the classic
   intermittent-502 when a container sits on several networks and traefik
   picks an arbitrary IP).
2. The rule label is single-quoted, so rules with spaces
   (`Host(...) && PathPrefix(...)`) survive quadlet's word-splitting.
3. Hardened guarantees, not defaults: `Internal=true` (no gateway routing or
   NAT, the pair network can never become an egress path) and
   `isolate=strict` (no cross-network traffic at all; netavark before 2.0
   allowed it by default). Neither can be overridden. Strict isolation
   requires netavark >= 1.7 (podman 4.7); netavark >= 2.0 defaults to it.
   Reluctantly absent: `DisableDNS`. It belongs here as isolation, not
   hygiene: aardvark-dns forwards non-container queries to the host's
   resolvers, making DNS an egress side-channel through an otherwise
   Internal network, and `DisableDNS` is the only per-network off-switch.
   But combined with `Internal`, podman < 6 omits the network's gateway
   *address*, and traefik's docker client fails parsing `Gateway: <nil>`,
   never configuring the backend at all
   ([podman#28705](https://github.com/podman-container-tools/podman/issues/28705),
   fixed for podman 6). Until podman 6 is the floor, the DNS side-channel
   is a known, accepted gap in the pair-network isolation.
4. The `creidhne.pair=<name>` marker declares the isolation contract:
   exactly two containers (service + proxy) should ever attach. A future
   `crei lint` rule can count graph attachments against it; the marker is
   the whole contract, so the check needs no knowledge of this helper.

Traefik attaches, it never defines: exactly one owner per pair network (the
service quadlet); the proxy side is a single `Network:` entry.

## Inputs (`#exposes`)

| Field | Type | Default | Purpose |
| --- | --- | --- | --- |
| `routes` | map, at least one entry | required | One traefik router/service per key; all share the pair network |
| `networkName` | `string` | `"proxy"` | Handle: the `units.networks` key; file is `<quadlet>-<networkName>.network` |
| `pair` | `string` | quadlet `name` | Marker label value |
| `extraOptions?` | `[...#KeyValue]` | none | Netavark options appended after the fixed isolate |

### Route fields (`#exposes.routes.<key>`)

| Field | Type | Default | Purpose |
| --- | --- | --- | --- |
| `port` | `int` (1-65535) | required for service-owning routes | Backend port the container listens on |
| `rule!` | `string`, no `'` | required | Traefik router rule |
| `entrypoints?` | `[...string]` | traefik default | Router entrypoints, joined with `,` |
| `priority?` | `int` | traefik default | Router priority |
| `middlewares?` | `[...string]` | none | Middleware names for this router; define them in `extraLabels` |
| `extraLabels?` | `[...#KeyValue]` | none | Appended verbatim (middleware definitions, TLS, ...) |
| `router` | `string` | `"<name>-<key>"` | Keys the traefik router |
| `service` | `string` | own router name | Service the router binds to (always explicit: traefik cannot auto-link with several services on one container) |
| `#serviceName` | computed | resolved `service` | Canonical handle other routes share a service by |

A route that shares another route's service references its canonical
handle and needs no `port` (2 routers, 1 service):

```cue
#exposes: routes: {
    pod: {port: 8080, rule: "Host(`minus.lan`)"}
    "pod-root": {
        rule:        "Host(`minus.lan`) && Path(`/`)"
        service:     routes.pod.#serviceName
        priority:    100
        middlewares: ["to-ui"]
        extraLabels: ["traefik.http.middlewares.to-ui.redirectregex.regex=..."]
    }
}
```

Place `#exposes.#label` for every route on one container, or a single
route's `#exposes.routes.<key>.#label` per container when a quadlet's
containers split the routes. A `#checks` entry enforces at least one route
and every route's `port`/`rule`, so an unfilled mixin fails the build:

```
Error: quadlet books: check "traefik-proxy/exposes" failed: mixing
#TraefikProxyMixin requires at least one #exposes.routes entry
```

The mixin places the pair network itself at the `networkName` handle
(default `units.networks.proxy`, file `<quadlet>-proxy.network`);
`#exposes.#network` aliases the placed unit, so `#exposes.#network.#self`
resolves to the canonical handles. The unit body is open, so decorate it in
place; a `NetworkName:` decoration flows into `traefik.docker.network`
automatically:

```cue
units: networks: proxy: Network: Subnet: ["10.89.44.0/24"]
units: networks: proxy: Network: NetworkName: "gf-proxy"
```

`Internal` and the isolate option are fixed: overriding them is a conflict
error, so a placed pair network always carries the guarantees.

Forgetting `#exposes` entirely still places the pair network (it renders
from defaults), so the mistake surfaces in `crei plan` instead of silently
doing nothing; the traefik labels stay enforced at their `Label:` placement.

## Layering

`#ReverseProxyMixin` is the generic pattern (pair network, marker, defaults,
`networkName` ownership); `#TraefikProxyMixin` layers the label DSL on top.
A different proxy (caddy, nginx) would be a sibling layer over the same
generic mixin: fix `networkName`, unify `#exposes` with `creidhne.#Rendered`,
and compute `#rendered` from your proxy's discovery convention.

Typos in `#exposes` are rejected (the layer's config struct is closed); the
error surfaces as an empty-disjunction failure at the `Label:` placement.
