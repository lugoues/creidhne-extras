package creidhne_extras

#DockTailSpec: #StringLabelList & {
	prefix: "docktail"
	#value: {
		service?: {
			// Enable a private Tailscale service for the container.
			"enable": string
			// Service name, such as web or api.
			"name": string
			// Backend container port to proxy to.
			"port": number
			// Human-readable description shown for the service in the Tailscale admin panel. Requires API credentials (synced to the Service definition's comment).
			"description"?: string
			// No 	true 	Proxy directly to container IP instead of requiring a published host port.
			"direct"?: bool
			// Docker network used for direct container IP detection.
			"network"?: string
			// Backend protocol.
			"protocol"?: string
			// Port Tailscale listens on.
			"service-port"?: number
			// Tailscale-facing protocol.
			"service-protocol"?: string
		}
		tags?: [string]
		funnel: {
			// Enable Tailscale Funnel.
			"enable": bool
			// Backend container port for Funnel traffic.
			"port": number
			// Public Funnel port. HTTPS/HTTP Funnel supports 443, 8443, or 10000.
			"funnel-port"?: number
			// Funnel protocol: http, https, tcp, or tls-terminated-tcp.
			"protocol"?: string
			// Funnel path. Must start with /.
			"path"?: string
		}
	}
}
