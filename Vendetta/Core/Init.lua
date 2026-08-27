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
		Ven.isTrackerHidden = db.isTrackerHidden or false
	end
end)
