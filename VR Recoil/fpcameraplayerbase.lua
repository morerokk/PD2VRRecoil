-- This file is normally used by the desktop version too. To avoid problems, don't do anything on desktop.
if not _G.IS_VR then return end

dofile(ModPath .. "VRRecoilMain.lua")

Hooks:PostHook(FPCameraPlayerBase, "init", "vrrecoil_cam_init", function(self)
    -- Initialize default akimbo recoil values
    self._recoil_kick_akimbo = {
        h = {}
    }
end)

-- Add callbacks for akimbo value resetting
-- The function has to be replaced entirely, because if the akimbo weapon was shot, this should not affect the main weapon.
local cam_start_shooting_orig = FPCameraPlayerBase.start_shooting
function FPCameraPlayerBase:start_shooting()

    if not VRRecoil.FiredWeaponIsAkimbo then
        return cam_start_shooting_orig(self)
    end

	self._recoil_kick_akimbo.accumulated = self._recoil_kick_akimbo.to_reduce or 0
	self._recoil_kick_akimbo.to_reduce = nil
	self._recoil_kick_akimbo.current = self._recoil_kick_akimbo.current and self._recoil_kick_akimbo.current or self._recoil_kick_akimbo.accumulated or 0
	self._recoil_kick_akimbo.h.accumulated = self._recoil_kick_akimbo.h.to_reduce or 0
	self._recoil_kick_akimbo.h.to_reduce = nil
	self._recoil_kick_akimbo.h.current = self._recoil_kick_akimbo.h.current and self._recoil_kick_akimbo.h.current or self._recoil_kick_akimbo.h.accumulated or 0
end

local cam_stop_shooting_orig = FPCameraPlayerBase.stop_shooting
function FPCameraPlayerBase:stop_shooting(wait)

    if not VRRecoil.FiredWeaponIsAkimbo then
        return cam_stop_shooting_orig(self, wait)
    end

	self._recoil_kick_akimbo.to_reduce = self._recoil_kick_akimbo.accumulated
	self._recoil_kick_akimbo.h.to_reduce = self._recoil_kick_akimbo.h.accumulated
	self._recoil_wait_akimbo = wait or 0
end

function FPCameraPlayerBase:stop_shooting_akimbo(wait)
	self._recoil_kick_akimbo.to_reduce = self._recoil_kick_akimbo.accumulated
	self._recoil_kick_akimbo.h.to_reduce = self._recoil_kick_akimbo.h.accumulated
	self._recoil_wait_akimbo = wait or 0
end

local cam_break_recoil_orig = FPCameraPlayerBase.break_recoil
function FPCameraPlayerBase:break_recoil()

    if not VRRecoil.FiredWeaponIsAkimbo then
        return cam_break_recoil_orig(self)
    end

    self._recoil_kick_akimbo.current = 0
	self._recoil_kick_akimbo.h.current = 0
	self._recoil_kick_akimbo.accumulated = 0
	self._recoil_kick_akimbo.h.accumulated = 0

	self:stop_shooting_akimbo()
end

