local addonName, Ven = ...

Ven.TrackerFrame = CreateFrame("Frame", "VendettaMainFrame", UIParent, "BackdropTemplate")
local f = Ven.TrackerFrame
f:SetSize(370, 40)
f:SetPoint("CENTER", 0, 150)
f:SetMovable(true)
f:EnableMouse(true)
f:RegisterForDrag("LeftButton")
f:SetScript("OnDragStart", f.StartMoving)
f:SetScript("OnDragStop", f.StopMovingOrSizing)
f:SetResizable(true)
f:SetResizeBounds(150, 40, 800, 600)
f:Hide()

f:SetBackdrop({
	bgFile = "Interface\\Buttons\\WHITE8x8",
	edgeFile = "Interface\\Buttons\\WHITE8x8",
	edgeSize = 1,
	insets = { left = 1, right = 1, top = 1, bottom = 1 },
})
f:SetBackdropColor(0.05, 0.05, 0.05, 0.7)
f:SetBackdropBorderColor(0.2, 0.2, 0.2, 0.9)

f.title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
f.title:SetPoint("TOP", 0, -8)
f.title:SetText("|cFF880000V E N D E T T A|r")
f.title:SetShadowOffset(1, -1)
f.title:SetShadowColor(0, 0, 0, 1)

local resizeBtn = CreateFrame("Button", nil, f)
resizeBtn:SetSize(16, 16)
resizeBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
resizeBtn:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
resizeBtn:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
resizeBtn:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
resizeBtn:SetScript("OnMouseDown", function()
	f:StartSizing("BOTTOMRIGHT")
end)
resizeBtn:SetScript("OnMouseUp", function()
	f:StopMovingOrSizing()
	Ven.InitHeroDB().trackerWidth = f:GetWidth()
end)

local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
closeBtn:SetSize(22, 22)
closeBtn:SetScript("OnClick", function()
	Ven.isTrackerHidden = true
	Ven.InitHeroDB().isTrackerHidden = true
	f:Hide()
end)

local openListBtn = CreateFrame("Button", nil, f)
openListBtn:SetSize(18, 18)
openListBtn:SetPoint("RIGHT", closeBtn, "LEFT", -2, 0)
openListBtn:SetNormalTexture("Interface\\GossipFrame\\TabardGossipIcon")
openListBtn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
openListBtn:SetScript("OnClick", function()
	if Ven.DBFrame:IsShown() then
		Ven.DBFrame:Hide()
	else
		Ven.RefreshDBView()
		Ven.DBFrame:Show()
	end
end)
openListBtn:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:SetText("Open Vendetta List")
	GameTooltip:Show()
end)
openListBtn:SetScript("OnLeave", function(self)
	GameTooltip:Hide()
end)

local Ven_CombatBlocker = CreateFrame("Frame", nil, f)
Ven_CombatBlocker:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -25)
Ven_CombatBlocker:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
Ven_CombatBlocker:SetFrameLevel(99)
Ven_CombatBlocker:EnableMouse(true)
Ven_CombatBlocker:Hide()
Ven.CombatBlocker = Ven_CombatBlocker

local Ven_QuickCopy = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
Ven_QuickCopy:SetSize(320, 25)
Ven_QuickCopy:SetFrameStrata("DIALOG")
Ven_QuickCopy:Hide()
Ven_QuickCopy:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
Ven_QuickCopy:SetBackdropColor(0.05, 0.05, 0.05, 1)
Ven_QuickCopy:SetBackdropBorderColor(0.2, 0.8, 0.2, 1)
Ven.QuickCopy = Ven_QuickCopy

local Ven_EditBox = CreateFrame("EditBox", nil, Ven_QuickCopy)
Ven_EditBox:SetFontObject("ChatFontNormal")
Ven_EditBox:SetSize(280, 20)
Ven_EditBox:SetPoint("LEFT", Ven_QuickCopy, "LEFT", 10, 0)
Ven_EditBox:SetAutoFocus(true)
Ven_EditBox:SetScript("OnEscapePressed", function()
	Ven_QuickCopy:Hide()
end)
Ven_EditBox:SetScript("OnChar", function(self)
	self:SetText(self.linkToCopy or "")
	self:HighlightText()
end)

