# `#DockTailSpec`

Typed `docktail.*` labels for the DockTail Tailscale sidecar. Built on
[`#StringLabelList`](utilities.md) with `prefix: "docktail"` and a closed
`#value` schema, so option-key typos fail at `crei validate` instead of
being silently ignored by the sidecar.

## Usage

```cue
Container: Label: [
    ce.#DockTailSpec & {#value: {
        funnel: {enable: true, port: 8080, protocol: "https"}
        tags: ["tag:web"]
    }},
]
```

Renders:

```ini
Label=docktail.funnel.enable=true
Label=docktail.funnel.port=8080
Label=docktail.funnel.protocol=https
Label=docktail.tags.0=tag:web
```

## Schema (`#value`)

### `funnel` (required)

| Field | Type | Purpose |
| --- | --- | --- |
| `enable` | `bool` | Enable Tailscale Funnel |
| `port` | `number` | Backend container port for Funnel traffic |
| `funnel-port?` | `number` | Public Funnel port (HTTPS/HTTP Funnel supports 443, 8443, or 10000) |
| `protocol?` | `string` | `http`, `https`, `tcp`, or `tls-terminated-tcp` |
| `path?` | `string` | Funnel path, must start with `/` |

### `service?`

| Field | Type | Purpose |
| --- | --- | --- |
| `enable` | `string` | Enable a private Tailscale service for the container |
| `name` | `string` | Service name, such as `web` or `api` |
| `port` | `number` | Backend container port to proxy to |
| `description?` | `string` | Shown in the Tailscale admin panel (requires API credentials) |
| `direct?` | `bool` | Proxy directly to the container IP instead of a published host port |
| `network?` | `string` | Docker network used for direct container IP detection |
| `protocol?` | `string` | Backend protocol |
| `service-port?` | `number` | Port Tailscale listens on |
| `service-protocol?` | `string` | Tailscale-facing protocol |

### `tags?`

`[string]`: currently exactly one tag (widen to `[...string]` for several).
Tags render with indexed keys: `docktail.tags.0=tag:web`.

## Caveats

- `service.description` is free text: values with spaces word-split in
  quadlet's `Label=` line (see the [utilities caveats](utilities.md#caveats)).
- `service.enable` is typed `string` today, while `funnel.enable` is `bool`.
