package creidhne_extras

import c "github.com/lugoues/creidhne"

// Provide some helper types for https://github.com/lugoues/borgmatic-manager

#BorgManagerSpec: c.#JSONLabel & {
	key: "borgmatic-manager.spec"
	value: {
		enable: bool
		group:  string
		volumes: [...string]
		// config is a borgmatic configuration fragment, validated against the
		// imported borgmatic schema (borgmatic-config.gen.cue, regenerate with
		// `mise run gen:borgmatic-schema`): unknown options are rejected at
		// crei validate instead of surfacing when the manager parses the label.
		config: #BorgmaticConfig
		db: [...]
	}
}
