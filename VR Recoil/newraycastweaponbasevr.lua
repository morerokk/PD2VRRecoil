-- Remove built-in "spread" recoil
local spread_orig = NewRaycastWeaponBase._get_spread
function NewRaycastWeaponBaseVR:_get_spread(user_unit)
	return spread_orig(self, user_unit)
end
