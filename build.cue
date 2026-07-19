package creidhne_extras

import (
	c "github.com/lugoues/creidhne"
)

// #BareContainerFile wraps a base image with the build context and nothing
// else: parameterize the base via BuildArg (IMAGE=...), and every Context
// entry lands at its path from /. Pair it with #BareBuildSpec to make the
// missing-IMAGE mistake a validate-time error.
#BareContainerFile: """
	ARG IMAGE
	FROM ${IMAGE}

	COPY . /
	"""

// #BareCheckContainerFile is #BareContainerFile plus one microcheck
// utility: tiny static healthcheck binaries (~40-500KB, work in
// scratch/distroless, no curl/wget needed). CHECK picks which one
// (httpcheck by default; httpscheck, portcheck, parallel, pidcheck), and
// must be redeclared after FROM: pre-FROM args only reach FROM lines.
// Wire the check on the container:
//
//	HealthCmd: "/bin/httpcheck http://localhost:8080/healthz"
//	Notify:    "healthy"
#BareCheckContainerFile: """
	ARG IMAGE
	FROM ${IMAGE}
	ARG CHECK=httpcheck

	COPY --from=ghcr.io/tarampampam/microcheck:1 /bin/${CHECK} /bin/${CHECK}
	COPY . /
	"""

// #BareBuildSpec types the "I just need to add context" build: wrap a
// base image with the unit's Context files, nothing else. The base image
// is a required input, so forgetting it fails `crei validate` instead of
// podman build on the host (a raw `ARG IMAGE` dies at unit start), and
// setting #check switches to the microcheck Containerfile.
//
//	units: builds: web: ce.#BareBuildSpec & {
//	    #image: "docker.io/nginx:1.27"
//	    #check: "httpcheck"
//	    Context: {"etc/nginx/nginx.conf": "..."}
//	}
//	units: #container: Container: Image: units.builds.web.#self
#BareBuildSpec: {
	// #image is the base image the build wraps; required.
	#image: c.#ImageName

	// #check selects a microcheck utility; its presence selects the
	// Containerfile. The shipped Containerfiles declare no other ARGs, so
	// there is nothing else to pass; a custom multi-ARG Containerfile is
	// beyond the bare pattern (use the raw strings with hand-written
	// ContainerFile/BuildArg instead of the spec).
	#check?: "httpcheck" | "httpscheck" | "portcheck" | "parallel" | "pidcheck"

	if #check == _|_ {
		ContainerFile: #BareContainerFile
	}
	if #check != _|_ {
		ContainerFile: #BareCheckContainerFile
	}
	Build: {
		BuildArg: [
			"IMAGE=\(#image)",
			if #check != _|_ {"CHECK=\(#check)"},
		]
		...
	}
	...
}
