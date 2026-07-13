package creidhne_extras

import "list"

import c "github.com/lugoues/creidhne"

#FlattenStruct: {
	#in: {...}
	#prefix: string
	out: list.FlattenN([
		for k, v in #in {
			let p = "\(#prefix).\(k)"
			if (v & {...}) != _|_ {(#FlattenStruct & {#in: v, #prefix: p}).out}
			if (v & {...}) == _|_ {
				if (v & [...]) != _|_ {
					(#FlattenStruct & {#in: {for i, e in v {"\(i)": e}}, #prefix: p}).out
				}
				if (v & [...]) == _|_ {["\(p)=\(v)"]}
			}
		},
	], 1)
}

#StringLabelList: c.#Rendered & {
	prefix: string
	#value: {...}
	#rendered: (#FlattenStruct & {#in: #value, #prefix: prefix}).out
}