-- Perform recoil kick
local camera_recoil_kick_orig = FPCameraPlayerBase.recoil_kick
function FPCameraPlayerBase:recoil_kick(up, down, left, right)
    -- If the fired weapon is not the akimbo one, return the original function
    if not VRRecoil.FiredWeaponIsAkimbo then
        return camera_recoil_kick_orig(self, up, down, left, right)
	end
	
	-- IreNFist compatibility for the offhand akimbo, copypasted from IreNFist itself
	if VRRecoil.ModCompatibility.IreNFist then
		-- If we get this far, this means we already know that the fired weapon is akimbo.
		-- Technically this means that the same recoil "pattern" will run over both weapons at once (instead of individually), but I consider this acceptable.

		-- set default recoil table
		local recoil_table = {
			{-1, -1, 0, 0}
		}
		local recoil_loop_point = 999

		-- get recoil table
		if self._parent_unit then
			if self._parent_unit:inventory() then
				if self._parent_unit:inventory():equipped_unit() then
					if self._parent_unit:inventory():equipped_unit():base() then
						if self._parent_unit:inventory():equipped_unit():base()._recoil_table then
							recoil_table = self._parent_unit:inventory():equipped_unit():base()._recoil_table
							recoil_loop_point = self._parent_unit:inventory():equipped_unit():base()._recoil_loop_point or 999
						end
					end
				end
			end
		end

		local recoil_index = self._accumulated_recoil+1
		-- don't pull table values that are off the table
		if recoil_index > #recoil_table then
			-- invalid or no recoil loop point
			if (recoil_loop_point or 0) > #recoil_table then
				recoil_index = #recoil_table
			-- use loop point
			else
				recoil_index = recoil_loop_point or #recoil_table
				self._accumulated_recoil = recoil_loop_point - 1
			end
		end

		-- send kick values
		local v = math.lerp(up * recoil_table[recoil_index][1], down * recoil_table[recoil_index][2], math.random())
		self._recoil_kick_akimbo.accumulated = (self._recoil_kick_akimbo.accumulated or 0) + v

		local h = math.lerp(left * recoil_table[recoil_index][3], right * recoil_table[recoil_index][4], math.random())
		self._recoil_kick_akimbo.h.accumulated = (self._recoil_kick_akimbo.h.accumulated or 0) + h

		-- set InF recoil system values
		self._last_shot_time = os.clock()
		self._last_unapplied_recoil_time = self._last_unapplied_recoil_time or self._last_shot_time
		self._current_wpn = self._parent_unit:inventory():equipped_unit():base()._factory_id
		self._accumulated_recoil = self._accumulated_recoil + 1
	else
		-- Below is the same as the original function, except modified for akimbos.

		if math.abs(self._recoil_kick_akimbo.accumulated) < 20 then
			local v = math.lerp(up, down, math.random())
			self._recoil_kick_akimbo.accumulated = (self._recoil_kick_akimbo.accumulated or 0) + v
		end

		local h = math.lerp(left, right, math.random())
		self._recoil_kick_akimbo.h.accumulated = (self._recoil_kick_akimbo.h.accumulated or 0) + h
	end
end

-- Update recoil values to allow gradual resetting of recoil for the akimbo weapon too
Hooks:PostHook(FPCameraPlayerBase, "_vertical_recoil_kick", "vrrecoil_cam_v_recoil_kick", function(self, t, dt)
	if self._recoil_kick_akimbo.current and self._episilon < self._recoil_kick_akimbo.accumulated - self._recoil_kick_akimbo.current then
		local n = math.step(self._recoil_kick_akimbo.current, self._recoil_kick_akimbo.accumulated, 40 * dt)
		self._recoil_kick_akimbo.current = n
	elseif self._recoil_wait_akimbo then
		self._recoil_wait_akimbo = self._recoil_wait_akimbo - dt

		if self._recoil_wait_akimbo < 0 then
			self._recoil_wait_akimbo = nil
		end
	elseif self._recoil_kick_akimbo.to_reduce then
		self._recoil_kick_akimbo.current = nil
		local n = math.lerp(self._recoil_kick_akimbo.to_reduce, 0, 9 * dt)
		self._recoil_kick_akimbo.to_reduce = n

		if self._recoil_kick_akimbo.to_reduce == 0 then
			self._recoil_kick_akimbo.to_reduce = nil
		end
	end
end)

-- "horizonatal" is a typo on OVK's part, not mine.
Hooks:PostHook(FPCameraPlayerBase, "_horizonatal_recoil_kick", "vrrecoil_cam_h_recoil_kick", function(self, t, dt)
	if self._recoil_kick_akimbo.h.current and self._episilon < math.abs(self._recoil_kick_akimbo.h.accumulated - self._recoil_kick_akimbo.h.current) then
		local n = math.step(self._recoil_kick_akimbo.h.current, self._recoil_kick_akimbo.h.accumulated, 40 * dt)
		self._recoil_kick_akimbo.h.current = n
	elseif self._recoil_wait_akimbo then
		self._recoil_wait_akimbo = self._recoil_wait_akimbo - dt

		if self._recoil_wait_akimbo < 0 then
			self._recoil_wait_akimbo = nil
		end
	elseif self._recoil_kick_akimbo.h.to_reduce then
		self._recoil_kick_akimbo.h.current = nil
		local n = math.lerp(self._recoil_kick_akimbo.h.to_reduce, 0, 5 * dt)
		self._recoil_kick_akimbo.h.to_reduce = n

		if self._recoil_kick_akimbo.h.to_reduce == 0 then
			self._recoil_kick_akimbo.h.to_reduce = nil
		end
	end
end)
