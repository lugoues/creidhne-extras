# `#InternalNetworkSpec`

The hardened base for container-to-container networks. Unify it with a
network unit and every placement carries the same guarantees; the pair
network (`#ReverseProxyMixin`) and the static network
(`#StaticNetworkMixin`) both build on it.

## Guarantees (overriding any is a conflict)

| Field | Value | Why |
| --- | --- | --- |
| `Internal` | `true` | No gateway routing, no NAT: the network can never become an egress path |
| `Options` | `isolate=strict` first | No cross-network traffic at all (netavark >= 1.7; >= 2.0 defaults to it) |
| `NetworkDeleteOnStop` | `true` | Removed when the network's own unit stops; attachers are dependents, so systemd stops them first and removal runs against an empty network. Stopping a consuming service alone never touches the network |

## Usage

```cue
units: networks: internal: ce.#InternalNetworkSpec & {
    #extraOptions: ["mtu=1400"]
    Network: Subnet: ["10.60.0.0/24"]
}
```

Renders:

```ini
[Network]
Options=isolate=strict
Options=mtu=1400
Subnet=10.60.0.0/24
Internal=true
NetworkDeleteOnStop=true
```

`#extraOptions` appends netavark options after the fixed isolate (`mtu=`,
`metric=`, `no_default_route=`, ...); everything else on the unit stays
open for decoration in place.

## What it deliberately does not set

`DisableDNS`: peers resolve each other through aardvark, so switching DNS
off requires resolving names another way. Until then the aardvark
upstream-forwarding side-channel (non-container queries forwarded to the
host's resolvers) stays open through an otherwise `Internal` network.
[`#StaticNetworkMixin`](static-network.md) is the full treatment: DNS off,
names served from an injected `/etc/hosts` book.
