local addonName, Ven = ...

local recentAttackers, recentDamageDealt, lastKillRegistered = {}, {}, {}
local wasDBVisibleBeforeCombat = false

local function GetFactionFromRace(raceFile)
	if not raceFile then
		return "?"
	end
	if
		raceFile == "Orc"
		or raceFile == "Scourge"
		or raceFile == "Tauren"
		or raceFile == "Troll"
		or raceFile == "BloodElf"
	then
		return "Horde"
	end
	if
		raceFile == "Human"
		or raceFile == "Dwarf"
		or raceFile == "NightElf"
		or raceFile == "Gnome"
		or raceFile == "Draenei"
	then
		return "Alliance"
	end
	return "?"
end

local function UpdateMissingDBInfo(name)
	if not name then
		return
	end
	local db = Ven.InitHeroDB()
	local pc = Ven.playerCache[name]
	if db[name] and pc then
		if not db[name].classFile and pc.classFile then
			db[name].classFile = pc.classFile
			db[name].class = pc.class
			db[name].race = pc.race
			db[name].faction = pc.faction
		end
		if pc.level and pc.level ~= "?" and pc.level ~= -1 and (not db[name].level or db[name].level == "?") then
			db[name].level = pc.level
		end
	end
end

local function CachePlayerFromGUID(name, guid)
	if not name or not guid then
		return
	end
	local localizedClass, englishClass, localizedRace, englishRace = GetPlayerInfoByGUID(guid)
	if englishClass then
		Ven.playerCache[name] = Ven.playerCache[name] or {}
		Ven.playerCache[name].classFile = englishClass
		Ven.playerCache[name].class = localizedClass
		Ven.playerCache[name].race = localizedRace
		Ven.playerCache[name].faction = GetFactionFromRace(englishRace)
		UpdateMissingDBInfo(name)
	end
end

