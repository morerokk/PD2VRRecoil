dofile(ModPath .. "VRRecoilMain.lua")

-- This file is normally used by the desktop version too. To avoid problems, don't do anything on desktop.
if not _G.IS_VR then return end

Hooks:PostHook(FPCameraPlayerBase, "init", "vrrecoil_cam_init", function(self)
    -- Initialize default akimbo recoil values
    self._recoil_kick_akimbo = {
        h = {}
    }
end)

-- Add callbacks for akimbo value resetting
-- The function has to be replace entirely, because if the akimbo weapon was shot, this should not affect the main weapon.
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

--[[
local cam_stop_shooting_orig = FPCameraPlayerBase.stop_shooting
function FPCameraPlayerBase:stop_shooting(wait)

    if not VRRecoil.FiredWeaponIsAkimbo then
        return cam_stop_shooting_orig(self, wait)
    end

	self._recoil_kick_akimbo.to_reduce = self._recoil_kick_akimbo.accumulated
	self._recoil_kick_akimbo.h.to_reduce = self._recoil_kick_akimbo.h.accumulated
	self._recoil_wait_akimbo = wait or 0
end
]]

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

    -- Below is the same as the original function, except modified for akimbos.

	if math.abs(self._recoil_kick_akimbo.accumulated) < 20 then
		local v = math.lerp(up, down, math.random())
		self._recoil_kick_akimbo.accumulated = (self._recoil_kick_akimbo.accumulated or 0) + v
	end

	local h = math.lerp(left, right, math.random())
	self._recoil_kick_akimbo.h.accumulated = (self._recoil_kick_akimbo.h.accumulated or 0) + h
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
