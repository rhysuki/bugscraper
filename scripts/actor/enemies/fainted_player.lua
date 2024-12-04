require "scripts.util"
local Enemy = require "scripts.actor.enemy"
local sounds = require "data.sounds"
local images = require "data.images"
local skins = require "data.skins"

local Guns = require "data.guns"
local Timer = require "scripts.timer"

local FaintedPlayer = Enemy:inherit()

function FaintedPlayer:init(x, y, player)
    -- self:init_enemy(x,y, player.skin.spr_dead, 15, 15);
    self:init_enemy(x,y, images.cocoon, 15, 15)
    self.name = "fainted_player"

    self.player_n = player.n or 1

    self.follow_player = false
    self.counts_as_enemy = false

    self.life = 12
    self.damage = 0
    self.self_knockback_mult = 0.1
    
	self.destroy_bullet_on_impact = false
	self.is_immune_to_bullets = true
    
    self.knockback = 0
    
    self.is_immune_to_explosions = true
    self.is_immune_to_electricity = true
    self.is_stompable = false
    self.do_stomp_animation = false
    self.stompable_cooldown_timer = Timer:new(0.5)
    self.stompable_cooldown_timer:start()
    -- self.stomps = 3
    
    self.is_pushable = false
    self.is_knockbackable = false
    self.loot = {}

    self.has_revived = false

    self.gun = player.gun
    
    local skin = player.skin
    self.spr:set_outline(skin.color_palette[1], "round")

    -- self.sound_damage = {"cloth1", "cloth2", "cloth3"}
    -- self.sound_death = "cloth_drop"
    -- self.sound_stomp = "cloth_drop"
end

function FaintedPlayer:update(dt)
    self:update_enemy(dt)

    if self.stompable_cooldown_timer:update(dt) then
        self.is_stompable = true
    end
end

function FaintedPlayer:on_death(damager, reason)
    if self.has_revived then
        return
    end
    
    self:revive(damager)
end

function FaintedPlayer:revive(damager)
    print_debug("revive 1")
    Particles:image(self.mid_x, self.mid_y, 20, {images.cocoon_fragment_1, images.cocoon_fragment_2}, self.w, nil, nil, 0.5)
    
    local reviver
    if damager and damager.is_player then
        reviver = damager
    elseif damager and damager.is_bullet then
        reviver = damager.player
    elseif damager == nil then
        reviver = damager
    else
        return
    end
    print_debug("revive 2")

    self.has_revived = true

    local new_player = game:new_player(self.player_n, self.x, self.y)
    print_debug("revive 3")

    new_player:set_invincibility(new_player.max_invincible_time)
    new_player:equip_gun(self.gun)
    for _, upgrade in pairs(game.upgrades) do
        new_player:apply_upgrade(upgrade, true)
    end
    
    if reviver and reviver.is_player then
    print_debug("revive 4")

        local l = math.floor(reviver.life/2)
        local player_life, reviver_life = l, reviver.life - l
        if reviver.life <= 1 then
            player_life = 1
            reviver_life = 0
    print_debug("revive 5")

        end
        Particles:word(new_player.mid_x,  new_player.mid_y - 16,  concat("+", player_life), COL_LIGHT_RED)    
        Particles:word(reviver.mid_x, reviver.mid_y - 16, concat("-", reviver.life - reviver_life), COL_LIGHT_RED)    
        new_player:set_life(player_life)
        reviver:set_life(reviver_life)

    elseif reviver == nil then
    print_debug("revive 5")

        new_player:set_life(1)

    end

    print_debug("revive 6")

    if not self.is_dead then
        self:kill()
    end
    print_debug("revive 7")

    
end

function FaintedPlayer:draw()
    self:draw_enemy()
    
end

return FaintedPlayer