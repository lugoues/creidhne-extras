# Reverse-proxy pair networks

`#ReverseProxySpec` and `#TraefikProxySpec` implement the per-service proxy
pattern: every exposed service gets a dedicated "pair" network shared only
with the reverse proxy. Podman networks have no peer isolation (every peer
on a network sees every peer), so isolation comes from one network per
exposed service.

Both are magic-free value helpers: they only compute a network unit body and
a label list; every placement stays explicit and visible in your quadlet.

## Usage

Unify the spec at the quadlet level so it reads the quadlet's `name`:

```cue
grafana: creidhne.#Quadlet & ce.#TraefikProxySpec & {
    name: "grafana"
    #exposes: {
        port: 3000
        rule: "Host(`grafana.example.lan`)"
        entrypoints: ["websecure"]
    }
    units: #container: Container: {
        Image:   "docker.io/grafana/grafana:11"
        Network: [units.networks.proxy.#self]
        Label:   [#exposes.#label] // nested label block, splices flat
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
t
Renders:

```ini
# grafana-proxy.network
[Network]
Options=isolate=strict
Internal=true
DisableDNS=true
Label=creidhne.pair=grafana

# grafana.container
[Container]
Image=docker.io/grafana/grafana:11
Network=grafana-proxy.network
Label=traefik.enable=true
Label='traefik.http.routers.grafana.rule=Host(`grafana.example.lan`)'
Label=traefik.http.services.grafana.loadbalancer.server.port=3000
Label=traefik.docker.network=systemd-grafana-proxy
Label=traefik.http.routers.grafana.entrypoints=websecure

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
3. Hardened guarantees, not defaults: `Internal=true` (no gateway or NAT,
   the pair network can never become an egress path), `isolate=strict` (no
   cross-network traffic at all; netavark before 2.0 allowed it by default),
   and `DisableDNS=true` (two peers that dial each other by IP; DNS is dead
   weight). None of these can be overridden. Strict isolation requires
   netavark >= 1.7 (podman 4.7); netavark >= 2.0 defaults to it anyway.
4. The `creidhne.pair=<name>` marker declares the isolation contract:
   exactly two containers (service + proxy) should ever attach. A future
   `crei lint` rule can count graph attachments against it; the marker is
   the whole contract, so the check needs no knowledge of this helper.

Traefik attaches, it never defines: exactly one owner per pair network (the
service quadlet); the proxy side is a single `Network:` entry.

## Inputs (`#exposes`)

| Field | Type | Default | Purpose |
| --- | --- | --- | --- |
| `port!` | `int` (1-65535) | required | Backend port the container listens on |
| `rule!` | `string`, no `'` | required | Traefik router rule |
| `entrypoints?` | `[...string]` | traefik default | Router entrypoints, joined with `,` |
| `extraLabels?` | `[...#KeyValue]` | none | Appended verbatim (middlewares, TLS, ...) |
| `router` | `string` | quadlet `name` | Keys the traefik router and service |
| `networkName` | `string` | `"proxy"` | Handle: the `units.networks` key; file is `<quadlet>-<networkName>.network` |
| `pair` | `string` | quadlet `name` | Marker label value |
| `extraOptions?` | `[...#KeyValue]` | none | Netavark options appended after the fixed isolate |

The spec places the pair network itself at the `networkName` handle
(default `units.networks.proxy`, file `<quadlet>-proxy.network`);
`#exposes.#network` aliases the placed unit, so `#exposes.#network.#self`
resolves to the canonical handles. The unit body is open, so decorate it in
place; a `NetworkName:` decoration flows into `traefik.docker.network`
automatically:

```cue
units: networks: proxy: Network: Subnet: ["10.89.44.0/24"]
units: networks: proxy: Network: NetworkName: "gf-proxy"
```

`Internal`, `DisableDNS`, and the isolate option are fixed: overriding them
is a conflict error, so a placed pair network always carries the guarantees.

Forgetting `#exposes` entirely still places the pair network (it renders
from defaults), so the mistake surfaces in `crei plan` instead of silently
doing nothing; the traefik labels stay enforced at their `Label:` placement.

## Layering

`#ReverseProxySpec` is the generic pattern (pair network, marker, defaults,
`networkName` ownership); `#TraefikProxySpec` layers the label DSL on top.
A different proxy (caddy, nginx) would be a sibling layer over the same
generic spec: fix `networkName`, unify `#exposes` with `creidhne.#Rendered`,
and compute `#rendered` from your proxy's discovery convention.

Typos in `#exposes` are rejected (the layer's config struct is closed); the
error surfaces as an empty-disjunction failure at the `Label:` placement.
