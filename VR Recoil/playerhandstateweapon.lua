dofile(ModPath .. "VRRecoilMain.lua")

local playercam = nil;

local function getPlayerCam()
	-- Mother of sanity checks
	-- This is necessary because of procedural arm animation
	if managers.player and managers.player:player_unit() and managers.player:player_unit():camera() and managers.player:player_unit():camera():camera_unit() then
		playercam = managers.player:player_unit():camera():camera_unit():base()
	end
end

local enter_orig = PlayerHandStateWeapon.at_enter
function PlayerHandStateWeapon:at_enter(prev_state)
	local result = enter_orig(self, prev_state)
	
	getPlayerCam()
	
	return result
end

local updateweapon_orig = PlayerHandStateWeapon.update
function PlayerHandStateWeapon:update(t, dt)
	local result = updateweapon_orig(self, t, dt)
	
	-- Get playercam if it is nil
	-- If it is *still* nil, avoid crashes and just return the original function for now.
	-- This is a vanilla bug with procedural arm animation.
	if not playercam then
		getPlayerCam()
		if not playercam then
			return result
		end
	end
	
	local verticalKick = playercam._recoil_kick.to_reduce or playercam._recoil_kick.accumulated
	local horizontalKick = playercam._recoil_kick.h.to_reduce or playercam._recoil_kick.h.accumulated
	
	if not verticalKick or not horizontalKick then
		return result
	end
	
	-- Reduce across the board, but reduce it more if two-handing the weapon
	local is_assisting = self:hsm():other_hand():current_state_name() == "weapon_assist"
	if is_assisting then
		verticalKick = verticalKick * VRRecoil.Tweak.TwohandedRecoilMultiplier
		horizontalKick = horizontalKick * VRRecoil.Tweak.TwohandedRecoilMultiplier
	else
		verticalKick = verticalKick * VRRecoil.Tweak.OnehandedRecoilMultiplier
		horizontalKick = horizontalKick * VRRecoil.Tweak.OnehandedRecoilMultiplier
	end
	
	-- Work around possible crashes like with bows
	if not self._weapon_unit then
		return result
	end
	
	local weaponRotation = self._weapon_unit:rotation()
	local weaponPitch = weaponRotation:pitch()
	local weaponYaw = weaponRotation:yaw()
	local weaponRoll = weaponRotation:roll()
	
	mrotation.set_yaw_pitch_roll(weaponRotation, weaponYaw + horizontalKick, weaponPitch + verticalKick, weaponRoll)
	self._weapon_unit:set_rotation(weaponRotation)
	
	return result
end