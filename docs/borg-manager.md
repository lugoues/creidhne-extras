# `#BorgManagerSpec`

The borgmatic-manager payload as a typed, validated JSON label. Built on
creidhne's `#JSONLabel`, so the whole payload lands in a single label whose
value is escaped, single-quoted JSON that the manager decodes back.

## Usage

```cue
Container: Label: [
    ce.#BorgManagerSpec & {value: {
        enable: true
        group:  "media"
        volumes: [
            units.volumes.data.#volumeName,
            units.volumes.config.#volumeName,
        ]
    }},
]
```

Renders (one label):

```ini
Label='borgmatic-manager.spec={"enable":true,"group":"media","volumes":["app-data","app-config"],"config":{},"db":[]}'
```

Note the field is `value:` (from `#JSONLabel`), not `#value:` as in the
`#StringLabelList` family.

## Schema (`value`)

| Field | Type | Notes |
| --- | --- | --- |
| `enable` | `bool` | required |
| `group` | `string` | required; backup group the container joins |
| `volumes` | `[...string]` | runtime volume names; pass the canonical `#volumeName` handles so they can never drift |
| `config` | `{...}` | open struct, passed through verbatim; marshals to `{}` when unset |
| `db` | `[...]` | open list, passed through verbatim; marshals to `[]` when unset |

## Why `#JSONLabel` and not `#StringLabelList`

The payload carries nested config and arbitrary values (paths, free text).
JSON in one label keeps arbitrary values safe: `#JSONLabel` HTML-escapes the
JSON, replaces single quotes with `\u0027`, and single-quotes the whole
`key=value`, so quadlet's word-splitting and systemd's quoting can't mangle
it, and the result is still valid JSON for the consumer.
