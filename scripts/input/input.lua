require "scripts.util"
local Class = require "scripts.meta.class"
local InputUser = require "scripts.input.input_user"
local InputProfile = require "scripts.input.input_profile"
local images = require "data.images"
local key_constant_to_image_name = require "data.buttons.images_buttons_keyboard"
local controller_buttons = require "data.buttons.controller_buttons"

local InputManager = Class:inherit()

function InputManager:init()
    self.users = {}
    self.joystick_to_user_map = {}

	self.standby_mode = false
    -- We need to enable/disable standy mode a frame later so we buffer it 
    -- active = is the buffer active? 
    -- value = what value should standby_mode take?
	self.buffer_standby_mode = {active = false, value = false} 
    self.last_ui_user_n = -1

	self.default_mapping_empty =         self:process_input_map(RAW_INPUT_MAP_DEFAULT_EMPTY)
	self.default_mapping =               self:process_input_map(RAW_INPUT_MAP_DEFAULT_GLOBAL)
	self.default_mapping_controller =    self:process_input_map(RAW_INPUT_MAP_DEFAULT_CONTROLLER)
	self.default_mapping_keyboard_solo = self:process_input_map(RAW_INPUT_MAP_DEFAULT_KEYBOARD_SOLO)
	self.default_mapping_split_kb_p1 =   self:process_input_map(RAW_INPUT_MAP_DEFAULT_SPLIT_KEYBOARD_P1)
	self.default_mapping_split_kb_p2 =   self:process_input_map(RAW_INPUT_MAP_DEFAULT_SPLIT_KEYBOARD_P2)

	self.input_profiles = {
        ["empty"] =             InputProfile:new("empty",             "k", self.default_mapping_empty),
        ["global"] =            InputProfile:new("global",            "k", self.default_mapping),
        ["controller_1"] =      InputProfile:new("controller_1",      "c", self.default_mapping_controller),
        ["controller_2"] =      InputProfile:new("controller_2",      "c", self.default_mapping_controller),
        ["controller_3"] =      InputProfile:new("controller_3",      "c", self.default_mapping_controller),
        ["controller_4"] =      InputProfile:new("controller_4",      "c", self.default_mapping_controller),
        ["keyboard_solo"] =     InputProfile:new("keyboard_solo",     "k", self.default_mapping_keyboard_solo),
        ["keyboard_split_p1"] = InputProfile:new("keyboard_split_p1", "k", self.default_mapping_split_kb_p1),
        ["keyboard_split_p2"] = InputProfile:new("keyboard_split_p2", "k", self.default_mapping_split_kb_p2),
    }

    self:load_controls()
end

function InputManager:init_users()
    self.global_user = self:new_user(GLOBAL_INPUT_USER_PLAYER_N, "global", true)
end

function InputManager:can_add_user()
    return self:get_number_of_users() < MAX_NUMBER_OF_PLAYERS
    -- if input_type == INPUT_TYPE_CONTROLLER then 
    -- elseif input_type == INPUT_TYPE_KEYBOARD then 
    --     return (self:get_number_of_users() < MAX_NUMBER_OF_PLAYERS) and 
    --         self:get_number_of_users(INPUT_TYPE_KEYBOARD) < 1
    -- end
    -- return true
end

function InputManager:get_number_of_users(input_type)
    local count = 0
    for i = 1, MAX_NUMBER_OF_PLAYERS do
        if self.users[i] ~= nil then
            if (input_type == nil) or (self.users[i].primary_input_type == input_type) then
                count = count + 1
            end
        end
    end
    return count
end

function InputManager:get_primary_input_type(player_n)
    local user = self.users[player_n]
    assert(user ~= nil, concat("user ", player_n, " doesn't exist"))
    return user.primary_input_type
end

