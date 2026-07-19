# Bare builds

The "wrap an upstream image" pattern: a build whose only job is layering
your `Context:` files (and optionally a healthcheck binary) onto a base
image. Three helpers compose it.

## `#BareBuildSpec`

Unify with a build unit; the base image is a required input, so forgetting
it fails `crei validate` instead of podman build at unit start (a raw
`ARG IMAGE` Containerfile dies on the host, off-box and cryptic). Setting
`#check` switches the Containerfile to the microcheck variant.

```cue
units: builds: web: ce.#BareBuildSpec & {
    #image: "docker.io/nginx:1.27"
    #check: "httpcheck"
    Context: {"etc/nginx/nginx.conf": "..."}
}
units: #container: Container: Image: units.builds.web.#self
```

| Input | Type | Default | Purpose |
| --- | --- | --- | --- |
| `#image` | `#ImageName` | required | Base image the build wraps |
| `#check?` | enum | absent | Microcheck utility; presence selects `#BareCheckContainerFile`, typo-checked at validate |

The spec owns `ContainerFile` and `BuildArg`: it is the "I just need to
add context" pattern, and the shipped Containerfiles declare no other
ARGs. A custom Containerfile with its own ARGs is beyond it; use the raw
string values below with hand-written `ContainerFile`/`BuildArg`.

## `#BareContainerFile`

The Containerfile value itself: `FROM ${IMAGE}` + `COPY . /`. Every
`Context:` entry lands at its path from the root (`"etc/app.conf"` becomes
`/etc/app.conf`). Usable standalone as `ContainerFile:` with a hand-written
`BuildArg: ["IMAGE=..."]` when you don't want the spec.

## `#BareCheckContainerFile`

Same, plus one [microcheck](https://github.com/tarampampam/microcheck)
utility: tiny static healthcheck binaries (~40-500KB) for images without
curl/wget (work in scratch/distroless). The `CHECK` build arg picks which
one, `httpcheck` by default; through the spec it is one typed knob:

```cue
#check: "portcheck"
```

| Utility | Check | Example `HealthCmd` |
| --- | --- | --- |
| `httpcheck` | HTTP endpoint | `/bin/httpcheck http://localhost:8080/healthz` |
| `httpscheck` | HTTP(S), protocol autodetect | `/bin/httpscheck localhost:8443/healthz` |
| `portcheck` | TCP/UDP port | `/bin/portcheck --port 5432` |
| `parallel` | combine checks | `/bin/parallel "httpcheck http://127.0.0.1:8080" "portcheck --port 8081"` |
| `pidcheck` | pidfile/pid alive | `/bin/pidcheck --file /run/app.pid` |

The binary alone checks nothing: wire it on the container.

```cue
Container: {
    HealthCmd: "/bin/httpcheck http://localhost:8080/healthz"
    Notify:    "healthy"
}
```

The `microcheck:1` major tag is the pinning form upstream recommends
(`latest` is discouraged); pin `X.Y.Z` or a digest for stricter
reproducibility.
