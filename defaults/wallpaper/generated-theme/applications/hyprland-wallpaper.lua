-- hyprland colors generated from the active wallpaper palette
local black = "rgb(121318)"
local white = "rgb(E4E1E9)"
local gray = "rgb(46464F)"
local red = "rgb(FFB4AB)"
local yellow = "rgb(E6BAD7)"
local blue = "rgb(BBC3FF)"
local cyan = "rgb(C3C5DD)"

hl.config({
	general = {
		col = {
			active_border = { colors = { cyan, white, cyan }, angle = 45 },
			inactive_border = gray,
		},
	},
})

hl.config({
	group = {
		groupbar = {
			col = {
				active = cyan,
				inactive = gray,
			},
		},
	},
})

