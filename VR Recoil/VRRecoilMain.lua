if not VRRecoil then
	_G.VRRecoil = {}

	-- Tweakdata
	VRRecoil.Tweak = {}
	VRRecoil.Tweak.OnehandedRecoilMultiplier = 0.75
	VRRecoil.Tweak.TwohandedRecoilMultiplier = 0.35
	
	-- User settings
	VRRecoil.Settings = {
		AkimboSeparateRecoil = true
	}

	-- Is the currently fired weapon the akimbo one?
	-- This variable is updated on a PreHook every time the user fires weapons in VR
	VRRecoil.FiredWeaponIsAkimbo = false

	VRRecoil.ModCompatibility = {}

	-- Blatant favouritism inbound
	-- If Irenfist is installed, loosen up on the recoil just slightly.
	-- IreNFist has brutal recoil and it needs to be reduced just slightly more in VR to be fun.
	if BeardLib.Utils:ModLoaded("irenfist") or BeardLib.Utils:ModLoaded("infmod") or BeardLib.Utils:ModLoaded("IRE AND FIST REBORN") then
		VRRecoil.Tweak.OnehandedRecoilMultiplier = 0.65
		VRRecoil.Tweak.TwohandedRecoilMultiplier = 0.3
		VRRecoil.ModCompatibility.IreNFist = true
		log("[VR Recoil] IreNFist found, recoil multipliers slightly lowered")
	end
end