local qcCloseBtn = CreateFrame("Button", nil, Ven_QuickCopy, "UIPanelCloseButton")
qcCloseBtn:SetPoint("RIGHT", Ven_QuickCopy, "RIGHT", -2, 0)
qcCloseBtn:SetSize(24, 24)
qcCloseBtn:SetScript("OnClick", function()
	Ven_QuickCopy:Hide()
end)

function Ven.ShowCopyBox(text)
	if not text or not Ven.QuickCopy then
		return
	end
	Ven.QuickCopy:ClearAllPoints()
	Ven.QuickCopy:SetPoint("CENTER", UIParent, "CENTER", 0, 50)
	for _, child in ipairs({ Ven.QuickCopy:GetChildren() }) do
		if child:GetObjectType() == "EditBox" then
			child.linkToCopy = text
			child:SetText(text)
			child:SetFocus()
			child:HighlightText()
			break
		end
	end
	Ven.QuickCopy:Show()
end

local function RowOnEnter(self)
	local rowFrame = self.targetName and self or self:GetParent()
	if not rowFrame.targetName then
		return
	end
	Ven.ShowPlayerTooltip(rowFrame, rowFrame.targetName)
end

local rows = {}
f:SetScript("OnSizeChanged", function(self)
	local w = self:GetWidth()
	for i = 1, 8 do
		local r = rows[i]
		if r:IsShown() and r.targetName then
			local finalStr = ""
			if w >= 180 and r.lvlText and r.lvlText ~= "" then
				finalStr = finalStr .. "  " .. r.lvlText
			end
			if w >= 230 and r.historyText and r.historyText ~= "" then
				finalStr = finalStr .. "  " .. r.historyText
			end
			if w >= 290 and r.noteText and r.noteText ~= "" then
				finalStr = finalStr .. "  " .. r.noteText
			end
			if r.timerText and r.timerText ~= "" then
				finalStr = finalStr .. "  " .. r.timerText
			end
			r.extraText:SetText(finalStr)
		end
	end
end)

