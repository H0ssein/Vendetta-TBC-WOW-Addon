local addonName, Ven = ...

Ven.soundList = {
	{ name = "Disabled", id = -1 },
	{ name = "Intruder Alert", id = 555503 },
	{ name = "Alarm Clock", id = 567399 },
	{ name = "Game Tick", id = 568232 },
	{ name = "Bell", id = 567542 },
	{ name = "Bell2", id = 567551 },
	{ name = "Click", id = 567455 },
	{ name = "Click2", id = 4906953 },
	{ name = "Click3", id = 4906955 },
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

function Ven.GetCircularClassIcon(classFile)
	if classFile and classCoords[classFile] then
		local c = classCoords[classFile]
		return string.format(
			"|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:18:18:0:0:256:256:%d:%d:%d:%d|t",
			c[1] * 256 + 6,
			c[2] * 256 - 6,
			c[3] * 256 + 6,
			c[4] * 256 - 6
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
popup:EnableKeyboard(true)
popup:SetPropagateKeyboardInput(true)
popup:Hide()

popup:SetScript("OnKeyDown", function(self, key)
	if key == "ESCAPE" then
		self:SetPropagateKeyboardInput(false)
		if self.cfg and self.cfg.OnCancel then
			self.cfg.OnCancel(self, self.data)
		end
		Ven.HidePopup()
	else
		self:SetPropagateKeyboardInput(true)
	end
end)
popup.titleFrame = CreateFrame("Frame", nil, popup)
popup.titleFrame:SetHeight(20)
popup.titleFrame:SetPoint("TOP", 0, -20)

popup.textPrefix = popup.titleFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
popup.textPrefix:SetPoint("LEFT", popup.titleFrame, "LEFT", 0, 0)

popup.classIcon = popup.titleFrame:CreateTexture(nil, "OVERLAY", nil, 1)
popup.classIcon:SetSize(18, 18)

popup.factionIcon = popup.titleFrame:CreateTexture(nil, "OVERLAY", nil, 2)
popup.factionIcon:SetSize(12, 12)
popup.factionIcon:SetPoint("BOTTOMRIGHT", popup.classIcon, "BOTTOMRIGHT", 4, -4)

popup.textName = popup.titleFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")

popup.textDesc = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
popup.textDesc:SetPoint("TOP", popup.titleFrame, "BOTTOM", 0, -5)
popup.textDesc:SetWidth(330)

function Ven.SetPopupTitle(prefix, classFile, faction, nameStr, desc)
	popup.textPrefix:SetText(prefix or "")
	popup.textName:SetText(nameStr or "")
	popup.textDesc:SetText(desc or "")
	
	local totalWidth = popup.textPrefix:GetStringWidth()
	
	if classFile and classCoords[classFile] then
		local c = classCoords[classFile]
		popup.classIcon:SetTexture("Interface\\TargetingFrame\\UI-Classes-Circles")
		popup.classIcon:SetTexCoord(c[1], c[2], c[3], c[4])
		popup.classIcon:SetPoint("LEFT", popup.textPrefix, "RIGHT", 4, 0)
		popup.classIcon:Show()
		
		totalWidth = totalWidth + 18 + 4
		
		if faction == "Alliance" then
			popup.factionIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-Alliance")
			popup.factionIcon:SetTexCoord(0, 0.625, 0, 0.625)
			popup.factionIcon:Show()
		elseif faction == "Horde" then
			popup.factionIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-Horde")
			popup.factionIcon:SetTexCoord(0, 0.625, 0, 0.625)
			popup.factionIcon:Show()
		else
			popup.factionIcon:Hide()
		end
		
		popup.textName:SetPoint("LEFT", popup.classIcon, "RIGHT", 4, 0)
		totalWidth = totalWidth + 4
	else
		popup.classIcon:Hide()
		popup.factionIcon:Hide()
		popup.textName:SetPoint("LEFT", popup.textPrefix, "RIGHT", 0, 0)
	end
	
	totalWidth = totalWidth + popup.textName:GetStringWidth()
	popup.titleFrame:SetWidth(totalWidth)
end

popup.editBox = CreateFrame("EditBox", nil, popup, "BackdropTemplate")
popup.editBox:SetSize(240, 24)
popup.editBox:SetPoint("CENTER", 0, 5)
popup.editBox:SetFontObject("GameFontHighlight")
popup.editBox:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
popup.editBox:SetBackdropColor(0.05, 0.05, 0.05, 0.9)
popup.editBox:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
popup.editBox:SetTextInsets(8, 8, 0, 0)
popup.editBox:SetAutoFocus(false)

popup.editBox.placeholder = popup.editBox:CreateFontString(nil, "OVERLAY", "GameFontDisable")
popup.editBox.placeholder:SetPoint("LEFT", popup.editBox, "LEFT", 8, 0)

popup.editBox:SetScript("OnTextChanged", function(self)
	if self:GetText() == "" then
		self.placeholder:Show()
	else
		self.placeholder:Hide()
	end
end)

popup.editBox:SetScript("OnEscapePressed", function(self)
	self:ClearFocus()
end)

popup.btn1 = CreateFrame("Button", nil, popup, "BackdropTemplate")
popup.btn1:SetSize(90, 24)
popup.btn1:SetPoint("BOTTOMLEFT", 75, 15)
Ven.StyleFlatButton(popup.btn1)
popup.btn2 = CreateFrame("Button", nil, popup, "BackdropTemplate")
popup.btn2:SetSize(90, 24)
popup.btn2:SetPoint("BOTTOMRIGHT", -75, 15)
Ven.StyleFlatButton(popup.btn2)

function Ven.ShowPopup(cfg, data)
	popup.cfg = cfg
	popup.data = data
	popup.btn1:SetText(cfg.button1 or "Yes")
	popup.btn2:SetText(cfg.button2 or "No")

	if GameTooltip:IsShown() then
		GameTooltip:Hide()
	end

	if cfg.hasEditBox then
		popup:SetHeight(110)
		popup.editBox:Show()
		popup.editBox:SetPoint("CENTER", 0, -5)
		popup.editBox:SetText("")
		if cfg.placeholder then
			popup.editBox.placeholder:SetText(cfg.placeholder)
			popup.editBox.placeholder:Show()
		else
			popup.editBox.placeholder:Hide()
		end
		if cfg.maxLetters then
			popup.editBox:SetMaxLetters(cfg.maxLetters)
		else
			popup.editBox:SetMaxLetters(255)
		end
		popup.btn1:SetPoint("BOTTOMLEFT", 75, 15)
		popup.btn2:SetPoint("BOTTOMRIGHT", -75, 15)
	else
		popup:SetHeight(90)
		popup.editBox:Hide()
		popup.btn1:SetPoint("BOTTOMLEFT", 75, 15)
		popup.btn2:SetPoint("BOTTOMRIGHT", -75, 15)
	end
	
	if cfg.OnShow then
		cfg.OnShow(popup, data)
	end
	
	if cfg.hasEditBox and cfg.placeholder then
		if popup.editBox:GetText() == "" then
			popup.editBox.placeholder:Show()
		else
			popup.editBox.placeholder:Hide()
		end
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
	Ven.HidePopup()
end)
function Ven.HidePopup()
	popup:Hide()
end
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

function Ven.ShouldIgnoreKills()
	local inInstance, instanceType = IsInInstance()
	if inInstance and (instanceType == "party" or instanceType == "raid" or instanceType == "scenario") then
		return true
	end
	local db = Ven.InitHeroDB()
	if inInstance then
		if instanceType == "pvp" and db.ignoreBGKills then return true end
		if instanceType == "arena" and db.ignoreArenaKills then return true end
	end
	return false
end

local muteRestoreTimer
function Ven.AlertPlaySound(soundId, isForced, instPlay)
	if not soundId or soundId == -1 then
		return
	end
	local inInstance, instanceType = IsInInstance()
	if inInstance and (instanceType == "pvp" or instanceType == "arena") then
		if not instPlay then
			return
		end
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
					table.insert(altHistory, { hero = hero, lk = pData.lastKillTime, ld = pData.lastDeathTime, lkLoc = pData.lastKillLoc, ldLoc = pData.lastDeathLoc })
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
				local lkLocStr = ""
				if hist.lkLoc and hist.lkLoc ~= "" then
					local p = string.match(hist.lkLoc, "^([^%-%(]+)")
					if p then lkLocStr = " (|cFF00FFFF" .. p:gsub("%s+$", "") .. "|r)" end
				end
				GameTooltip:AddLine(
					"Last kill by " .. hColor .. hist.hero .. "|r : " .. Ven.FormatTimeStr(hist.lk) .. lkLocStr,
					1,
					1,
					1
				)
			end
			if hist.ld then
				local ldLocStr = ""
				if hist.ldLoc and hist.ldLoc ~= "" then
					local p = string.match(hist.ldLoc, "^([^%-%(]+)")
					if p then ldLocStr = " (|cFF00FFFF" .. p:gsub("%s+$", "") .. "|r)" end
				end
				GameTooltip:AddLine(
					"Last killed " .. hColor .. hist.hero .. "|r : " .. Ven.FormatTimeStr(hist.ld) .. ldLocStr,
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

function Ven.StyleScrollFrame(scrollFrame)
	local sBar = scrollFrame.ScrollBar or _G[scrollFrame:GetName() .. "ScrollBar"]
	if not sBar then
		if scrollFrame:GetObjectType() == "Slider" then
			sBar = scrollFrame
		else
			return
		end
	end
	
	local thumb = sBar:GetThumbTexture() or _G[sBar:GetName() .. "ThumbTexture"]
	for _, tex in pairs({sBar:GetRegions()}) do
		if tex:GetObjectType() == "Texture" and tex ~= thumb then
			tex:SetTexture(nil)
		end
	end
	
	local upBtn = sBar.ScrollUpButton or _G[sBar:GetName() .. "ScrollUpButton"]
	local downBtn = sBar.ScrollDownButton or _G[sBar:GetName() .. "ScrollDownButton"]
	
	local sBarBg = scrollFrame.ScrollBarBg
	if not sBarBg then
		sBar:ClearAllPoints()
		if scrollFrame:GetObjectType() == "ScrollFrame" then
			sBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 6, 0)
			sBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 6, 0)
		end
		
		if upBtn then
			upBtn:ClearAllPoints()
			upBtn:SetPoint("TOP", sBar, "TOP", 0, 0)
		end
		if downBtn then
			downBtn:ClearAllPoints()
			downBtn:SetPoint("BOTTOM", sBar, "BOTTOM", 0, 0)
		end
		
		sBarBg = CreateFrame("Frame", nil, scrollFrame, "BackdropTemplate")
		scrollFrame.ScrollBarBg = sBarBg
		sBarBg:SetFrameLevel(math.max(1, sBar:GetFrameLevel() - 1))
		sBarBg:SetPoint("TOPLEFT", sBar, "TOPLEFT", -1, 2)
		sBarBg:SetPoint("BOTTOMRIGHT", sBar, "BOTTOMRIGHT", 1, -2)
		sBarBg:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
		sBarBg:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
		sBarBg:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
	end
	
	if thumb then
		thumb:SetTexture("Interface\\Buttons\\WHITE8x8")
		thumb:SetVertexColor(0.7, 0.7, 0.7, 1)
		thumb:SetWidth(12)
	end
	
	if upBtn then
		upBtn:SetNormalTexture("")
		upBtn:SetPushedTexture("")
		upBtn:SetDisabledTexture("")
		if upBtn:GetNormalTexture() then upBtn:GetNormalTexture():SetAlpha(0) end
		if upBtn:GetPushedTexture() then upBtn:GetPushedTexture():SetAlpha(0) end
		if upBtn:GetDisabledTexture() then upBtn:GetDisabledTexture():SetAlpha(0) end
		
		upBtn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
		if not upBtn.txt then
			local t = upBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			t:SetPoint("CENTER", 0, 1)
			t:SetText("^")
			t:SetTextColor(0.8, 0.8, 0.8)
			upBtn.txt = t
		end
		
		upBtn:SetScript("OnClick", function()
			local minV, maxV = sBar:GetMinMaxValues()
			sBar:SetValue(minV)
		end)
	end
	
	if downBtn then
		downBtn:SetNormalTexture("")
		downBtn:SetPushedTexture("")
		downBtn:SetDisabledTexture("")
		if downBtn:GetNormalTexture() then downBtn:GetNormalTexture():SetAlpha(0) end
		if downBtn:GetPushedTexture() then downBtn:GetPushedTexture():SetAlpha(0) end
		if downBtn:GetDisabledTexture() then downBtn:GetDisabledTexture():SetAlpha(0) end
		
		downBtn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
		if not downBtn.txt then
			local t = downBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			t:SetPoint("CENTER", 0, 1)
			t:SetText("v")
			t:SetTextColor(0.8, 0.8, 0.8)
			downBtn.txt = t
		end
		
		downBtn:SetScript("OnClick", function()
			local minV, maxV = sBar:GetMinMaxValues()
			sBar:SetValue(maxV)
		end)
	end
	
	local function UpdateScrollState()
		local val, minV, maxV
		
		if scrollFrame.GetVerticalScrollRange then
			local yrange = math.floor(scrollFrame:GetVerticalScrollRange() or 0)
			val = math.floor(scrollFrame:GetVerticalScroll() or 0)
			minV, maxV = 0, yrange
		else
			val = sBar:GetValue()
			minV, maxV = sBar:GetMinMaxValues()
		end
		
		if maxV == 0 then
			sBar:SetAlpha(0)
			sBar:Hide()
			if scrollFrame.ScrollBarBg then scrollFrame.ScrollBarBg:Hide() end
			if upBtn then upBtn:Hide() end
			if downBtn then downBtn:Hide() end
			if thumb then thumb:Hide() end
		else
			sBar:SetAlpha(1)
			sBar:Show()
			if scrollFrame.ScrollBarBg then scrollFrame.ScrollBarBg:Show() end
			if upBtn then upBtn:Show() end
			if downBtn then downBtn:Show() end
			if thumb then thumb:Show() end
			
			if upBtn and upBtn.txt then
				if val <= minV then
					upBtn.txt:SetAlpha(0)
					upBtn:EnableMouse(false)
				else
					upBtn.txt:SetAlpha(1)
					upBtn:EnableMouse(true)
				end
			end
			
			if downBtn and downBtn.txt then
				if val >= maxV - 1 then
					downBtn.txt:SetAlpha(0)
					downBtn:EnableMouse(false)
				else
					downBtn.txt:SetAlpha(1)
					downBtn:EnableMouse(true)
				end
			end
		end
	end

	if scrollFrame:GetObjectType() == "ScrollFrame" then
		scrollFrame:HookScript("OnScrollRangeChanged", UpdateScrollState)
		scrollFrame:HookScript("OnVerticalScroll", UpdateScrollState)
		scrollFrame:HookScript("OnShow", UpdateScrollState)
		scrollFrame:HookScript("OnSizeChanged", UpdateScrollState)
	end
	sBar:HookScript("OnValueChanged", UpdateScrollState)
	sBar:HookScript("OnShow", UpdateScrollState)
	
	local function PassMouseWheel(self, delta)
		if scrollFrame:GetObjectType() == "ScrollFrame" then
			local func = scrollFrame:GetScript("OnMouseWheel")
			if func then
				func(scrollFrame, delta)
			end
		elseif scrollFrame:GetObjectType() == "Slider" then
			local minV, maxV = sBar:GetMinMaxValues()
			sBar:SetValue(math.min(math.max(sBar:GetValue() - (delta * 16), minV), maxV))
		end
	end
	
	sBar:EnableMouseWheel(true)
	sBar:SetScript("OnMouseWheel", PassMouseWheel)
	if sBarBg then
		sBarBg:EnableMouseWheel(true)
		sBarBg:SetScript("OnMouseWheel", PassMouseWheel)
	end
end