function InputManager:assign_input_profile(player_n, profile_id)
    local user = self:get_user(player_n)
    if user == nil then return end

    if profile_id == "controller" then
        profile_id = concat("controller_", player_n)
        user.primary_input_type = INPUT_TYPE_CONTROLLER
    else
        user.primary_input_type = INPUT_TYPE_KEYBOARD
    end
    user:set_input_profile_id(profile_id)
end

function InputManager:update(dt)
    for i, user in pairs(self.users) do
        user:update(dt)
    end
end

function InputManager:update_last_input_state(dt)
    for i, user in pairs(self.users) do
        user:update_last_input_state()
    end

    if self.buffer_standby_mode.active then
        self.standby_mode = self.buffer_standby_mode.value
        self.buffer_standby_mode.active = false
    end
end

function InputManager:get_input_profile(profile_id)
    return self.input_profiles[profile_id]
end

function InputManager:get_input_profile_from_player_n(n)
    -- local map = self.input_maps[n]
    -- if map == nil then return {} end
    -- return self.input_maps[n]:get_mappings() or {}
    
    local user = self:get_user(n)
    if user == nil then return end
    return user:get_input_profile()
end

function InputManager:new_user(n, input_profile_id, is_global)
    input_profile_id = param(input_profile_id, "empty")
    is_global = param(is_global, false)

    local user = InputUser:new(n, input_profile_id, is_global)
    self.users[n] = user
    return user
end

function InputManager:remove_user(n)
    local user = self.users[n]
    if user == nil then
        return false
    end

    if user.joystick then
        self.joystick_to_user_map[user.joystick] = nil
    end
    self.users[n] = nil
end

function InputManager:assign_joystick(user_n, joystick)
    if joystick == nil or not joystick:isConnected() then
        return 
    end

    local input_user = Input.users[user_n]
    if input_user then
        input_user.joystick = joystick
        self.joystick_to_user_map[joystick] = input_user
    end
end

function InputManager:joystickadded(joystick)
    -- for i = 1, MAX_NUMBER_OF_PLAYERS do
	-- 	local input_user = Input.users[i]
	-- 	if input_user and (input_user.joystick == nil or not input_user.joystick:isConnected()) then
	-- 		input_user.joystick = joystick
    --         self.joystick_to_user_map[joystick] = input_user
	-- 		return
	-- 	end
	-- end
end

function InputManager:joystickremoved(joystick)
    -- local input_user = self.joystick_to_user_map[joystick]
    -- if input_user == nil then
    --     return
    -- end

    -- input_user.joystick = joystick
    -- self.joystick_to_user_map[joystick] = nil
end

function InputManager:gamepadaxis(joystick, axis, value)
end

function InputManager:axis_to_key_name(axis, value)
    local code = tostring(axis)..ternary(value > 0, "+", "-")
    local name = AXIS_TO_KEY_NAME_MAP[code]
    return name
end

function InputManager:is_axis_down(player_n, axis_name) 
    local user = self:get_user(player_n)
    assert(user ~= nil, "user "..tostring(player_n).." doesn't exist")

    return user:is_axis_down(axis_name)
end

function InputManager:get_joystick_user(joystick)
    return self.joystick_to_user_map[joystick]
end

function InputManager:get_joystick_user_n(joystick)
    local user = self.joystick_to_user_map[joystick]
    if user == nil then return -1 end

    return user.n
end

function InputManager:gamepadpressed(joystick, buttoncode)
end

function InputManager:gamepadreleased(joystick, buttoncode)
end

function InputManager:is_keyboard_button_in_list_down(buttons)
    for _, button in pairs(buttons) do
		if love.keyboard.isScancodeDown(button.key_name) then
			return true
		end
	end
	return false
end

function InputManager:is_keyboard_down(button)
    return love.keyboard.isScancodeDown(button.key_name)
end

function InputManager:action_down(n, action, bypass_standy)
    if self.standby_mode and not bypass_standy then
        return false
    end
    if action == nil then
        return self:action_down_any_player(n)
    end
    local user = self.users[n]
    if not user then return false end
    return user:action_down(action)
end

