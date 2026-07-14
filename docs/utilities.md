# Label utilities

`utilities.cue` holds the base machinery for prefix-keyed label DSLs (the
convention where a sidecar reads `myapp.some.path=value` labels).

## `#StringLabelList`

A `creidhne.#Rendered` multi-label helper: give it a `prefix` and a `#value`
struct, and it renders one label per leaf, keyed by the dot-separated path.
Place it directly in any `Label:` list.

```cue
Container: Label: [
    ce.#StringLabelList & {prefix: "acme", #value: {tier: "web", replicas: 2}},
]
```

Renders:

```ini
Label=acme.tier=web
Label=acme.replicas=2
```

Typed DSLs build on it by fixing the prefix and constraining `#value` (see
[`#DockTailSpec`](docktail.md)):

```cue
#MySpec: ce.#StringLabelList & {
    prefix: "myapp"
    #value: {
        enable: bool
        port?:  int
    }
}
```

The constrained `#value` struct is where the value comes from: a typo'd
option key dies at `crei validate` instead of being silently ignored by the
sidecar at runtime.

## `#FlattenStruct`

The recursive engine underneath: flattens an arbitrary struct into a list of
`prefix.path=value` strings.

| Input shape | Output |
| --- | --- |
| Scalar field `x: v` | `prefix.x=v` |
| Nested struct `a: b: v` | `prefix.a.b=v` |
| List `xs: [v0, v1]` | `prefix.xs.0=v0`, `prefix.xs.1=v1` (indexed keys) |

```cue
(ce.#FlattenStruct & {
    #prefix: "docktail"
    #in: {funnel: {enable: true, port: 8080}, tags: ["a", "b"]}
}).out
// ["docktail.funnel.enable=true", "docktail.funnel.port=8080",
//  "docktail.tags.0=a", "docktail.tags.1=b"]
```

Use it directly when you need the string list itself (for joining, for a
different placement); use `#StringLabelList` when the destination is a
`Label:` list.

## Caveats

- **Values are not quoted.** A value containing whitespace word-splits in
  quadlet's `Label=` line. For free-text values, quote at the DSL layer
  (render `'key=value'`, the `#JSONLabel` treatment) or keep values
  machine-shaped.
- Scalars interpolate with CUE's default formatting: `true`, `8080`. Structs
  and lists recurse; there is no depth limit beyond your data.
