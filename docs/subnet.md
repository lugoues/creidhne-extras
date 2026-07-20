# `#Subnet`

Plans a subnet's address layout for a `.network` unit: gateway, a fixed
static-host block, and the dynamic `IPRange`. The static reserve
`[staticStart, dynamicStart)` is deliberately fixed: adding a host never
changes `ipRange` (a changed range means recreating the network), and
statics overflowing the reserve fail the build (`#fits`) instead of
shifting it.

## Usage

```cue
_subnets: lan: ce.#Subnet & {
    #cidr: "10.20.0.0/24"
    static: ["hosta", "hostb"]
}

units: networks: lan: Network: {
    Subnet:  [_subnets.lan.cidr]
    Gateway: [_subnets.lan.gateway]
    IPRange: [_subnets.lan.ipRange]
}
```

With the defaults (`staticStart: 2`, `dynamicStart: 10`): gateway `.1`,
statics `.2`-`.9` (8 slots), dynamic `.10`-`.254`. `byName` maps each
static host to its address (`_subnets.lan.byName.hosta = "10.20.0.2"`),
ready for `#StaticNetworkMixin` member pins or a container `IP=`.

| Field | Type | Default | Purpose |
| --- | --- | --- | --- |
| `#cidr` | `net.IPCIDR` | required | The subnet |
| `static` | `[...string]`, unique | `[]` | Hosts assigned increasing IPs in author order (append-only: inserting renumbers) |
| `staticStart` | `int > 1` | `2` | First static offset (gateway sits at 1) |
| `dynamicStart` | `int` | `10` | First dynamic offset; fixes the reserve size. Widen it up front: changing it later is the network rebuild this helper avoids |

## Traps

- Declare instances under a hidden or definition field (`_subnets:`): a
  project-wide `[_]: creidhne.#Quadlet` pattern sweeps regular top-level
  fields and rejects the helper against the quadlet's closed field set.
- Requires the cue 0.17 evaluator (crei >= v2.6.0): `net.ParseCIDR` and
  `net.AddIP` do the address math.