function InputManager:action_pressed(n, action, bypass_standy)
    if self.standby_mode and not bypass_standy then
        return false
    end
    if action == nil then
        return self:action_pressed_any_player(n)
    end
    local user = self.users[n]
    if not user then return false end
    local output = user:action_pressed(action)
    return output
end

function InputManager:action_down_any_player(action, bypass_standy)
    if self.standby_mode and not bypass_standy then
        return false
    end
    for i, user in pairs(self.users) do
        if user:action_down(action) then return true end
    end
    return false
end

function InputManager:action_pressed_any_player(action, bypass_standy)
    if self.standby_mode and not bypass_standy then
        return false
    end
    for i, user in pairs(self.users) do
        if user:action_pressed(action) then return true end
    end
    return false
end

function InputManager:action_down_global(action, bypass_standy)
    if self.standby_mode and not bypass_standy then
        return false
    end
    return self.global_user:action_down(action)
end

function InputManager:action_pressed_global(action, bypass_standy)
    if self.standby_mode and not bypass_standy then
        return false
    end
    return self.global_user:action_pressed(action)
end

function InputManager:get_user(n)
    return self.users[n]
end

function InputManager:get_global_user()
    return self.global_user
end

function InputManager:get_primary_button(n, action)
    local user = self:get_user(n)
    if user == nil then
        return nil
    end
    return user:get_primary_button(action)
end

function InputManager:get_buttons_from_player_n(player_n, action)
    local profile = self:get_input_profile_from_player_n(player_n)
    if profile == nil then 
        return {} 
    end
    local buttons = profile:get_buttons(action)

    return buttons or {}
end

function InputManager:set_action_buttons(profile_id, action, buttons)
    local map = self:get_input_profile(profile_id)
    if map == nil then
        print(concat("set_action_buttons: profile '",profile_id,"' doesn't exist"))
        return
    end

    map:set_action_buttons(action, buttons)

	self:update_controls_file(profile_id)
end

function InputManager:add_action_button(profile_id, action, new_button)
    local profile = self:get_input_profile(profile_id)
    assert(profile ~= nil, concat("add_action_button: profile '",profile_id,"' doesn't exist"))

    local current_buttons = profile:get_buttons(action)
    print_table(current_buttons)
    table.insert(current_buttons, new_button)
    print_table(current_buttons)

	self:update_controls_file(profile_id)
end

function InputManager:mark_action_as_handled(player_n, action)
    local user = self:get_user(player_n)
    if user == nil then return end
    self:get_user(player_n):mark_action_as_handled(action)
end

function InputManager:mark_action_as_handled_for_all_users(action)
    for i = 1, MAX_NUMBER_OF_PLAYERS do
        self:mark_action_as_handled(i, action)
    end
end

function InputManager:reset_controls(profile_id, input_mode)
    -- fixme assign default controls to input scheme and load them in this function
	local profile = self:get_input_profile(profile_id)
    assert(profile ~= nil, concat("profile '",profile_id, "' does not exist"))

    local new_mapping = {}
    for action, default_buttons in pairs(profile:get_default_mappings()) do
        local current_buttons = profile:get_buttons(action)

        local new_buttons = {}
        for _, button in pairs(default_buttons) do
            if button.type == input_mode then
                table.insert(new_buttons, button)
            end
        end

        for _, button in pairs(current_buttons) do
            if button.type ~= input_mode then
                table.insert(new_buttons, button)
            end
        end
        new_mapping[action] = new_buttons
    end

    profile:set_mappings(new_mapping)

    self:update_controls_file(profile_id)
end

function InputManager:is_button_in_use(profile_id, action, button)
	local profile = self:get_input_profile(profile_id)
    assert(profile ~= nil, concat("profile '", profile_id, "'' does not exist"))
    
    local assigned_buttons = profile:get_buttons(action)
    assert(assigned_buttons ~= nil, concat("action ",action, " has no assigned buttons for profile '", profile_id, "'"))
    for _, assigned_button in ipairs(assigned_buttons) do
        if assigned_button.type == button.type and assigned_button.key_name == button.key_name then
            return true
        end
    end
    return false
