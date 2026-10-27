## Paletas de las zonas (provisionales): fondo en degradado, bloques y siluetas del fondo.
class_name Themes
extends RefCounted

const DEFAULT := "piedra"
const PALETTES := {
	"piedra": {
		"bg_top": Color("1a2030"), "bg_bottom": Color("10131c"),
		"block": Color("3a4258"), "block_top": Color("7a87a6"), "block_shadow": Color("262c3c"),
		"far": Color("1e2638"), "near": Color("252e44"),
	},
	"agua": {
		"bg_top": Color("12262a"), "bg_bottom": Color("0b1618"),
		"block": Color("2f4f55"), "block_top": Color("6fb0a8"), "block_shadow": Color("1f3438"),
		"far": Color("15302f"), "near": Color("1b3b3b"),
	},
	"calido": {
		"bg_top": Color("2a1f1a"), "bg_bottom": Color("161110"),
		"block": Color("54423a"), "block_top": Color("b08a5a"), "block_shadow": Color("3a2d27"),
		"far": Color("2e231d"), "near": Color("382a22"),
	},
	"morado": {
		"bg_top": Color("221a33"), "bg_bottom": Color("110d1c"),
		"block": Color("443a5e"), "block_top": Color("9a86c8"), "block_shadow": Color("2d2640"),
		"far": Color("261d3a"), "near": Color("2f2548"),
	},
	"rojo": {
		"bg_top": Color("2e1418"), "bg_bottom": Color("160a0c"),
		"block": Color("5a2e36"), "block_top": Color("c26a72"), "block_shadow": Color("3c1d23"),
		"far": Color("33171c"), "near": Color("3f1c22"),
	},
}


static func palette(theme: String) -> Dictionary:
	return PALETTES.get(theme, PALETTES[DEFAULT])
