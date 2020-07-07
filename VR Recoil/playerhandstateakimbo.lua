dofile(ModPath .. "VRRecoilMain.lua")

local playercam = nil
local weaponInitialRotation = nil

local function getPlayerCam()
	-- Mother of sanity checks
	-- This is necessary because of procedural arm animation
	if managers.player and managers.player:player_unit() and managers.player:player_unit():camera() and managers.player:player_unit():camera():camera_unit() then
		playercam = managers.player:player_unit():camera():camera_unit():base()
	end
end

local akimboenter_orig = PlayerHandStateAkimbo.at_enter
function PlayerHandStateAkimbo:at_enter(prev_state)
	local result = akimboenter_orig(self, prev_state)
	
	getPlayerCam()
	weaponInitialRotation = self._weapon_unit:local_rotation()
	
	return result
end

local akimboupdate_orig = PlayerHandStateAkimbo.update
function PlayerHandStateAkimbo:update(t, dt)
	local result = akimboupdate_orig(self, t, dt)
	
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
	
	if not verticalKick or not horizontalKick or not weaponInitialRotation then
		return result
	end
	
	verticalKick = verticalKick * VRRecoil.OnehandedRecoilMultiplier
	horizontalKick = horizontalKick * VRRecoil.OnehandedRecoilMultiplier
	
	local weaponRotation = mrotation.copy(weaponInitialRotation)
	local weaponPitch = weaponRotation:pitch()
	local weaponYaw = weaponRotation:yaw()
	local weaponRoll = weaponRotation:roll()
	
	mrotation.set_yaw_pitch_roll(weaponRotation, weaponYaw + horizontalKick, weaponPitch + verticalKick, weaponRoll)
	self._weapon_unit:set_local_rotation(weaponRotation)
	
	return result
end