end

function InputManager:set_standby_mode(enabled)
    -- self.standby_mode = enabled
    self.buffer_standby_mode.value = enabled
    self.buffer_standby_mode.active = true
end

function InputManager:split_keyboard()
    local p1 = nil
    local p2 = nil
    for i=1, MAX_NUMBER_OF_PLAYERS do
        local user = self.users[i]
        if user and user.primary_input_type == INPUT_TYPE_KEYBOARD then
            if p1 == nil then
                p1 = i
            else
                p2 = i
            end
        end
    end

    if p2 == nil then
        return
    end

    self:assign_input_profile(p1, "keyboard_split_p1")
    self:assign_input_profile(p2, "keyboard_split_p2")
end

function InputManager:unsplit_keyboard()
    for i=1, MAX_NUMBER_OF_PLAYERS do
        local user = self.users[i]
        if user and user.primary_input_type == INPUT_TYPE_KEYBOARD then
            self:assign_input_profile(i, "keyboard_solo")
        end
    end
end

function InputManager:get_button_style(player_n)
    local user_brand = nil
    if self:get_user(player_n) then
        user_brand = self:get_user(player_n):get_button_style()
    else
        user_brand = Options:get("button_style_p"..tostring(player_n))
        if user_brand == BUTTON_STYLE_DETECT then
            user_brand = BUTTON_STYLE_XBOX
        end
    end
    return user_brand or BUTTON_STYLE_XBOX
end

function InputManager:get_last_ui_user_n()
    return self.last_ui_user_n
end

function InputManager:set_last_ui_user_n(n)
    self.last_ui_user_n = n 
end

-----------------------------------------------------

function InputManager:generate_unknown_key_icon(icon, text)
    local old_canvas = love.graphics.getCanvas()

    local text_w = get_text_width(text.."[]")
    local open_bracket_w = get_text_width("[")
    local new_canvas = love.graphics.newCanvas(icon:getWidth() + text_w + 3, icon:getHeight() + 2)
    love.graphics.setCanvas(new_canvas)

    love.graphics.print("[", 1, 1)
    love.graphics.draw(icon, open_bracket_w + 1, 1)
    love.graphics.print(text.."]", open_bracket_w + icon:getWidth() + 1, 1)

    love.graphics.setCanvas(old_canvas)
    return new_canvas
end

function InputManager:get_action_primary_icon(player_n, action, brand_override)
    local button = Input:get_primary_button(player_n, action)
    if button == nil then
        return ternary(self:get_primary_input_type(player_n) == INPUT_TYPE_KEYBOARD, images.btn_k_unknown, images.btn_c_unknown)
    end
    local icon = Input:get_button_icon(player_n, button, brand_override)
    return icon
end

function InputManager:get_button_icon(player_n, button, brand_override)
    button = button or {}

    local img = nil
    if button.type == "k" then
		local key_constant = love.keyboard.getKeyFromScancode(button.key_name)
        local image_name = key_constant_to_image_name[key_constant]
		if image_name ~= nil then
            img = images[image_name]
        end

        if img == nil or img == images.btn_k_unknown then
            return self:generate_unknown_key_icon(images.btn_k_unknown, button.key_name)
        end

    elseif button.type == "c" then
        local brand = (brand_override or self:get_button_style(player_n)) or BUTTON_STYLE_XBOX
        img = self:get_button_icon_controller(button, brand)
        
        if img == nil then
            return self:generate_unknown_key_icon(images.btn_c_unknown, button.key_name)
        end
        
	end
    return img or self:generate_unknown_key_icon(images.btn_k_unknown, "?")
end

function InputManager:get_button_icon_controller(button, brand)
    assert(button ~= nil, "no button defined")
    assert(button.type == INPUT_TYPE_CONTROLLER, "input type is not controller")

    local image_name = string.format("btn_c_%s_%s", brand, button.key_name)
    return images[image_name] or self:generate_unknown_key_icon(images.btn_c_unknown, button.key_name)
