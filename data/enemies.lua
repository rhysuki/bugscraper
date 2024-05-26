require "scripts.util"

local enemies = {
	Larva =            require "scripts.actor.enemies.larva",
	Fly =              require "scripts.actor.enemies.fly",
	SpikedFly =        require "scripts.actor.enemies.spiked_fly",
	Woodlouse =        require "scripts.actor.enemies.woodlouse",
	Mosquito =         require "scripts.actor.enemies.mosquito",
	Slug =             require "scripts.actor.enemies.slug",
	MushroomAnt =      require "scripts.actor.enemies.mushroom_ant",
	HoneypotAnt =      require "scripts.actor.enemies.honeypot_ant",
	Spider =           require "scripts.actor.enemies.spider",
	StinkBug =         require "scripts.actor.enemies.stink_bug", --*
	Dung =             require "scripts.actor.enemies.dung",
	DungBeetle =       require "scripts.actor.enemies.dung_beetle",
	FlyingDung =       require "scripts.actor.enemies.flying_dung",
	
	SnailShelled =     require "scripts.actor.enemies.snail_shelled", 
	Grasshopper =      require "scripts.actor.enemies.grasshopper", 
	ChipBug =          require "scripts.actor.enemies.chip_bug", --* 
	MetalFly =         require "scripts.actor.enemies.metal_fly", --*
	FlyBuddy =         require "scripts.actor.enemies.fly_buddy", --*
	DrillBee =         require "scripts.actor.enemies.drill_bee", --*
	Turret =           require "scripts.actor.enemies.turret", --*
		
	Dummy =            require "scripts.actor.enemies.dummy",
	ButtonBigPressed = require "scripts.actor.enemies.button_big_pressed",
	ButtonBig =        require "scripts.actor.enemies.button_big",
	ButtonBigGlass =   require "scripts.actor.enemies.button_big_glass",
	ButtonSmallGlass = require "scripts.actor.enemies.button_small_glass",
	ButtonSmall =      require "scripts.actor.enemies.button_small",
	ExitSign =         require "scripts.actor.enemies.exit_sign",
	UpgradeDisplay =   require "scripts.actor.enemies.upgrade_display",
	VendingMachine =   require "scripts.actor.enemies.vending_machine.vending_machine",
	
	Cocoon =           require "scripts.actor.enemies.cocoon",
	FaintedPlayer =    require "scripts.actor.enemies.fainted_player",

	PoisonCloud =      require "scripts.actor.enemies.poison_cloud",
	ElectricArc =      require "scripts.actor.enemies.electric_arc",
	ElectricRays =     require "scripts.actor.enemies.electric_rays", --*
	PongBall =         require "scripts.actor.enemies.pong_ball",
}

return enemies