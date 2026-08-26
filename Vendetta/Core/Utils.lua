local addonName, Ven = ...

Ven.soundList = {
	{ name = "Disabled", id = -1 },
	{ name = "Intruder Alert", id = 555503 },
	{ name = "Alarm Clock", id = 567399 },
	{ name = "PvP Warning", id = 567488 },
	{ name = "PvP Warning 2", id = 569250 },
	{ name = "PvP Alliance", id = 567505 },
	{ name = "PvP Horde", id = 567446 },
	{ name = "Raid Boss Warning", id = 567394 },
	{ name = "Raid Warning", id = 567397 },
	{ name = "Flag Captured Horde", id = 567423 },
	{ name = "Flag Taken", id = 569200 },
	{ name = "Fel Reaver Alarm", id = 10422 },
	{ name = "Error Buzz", id = 6495 },
	{ name = "Quest Failed", id = 878 },
	{ name = "Ready Check", id = 8960 },
	{ name = "Level Up", id = 888 },
}

function Ven.InitHeroDB()
	local rName, pName = GetRealmName() or "Unknown", UnitName("player") or "Unknown"
	VendettaDB[rName] = VendettaDB[rName] or {}
	VendettaDB[rName][pName] = VendettaDB[rName][pName] or {}
	return VendettaDB[rName][pName]
end

function Ven.GetLevelColor(level)
	if not level or level == "?" then
		return "|cFFFFFFFF"
	end
	if level == -1 then
		return "|cFFFF1A1A"
	end
	local color = GetQuestDifficultyColor(level)
	if color then
		return string.format("|cff%02x%02x%02x", color.r * 255, color.g * 255, color.b * 255)
	end
	return "|cFFFFFFFF"
end

function Ven.GetClassColor(classFile)
	if classFile and RAID_CLASS_COLORS[classFile] then
		local c = RAID_CLASS_COLORS[classFile]
		return string.format("|cff%02x%02x%02x", c.r * 255, c.g * 255, c.b * 255)
	end
	return "|cFFFFFFFF"
end

local classCoords = {
	["WARRIOR"] = { 0, 0.25, 0, 0.25 },
	["MAGE"] = { 0.25, 0.496, 0, 0.25 },
	["ROGUE"] = { 0.496, 0.742, 0, 0.25 },
	["DRUID"] = { 0.742, 0.988, 0, 0.25 },
	["HUNTER"] = { 0, 0.25, 0.25, 0.5 },
	["SHAMAN"] = { 0.25, 0.496, 0.25, 0.5 },
	["PRIEST"] = { 0.496, 0.742, 0.25, 0.5 },
	["WARLOCK"] = { 0.742, 0.988, 0.25, 0.5 },
	["PALADIN"] = { 0, 0.25, 0.5, 0.75 },
}

function Ven.GetClassIcon(classFile)
	if classFile and classCoords[classFile] then
		local c = classCoords[classFile]
		return string.format(
			"|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:16:16:0:0:256:256:%d:%d:%d:%d|t",
			c[1] * 256,
			c[2] * 256,
			c[3] * 256,
			c[4] * 256
		)
	end
	return ""
end

function Ven.StyleFlatButton(btn)
	btn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
	btn:SetBackdropColor(0.15, 0.15, 0.15, 0.8)
	btn:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
	if not btn.flatText then
		btn.flatText = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		btn.flatText:SetPoint("CENTER", 0, 0)
		btn:SetFontString(btn.flatText)
	end
	btn:HookScript("OnEnter", function(self)
		self:SetBackdropColor(0.25, 0.25, 0.25, 0.9)
	end)
	btn:HookScript("OnLeave", function(self)
		self:SetBackdropColor(0.15, 0.15, 0.15, 0.8)
	end)
end

function Ven.GetFactionIcon(faction)
	if faction == "Alliance" then
		return "|TInterface\\Icons\\INV_BannerPVP_02:14:14|t "
	elseif faction == "Horde" then
		return "|TInterface\\Icons\\INV_BannerPVP_01:14:14|t "
	end
	return ""
