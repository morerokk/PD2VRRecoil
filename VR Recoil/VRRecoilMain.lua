if not VRRecoil then
	_G.VRRecoil = {}

	-- Tweakdata
	VRRecoil.Tweak = {}
	VRRecoil.Tweak.OnehandedRecoilMultiplier = 0.65
	VRRecoil.Tweak.TwohandedRecoilMultiplier = 0.3
	
	-- User settings
	VRRecoil.Settings = {
		AkimboSeparateRecoil = true
	}

	-- Is the currently fired weapon the akimbo one?
	-- This variable is updated on a PreHook every time the user fires weapons in VR
	VRRecoil.FiredWeaponIsAkimbo = false
end