local function RegisterKill(enemyName, enemyGUID)
	local myName, myGUID = UnitName("player"), UnitGUID("player")
	if not enemyName or enemyName == myName or (enemyGUID and enemyGUID == myGUID) then
		return
	end

	local now = GetTime()
	if lastKillRegistered[enemyName] and (now - lastKillRegistered[enemyName] < 5) then
		return
	end
	lastKillRegistered[enemyName] = now
	if enemyGUID then
		CachePlayerFromGUID(enemyName, enemyGUID)
	end

	local db = Ven.InitHeroDB()
	if not db[enemyName] then
		local pc = Ven.playerCache[enemyName] or Ven.SyncPlayerDataFromOtherHeroes(enemyName) or {}
		db[enemyName] = {
			kills = 0,
			deaths = 0,
			level = pc.level or "?",
			class = pc.class or "?",
			classFile = pc.classFile,
			race = pc.race or "?",
			faction = pc.faction or "?",
			note = "",
			bountyNote = "",
			isWanted = false,
			isBounty = false,
			timeAdded = time(),
		}
	end
	UpdateMissingDBInfo(enemyName)
	db[enemyName].kills = (db[enemyName].kills or 0) + 1

	local zText, mText = GetZoneText() or "", GetMinimapZoneText() or ""
	local pureZone = zText
	if mText ~= "" and mText ~= zText then
		pureZone = pureZone .. " - " .. mText
	end
	local layer = Ven.GetCurrentLayer()
	local killLoc = pureZone
	if layer ~= "" then
		killLoc = killLoc .. " (Layer " .. layer .. ")"
	end

	local killTimestamp = time()
	db[enemyName].lastKillTime = killTimestamp
	db[enemyName].lastKillLoc = killLoc

	local playedKillSound = false
	if db[enemyName].isWanted then
		local kIdx, kForce = db.wantedKillSoundIdx or 3, db.wantedKillForceBG or false
		if kIdx == 2 then
			local rIdx = math.random(3, #Ven.killSoundList)
			Ven.AlertPlaySound(Ven.killSoundList[rIdx].id, kForce)
		else
			Ven.AlertPlaySound(Ven.killSoundList[kIdx] and Ven.killSoundList[kIdx].id, kForce)
		end
		playedKillSound = true
	end
	if db[enemyName].isBounty and not playedKillSound then
		local kIdx, kForce = db.bountyKillSoundIdx or 2, db.bountyKillForceBG or false
		if kIdx == 2 then
			local rIdx = math.random(3, #Ven.killSoundList)
			Ven.AlertPlaySound(Ven.killSoundList[rIdx].id, kForce)
		else
			Ven.AlertPlaySound(Ven.killSoundList[kIdx] and Ven.killSoundList[kIdx].id, kForce)
		end
		playedKillSound = true
	end

	local inInst = IsInInstance()
	local isNetBounty = Ven.BountyBoard and Ven.BountyBoard[enemyName]
	local isNetWanted = Ven.WantedBoard and Ven.WantedBoard[enemyName]
	if db.enableNetwork and not inInst and (isNetBounty or isNetWanted) then
		if not playedKillSound then
			local bkIdx, bkForce = db.bountyKillSoundIdx or 2, db.bountyKillForceBG or false
			if bkIdx == 2 then
				local rIdx = math.random(3, #Ven.killSoundList)
				Ven.AlertPlaySound(Ven.killSoundList[rIdx].id, bkForce)
			else
				Ven.AlertPlaySound(Ven.killSoundList[bkIdx] and Ven.killSoundList[bkIdx].id, bkForce)
			end
		end

		local notifiedOwners = {}
		local function AddPending(board)
			if not board then
				return
			end
			for owner, _ in pairs(board) do
				if not notifiedOwners[owner] then
					notifiedOwners[owner] = true
					Ven.PendingBounties = Ven.PendingBounties or {}
					local found = false
					for _, pData in ipairs(Ven.PendingBounties) do
						if string.lower(pData.owner) == string.lower(owner) and pData.target == enemyName then
							pData.count = (pData.count or 1) + 1
							pData.timestamp = killTimestamp
							pData.loc = killLoc
							found = true
							break
						end
					end
					if not found then
						table.insert(
							Ven.PendingBounties,
							{ owner = owner, target = enemyName, timestamp = killTimestamp, loc = killLoc, count = 1 }
						)
					end
				end
			end
		end
		AddPending(Ven.BountyBoard and Ven.BountyBoard[enemyName])
		AddPending(Ven.WantedBoard and Ven.WantedBoard[enemyName])
		if Ven.ProcessPendingBounties then
			Ven.ProcessPendingBounties()
		end
	end
	if Ven.DBFrame and Ven.DBFrame:IsShown() and Ven.RefreshDBView then
		Ven.RefreshDBView()
	end
	if Ven.UpdateTrackerUI then
		Ven.UpdateTrackerUI()
	end
end

local combatLogFrame = CreateFrame("Frame")
combatLogFrame:RegisterEvent("ADDON_LOADED")
combatLogFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
combatLogFrame:RegisterEvent("PLAYER_DEAD")
combatLogFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
combatLogFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

combatLogFrame:SetScript("OnEvent", function(self, event, ...)
	if event == "PLAYER_REGEN_DISABLED" then
		if Ven.CombatBlocker then
			Ven.CombatBlocker:Show()
		end
		if Ven.InitHeroDB().hideInCombat then
			if Ven.DBFrame and Ven.DBFrame:IsShown() then
				wasDBVisibleBeforeCombat = true
				Ven.DBFrame:Hide()
			end
			if Ven.TrackerFrame and not InCombatLockdown() then
				Ven.TrackerFrame:Hide()
			end
			if Ven.QuickCopy then
				Ven.QuickCopy:Hide()
			end
		end
	elseif event == "PLAYER_REGEN_ENABLED" then
		if Ven.CombatBlocker then
			Ven.CombatBlocker:Hide()
		end
		if Ven.InitHeroDB().hideInCombat and wasDBVisibleBeforeCombat then
			if Ven.DBFrame then
				Ven.DBFrame:Show()
			end
		end
		wasDBVisibleBeforeCombat = false
		if Ven.UpdateTrackerUI then
			Ven.UpdateTrackerUI()
		end
	elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
		if Ven.ShouldIgnoreCombat() then
			return
		end
		local _, subevent, _, sourceGUID, sourceName, _, _, destGUID, destName = CombatLogGetCurrentEventInfo()
		local isSourcePlayer, isDestPlayer =
			sourceGUID and string.match(sourceGUID, "^Player%-"), destGUID and string.match(destGUID, "^Player%-")
		local myGUID, myName = UnitGUID("player"), UnitName("player")
		local sName, dName =
			sourceName and string.match(sourceName, "([^%-]+)"), destName and string.match(destName, "([^%-]+)")
		if isSourcePlayer and sName and sName ~= myName and sourceGUID ~= myGUID then
			CachePlayerFromGUID(sName, sourceGUID)
		end
		if isDestPlayer and dName and dName ~= myName and destGUID ~= myGUID then
			CachePlayerFromGUID(dName, destGUID)
		end

		if
			sourceGUID == myGUID
			and string.match(subevent, "_DAMAGE")
			and isDestPlayer
			and destGUID ~= myGUID
			and dName ~= myName
		then
			recentDamageDealt[dName] = { time = GetTime(), guid = destGUID }
		elseif
			subevent == "PARTY_KILL"
			and sourceGUID == myGUID
			and isDestPlayer
			and destGUID ~= myGUID
			and dName ~= myName
		then
			RegisterKill(dName, destGUID)
		elseif subevent == "UNIT_DIED" and isDestPlayer and destGUID ~= myGUID and dName ~= myName then
			if dName and recentDamageDealt[dName] and (GetTime() - recentDamageDealt[dName].time < 15) then
				RegisterKill(dName, recentDamageDealt[dName].guid)
				recentDamageDealt[dName] = nil
			end
		elseif
			string.match(subevent, "_DAMAGE")
			and destGUID == myGUID
			and isSourcePlayer
			and sourceGUID ~= myGUID
			and sName ~= myName
		then
			recentAttackers[sName] = { time = GetTime(), guid = sourceGUID }
		end
	elseif event == "PLAYER_DEAD" then
		if Ven.ShouldIgnoreCombat() then
			recentAttackers = {}
			return
		end
		local deathTimestamp, myName, myGUID = time(), UnitName("player"), UnitGUID("player")
		for name, data in pairs(recentAttackers) do
			if name ~= myName and data.guid ~= myGUID and GetTime() - data.time < 15 then
				CachePlayerFromGUID(name, data.guid)
				local db = Ven.InitHeroDB()
				if not db[name] then
					local pc = Ven.playerCache[name] or Ven.SyncPlayerDataFromOtherHeroes(name) or {}
					db[name] = {
						kills = 0,
						deaths = 0,
						level = pc.level or "?",
						class = pc.class or "?",
						classFile = pc.classFile,
						race = pc.race or "?",
						faction = pc.faction or "?",
						note = "",
						bountyNote = "",
						isWanted = false,
						isBounty = false,
						timeAdded = time(),
					}
				end
				UpdateMissingDBInfo(name)
				db[name].deaths = (db[name].deaths or 0) + 1
				db[name].lastDeathTime = deathTimestamp
			end
		end
		recentAttackers = {}
		if Ven.DBFrame and Ven.DBFrame:IsShown() and Ven.RefreshDBView then
			Ven.RefreshDBView()
		end
		if Ven.UpdateTrackerUI then
			Ven.UpdateTrackerUI()
		end
	elseif event == "ADDON_LOADED" then
		local loadedAddon = ...
		if loadedAddon == addonName then
			local db = Ven.InitHeroDB()
			if db.trackerWidth and Ven.TrackerFrame then
				Ven.TrackerFrame:SetWidth(db.trackerWidth)
			end
			local rName, pName = GetRealmName() or "Unknown", UnitName("player") or "Unknown"
			if VendettaDB[rName] then
				for hero, enemies in pairs(VendettaDB[rName]) do
					if type(enemies) == "table" then
						for eName, eData in pairs(enemies) do
							if type(eData) == "table" and (eData.isWanted or eData.isBounty) and hero ~= pName then
								if not db[eName] then
									db[eName] = {
										kills = 0,
										deaths = 0,
										level = eData.level,
										class = eData.class,
										classFile = eData.classFile,
										race = eData.race,
										faction = eData.faction,
										note = eData.note,
										bountyNote = eData.bountyNote,
										isWanted = eData.isWanted,
										isBounty = eData.isBounty,
									}
								else
									db[eName].isWanted = eData.isWanted
									db[eName].isBounty = eData.isBounty
									db[eName].bountyNote = eData.bountyNote
								end
							end
						end
					end
				end
			end
		end
	end
end)

local scanTimer = 0
CreateFrame("Frame"):SetScript("OnUpdate", function(self, elapsed)
	scanTimer = scanTimer + elapsed
	if scanTimer < 0.5 then
		return
	end
	scanTimer = 0
	if Ven.ShouldIgnoreCombat() then
		if Ven.TrackerFrame and Ven.TrackerFrame:IsShown() then
			Ven.TrackerFrame:Hide()
		end
		return
	end

	local db = Ven.InitHeroDB()
	local isSafeZone = (GetZonePVPInfo() == "sanctuary")
	local inInstance, instanceType = IsInInstance()
	local isPvPInst = inInstance and (instanceType == "pvp" or instanceType == "arena")
	if inInstance and (instanceType == "party" or instanceType == "raid" or instanceType == "scenario") then
		return
	end

	local scanWanteds = (not inInstance and db.trackWantedsWorld ~= false)
		or (isPvPInst and db.trackWantedsInst ~= false)
	local scanEnemies = (not inInstance and db.trackTargetsWorld ~= false)
		or (isPvPInst and db.trackTargetsInst ~= false)
	local scanAllies = (not inInstance and db.trackAlliesWorld == true) or (isPvPInst and db.trackAlliesInst == true)
	local foundThisTick = {}
	local unitsToScan = { "target", "mouseover" }
	for i = 1, 40 do
		table.insert(unitsToScan, "nameplate" .. i)
	end

	for _, unit in ipairs(unitsToScan) do
		if UnitExists(unit) and UnitIsPlayer(unit) then
			local name = UnitName(unit)
			if name then
				local guid, lvl, localizedClass, cFile, localizedRace, fac =
					UnitGUID(unit),
					UnitLevel(unit),
					UnitClass(unit),
					select(2, UnitClass(unit)),
					UnitRace(unit),
					UnitFactionGroup(unit)
				if cFile then
					Ven.playerCache[name] = Ven.playerCache[name] or {}
					Ven.playerCache[name].classFile = cFile
					Ven.playerCache[name].class = localizedClass
					Ven.playerCache[name].race = localizedRace
					Ven.playerCache[name].faction = fac
					if lvl and lvl > 0 then
						Ven.playerCache[name].level = lvl
					end
					UpdateMissingDBInfo(name)
				else
					CachePlayerFromGUID(name, guid)
					if lvl and lvl > 0 then
						Ven.playerCache[name] = Ven.playerCache[name] or {}
						Ven.playerCache[name].level = lvl
						UpdateMissingDBInfo(name)
					end
				end

				if not UnitIsDeadOrGhost(unit) then
					local isPersWanted = type(db[name]) == "table" and db[name].isWanted
					local isPersBounty = type(db[name]) == "table" and db[name].isBounty
					local isNetBounty = db.enableNetwork and Ven.BountyBoard and Ven.BountyBoard[name]
					local isNetWanted = db.enableNetwork and Ven.WantedBoard and Ven.WantedBoard[name]

					local playedSpotSound = false

					if scanWanteds and (not isSafeZone or db.trackInSafeZones) then
						if isPersWanted or isPersBounty or isNetWanted then
							local t = GetTime()
							local timeSinceLastSeen = t - (Ven.wantedLastSeen[name] or 0)
							Ven.wantedLastSeen[name] = t

							Ven.hasAlertedFor = Ven.hasAlertedFor or {}
							if timeSinceLastSeen > 15 then
								Ven.hasAlertedFor[name] = false
							end

							if isPersWanted or isPersBounty then
								Ven.lastSeenDBWrite = Ven.lastSeenDBWrite or {}
								if timeSinceLastSeen > 15 or (t - (Ven.lastSeenDBWrite[name] or 0) > 60) then
									local zText, mText = GetZoneText() or "", GetMinimapZoneText() or ""
									local pureZone = zText
									if mText ~= "" and mText ~= zText then
										pureZone = pureZone .. " - " .. mText
									end
									local layer = Ven.GetCurrentLayer()
									local locStr = pureZone
									if layer ~= "" then
										locStr = locStr .. " (Layer " .. layer .. ")"
									end
									db[name].lastSeenLoc = locStr
									db[name].lastSeenTime = time()
									Ven.lastSeenDBWrite[name] = t
								end
							end

							if not Ven.hasAlertedFor[name] then
								Ven.hasAlertedFor[name] = true
								Ven.wantedOffset = 0
								Ven.isTrackerHidden = false
								db.isTrackerHidden = false
								if Ven.TrackerFrame and not Ven.TrackerFrame:IsShown() then
									Ven.TrackerFrame:Show()
								end

								if isPersWanted then
									local wIdx = db.wantedSoundIdx or 3
									if Ven.soundList and Ven.soundList[wIdx] then
										Ven.AlertPlaySound(Ven.soundList[wIdx].id, db.wantedForceBG)
									end
									RaidNotice_AddMessage(
										RaidWarningFrame,
										"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:24|t |cFFFF0000WANTED SPOTTED: "
											.. name
											.. "|r |TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:24|t",
										ChatTypeInfo["RAID_WARNING"]
									)
								elseif isPersBounty then
									local bIdx = db.bountySpottedSoundIdx or 4
									if Ven.soundList and Ven.soundList[bIdx] then
										Ven.AlertPlaySound(Ven.soundList[bIdx].id, db.bountySpottedForceBG)
									end
									RaidNotice_AddMessage(
										RaidWarningFrame,
										"|TInterface\\Icons\\INV_Misc_Coin_02:24|t |cFFFFAA00YOUR BOUNTY SPOTTED: "
											.. name
											.. "|r |TInterface\\Icons\\INV_Misc_Coin_02:24|t",
										ChatTypeInfo["RAID_WARNING"]
									)
								elseif isNetWanted then
									local wIdx = db.wantedSoundIdx or 3
									if Ven.soundList and Ven.soundList[wIdx] then
										Ven.AlertPlaySound(Ven.soundList[wIdx].id, db.wantedForceBG)
									end
									local ownerList = ""
									for o, _ in pairs(Ven.WantedBoard[name]) do
										if ownerList == "" then
											ownerList = o
										else
											ownerList = ownerList .. ", " .. o
										end
									end
									RaidNotice_AddMessage(
										RaidWarningFrame,
										"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:24|t |cFFFF0000SHARED WANTED SPOTTED: "
											.. name
											.. " (By: "
											.. ownerList
											.. ")|r |TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:24|t",
										ChatTypeInfo["RAID_WARNING"]
									)
								end
								playedSpotSound = true
							end
						end
					end

					if db.enableNetwork and not inInstance and UnitCanAttack("player", unit) then
						if isNetBounty or isNetWanted then
							local t = GetTime()
							local timeSinceLastBountySeen = t - (Ven.bountyLastSeen and Ven.bountyLastSeen[name] or 0)
							Ven.bountyLastSeen = Ven.bountyLastSeen or {}
							Ven.bountyLastSeen[name] = t

							Ven.hasBountyAlertedFor = Ven.hasBountyAlertedFor or {}
							if timeSinceLastBountySeen > 15 then
								Ven.hasBountyAlertedFor[name] = false
							end

							if isNetBounty and db.huntMode then
								if not Ven.hasBountyAlertedFor[name] then
									Ven.hasBountyAlertedFor[name] = true
									Ven.wantedOffset = 0
									Ven.isTrackerHidden = false
									db.isTrackerHidden = false
									if Ven.TrackerFrame and not Ven.TrackerFrame:IsShown() then
										Ven.TrackerFrame:Show()
									end

									if not playedSpotSound then
										local bIdx = db.bountySpottedSoundIdx or 4
										if Ven.soundList and Ven.soundList[bIdx] then
											Ven.AlertPlaySound(Ven.soundList[bIdx].id, db.bountySpottedForceBG)
										end
									end
									local ownerList = ""
									for o, _ in pairs(Ven.BountyBoard[name]) do
										if ownerList == "" then
											ownerList = o
										else
											ownerList = ownerList .. ", " .. o
										end
									end
									RaidNotice_AddMessage(
										RaidWarningFrame,
										"|TInterface\\Icons\\Ability_Hunter_SniperShot:24|t |cFF00FFFFNETWORK BOUNTY SPOTTED: "
											.. name
											.. " (By: "
											.. ownerList
											.. ")|r |TInterface\\Icons\\Ability_Hunter_SniperShot:24|t",
										ChatTypeInfo["RAID_WARNING"]
									)
								end
							end

							Ven.bountyBroadcastCD = Ven.bountyBroadcastCD or {}
							Ven.lastWhisperedZone = Ven.lastWhisperedZone or {}
							local zText = GetZoneText() or ""
							local mText = GetMinimapZoneText() or ""
							local pureZone = zText
							if mText ~= "" and mText ~= zText then
								pureZone = pureZone .. " - " .. mText
							end
							local layer = Ven.GetCurrentLayer()
							local locStr = pureZone
							if layer ~= "" then
								locStr = locStr .. " (Layer " .. layer .. ")"
							end

							local lastZone = Ven.lastWhisperedZone[name] or ""
							local timeSinceBroadcast = t - (Ven.bountyBroadcastCD[name] or 0)

							if timeSinceBroadcast > 300 or pureZone ~= lastZone then
								Ven.bountyBroadcastCD[name] = t
								Ven.lastWhisperedZone[name] = pureZone

								if Ven.Broadcast then
									Ven.Broadcast("SEEN", name, zText, mText, Ven.GetCurrentLayer())
								end

								Ven.lastAutoWhisper = Ven.lastAutoWhisper or 0
								if t - Ven.lastAutoWhisper > 15 then
									local wCount = 0
									local _, myClass = UnitClass("player")
									local function NotifyOwners(board)
										if not board then
											return
										end
										for owner, _ in pairs(board) do
											if wCount < 2 then
												local msg = "VEN_SYS_MSG~SEEN_WHISPER~"
													.. name
													.. "~"
													.. locStr
													.. "~"
													.. tostring(myClass)
												Ven.recentSystemWhispers = Ven.recentSystemWhispers or {}
												Ven.recentSystemWhispers[string.lower(owner)] = GetTime()
												SendChatMessage(msg, "WHISPER", nil, owner)
												wCount = wCount + 1
											end
										end
									end
									NotifyOwners(Ven.BountyBoard and Ven.BountyBoard[name])
									NotifyOwners(Ven.WantedBoard and Ven.WantedBoard[name])
									if wCount > 0 then
										Ven.lastAutoWhisper = t
									end
								end
							end
						end
					end
				end

				if
					UnitIsUnit(unit .. "target", "player")
					and not UnitIsUnit(unit, "player")
					and not UnitIsDeadOrGhost(unit)
				then
					if not isSafeZone or db.trackInSafeZones then
						local isAlly = not UnitCanAttack("player", unit)
						local allowedToScan = false
						if isAlly then
							if scanAllies then
								local inGroup = UnitInParty(unit) or UnitInRaid(unit)
								if db.trackGroupMembers or not inGroup then
									allowedToScan = true
								end
							end
						else
							if scanEnemies then
								allowedToScan = true
							end
						end
						if allowedToScan then
							local pc = Ven.playerCache[name] or {}
							foundThisTick[name] = {
								level = pc.level or lvl,
								class = pc.class,
								classFile = pc.classFile,
								race = pc.race,
								faction = pc.faction,
								isAlly = isAlly,
							}
						end
					end
				end
			end
		end
	end

	for name, data in pairs(foundThisTick) do
		if not Ven.activeTargets[name] then
			if data.isAlly then
				local fIdx = db.friendlySoundIdx or 14
				if Ven.soundList and Ven.soundList[fIdx] then
					Ven.AlertPlaySound(Ven.soundList[fIdx].id, db.friendlyForceBG)
				end
				RaidNotice_AddMessage(
					RaidWarningFrame,
					"|cff00ff00[!] " .. name .. " (Ally) IS TARGETING YOU! [!]|r",
					ChatTypeInfo["RAID_WARNING"]
				)
			else
				local tIdx = db.targetSoundIdx or 2
				if Ven.soundList and Ven.soundList[tIdx] then
					Ven.AlertPlaySound(Ven.soundList[tIdx].id, db.targetForceBG)
				end
				RaidNotice_AddMessage(
					RaidWarningFrame,
					"|cffff0000[!] " .. name .. " IS TARGETING YOU! [!]|r",
					ChatTypeInfo["RAID_WARNING"]
				)
			end
		end
		Ven.activeTargets[name] = data
		Ven.activeTargets[name].isTargetingMe = true
		Ven.activeTargets[name].lastSeen = GetTime()
	end
	for name, data in pairs(Ven.activeTargets) do
		if not foundThisTick[name] then
			data.isTargetingMe = false
		end
	end
	if Ven.UpdateTrackerUI then
		Ven.UpdateTrackerUI()
	end
end)
