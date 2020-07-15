dofile(ModPath .. "VRRecoilMain.lua")

local playerstandardvr_check_fire_orig = PlayerStandardVR._check_fire_per_weapon
function PlayerStandardVR:_check_fire_per_weapon(t, pressed, held, released, weap_base, akimbo)
    -- This global variable checks which weapon is currently being fired/evaluated
    VRRecoil.FiredWeaponIsAkimbo = akimbo and true or false

    return playerstandardvr_check_fire_orig(self, t, pressed, held, released, weap_base, akimbo)
end

-- Allow the akimbo weapon to return to a resting state
--[[
Hooks:PostHook(PlayerStandardVR, "_check_stop_shooting", "vrrecoil_playerstandardvr_checkstopshoot", function(self)
    if self._equipped_unit:base().akimbo then
        self._camera_unit:base():stop_shooting_akimbo(self._equipped_unit:base():recoil_wait())
    end
end)
]]

--[[
Hooks:PostHook(PlayerStandardVR, "_stop_shooting_weapon", "vrrecoil_playerstandardvr_stopshooting", function(self, index)
    if index == 1 then
        self._camera_unit:base():stop_shooting(self._equipped_unit:base():recoil_wait())
    elseif index == 2 then
        self._camera_unit:base():stop_shooting_akimbo(self._equipped_unit:base():recoil_wait())
    end
end)
]]

function PlayerStandardVR:_check_stop_shooting()
	local akimbo = self._equipped_unit:base().AKIMBO

	if self._shooting and self._shooting_weapons then
        for k, weap_base in pairs(self._shooting_weapons) do
            
            if k == 1 then
                self._camera_unit:base():stop_shooting(self._equipped_unit:base():recoil_wait())
            elseif k == 2 then
                self._camera_unit:base():stop_shooting_akimbo(self._equipped_unit:base():recoil_wait())
            end

			weap_base:stop_shooting()
			self._ext_network:send("sync_stop_auto_fire_sound", k - 1)

			self._shooting_weapons[k] = nil
		end

		if not next(self._shooting_weapons) then
			self._shooting = false
			self._shooting_t = nil
		end
	end
end
