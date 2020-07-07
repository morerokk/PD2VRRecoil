-- Remove built-in "spread" recoil
function NewRaycastWeaponBaseVR:_get_spread(user_unit)
	return NewRaycastWeaponBase._get_spread(self, user_unit)
end