end

local popup = CreateFrame("Frame", "VendettaCustomPopup", UIParent, "BackdropTemplate")
popup:SetSize(350, 130)
popup:SetPoint("CENTER", 0, 100)
popup:SetFrameStrata("TOOLTIP")
popup:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
popup:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
popup:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
popup:Hide()
popup.text = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
popup.text:SetPoint("TOP", 0, -20)
popup.text:SetWidth(330)

popup.editBox = CreateFrame("EditBox", nil, popup, "BackdropTemplate")
popup.editBox:SetSize(200, 24)
popup.editBox:SetPoint("CENTER", 0, 5)
popup.editBox:SetFontObject("GameFontHighlight")
popup.editBox:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
popup.editBox:SetBackdropColor(0, 0, 0, 0.8)
popup.editBox:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
popup.editBox:SetTextInsets(6, 6, 0, 0)
popup.editBox:SetAutoFocus(false)

popup.btn1 = CreateFrame("Button", nil, popup, "BackdropTemplate")
popup.btn1:SetSize(100, 24)
popup.btn1:SetPoint("BOTTOMLEFT", 60, 15)
Ven.StyleFlatButton(popup.btn1)
popup.btn2 = CreateFrame("Button", nil, popup, "BackdropTemplate")
popup.btn2:SetSize(100, 24)
popup.btn2:SetPoint("BOTTOMRIGHT", -60, 15)
Ven.StyleFlatButton(popup.btn2)

function Ven.ShowPopup(cfg, data)
	popup.cfg = cfg
	popup.data = data
	popup.text:SetText(string.format(cfg.text, data or ""))
	popup.btn1:SetText(cfg.button1 or "Yes")
	popup.btn2:SetText(cfg.button2 or "No")

	if cfg.hasEditBox then
		popup.editBox:Show()
		popup.editBox:SetText("")
		if cfg.maxLetters then
			popup.editBox:SetMaxLetters(cfg.maxLetters)
		else
			popup.editBox:SetMaxLetters(255)
		end
		if cfg.OnShow then
			cfg.OnShow(popup, data)
		end
		popup.btn1:SetPoint("BOTTOMLEFT", 60, 15)
		popup.btn2:SetPoint("BOTTOMRIGHT", -60, 15)
	else
		popup.editBox:Hide()
		popup.btn1:SetPoint("BOTTOMLEFT", 60, 25)
		popup.btn2:SetPoint("BOTTOMRIGHT", -60, 25)
	end
	popup:Show()

	if cfg.hasEditBox then
		popup.editBox:SetFocus()
		C_Timer.After(0.01, function()
			local t = popup.editBox:GetText() or ""
			popup.editBox:SetCursorPosition(string.len(t))
		end)
	end
end

popup.btn1:SetScript("OnClick", function()
	local val = popup.editBox:IsShown() and popup.editBox:GetText() or nil
	if popup.cfg and popup.cfg.OnAccept then
		popup.cfg.OnAccept(popup, popup.data, val)
	end
	popup:Hide()
end)
popup.btn2:SetScript("OnClick", function()
	if popup.cfg and popup.cfg.OnCancel then
		popup.cfg.OnCancel(popup, popup.data)
	end
	popup:Hide()
end)
popup.editBox:SetScript("OnEscapePressed", function(self)
	popup:Hide()
end)
popup.editBox:SetScript("OnEnterPressed", function(self)
	popup.btn1:Click()
end)

function Ven.GetEffectiveTrackerMode()
	local db = Ven.InitHeroDB()
	local inInstance, instanceType = IsInInstance()
	if inInstance and (instanceType == "pvp" or instanceType == "arena") then
		return db.trackerModeInst or 1
	end
	return db.trackerModeWorld or 1
end