for i = 1, 8 do
	local row = CreateFrame("Frame", "VenRow" .. i, f)
	row:SetHeight(25)
	row:Hide()
	row.secureBtn = CreateFrame("Button", nil, row, "SecureActionButtonTemplate")
	row.secureBtn:SetAllPoints(row)
	row.secureBtn:RegisterForClicks("AnyUp")
	row.secureBtn:SetAttribute("type", "macro")
	row.secureBtn:SetScript("OnEnter", RowOnEnter)
	row.secureBtn:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	row.line = row:CreateTexture(nil, "BACKGROUND")
	row.line:SetPoint("BOTTOMLEFT")
	row.line:SetPoint("BOTTOMRIGHT")
	row.line:SetHeight(1)
	row.line:SetColorTexture(0.15, 0.15, 0.15, 0.4)

	row.dbBtn = CreateFrame("Button", nil, row)
	row.dbBtn:SetSize(14, 14)
	row.dbBtn:SetPoint("LEFT", 4, 0)
	row.dbBtn:SetNormalTexture("Interface\\Icons\\INV_Misc_Spyglass_02")
	row.dbBtn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
	row.dbBtn:SetScript("OnClick", function(self)
		local n = self:GetParent().targetName
		if not n then
			return
		end
		local db = Ven.InitHeroDB()
		if not db[n] then
			local s = Ven.playerCache[n] or Ven.SyncPlayerDataFromOtherHeroes(n) or {}
			db[n] = {
				kills = 0,
				deaths = 0,
				level = s.level or "?",
				class = s.class or "?",
				classFile = s.classFile,
				race = s.race or "?",
				faction = s.faction or "?",
				note = s.note or "",
				isWanted = false,
				isBounty = false,
				timeAdded = time(),
				lastCombat = 0,
			}
		end
		if Ven.DBFrame then
			if not Ven.DBFrame:IsShown() then
				Ven.DBFrame:Show()
			end
			if VendettaSearchBox then
				VendettaSearchBox:SetText(n)
			end
			if Ven.RefreshDBView then
				Ven.RefreshDBView()
			end
		end
	end)
	row.dbBtn:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText("Search / Add to Database")
		GameTooltip:Show()
	end)
	row.dbBtn:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	row.armoryBtn = CreateFrame("Button", nil, row)
	row.armoryBtn:SetSize(14, 14)
	row.armoryBtn:SetPoint("LEFT", row.dbBtn, "RIGHT", 4, 0)
	row.armoryBtn:SetNormalTexture("Interface\\Icons\\INV_Misc_Note_02")
	row.armoryBtn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
	row.armoryBtn:SetScript("OnClick", function(self)
		Ven.ShowCopyBox(self:GetParent().armoryLink)
	end)
	row.armoryBtn:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText("Copy Armory Link")
		GameTooltip:Show()
	end)
	row.armoryBtn:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	row.nameText:SetPoint("LEFT", 40, 0)
	row.nameText:SetShadowOffset(1, -1)
	row.nameText:SetShadowColor(0, 0, 0, 1)

	row.extraText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	row.extraText:SetPoint("LEFT", row.nameText, "RIGHT", 0, 0)
	row.extraText:SetPoint("RIGHT", row, "RIGHT", -5, 0)
	row.extraText:SetJustifyH("LEFT")
	row.extraText:SetWordWrap(false)
	row.extraText:SetShadowOffset(1, -1)
	row.extraText:SetShadowColor(0, 0, 0, 1)

	row:EnableMouseWheel(true)
	row:SetScript("OnMouseWheel", function(self, delta)
		if self.isWantedType then
			Ven.wantedOffset = math.max(0, Ven.wantedOffset - delta)
		else
			Ven.targetOffset = math.max(0, Ven.targetOffset - delta)
		end
		Ven.UpdateTrackerUI()
	end)
	rows[i] = row
end
Ven.TrackerRows = rows

