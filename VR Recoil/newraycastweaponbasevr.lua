dofile(ModPath .. "VRRecoilMain.lua")

-- For IreNFist, use a copied get_spread function from the mod
-- For vanilla, just remove the spread recoil multiplier since recoil is already being handled
if VRRecoil.ModCompatibility.IreNFist then
	function NewRaycastWeaponBaseVR:_get_spread(user_unit)
		local current_state = user_unit:movement()._current_state
	
		if not current_state then
			return 0, 0
		end
	
		local spread_values = self:weapon_tweak_data().spread
	
		if not spread_values then
			return 0, 0
		end
	
		local current_spread_value = spread_values[current_state:get_movement_state()]
		local spread_x, spread_y = nil
	
		-- get base spread
		if type(current_spread_value) == "number" then
			spread_x = self:_get_spread_from_number(user_unit, current_state, current_spread_value)
			spread_y = spread_x
		else
			spread_x, spread_y = self:_get_spread_from_table(user_unit, current_state, current_spread_value)
		end

		-- More hipfire spread is kinda BS in VR so we don't do that here. Just always run the ADS multipliers, it's hard enough to aim as it is.
		local ads_spread
		if current_state._moving then
			ads_spread = spread_values.moving_steelsight
		else
			ads_spread = spread_values.steelsight
		end
		if type(ads_spread) == "number" then
			spread_x = self:_get_spread_from_number(user_unit, current_state, ads_spread)
			spread_y = spread_x
		else
			spread_x = self:_get_spread_from_number(user_unit, current_state, ads_spread[1])
			spread_y = spread_y * self:_get_spread_from_number(user_unit, current_state, ads_spread[2])
		end
		if self:weapon_tweak_data().spreadadd then
			spread_x = spread_x + self:weapon_tweak_data().spreadadd.steelsight
			spread_y = spread_x
		end
	
		if self:in_burst_mode() and self._burst_spread_mult then
			spread_x = spread_x * self._burst_spread_mult
			spread_y = spread_y * self._burst_spread_mult
		end
	
		-- extra multiplier
		if self._spread_multiplier then
			spread_x = spread_x * self._spread_multiplier[1]
			spread_y = spread_y * self._spread_multiplier[2]
		end
	
		return spread_x, spread_y
	end
else
	-- Remove built-in "spread" recoil
	-- Sadly this requires copypasting the original function
	local spread_orig = NewRaycastWeaponBase._get_spread
	function NewRaycastWeaponBaseVR:_get_spread(user_unit)
		local current_state = user_unit:movement()._current_state

		if not current_state then
			return 0, 0
		end

		local spread_values = self:weapon_tweak_data().spread

		if not spread_values then
			return 0, 0
		end

		local current_spread_value = spread_values[current_state:get_movement_state()]
		local spread_x, spread_y = nil

		if type(current_spread_value) == "number" then
			spread_x = self:_get_spread_from_number(user_unit, current_state, current_spread_value)
			spread_y = spread_x
		else
			spread_x, spread_y = self:_get_spread_from_table(user_unit, current_state, current_spread_value)
		end

		if current_state:in_steelsight() then
			local steelsight_tweak = spread_values.steelsight
			local multi_x, multi_y = nil

			if type(steelsight_tweak) == "number" then
				multi_x = 1 + 1 - steelsight_tweak
				multi_y = multi_x
			else
				multi_x = 1 + 1 - steelsight_tweak[1]
				multi_y = 1 + 1 - steelsight_tweak[2]
			end

			spread_x = spread_x * multi_x
			spread_y = spread_y * multi_y
		end

		if self._spread_multiplier then
			spread_x = spread_x * self._spread_multiplier[1]
			spread_y = spread_y * self._spread_multiplier[2]
		end

		return spread_x, spread_y
	end
end