function Ven.ShouldIgnoreCombat()
	local inInstance, instanceType = IsInInstance()
	if inInstance and (instanceType == "party" or instanceType == "raid" or instanceType == "scenario") then
		return true
	end
	local db = Ven.InitHeroDB()
	if db.ignoreInstKills and inInstance and (instanceType == "pvp" or instanceType == "arena") then
		return true
	end
	return false
end

local muteRestoreTimer
function Ven.AlertPlaySound(soundId, isForced)
	if not soundId or soundId == -1 then
		return
	end
	local function Play(id, chan)
		if type(id) == "number" and id > 100000 then
			PlaySoundFile(id, chan)
		else
			PlaySound(id, chan)
		end
	end
	if isForced then
		local masterMuted, bgMuted =
			GetCVar("Sound_EnableAllSound") == "0", GetCVar("Sound_EnableSoundWhenGameIsInBG") == "0"
		if masterMuted then
			SetCVar("Sound_EnableAllSound", 1)
		end
		if bgMuted then
			SetCVar("Sound_EnableSoundWhenGameIsInBG", 1)
		end
		Play(soundId, "Master")
		if masterMuted or bgMuted then
			if muteRestoreTimer then
				muteRestoreTimer:Cancel()
			end
			muteRestoreTimer = C_Timer.NewTimer(3.5, function()
				if masterMuted then
					SetCVar("Sound_EnableAllSound", 0)
				end
				if bgMuted then
					SetCVar("Sound_EnableSoundWhenGameIsInBG", 0)
				end
			end)
		end
	else
		Play(soundId, "SFX")
	end
end

function Ven.SyncPlayerDataFromOtherHeroes(playerName)
	local rName = GetRealmName() or "Unknown"
	if VendettaDB[rName] then
		for hero, enemies in pairs(VendettaDB[rName]) do
			if
				type(enemies) == "table"
				and enemies[playerName]
				and type(enemies[playerName]) == "table"
				and enemies[playerName].classFile
			then
				return {
					level = enemies[playerName].level,
					class = enemies[playerName].class,
					classFile = enemies[playerName].classFile,
					race = enemies[playerName].race,
					faction = enemies[playerName].faction,
				}
			end
		end
	end
	return nil
end

function Ven.GetCurrentLayer()
	if NWB_CurrentLayer and tostring(NWB_CurrentLayer) ~= "0" and tostring(NWB_CurrentLayer) ~= "" then
		return tostring(NWB_CurrentLayer)
	end
	return ""
end

function Ven.GetServerOffset()
	local sH, sM = GetGameTime()
	local d = date("*t")
	local diffMins = (sH * 60 + sM) - (d.hour * 60 + d.min)
	if diffMins < -720 then
		diffMins = diffMins + 1440
	elseif diffMins > 720 then
		diffMins = diffMins - 1440
	end
	return diffMins * 60
end

function Ven.ParseOldTime(t)
	if type(t) == "number" then
		return t
	end
	if type(t) ~= "string" or t == "" then
		return 0
	end
	local y, m, d, h, min, s = string.match(t, "(%d+)/(%d+)/(%d+)%s+(%d+):(%d+):?(%d*)")
	if y then
		s = (s ~= "" and s) or "00"
		return time({ year = y, month = m, day = d, hour = h, min = min, sec = s })
	end
	return 0
end

function Ven.FormatTimeStr(ts, formatType)
	ts = Ven.ParseOldTime(ts)
	if not ts or ts == 0 then
		return "1900/01/01"
	end
	local db = Ven.InitHeroDB()
	local isServerTime = (db.useServerTime ~= false)
	local offset = isServerTime and Ven.GetServerOffset() or 0
	local adjustedTs, nowAdjusted = ts + offset, time() + offset
	local isToday = date("%Y/%m/%d", adjustedTs) == date("%Y/%m/%d", nowAdjusted)
	local suffix = isServerTime and " ST" or " LT"

	if formatType == "relative" then
		if (time() - ts) < 60 then
			return ""
		end
		if isToday then
			return " at " .. date("%H:%M", adjustedTs) .. suffix
		else
			return " on " .. date("%Y/%m/%d %H:%M", adjustedTs) .. suffix
		end
	end
	if isToday then
		return date("%H:%M", adjustedTs) .. suffix
	else
		return date("%Y/%m/%d %H:%M", adjustedTs) .. suffix
	end
