# `#StaticNetworkMixin`

"DNS in CUE": a DNS-less internal network plus a static address book
injected into its member containers. It exists because aardvark-dns
forwards non-container queries to the host's resolvers (an egress
side-channel through an otherwise `Internal` network) and cannot be told
not to; the only per-network off-switch is `DisableDNS`, which kills name
resolution entirely. This mixin turns DNS off and moves resolution into
CUE: members get deterministic IPs and an `/etc/hosts` book publishing
each member's runtime `ContainerName`, so name-based configuration
(`\(x.#containerName)`) resolves exactly as it would through DNS.

## Usage

A quadlet-level mixin. `#static.members` are keys into `units.containers`;
the mixin injects each member's network attachment, hosts book, and a
`ContainerName` default:

```cue
firecrawl: creidhne.#Quadlet & ce.#StaticNetworkMixin & {
    name: "firecrawl"
    #static: {
        subnet: "10.30.0.0/24"
        members: {
            dashboard: _
            api:       _
            redis: {ip: "10.30.0.40"} // pin an address explicitly
        }
    }
    units: containers: {
        dashboard: Container: {Image: "..."}
        api: Container: {Image: "...", Environment: [
            "REDIS=redis://\(units.containers.redis.#containerName):6379",
        ]}
        redis: Container: {Image: "..."}
    }
}
```

Renders (for the api container; every member gets the same book):

```ini
[Container]
ContainerName=systemd-firecrawl-api
Environment=REDIS=redis://systemd-firecrawl-redis:6379
Network=firecrawl-static.network:ip=10.30.0.10
AddHost=systemd-firecrawl-api:10.30.0.10
AddHost=systemd-firecrawl-dashboard:10.30.0.11
AddHost=systemd-firecrawl-redis:10.30.0.40
```

When no member needs per-member config, omit `members` entirely and every
container in the quadlet joins with defaults:

```cue
stack: creidhne.#Quadlet & ce.#StaticNetworkMixin & {
    name: "stack"
    #static: subnet: "10.40.0.0/24"
    units: containers: {
        web: Container: {Image: "..."}
        db:  Container: {Image: "..."}
    }
}
```

## Inputs (`#static`)

| Field | Type | Default | Purpose |
| --- | --- | --- | --- |
| `subnet` | one IPv4 CIDR | required | Any prefix length; auto-assigned offsets are bounds-checked against it |
| `networkName` | `string` | `"static"` | Handle of the placed network unit; file is `<quadlet>-<networkName>.network` |
| `start` | `int > 1` | `10` | First auto-assigned host offset (the gateway takes low addresses) |
| `members?` | map | every container | Keys into `units.containers`; omitted, every container in the quadlet is a member |

### Member fields (`#static.members.<key>`)

| Field | Type | Purpose |
| --- | --- | --- |
| `ip?` | `string` | Pin this member's address instead of auto-assignment |

### Per-container knobs (definition fields on the member container)

| Field | Type | Purpose |
| --- | --- | --- |
| `#extraNetworks?` | list | Additional `Network=` attachments (e.g. a pair network's `#self`) |
| `#extraHosts?` | `[...string]` | Additional `AddHost=` entries beyond the book |

These sit on the container itself, next to what they affect, and work in
both modes:

```cue
units: containers: redis: {
    #extraHosts: ["legacy-db:10.30.0.99"]
    Container: {Image: "..."}
}
```

## What the mixin injects

For the placed network (at the `networkName` handle): `Internal`,
`isolate=strict`, `NetworkDeleteOnStop`, `Subnet`, and `DisableDNS`. The
last is this helper's premise, not an option. (The podman < 6
`Internal+DisableDNS` gateway-address bug, podman#28705, only bites
docker-API inspectors like traefik, which have no business on this
network; put traefik on a [pair network](reverse-proxy.md) via
`#extraNetworks` instead.)

For each member container:

- `Network`: the static attachment with its book IP, then the container's
  `#extraNetworks`.
- `AddHost`: the full book (every member's effective runtime name), then
  the container's `#extraHosts`.
- `ContainerName`: defaulted to `systemd-<stem>`, exactly the name
  quadlet would give the container anyway (podman's `systemd-%N`), so
  joining the network never changes a runtime name and the book serves
  the same names aardvark DNS would have. An explicit `ContainerName` on
  the container wins and flows into the book.

The mixin owns members' `Network` and `AddHost` lists: CUE lists unify
positionally and never merge, so a user-written list would conflict with
the injected one. `#extraNetworks`/`#extraHosts` are the mergeable
channel, and they are definition fields because that is the one
container-site channel a closed unit admits (closedness exempts
definitions; export drops them).

## Rules and traps

- **Members must be additional containers** (`units.containers.<key>`).
  The primary `units.#container` has no key to inject by, so it cannot be
  a member. Quadlets using this mixin should declare all networked
  services as named containers.
- **Omitted `members` means everyone**: there is no opt-out in that mode,
  and no `ip` pins (those live in the member map). List members
  explicitly when a member needs a pin or a container must stay off the
  network; non-member containers are left untouched. The container-site
  `#extraNetworks`/`#extraHosts` work in both modes.
- **`#extraNetworks`/`#extraHosts` on a non-member container are silently
  ignored** (selective mode): the injection no-ops there, and closedness
  cannot reject definition fields. Check membership first when an extra
  seems to have no effect.
- **Auto-assigned IPs follow sorted key order**: adding, removing, or
  renaming a member key renumbers the others (renumbered containers get
  recreated on apply). That is fine in normal operation because
  everything resolves by name through the book; pin `ip:` where an
  address must survive membership churn.
- `/etc/hosts` is written at container create: an address change requires
  recreating the consumers, not just the network. `crei status` flags the
  staleness.
- **Why inject a `ContainerName` default instead of reading the computed
  `#containerName`**: that accessor is a defaulted disjunction probing an
  optional field, and evaluating it across mutually-booked members trips
  evalv3's cycle detection (at unit and quadlet level alike). With the
  default injected the field is always concretely present, the book reads
  it safely, and user overrides win by ordinary default semantics.
- Auto-assigned offsets are bounds-checked against the subnet's host
  range; overflowing a small subnet fails the build. Pinned `ip:` values
  are taken verbatim (they bypass the bounds check).
