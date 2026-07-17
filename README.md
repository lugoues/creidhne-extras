# creidhne-extras

Opinionated helpers for [creidhne](https://github.com/lugoues/creidhne)
quadlet definitions. The placement rule for this module: **a helper lives
here iff it needs no changes to the core schema**. Everything in this repo
rides stock creidhne mechanisms (`#Rendered` label helpers, list flattening,
star-defaulted schema fields).

## Install

Vendor into a project for offline use, exactly like the embedded schema:

```sh
crei vendor github.com/lugoues/creidhne-extras@<tag>
```

Import with an explicit package qualifier (the module path ends in a dash,
so CUE cannot infer the package name):

```cue
import ce "github.com/lugoues/creidhne-extras:creidhne_extras"
```

## Helpers

| Helper | File | What it does |
| --- | --- | --- |
| [`#ReverseProxySpec`](docs/reverse-proxy.md) | `reverse-proxy.cue` | Per-service reverse-proxy pair network: isolation, marker label, hardened defaults |
| [`#TraefikProxySpec`](docs/reverse-proxy.md) | `reverse-proxy.cue` | Traefik label DSL layered on the pair-network pattern |
| [`#StaticNetworkMixin`](docs/static-network.md) | `static-network.cue` | "DNS in CUE": DNS-less network + injected address book (IPs, /etc/hosts, ContainerName defaults) |
| [`#DockTailSpec`](docs/docktail.md) | `docktail.cue` | Typed `docktail.*` labels for the DockTail Tailscale sidecar |
| [`#BorgManagerSpec`](docs/borg-manager.md) | `borg-manager.cue` | Typed JSON payload for the borgmatic-manager label |
| [`#FlattenStruct`, `#StringLabelList`](docs/utilities.md) | `utilities.cue` | Struct-to-dot-path label rendering, the base for prefix-keyed label DSLs |

The single-value helpers (`#DockTailSpec`, `#BorgManagerSpec`) are
`creidhne.#Rendered` values: place them directly in a `Label:` list and they
splice flat. `#TraefikProxySpec` exposes its label block as
`#exposes.#label`, spliced the same way.

```cue
Container: Label: [
    "app=web",
    ce.#DockTailSpec & {#value: {funnel: {enable: true, port: 8080}}},
    #exposes.#label,
]
```