end

function Ven.ShowPlayerTooltip(ownerFrame, playerName)
	if not ownerFrame or not playerName then
		return
	end
	GameTooltip:SetOwner(ownerFrame, "ANCHOR_RIGHT")
	GameTooltip:ClearLines()

	local rName = GetRealmName() or "Unknown"
	local dLevel, dRace, dClass, eClass = "?", "?", "?", nil
	local note, bNote = "", ""
	local totalKills, totalDeaths = 0, 0
	local isW, wSince, isB, bSince = false, 0, false, 0
	local lLoc, lTime = nil, 0
	local altHistory, hasHistory = {}, false

	if VendettaDB[rName] then
		for hero, rData in pairs(VendettaDB[rName]) do
			if type(rData) == "table" and rData[playerName] then
				local pData = rData[playerName]
				if pData.classFile then
					eClass = pData.classFile
				end
				if pData.race and pData.race ~= "?" then
					dRace = pData.race
				end
				if pData.class and pData.class ~= "?" then
					dClass = pData.class
				end
				if pData.level and pData.level ~= "?" then
					dLevel = pData.level
				end
				if pData.note and pData.note ~= "" then
					note = pData.note
				end
				if pData.bountyNote and pData.bountyNote ~= "" then
					bNote = pData.bountyNote
				end

				totalKills = totalKills + (pData.kills or 0)
				totalDeaths = totalDeaths + (pData.deaths or 0)
				if pData.isWanted then
					isW = true
					wSince = pData.wantedSince or time()
				end
				if pData.isBounty then
					isB = true
					bSince = pData.bountySince or time()
				end
				if pData.lastSeenLoc then
					lLoc = pData.lastSeenLoc
					lTime = pData.lastSeenTime or 0
				end
				if pData.lastKillTime or pData.lastDeathTime then
					hasHistory = true
					table.insert(altHistory, { hero = hero, lk = pData.lastKillTime, ld = pData.lastDeathTime })
				end
			end
		end
	end

	local pc = Ven.playerCache[playerName]
	if pc then
		if not eClass and pc.classFile then
			eClass = pc.classFile
		end
		if dRace == "?" and pc.race then
			dRace = pc.race
		end
		if dClass == "?" and pc.class then
			dClass = pc.class
		end
		if dLevel == "?" and pc.level then
			dLevel = pc.level
		end
	end

	local cColor = Ven.GetClassColor(eClass)
	local levelText = Ven.GetLevelColor(dLevel) .. (dLevel == -1 and "Boss/??" or dLevel) .. "|r"

	GameTooltip:AddLine(cColor .. playerName .. "|r")
	GameTooltip:AddLine("Level " .. levelText .. " " .. dRace .. " " .. dClass, 0.8, 0.8, 0.8)
	GameTooltip:AddLine("Combat History: [|cFF00FF00" .. totalKills .. "|r-|cFFFF1A1A" .. totalDeaths .. "|r]")
	GameTooltip:AddLine(" ")

	local hasNoteDisplayed = false
	if note ~= "" then
		GameTooltip:AddLine("Personal Note: |cFF00FFFF" .. note .. "|r", 1, 1, 1, true)
		hasNoteDisplayed = true
	end
	if isW then
		GameTooltip:AddLine("Wanted Since: |cFFFF0000" .. Ven.FormatTimeStr(wSince) .. "|r", 1, 1, 1)
		hasNoteDisplayed = true
	end
	if isB then
		GameTooltip:AddLine("Bounty Placed: |cFFFFAA00" .. Ven.FormatTimeStr(bSince) .. "|r", 1, 1, 1)
		if bNote ~= "" then
			GameTooltip:AddLine("Bounty Note: |cFFFFAA00" .. bNote .. "|r", 1, 1, 1, true)
		end
		hasNoteDisplayed = true
	end
	if hasNoteDisplayed then
		GameTooltip:AddLine(" ")
	end

	local db = Ven.InitHeroDB()
	if db.enableNetwork then
		Ven.SenderClasses = Ven.SenderClasses or {}
		local netWanteds = {}
		if Ven.WantedBoard and Ven.WantedBoard[playerName] then
			for owner, data in pairs(Ven.WantedBoard[playerName]) do
				table.insert(netWanteds, { name = owner, note = data.note })
			end
			table.sort(netWanteds, function(a, b)
				return a.name < b.name
			end)
		end
		if #netWanteds > 0 then
			GameTooltip:AddLine("Wanted By:", 1, 1, 1)
			for i = 1, math.min(3, #netWanteds) do
				local oName = netWanteds[i].name
				local oNote = netWanteds[i].note
				local oColor = Ven.GetClassColor(Ven.SenderClasses[oName]) or "|cFF00FFFF"
				local txt = " - " .. oColor .. oName .. "|r"
				if oNote and oNote ~= "" then
					txt = txt .. " (|cFF00FFFF" .. oNote .. "|r)"
				end
				GameTooltip:AddLine(txt, 1, 1, 1)
			end
			if #netWanteds > 3 then
				GameTooltip:AddLine("   (+ " .. (#netWanteds - 3) .. " others)", 0.5, 0.5, 0.5)
			end
			GameTooltip:AddLine(" ")
		end

		local netBounties = {}
		if Ven.BountyBoard and Ven.BountyBoard[playerName] then
			for owner, data in pairs(Ven.BountyBoard[playerName]) do
				table.insert(netBounties, { name = owner, note = data.note })
			end
			table.sort(netBounties, function(a, b)
				return a.name < b.name
			end)
		end
		if #netBounties > 0 then
			GameTooltip:AddLine("Bounty Placed By:", 1, 1, 1)
			for i = 1, math.min(3, #netBounties) do
				local oName = netBounties[i].name
				local oNote = netBounties[i].note
				local oColor = Ven.GetClassColor(Ven.SenderClasses[oName]) or "|cFF00FFFF"
				local txt = " - " .. oColor .. oName .. "|r"
				if oNote and oNote ~= "" then
					txt = txt .. " (|cFFFFAA00" .. oNote .. "|r)"
				end
				GameTooltip:AddLine(txt, 1, 1, 1)
			end
			if #netBounties > 3 then
				GameTooltip:AddLine("   (+ " .. (#netBounties - 3) .. " others)", 0.5, 0.5, 0.5)
			end
			GameTooltip:AddLine(" ")
		end
	end

	if lLoc then
		GameTooltip:AddLine(
			"Last Seen: |cFFFFFF00" .. Ven.FormatTimeStr(lTime) .. "|r - |cFF00FFFF" .. lLoc .. "|r",
			1,
			1,
			1
		)
		GameTooltip:AddLine(" ")
	end

	if hasHistory then
		for _, hist in ipairs(altHistory) do
			local hColor = VendettaDB["MyHeroes"]
					and VendettaDB["MyHeroes"][hist.hero]
					and Ven.GetClassColor(VendettaDB["MyHeroes"][hist.hero])
				or "|cFFFFFFFF"
			if hist.lk then
				GameTooltip:AddLine(
					"Last kill by " .. hColor .. hist.hero .. "|r : " .. Ven.FormatTimeStr(hist.lk),
					1,
					1,
					1
				)
			end
			if hist.ld then
				GameTooltip:AddLine(
					"Last killed " .. hColor .. hist.hero .. "|r : " .. Ven.FormatTimeStr(hist.ld),
					1,
					1,
					1
				)
			end
		end
	else
		GameTooltip:AddLine("No combat history found.", 0.5, 0.5, 0.5)
	end
	GameTooltip:Show()
end
