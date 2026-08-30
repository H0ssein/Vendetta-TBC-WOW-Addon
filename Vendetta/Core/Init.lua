local addonName, Ven = ...
_G[addonName] = Ven

Ven.playerCache = {}
Ven.activeTargets = {}
Ven.wantedLastSeen = {}
Ven.wantedAlertCooldowns = {}
Ven.wantedOffset = 0
Ven.targetOffset = 0
Ven.BountyBoard = {}
Ven.WantedBoard = {}

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(self, event, loadedAddon)
	if loadedAddon == addonName then
		VendettaDB = VendettaDB or {}
		VendettaDB["MyHeroes"] = VendettaDB["MyHeroes"] or {}
		VendettaDB["MyHeroes"][UnitName("player")] = select(2, UnitClass("player"))

		local db = Ven.InitHeroDB()
		if db.ignoreBGKills == nil then
			if db.ignoreInstKills ~= nil then
				db.ignoreBGKills = db.ignoreInstKills
				db.ignoreArenaKills = db.ignoreInstKills
				db.ignoreInstKills = nil
			else
				db.ignoreBGKills = true
				db.ignoreArenaKills = true
			end
		end
		if db.enableToasts == nil then
			db.enableToasts = true
			db.toastDuration = 5.0
			db.toastScale = 1.0
			db.toastBgColor = { r = 0.05, g = 0.05, b = 0.05, a = 0.95 }
			db.toastBorderColor = { r = 0.3, g = 0.3, b = 0.3, a = 1.0 }
			db.toastAnchor = "TOP"
			db.toastX = 0
			db.toastY = -90
		end
		if db.enableNetwork == nil then
			db.enableNetwork = true
		end
		Ven.isTrackerHidden = db.isTrackerHidden or false
	end
end)
