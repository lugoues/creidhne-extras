package creidhne_extras

import (
	"list"
	"strings"

	c "github.com/lugoues/creidhne"
)

// Protocol vocabularies from docktail's docs (docktail.org/docs, "Supported
// Protocols"). https+insecure is backend-only; the funnel set is the
// tailnet-facing one.
#DocktailBackendProtocol: "http" | "https" | "https+insecure" | "tcp" | "tls-terminated-tcp"
#DocktailServiceProtocol: "http" | "https" | "tcp" | "tls-terminated-tcp"

#DockTailSpec: c.#Rendered & {
	prefix: string | *"docktail"
	#value: {
		service?: {
			// Enable a private Tailscale service for the container.
			"enable": bool
			// Service name, such as web or api.
			"name": string
			// Backend container port to proxy to.
			"port": number
			// Human-readable description shown for the service in the Tailscale admin panel. Requires API credentials (synced to the Service definition's comment).
			"description"?: string
			// Proxy directly to the container IP instead of a published host port (docktail default: true).
			"direct"?: bool
			// Docker network used for direct container IP detection.
			"network"?: string
			// Backend protocol.
			"protocol"?: #DocktailBackendProtocol
			// Port Tailscale listens on.
			"service-port"?: number
			// Tailscale-facing protocol.
			"service-protocol"?: #DocktailServiceProtocol
			// HTTP(S) Serve mount point, default "/". Rejected on tcp service protocols.
			"path"?: string & =~"^/"
			// PROXY protocol version on TCP forwards; tcp/tls-terminated-tcp only.
			"proxy-protocol"?: 1 | 2
		}
		// Tailscale service tags; rendered comma-joined as docktail.tags
		// (docktail reads one label, not an indexed list).
		tags?: [...string]
		funnel: {
			// Enable Tailscale Funnel.
			"enable": bool
			// Backend container port for Funnel traffic.
			"port": number
			// Public Funnel port. HTTPS/HTTP Funnel supports 443, 8443, or 10000.
			"funnel-port"?: number
			// Funnel protocol.
			"protocol"?: #DocktailServiceProtocol
			// Funnel path, http/https only. Must start with /.
			"path"?: string & =~"^/"
		}
	}

	// Everything but tags flattens to one label per leaf; tags joins.
	#rendered: list.Concat([
		(#FlattenStruct & {#in: {for k, v in #value if k != "tags" {(k): v}}, #prefix: prefix}).out,
		[if #value.tags != _|_ {"\(prefix).tags=\(strings.Join(#value.tags, ","))"}],
	])
}
