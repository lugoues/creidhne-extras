package creidhne_extras

import "github.com/lugoues/creidhne"

// Provide some helper types for https://github.com/lugoues/borgmatic-manager

#BorgManagerSpec: creidhne.#JSONLabel & {
	key: "borgmatic-manager.spec"
	value: {
		enable: bool
		group:  string
		volumes: [...string]
		config: {...}
		db: [...]
	}
 		}
