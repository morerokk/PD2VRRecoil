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

-- Get the current rotation of the akimbo weapon
-- This is necessary because unlike PlayerHandStateWeapon, the weapon unit is not automatically set back to the correct position.
function PlayerHandStateAkimbo:getWeaponRotation()
	if self._weapon_unit then
		return self._weapon_unit:local_rotation()
	end
end

local akimboenter_orig = PlayerHandStateAkimbo.at_enter
function PlayerHandStateAkimbo:at_enter(prev_state)
	local result = akimboenter_orig(self, prev_state)
	
	weaponInitialRotation = nil
	
	getPlayerCam()
	
	-- This is an edge case that has actually happened at least once, causing a crash.
	if self._weapon_unit then
		weaponInitialRotation = self:getWeaponRotation()
	end
	
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
	
	-- Try to get the initial rotation again if it isnt set yet.
	-- If it still isnt there, return early and avoid recoil processing since it will just cause a crash.
	if not weaponInitialRotation then
		weaponInitialRotation = self:getWeaponRotation()
		if not weaponInitialRotation then
			return result
		end
	end

	-- If there is no weapon unit (can happen if you're cloaked?), you can get crashed if the weapon unit does not exist.
	if not self._weapon_unit or not self._weapon_unit.alive or not self._weapon_unit:alive() then
		return result
	end
	
	-- Same as PlayerHandStateWeapon, except it uses the akimbo-specific recoil variables.
	local verticalKick = playercam._recoil_kick_akimbo.to_reduce or playercam._recoil_kick_akimbo.accumulated
	local horizontalKick = playercam._recoil_kick_akimbo.h.to_reduce or playercam._recoil_kick_akimbo.h.accumulated
	
	if not verticalKick or not horizontalKick or not weaponInitialRotation then
		return result
	end
	
	verticalKick = verticalKick * VRRecoil.Tweak.OnehandedRecoilMultiplier
	horizontalKick = horizontalKick * VRRecoil.Tweak.OnehandedRecoilMultiplier
	
	local weaponRotation = mrotation.copy(weaponInitialRotation)
	local weaponPitch = weaponRotation:pitch()
	local weaponYaw = weaponRotation:yaw()
	local weaponRoll = weaponRotation:roll()
	
	mrotation.set_yaw_pitch_roll(weaponRotation, weaponYaw + horizontalKick, weaponPitch + verticalKick, weaponRoll)
	self._weapon_unit:set_local_rotation(weaponRotation)
	
	return result
end