end

function InputManager:draw_input_prompt(player_n, actions, label, label_color, x, y)
    for __, action in ipairs(actions) do
        local icon = Input:get_action_primary_icon(player_n, action)
        local icon_w = icon:getWidth()
        
        love.graphics.draw(icon, x, y)
        x = x + icon_w + 2
    end
    local text_w = get_text_width(label)
    print_outline(label_color, COL_BLACK_BLUE, label, x, y)

    x = x + text_w
    return x
end

-----------------------------------------------------
------------------| Reading files |------------------
-----------------------------------------------------

function InputManager:keycode_to_button(keycode)
    if keycode ~= nil and #keycode > 2 then
        local prefix = keycode:sub(1, 1)
        local keyname = keycode:sub(3, -1)
        return {
            type = prefix,
            key_name = keyname
        }
    end
    return nil
end

function InputManager:process_input_map(raw_input_map)
    local new_map = {}
    for action, keys in pairs(raw_input_map) do
        new_map[action] = {}
        for _, keycode in pairs(keys) do
            local button = self:keycode_to_button(keycode)
            if button ~= nil then
                table.insert(new_map[action], button)
            end
        end
    end
    return new_map
end

function InputManager:load_controls()
	if love.filesystem.getInfo == nil then
		print("/!\\ WARNING: love.filesystem.getInfo doesn't exist. Either running on web or LÖVE version is incorrect. Loading controls for players aborted, so custom keybinds will not be loaded.")
		return
	end

	for profile_id, profile in pairs(self.input_profiles) do
		local filename = concat("inputprofile_",profile_id,".txt")

		-- Check if file exists
		local file_exists = love.filesystem.getInfo(filename)
		if not file_exists then
			print(filename, "does not exist, so creating it")
			self:update_controls_file(profile_id)
        else
            local file = love.filesystem.newFile(filename)
            file:open("r")
    
            local new_mappings = copy_table(profile:get_mappings())
    
            -- Read file contents
            local text, size = file:read()
            if not text then    print(concat("Error reading ",filename,": ",size))    end
            local lines = split_str(text, "\n") -- Split lines
        
            for iline = 1, #lines do
                local line = lines[iline]
                local tab = split_str(line, ":")
                local action_name = tab[1]
                local keycodes = tab[2] or ""
                local keycode_table = split_str(keycodes, " ")
    
                local new_buttons = {}
                for _, keycode in pairs(keycode_table) do
                    local button = self:keycode_to_button(keycode)
                    if button ~= nil then
                        table.insert(new_buttons, button)
                    end
                end
                new_mappings[action_name] = new_buttons
            end
    
            file:close()
    
            self.input_profiles[profile_id]:set_mappings(new_mappings)
		end
	end
end

function InputManager:buttons_to_keycodes(buttons)
    local keycodes = {}
    for i, button in ipairs(buttons) do
        table.insert(keycodes, button.type .. "_" .. button.key_name)
    end
    return keycodes
end

function InputManager:update_all_controls_files()
	for profile_id, profile in pairs(self.input_profiles) do
        self:update_controls_file(profile_id)
    end
end

function InputManager:update_controls_file(profile_id)
    local filename = concat("inputprofile_",profile_id,".txt")
    local controlsfile = love.filesystem.newFile(filename)
    print(concat("Creating or updating ", filename, " file"))
    controlsfile:open("w")

    for action_name, buttons in pairs(self.input_profiles[profile_id]:get_mappings()) do
        local keycodes = self:buttons_to_keycodes(buttons)
        local keycodes_string = concatsep(keycodes," ")

        controlsfile:write(concat(action_name, ":", keycodes_string, "\n"))
    end

    controlsfile:close()
end

function InputManager:on_quit()
    self:update_all_controls_files()
end

return InputManager