function Ven.UpdateTrackerUI()
	local db = Ven.InitHeroDB()
	local inInstance, instanceType = IsInInstance()
	local isPvPInst = inInstance and (instanceType == "pvp" or instanceType == "arena")
	local isPvEInst = inInstance and (instanceType == "party" or instanceType == "raid" or instanceType == "scenario")

	if isPvEInst or Ven.isTrackerHidden then
		if not InCombatLockdown() then
			f:Hide()
		end
		return
	end
	if db.hideInCombat and InCombatLockdown() then
		return
	end

	local showWanteds = (not inInstance and db.trackWantedsWorld ~= false)
		or (isPvPInst and db.trackWantedsInst ~= false)
	local showEnemies = (not inInstance and db.trackTargetsWorld ~= false)
		or (isPvPInst and db.trackTargetsInst ~= false)
	local showAllies = (not inInstance and db.trackAlliesWorld == true) or (isPvPInst and db.trackAlliesInst == true)

	if
		not showWanteds
		and not showEnemies
		and not showAllies
		and not db.trackNetworkBounties
		and db.trackNetworkWanteds == false
	then
		if not InCombatLockdown() then
			f:Hide()
		end
		return
	end

	local currentTick = GetTime()
	for name, data in pairs(Ven.activeTargets) do
		if not data.isTargetingMe and (currentTick - data.lastSeen > 60) then
			Ven.activeTargets[name] = nil
		end
	end

	if InCombatLockdown() then
		for i = 1, 8 do
			local r = rows[i]
			if r:IsShown() and r.targetName and not r.isWantedType then
				local vData = Ven.activeTargets[r.targetName]
				if vData then
					local timeSinceSeen = currentTick - vData.lastSeen
					r.timerText = vData.isTargetingMe and "|cFF00FF00(Active)|r"
						or "|cFF888888(" .. math.floor(60 - timeSinceSeen) .. "s)|r"
				end
			end
		end
		f:GetScript("OnSizeChanged")(f)
		return
	end

	local wList, tList = {}, {}

	if showWanteds then
		for name, data in pairs(db) do
			if type(data) == "table" and (data.isWanted or data.isBounty) then
				local lSeen = Ven.wantedLastSeen[name] or 0
				if lSeen > 0 and (currentTick - lSeen) <= 60 then
					table.insert(
						wList,
						{ name = name, data = data, lastSeen = lSeen, isNetBounty = false, isNetWanted = false }
					)
				end
			end
		end
	end

	if db.trackNetworkBounties and Ven.BountyBoard then
		for name, owners in pairs(Ven.BountyBoard) do
			local lSeen = Ven.bountyLastSeen and Ven.bountyLastSeen[name] or 0
			if lSeen > 0 and (currentTick - lSeen) <= 60 then
				local alreadyInList = false
				for _, v in ipairs(wList) do
					if v.name == name then
						alreadyInList = true
						break
					end
				end

				if not alreadyInList then
					local pc = Ven.playerCache[name] or {}
					local fakeData = {
						classFile = pc.classFile,
						faction = pc.faction,
						level = pc.level,
						kills = 0,
						deaths = 0,
						note = "",
						isBounty = true,
					}
					table.insert(
						wList,
						{ name = name, data = fakeData, lastSeen = lSeen, isNetBounty = true, isNetWanted = false }
					)
				end
			end
		end
	end

	if (db.trackNetworkWanteds ~= false) and Ven.WantedBoard then
		for name, owners in pairs(Ven.WantedBoard) do
			local lSeen = Ven.wantedLastSeen and Ven.wantedLastSeen[name] or 0
			if lSeen > 0 and (currentTick - lSeen) <= 60 then
				local alreadyInList = false
				for _, v in ipairs(wList) do
					if v.name == name then
						alreadyInList = true
						break
					end
				end
				if not alreadyInList then
					local pc = Ven.playerCache[name] or {}
					local fakeData = {
						classFile = pc.classFile,
						faction = pc.faction,
						level = pc.level,
						kills = 0,
						deaths = 0,
						note = "",
						isWanted = true,
					}
					table.insert(
						wList,
						{ name = name, data = fakeData, lastSeen = lSeen, isNetBounty = false, isNetWanted = true }
					)
				end
			end
		end
	end

	table.sort(wList, function(a, b)
		return a.lastSeen > b.lastSeen
	end)

	for name, data in pairs(Ven.activeTargets) do
		local allowed = false
		if data.isAlly then
			if showAllies then
				local inGroup = UnitInParty(name) or UnitInRaid(name)
				if db.trackGroupMembers or not inGroup then
					allowed = true
				end
			end
		else
			if showEnemies then
				allowed = true
			end
		end
		if allowed then
			table.insert(tList, { name = name, data = data })
		end
	end
	table.sort(tList, function(a, b)
		return a.data.lastSeen > b.data.lastSeen
	end)

	Ven.wantedOffset = math.min(Ven.wantedOffset, math.max(0, #wList - 3))
	Ven.targetOffset = math.min(Ven.targetOffset, math.max(0, #tList - 5))

	for i = 1, 8 do
		rows[i]:Hide()
		if not InCombatLockdown() then
			rows[i].secureBtn:Hide()
		end
	end

	local rowIdx = 1
	for i = 1 + Ven.wantedOffset, math.min(#wList, 3 + Ven.wantedOffset) do
		local r, v = rows[rowIdx], wList[i]
		r.isWantedType = true
		r.targetName = v.name
		local cColor, cIcon = Ven.GetClassColor(v.data.classFile), Ven.GetClassIcon(v.data.classFile)

		r.nameText:SetText((Ven.GetFactionIcon(v.data.faction) or "") .. cIcon .. " " .. cColor .. v.name .. "|r")
		r.lvlText = Ven.GetLevelColor(v.data.level)
			.. ((v.data.level == -1) and "Boss/??" or (v.data.level or "?"))
			.. "|r"
		r.historyText = (v.isNetBounty or v.isNetWanted) and ""
			or "[|cFF00FF00" .. (v.data.kills or 0) .. "|r-|cFFFF1A1A" .. (v.data.deaths or 0) .. "|r]"
		r.noteText = (v.data.note and v.data.note ~= "") and "|cFF00FFFF[" .. v.data.note .. "]|r" or ""
		r.timerText = ""
		r.armoryLink = "https://classic-armory.org/character/eu/tbc-anniversary/"
			.. string.gsub(string.lower(GetRealmName() or ""), "[ ']", "-")
			.. "/"
			.. string.lower(v.name)
		r.line:SetColorTexture(
			(i == math.min(#wList, 3 + Ven.wantedOffset)) and 0.8 or 0.15,
			0.15,
			0.15,
			(i == math.min(#wList, 3 + Ven.wantedOffset)) and 0.8 or 0.4
		)
		r:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -25 - ((rowIdx - 1) * 25))
		r:SetPoint("TOPRIGHT", f, "TOPRIGHT", -15, -25 - ((rowIdx - 1) * 25))
		r:Show()
		if not InCombatLockdown() then
			r.secureBtn:SetAttribute("macrotext", "/targetexact " .. v.name)
			r.secureBtn:Show()
		end
		rowIdx = rowIdx + 1
	end

	for i = 1 + Ven.targetOffset, math.min(#tList, 5 + Ven.targetOffset) do
		local r, v = rows[rowIdx], tList[i]
		r.isWantedType = false
		r.targetName = v.name
		local cColor, cIcon = Ven.GetClassColor(v.data.classFile), Ven.GetClassIcon(v.data.classFile)
		r.nameText:SetText((Ven.GetFactionIcon(v.data.faction) or "") .. cIcon .. " " .. cColor .. v.name .. "|r")
		r.lvlText = Ven.GetLevelColor(v.data.level)
			.. ((v.data.level == -1) and "Boss/??" or (v.data.level or "?"))
			.. "|r"
		if db[v.name] then
			r.historyText = ((db[v.name].kills or 0) > 0 or (db[v.name].deaths or 0) > 0)
					and "[|cFF00FF00" .. (db[v.name].kills or 0) .. "|r-|cFFFF1A1A" .. (db[v.name].deaths or 0) .. "|r]"
				or ""
			r.noteText = (db[v.name].note and db[v.name].note ~= "") and "|cFF00FFFF[" .. db[v.name].note .. "]|r" or ""
		else
			r.historyText = ""
			r.noteText = ""
		end

		local timeSinceSeen = currentTick - v.data.lastSeen
		r.timerText = v.data.isTargetingMe and "|cFF00FF00(Active)|r"
			or "|cFF888888(" .. math.floor(60 - timeSinceSeen) .. "s)|r"

		r.armoryLink = "https://classic-armory.org/character/eu/tbc-anniversary/"
			.. string.gsub(string.lower(GetRealmName() or ""), "[ ']", "-")
			.. "/"
			.. string.lower(v.name)
		r.line:SetColorTexture(0.15, 0.15, 0.15, 0.4)
		r:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -25 - ((rowIdx - 1) * 25))
		r:SetPoint("TOPRIGHT", f, "TOPRIGHT", -15, -25 - ((rowIdx - 1) * 25))
		r:Show()
		if not InCombatLockdown() then
			r.secureBtn:SetAttribute("macrotext", "/targetexact " .. v.name)
			r.secureBtn:Show()
		end
		rowIdx = rowIdx + 1
	end

	if rowIdx > 1 then
		f:SetHeight(30 + ((rowIdx - 1) * 25))
		f:Show()
	else
		f:Hide()
	end
	f:GetScript("OnSizeChanged")(f)
end
