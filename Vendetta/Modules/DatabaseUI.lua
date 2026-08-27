local addonName, Ven = ...

local reservedKeys = {
	NetworkBounties = true,
	NetworkCache = true,
	NetworkWanteds = true,
	SenderClasses = true,
	PendingBounties = true,
	whitelistData = true,
}

local function HandleScroll(self, delta)
	if GameTooltip:IsShown() then
		GameTooltip:Hide()
	end
	local maxItems = Ven.numDBItems or 0
	if maxItems <= 10 then
		return
	end

	local scrollBar = _G["VendettaDBScrollFrameScrollBar"]
	if scrollBar then
		local current = scrollBar:GetValue()
		local maxVal = (maxItems - 10) * 20
		scrollBar:SetValue(math.min(math.max(current - (delta * 20), 0), maxVal))
	end
end

local function ShowCopyBox(text)
	if not text or not Ven.QuickCopy then
		return
	end
	Ven.QuickCopy:ClearAllPoints()
	Ven.QuickCopy:SetPoint("CENTER", UIParent, "CENTER", 0, 50)
	for _, child in ipairs({ Ven.QuickCopy:GetChildren() }) do
		if child:GetObjectType() == "EditBox" then
			child:SetText(text)
			child:SetFocus()
			child:HighlightText()
			break
		end
	end
	Ven.QuickCopy:Show()
end

Ven.Popups = Ven.Popups or {}
Ven.Popups["VENDETTA_CONFIRM_DELETE"] = {
	text = "Delete %s?",
	button1 = "Yes",
	button2 = "No",
	OnShow = function(self, data)
		local db = Ven.InitHeroDB()
		local v = db and db[data]
		if v then
			local fIcon = Ven.GetFactionIcon(v.faction) or ""
			local cIcon = Ven.GetClassIcon(v.classFile) or ""
			local cColor = Ven.GetClassColor(v.classFile) or "|cFFFFFFFF"
			self.text:SetText("Delete " .. fIcon .. cIcon .. " " .. cColor .. data .. "|r?")
		end
	end,
	OnAccept = function(self, data)
		for realm, realmData in pairs(VendettaDB) do
			if realm ~= "MyHeroes" then
				for heroName, enemies in pairs(realmData) do
					if not reservedKeys[heroName] and type(enemies) == "table" and enemies[data] then
						enemies[data] = nil
					end
				end
			end
		end
		if Ven.DBFrame:IsShown() then
			Ven.RefreshDBView()
		end
	end,
}

Ven.Popups["VENDETTA_CONFIRM_CLEAR_BOUNTIES"] = {
	text = "Are you sure you want to clear all Network Data\n(Pending reports will NOT be deleted)",
	button1 = "Yes",
	button2 = "No",
	OnAccept = function()
		if Ven.BountyBoard then
			for enemy, _ in pairs(Ven.BountyBoard) do
				Ven.BountyBoard[enemy] = nil
				if Ven.netCache then
					Ven.netCache[enemy] = nil
				end
			end
		end
		if Ven.WantedBoard then
			for enemy, _ in pairs(Ven.WantedBoard) do
				Ven.WantedBoard[enemy] = nil
				if Ven.netCache then
					Ven.netCache[enemy] = nil
				end
			end
		end
		if Ven.DBFrame and Ven.DBFrame:IsShown() and Ven.RefreshDBView then
			Ven.RefreshDBView()
		end
		if Ven.UpdateTrackerUI then
			Ven.UpdateTrackerUI()
		end
		print("|cFF00FFFF[Vendetta]|r All network bounties and wanteds have been cleared.")
	end,
}

Ven.Popups["VENDETTA_SET_NOTE"] = {
	text = "Set note for '%s' (Max 15 chars):",
	button1 = "Save",
	button2 = "Cancel",
	hasEditBox = true,
	maxLetters = 15,
	OnShow = function(self, data)
		local rName = GetRealmName() or "Unknown"
		if VendettaDB[rName] then
			for heroName, enemies in pairs(VendettaDB[rName]) do
				if not reservedKeys[heroName] and type(enemies) == "table" and enemies[data] and enemies[data].note then
					self.editBox:SetText(string.sub(enemies[data].note, 1, 15))
					break
				end
			end
		end
	end,
	OnAccept = function(self, data, inputStr)
		if inputStr and data then
			local rName = GetRealmName() or "Unknown"
			local newNote = string.sub(inputStr, 1, 15)
			local db = Ven.InitHeroDB()
			if db.showAccountWide then
				for heroName, enemies in pairs(VendettaDB[rName]) do
					if not reservedKeys[heroName] and type(enemies) == "table" and enemies[data] then
						enemies[data].note = newNote
					end
				end
			end
			if not db[data] then
				local pc = Ven.playerCache[data] or Ven.SyncPlayerDataFromOtherHeroes(data) or {}
				db[data] = {
					kills = 0,
					deaths = 0,
					level = pc.level or "?",
					class = pc.class or "?",
					classFile = pc.classFile,
					race = pc.race or "?",
					faction = pc.faction or "?",
					note = newNote,
					bountyNote = "",
					isWanted = false,
					isBounty = false,
					timeAdded = time(),
					lastCombat = 0,
				}
			else
				db[data].note = newNote
			end
			if Ven.DBFrame:IsShown() then
				Ven.RefreshDBView()
			end
		end
	end,
}

Ven.Popups["VENDETTA_SET_BOUNTY"] = {
	text = "Set Bounty Note for '%s'\n(Max 15 chars):",
	button1 = "Save",
	button2 = "Cancel",
	hasEditBox = true,
	maxLetters = 15,
	OnAccept = function(self, data, inputStr)
		if inputStr and data then
			local rName = GetRealmName() or "Unknown"
			local newNote = string.sub(inputStr, 1, 15)
			local tAdded = time()
			local db = Ven.InitHeroDB()
			if db.showAccountWide then
				for heroName, enemies in pairs(VendettaDB[rName]) do
					if not reservedKeys[heroName] and type(enemies) == "table" and enemies[data] then
						enemies[data].isBounty = true
						enemies[data].bountyNote = newNote
						enemies[data].bountySince = tAdded
					end
				end
			end
			if not db[data] then
				local pc = Ven.playerCache[data] or Ven.SyncPlayerDataFromOtherHeroes(data) or {}
				db[data] = {
					kills = 0,
					deaths = 0,
					level = pc.level or "?",
					class = pc.class or "?",
					classFile = pc.classFile,
					race = pc.race or "?",
					faction = pc.faction or "?",
					note = "",
					bountyNote = newNote,
					isWanted = false,
					isBounty = true,
					bountySince = tAdded,
					timeAdded = time(),
					lastCombat = 0,
				}
			else
				db[data].isBounty = true
				db[data].bountyNote = newNote
				db[data].bountySince = tAdded
			end
			local _, myClass = UnitClass("player")
			if Ven.Broadcast then
				Ven.Broadcast(
					"BOUNTY",
					data,
					db[data].faction or "?",
					db[data].level or "?",
					db[data].classFile or "?",
					db[data].race or "?",
					newNote,
					myClass
				)
			end
			if Ven.DBFrame:IsShown() then
				Ven.RefreshDBView()
			end
			if Ven.UpdateTrackerUI then
				Ven.UpdateTrackerUI()
			end
		end
	end,
}

Ven.Popups["VENDETTA_ADD_PLAYER"] = {
	text = "Enter player name:",
	button1 = "Add",
	button2 = "Cancel",
	hasEditBox = true,
	OnAccept = function(self, data, inputStr)
		if inputStr then
			local name = inputStr
			if name and name ~= "" then
				name = string.upper(string.sub(name, 1, 1)) .. string.lower(string.sub(name, 2))
				local db = Ven.InitHeroDB()
				local tAdded = time()
				if not db[name] then
					local s = Ven.SyncPlayerDataFromOtherHeroes(name) or Ven.playerCache[name] or {}
					db[name] = {
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
						timeAdded = tAdded,
						lastCombat = 0,
					}
				else
					db[name].timeAdded = tAdded
				end
				if Ven.DBFrame:IsShown() then
					Ven.RefreshDBView()
				end
			end
		end
	end,
}

local DBFrame = CreateFrame("Frame", "VendettaDBFrame", UIParent, "BackdropTemplate")
Ven.DBFrame = DBFrame
DBFrame:SetSize(570, 360)
DBFrame:SetPoint("CENTER")
DBFrame:SetMovable(true)
DBFrame:EnableMouse(true)
DBFrame:RegisterForDrag("LeftButton")
DBFrame:SetScript("OnDragStart", DBFrame.StartMoving)
DBFrame:SetScript("OnDragStop", DBFrame.StopMovingOrSizing)
DBFrame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
DBFrame:SetBackdropColor(0.05, 0.05, 0.05, 0.7)
DBFrame:SetBackdropBorderColor(0.2, 0.2, 0.2, 0.9)
DBFrame:Hide()

DBFrame:EnableMouseWheel(true)
DBFrame:SetScript("OnMouseWheel", HandleScroll)

DBFrame.title = DBFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
DBFrame.title:SetPoint("TOP", 0, -10)
DBFrame.title:SetText("Vendetta Database")
DBFrame.title:SetShadowOffset(1, -1)
DBFrame.title:SetShadowColor(0, 0, 0, 1)

local closeBtn = CreateFrame("Button", nil, DBFrame, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", -5, -5)
local optBtn = CreateFrame("Button", nil, DBFrame)
optBtn:SetSize(18, 18)
optBtn:SetPoint("RIGHT", closeBtn, "LEFT", -4, 0)
optBtn:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")
optBtn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
optBtn:SetScript("OnClick", function()
	if Ven.OptionsFrame:IsShown() then
		Ven.OptionsFrame:Hide()
	else
		Ven.OptionsFrame:Show()
	end
end)
optBtn:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_TOP")
	GameTooltip:SetText("Options")
	GameTooltip:Show()
end)
optBtn:SetScript("OnLeave", function()
	GameTooltip:Hide()
end)

local searchBox = CreateFrame("EditBox", "VendettaSearchBox", DBFrame, "BackdropTemplate")
searchBox:SetFontObject("GameFontHighlightSmall")
searchBox:SetSize(160, 22)
searchBox:SetPoint("TOPLEFT", 15, -35)
searchBox:SetAutoFocus(false)
searchBox:SetTextInsets(6, 20, 0, 0)
searchBox:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
searchBox:SetBackdropColor(0, 0, 0, 0.5)
searchBox:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)

searchBox.placeholder = searchBox:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
searchBox.placeholder:SetPoint("LEFT", 6, 0)
searchBox.placeholder:SetText("Search...")

local clearSearchBtn = CreateFrame("Button", nil, searchBox)
clearSearchBtn:SetSize(14, 14)
clearSearchBtn:SetPoint("RIGHT", searchBox, "RIGHT", -4, 0)
clearSearchBtn:SetNormalTexture("Interface\\FriendsFrame\\ClearBroadcastIcon")
clearSearchBtn:SetAlpha(0.6)
clearSearchBtn:SetScript("OnEnter", function(self)
	self:SetAlpha(1.0)
end)
clearSearchBtn:SetScript("OnLeave", function(self)
	self:SetAlpha(0.6)
end)
clearSearchBtn:SetScript("OnClick", function()
	searchBox:SetText("")
	searchBox:ClearFocus()
end)
clearSearchBtn:Hide()

local filterBtn = CreateFrame("Button", "VendettaFilterBtn", DBFrame, "BackdropTemplate")
filterBtn:SetSize(75, 22)
filterBtn:SetPoint("LEFT", searchBox, "RIGHT", 10, 0)
filterBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
filterBtn:SetBackdropColor(0.15, 0.15, 0.15, 0.8)
filterBtn:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
local filterBtnText = filterBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
filterBtnText:SetPoint("CENTER", 0, 0)
filterBtn:SetFontString(filterBtnText)
filterBtn:SetText("Filters")
filterBtn:SetScript("OnEnter", function(self)
	self:SetBackdropColor(0.25, 0.25, 0.25, 0.9)
end)
filterBtn:SetScript("OnLeave", function(self)
	self:SetBackdropColor(0.15, 0.15, 0.15, 0.8)
end)

local filterMenu = CreateFrame("Frame", "VendettaFilterMenu")
filterMenu.displayMode = "MENU"
filterMenu.initialize = function(self, level)
	level = level or 1
	local db = Ven.InitHeroDB()
	if db.showPersonalData == nil then
		db.showPersonalData = true
	end
	if db.showAccountWide == nil then
		db.showAccountWide = true
	end
	if db.showNetworkBounties == nil then
		db.showNetworkBounties = true
	end
	db.filterFaction = db.filterFaction or "ALL"
	db.filterClass = db.filterClass or "ALL"
	if db.filterLevel70Only == nil then
		db.filterLevel70Only = false
	end

	if level == 1 then
		local info = UIDropDownMenu_CreateInfo()
		info.text = "|cFFFFD100Data Settings|r"
		info.hasArrow = true
		info.value = "DATA"
		info.notCheckable = true
		UIDropDownMenu_AddButton(info, level)
		info = UIDropDownMenu_CreateInfo()
		info.text = "|cFFFFD100Class|r"
		info.hasArrow = true
		info.value = "CLASS"
		info.notCheckable = true
		UIDropDownMenu_AddButton(info, level)
		info = UIDropDownMenu_CreateInfo()
		info.text = "|cFFFFD100Faction|r"
		info.hasArrow = true
		info.value = "FACTION"
		info.notCheckable = true
		UIDropDownMenu_AddButton(info, level)

		info = UIDropDownMenu_CreateInfo()
		info.text = "|cFFFFD100Level 70 Only|r"
		info.isNotRadio = true
		info.keepShownOnClick = true
		info.checked = db.filterLevel70Only
		info.func = function(_, _, _, checked)
			db.filterLevel70Only = checked
			Ven.RefreshDBView()
		end
		UIDropDownMenu_AddButton(info, level)

		info = UIDropDownMenu_CreateInfo()
		info.disabled = true
		info.notCheckable = true
		UIDropDownMenu_AddButton(info, level)
		info = UIDropDownMenu_CreateInfo()
		info.text = "|cFFFF1A1AClear All Filters|r"
		info.notCheckable = true
		info.func = function()
			db.filterFaction = "ALL"
			db.filterClass = "ALL"
			db.filterLevel70Only = false
			db.filterWantedOnly = false
			db.showAccountWide = true
			db.showNetworkBounties = true
			db.showPersonalData = true
			Ven.RefreshDBView()
			CloseDropDownMenus()
		end
		UIDropDownMenu_AddButton(info, level)
	elseif level == 2 then
		local val = UIDROPDOWNMENU_MENU_VALUE
		if val == "DATA" then
			local info = UIDropDownMenu_CreateInfo()
			info.text = "Personal Data"
			info.isNotRadio = true
			info.keepShownOnClick = true
			info.checked = db.showPersonalData
			info.func = function(_, _, _, checked)
				db.showPersonalData = checked
				Ven.RefreshDBView()
			end
			UIDropDownMenu_AddButton(info, level)
			info = UIDropDownMenu_CreateInfo()
			info.text = "Account Wide"
			info.isNotRadio = true
			info.keepShownOnClick = true
			info.checked = db.showAccountWide
			info.func = function(_, _, _, checked)
				db.showAccountWide = checked
				Ven.RefreshDBView()
			end
			UIDropDownMenu_AddButton(info, level)
			info = UIDropDownMenu_CreateInfo()
			info.text = "Wanted/Bounty Only"
			info.isNotRadio = true
			info.keepShownOnClick = true
			info.checked = db.filterWantedOnly
			info.func = function(_, _, _, checked)
				db.filterWantedOnly = checked
				Ven.RefreshDBView()
			end
			UIDropDownMenu_AddButton(info, level)
			info = UIDropDownMenu_CreateInfo()
			info.text = "Network Bounties & Wanteds"
			info.isNotRadio = true
			info.keepShownOnClick = true
			info.checked = db.showNetworkBounties
			info.func = function(_, _, _, checked)
				db.showNetworkBounties = checked
				Ven.RefreshDBView()
			end
			UIDropDownMenu_AddButton(info, level)
		elseif val == "CLASS" then
			local classes = {
				{ "All Classes", "ALL" },
				{ "Druid", "DRUID" },
				{ "Hunter", "HUNTER" },
				{ "Mage", "MAGE" },
				{ "Paladin", "PALADIN" },
				{ "Priest", "PRIEST" },
				{ "Rogue", "ROGUE" },
				{ "Shaman", "SHAMAN" },
				{ "Warlock", "WARLOCK" },
				{ "Warrior", "WARRIOR" },
			}
			for _, c in ipairs(classes) do
				local info = UIDropDownMenu_CreateInfo()
				info.value = c[2]
				info.checked = (db.filterClass == c[2])
				info.func = function()
					db.filterClass = c[2]
					Ven.RefreshDBView()
					CloseDropDownMenus()
				end
				if c[2] ~= "ALL" then
					local colorStr = Ven.GetClassColor(c[2]) or "|cFFFFFFFF"
					local iconStr = Ven.GetClassIcon(c[2]) or ""
					info.text = iconStr .. " " .. colorStr .. c[1] .. "|r"
				else
					info.text = c[1]
				end
				UIDropDownMenu_AddButton(info, level)
			end
		elseif val == "FACTION" then
			local factions = { { "All Factions", "ALL" }, { "Alliance", "Alliance" }, { "Horde", "Horde" } }
			for _, f in ipairs(factions) do
				local info = UIDropDownMenu_CreateInfo()
				info.value = f[2]
				info.checked = (db.filterFaction == f[2])
				info.func = function()
					db.filterFaction = f[2]
					Ven.RefreshDBView()
					CloseDropDownMenus()
				end
				if f[2] ~= "ALL" then
					info.text = (Ven.GetFactionIcon(f[2]) or "") .. " " .. f[1]
				else
					info.text = f[1]
				end
				UIDropDownMenu_AddButton(info, level)
			end
		end
	end
end
filterBtn:SetScript("OnClick", function(self)
	ToggleDropDownMenu(1, nil, filterMenu, self, 0, 0)
end)

local headerLine = DBFrame:CreateTexture(nil, "BACKGROUND")
headerLine:SetSize(550, 1)
headerLine:SetPoint("TOP", 0, -80)
headerLine:SetColorTexture(0.3, 0.3, 0.3, 0.5)

local currentSort, sortAsc, dbRows = "lastCombat", false, {}
local scrollFrame = CreateFrame("ScrollFrame", "VendettaDBScrollFrame", DBFrame, "FauxScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 10, -110)
scrollFrame:SetPoint("BOTTOMRIGHT", -35, 45)
scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
	if GameTooltip:IsShown() then
		GameTooltip:Hide()
	end
	FauxScrollFrame_OnVerticalScroll(self, offset, 20, Ven.UpdateDBScroll)
end)
scrollFrame:EnableMouseWheel(true)
scrollFrame:SetScript("OnMouseWheel", HandleScroll)

local bLine = DBFrame:CreateTexture(nil, "BACKGROUND")
bLine:SetSize(550, 1)
bLine:SetPoint("BOTTOM", 0, 40)
bLine:SetColorTexture(0.3, 0.3, 0.3, 0.5)

local addPlayerBtn = CreateFrame("Button", nil, DBFrame, "BackdropTemplate")
addPlayerBtn:SetSize(80, 22)
addPlayerBtn:SetPoint("BOTTOMRIGHT", -15, 12)
Ven.StyleFlatButton(addPlayerBtn)
addPlayerBtn:SetText("Add Player")
addPlayerBtn:SetScript("OnClick", function()
	Ven.ShowPopup(Ven.Popups["VENDETTA_ADD_PLAYER"])
end)

DBFrame:SetScript("OnShow", function()
	currentSort = "lastCombat"
	sortAsc = false
	Ven.RefreshDBView()
end)

local cachedSortedDB, cachedMergedDB = {}, {}

function Ven.RefreshDBView()
	local rName, pName = GetRealmName() or "Unknown", UnitName("player") or "Unknown"
	local db = Ven.InitHeroDB()
	if db.showPersonalData == nil then
		db.showPersonalData = true
	end
	if db.showAccountWide == nil then
		db.showAccountWide = true
	end
	if db.showNetworkBounties == nil then
		db.showNetworkBounties = true
	end
	wipe(cachedSortedDB)
	wipe(cachedMergedDB)
	local sortedDB, isWantedOnly, filterText = cachedSortedDB, db.filterWantedOnly, string.lower(searchBox:GetText() or "")
	local merged = cachedMergedDB

	local function InsertToMerged(n, d)
		if not merged[n] then
			merged[n] = {
				kills = 0,
				deaths = 0,
				class = d.class or "?",
				classFile = d.classFile,
				level = d.level or "?",
				race = d.race or "?",
				faction = d.faction or "?",
				note = "",
				netNote = "",
				isWanted = false,
				isBounty = false,
				lastCombat = 0,
				timeAdded = Ven.ParseOldTime(d.timeAdded),
				isLocal = true,
			}
		else
			if d.classFile and not merged[n].classFile then
				merged[n].classFile = d.classFile
				merged[n].class = d.class
				merged[n].race = d.race
				merged[n].faction = d.faction
			end
			if d.level and d.level ~= "?" and (not merged[n].level or merged[n].level == "?") then
				merged[n].level = d.level
			end
			merged[n].isLocal = true
		end
		if d.isWanted and not d.wantedSince then
			d.wantedSince = time()
		end
		local t1, t2 = Ven.ParseOldTime(d.lastKillTime), Ven.ParseOldTime(d.lastDeathTime)
		local maxCombat = math.max(t1, t2)
		merged[n].kills = merged[n].kills + (d.kills or 0)
		merged[n].deaths = merged[n].deaths + (d.deaths or 0)
		if d.isWanted then
			merged[n].isWanted = true
			if d.wantedSince then
				merged[n].wantedSince = d.wantedSince
			end
		end
		if d.isBounty then
			merged[n].isBounty = true
			if d.bountySince then
				merged[n].bountySince = d.bountySince
			end
			if d.bountyNote then
				merged[n].bountyNote = d.bountyNote
			end
		end
		if d.lastSeenLoc then
			merged[n].lastSeenLoc = d.lastSeenLoc
		end
		if d.lastSeenTime then
			merged[n].lastSeenTime = d.lastSeenTime
		end
		if d.note and d.note ~= "" then
			merged[n].note = string.sub(d.note, 1, 15)
		end
		merged[n].lastCombat = math.max(maxCombat, merged[n].lastCombat or 0)
		merged[n].timeAdded = math.max(Ven.ParseOldTime(d.timeAdded), merged[n].timeAdded or 0)
	end

	if db.showPersonalData then
		for n, d in pairs(db) do
			if type(d) == "table" and not reservedKeys[n] then
				InsertToMerged(n, d)
			end
		end
	end
	if db.showAccountWide then
		for realm, rData in pairs(VendettaDB) do
			if realm ~= "MyHeroes" then
				for heroName, heroEnemies in pairs(rData) do
					if not reservedKeys[heroName] and not (realm == rName and heroName == pName) then
						if type(heroEnemies) == "table" then
							for n, d in pairs(heroEnemies) do
								if type(d) == "table" then
									InsertToMerged(n, d)
								end
							end
						end
					end
				end
			end
		end
	end
	if db.showNetworkBounties and db.enableNetwork then
		if Ven.BountyBoard then
			for n, owners in pairs(Ven.BountyBoard) do
				local fOwner, netNote = nil, ""
				for o, data in pairs(owners) do
					fOwner = fOwner or o
					netNote = type(data) == "table" and data.note or netNote
					break
				end
				if fOwner then
					local pc = Ven.playerCache[n] or {}
					if not merged[n] then
						merged[n] = {
							kills = 0,
							deaths = 0,
							class = pc.class or "?",
							classFile = pc.classFile,
							level = pc.level or "?",
							race = pc.race or "?",
							faction = pc.faction or "?",
							note = "",
							netNote = "",
							isWanted = false,
							isBounty = false,
							lastCombat = 0,
							timeAdded = 0,
							isLocal = false,
						}
					end
					merged[n].isNetBounty = true
					merged[n].netOwner = fOwner
					if netNote and netNote ~= "" then
						merged[n].netNote = string.sub(netNote, 1, 15)
					end
					if merged[n].level == "?" and pc.level then
						merged[n].level = pc.level
					end
					if not merged[n].classFile and pc.classFile then
						merged[n].classFile = pc.classFile
					end
					if merged[n].race == "?" and pc.race then
						merged[n].race = pc.race
					end
					if merged[n].faction == "?" and pc.faction then
						merged[n].faction = pc.faction
					end
				end
			end
		end
		if Ven.WantedBoard then
			for n, owners in pairs(Ven.WantedBoard) do
				local fOwner, netNote = nil, ""
				for o, data in pairs(owners) do
					fOwner = fOwner or o
					netNote = type(data) == "table" and data.note or netNote
					break
				end
				if fOwner then
					local pc = Ven.playerCache[n] or {}
					if not merged[n] then
						merged[n] = {
							kills = 0,
							deaths = 0,
							class = pc.class or "?",
							classFile = pc.classFile,
							level = pc.level or "?",
							race = pc.race or "?",
							faction = pc.faction or "?",
							note = "",
							netNote = "",
							isWanted = false,
							isBounty = false,
							lastCombat = 0,
							timeAdded = 0,
							isLocal = false,
						}
					end
					merged[n].isNetWanted = true
					merged[n].netOwnerWanted = fOwner
					if netNote and netNote ~= "" and merged[n].netNote == "" then
						merged[n].netNote = string.sub(netNote, 1, 15)
					end
					if merged[n].level == "?" and pc.level then
						merged[n].level = pc.level
					end
					if not merged[n].classFile and pc.classFile then
						merged[n].classFile = pc.classFile
					end
					if merged[n].race == "?" and pc.race then
						merged[n].race = pc.race
					end
					if merged[n].faction == "?" and pc.faction then
						merged[n].faction = pc.faction
					end
				end
			end
		end
	end

	for n, d in pairs(merged) do
		local passFaction = (not db.filterFaction or db.filterFaction == "ALL" or d.faction == db.filterFaction)
		local passClass = (not db.filterClass or db.filterClass == "ALL" or d.classFile == db.filterClass)
		local passLevel = true
		if db.filterLevel70Only then
			local lvl = tonumber(d.level) or 0
			if lvl ~= 70 then
				passLevel = false
			end
		end

		local displayNote = (d.note and d.note ~= "") and d.note or d.netNote
		local matchName = string.find(string.lower(n), filterText, 1, true)
		local matchNote = displayNote and string.find(string.lower(displayNote), filterText, 1, true)
		local displayOwner = d.netOwner or d.netOwnerWanted
		local matchOwner = db.showNetworkBounties
			and displayOwner
			and string.find(string.lower(displayOwner), filterText, 1, true)

		if passFaction and passClass and passLevel then
			if filterText == "" or matchName or matchNote or matchOwner then
				if
					not isWantedOnly
					or d.isWanted
					or d.isBounty
					or (db.showNetworkBounties and (d.isNetBounty or d.isNetWanted))
				then
					table.insert(
						sortedDB,
						{
							name = n,
							kills = d.kills,
							deaths = d.deaths,
							class = d.class,
							level = d.level,
							classFile = d.classFile,
							race = d.race,
							faction = d.faction,
							note = d.note,
							netNote = d.netNote,
							isWanted = d.isWanted,
							isBounty = d.isBounty,
							wantedSince = d.wantedSince,
							lastSeenLoc = d.lastSeenLoc,
							lastSeenTime = d.lastSeenTime,
							lastCombat = d.lastCombat,
							timeAdded = d.timeAdded,
							isNetBounty = d.isNetBounty,
							isNetWanted = d.isNetWanted,
							netOwner = d.netOwner,
							netOwnerWanted = d.netOwnerWanted,
							isLocal = d.isLocal,
						}
					)
				end
			end
		end
	end

	local fCount = 0
	if db.filterFaction and db.filterFaction ~= "ALL" then
		fCount = fCount + 1
	end
	if db.filterClass and db.filterClass ~= "ALL" then
		fCount = fCount + 1
	end
	if db.filterLevel70Only then
		fCount = fCount + 1
	end
	if fCount > 0 then
		filterBtn:SetText("Filters (" .. fCount .. ")")
	else
		filterBtn:SetText("Filters")
	end

	table.sort(sortedDB, function(a, b)
		if
			currentSort == "lastCombat"
			or currentSort == "timeAdded"
			or currentSort == "lastSeenTime"
			or currentSort == "wantedSince"
			or currentSort == "bountySince"
		then
			local vA, vB = Ven.ParseOldTime(a[currentSort]), Ven.ParseOldTime(b[currentSort])
			if currentSort == "lastCombat" then
				if vA == 0 then
					vA = Ven.ParseOldTime(a.timeAdded) or 0
				end
				if vB == 0 then
					vB = Ven.ParseOldTime(b.timeAdded) or 0
				end
			end
			if vA == vB then
				if currentSort == "lastCombat" then
					local tA, tB = Ven.ParseOldTime(a.timeAdded), Ven.ParseOldTime(b.timeAdded)
					if tA ~= tB then
						if sortAsc then
							return tA < tB
						else
							return tA > tB
						end
					end
				end
				return string.lower(a.name) < string.lower(b.name)
			end
			if sortAsc then
				return vA < vB
			else
				return vA > vB
			end
		else
			local vA, vB = a[currentSort], b[currentSort]
			if currentSort == "netOwner" then
				vA = vA or a.netOwnerWanted
				vB = vB or b.netOwnerWanted
			elseif currentSort == "note" then
				if not vA or vA == "" then
					vA = a.netNote
				end
				if not vB or vB == "" then
					vB = b.netNote
				end
			end
			if vA == nil then
				vA = ""
			end
			if vB == nil then
				vB = ""
			end
			if type(vA) ~= type(vB) then
				vA = tostring(vA)
				vB = tostring(vB)
			end

			if vA == "" and vB ~= "" then
				return false
			end
			if vB == "" and vA ~= "" then
				return true
			end

			if type(vA) == "string" and type(vB) == "string" then
				local vALow, vBLow = string.lower(vA), string.lower(vB)
				if vALow == vBLow then
					return string.lower(a.name) < string.lower(b.name)
				end
				if sortAsc then
					return vALow < vBLow
				else
					return vALow > vBLow
				end
			else
				if vA == vB then
					return string.lower(a.name) < string.lower(b.name)
				end
				if sortAsc then
					return vA < vB
				else
					return vA > vB
				end
			end
		end
	end)

	Ven.numDBItems = #sortedDB
	Ven.sortedDB = sortedDB
	Ven.UpdateDBScroll()
end

function Ven.UpdateDBScroll()
	local sortedDB = Ven.sortedDB or {}
	local rName = GetRealmName() or "Unknown"
	local db = Ven.InitHeroDB()

	FauxScrollFrame_Update(scrollFrame, #sortedDB, 10, 20)
	local offset = FauxScrollFrame_GetOffset(scrollFrame)
	for i = 1, 10 do
		local r, idx = dbRows[i], offset + i
		if sortedDB[idx] then
			local v = sortedDB[idx]
			local cColor, cIcon = Ven.GetClassColor(v.classFile), Ven.GetClassIcon(v.classFile)
			local fIcon = Ven.GetFactionIcon(v.faction)

			r.playerName = v.name
			r.name:SetText(fIcon .. cIcon .. " " .. cColor .. v.name .. "|r")

			local cleanRealm = string.gsub(string.lower(rName), "[ ']", "-")
			r.armoryBtn.link = "https://classic-armory.org/character/eu/tbc-anniversary/"
				.. cleanRealm
				.. "/"
				.. string.lower(v.name)

			r.level:SetText(Ven.GetLevelColor(v.level) .. (v.level or "?") .. "|r")
			r.kills:SetText("|cFF00FF00" .. v.kills .. "|r")
			r.deaths:SetText("|cFFFF1A1A" .. v.deaths .. "|r")

			if v.note and v.note ~= "" then
				r.note:SetText("|cFF00FFFF" .. v.note .. "|r")
			elseif v.netNote and v.netNote ~= "" then
				r.note:SetText("|cFF888888" .. v.netNote .. "|r")
			else
				r.note:SetText("")
			end

			local displayOwner = v.netOwner or v.netOwnerWanted
			if db.showNetworkBounties and displayOwner then
				Ven.SenderClasses = Ven.SenderClasses or {}
				local ownerColor = Ven.GetClassColor(Ven.SenderClasses[displayOwner]) or "|cFF00FFFF"
				r.wantedByStr:SetText(ownerColor .. displayOwner .. "|r")
				r.wantedByBtn.ownerName = displayOwner
				r.wantedByBtn:Show()
			else
				r.wantedByStr:SetText("")
				r.wantedByBtn:Hide()
			end

			r.noteBtn:Show()
			r.bountyBtn:Show()
			r.wantedBtn:Show()
			if v.isLocal then
				r.deleteBtn:Show()
			else
				r.deleteBtn:Hide()
			end

			r.wantedBtn:SetAlpha(v.isWanted and 1.0 or 0.2)
			r.bountyBtn:SetAlpha(v.isBounty and 1.0 or 0.2)
			r:Show()
		else
			r:Hide()
		end
	end
	if db.showNetworkBounties then
		Ven.DBFrame.wantedByHeader:Show()
	else
		Ven.DBFrame.wantedByHeader:Hide()
	end
end

searchBox:SetScript("OnTextChanged", function(self)
	if self:GetText() == "" then
		clearSearchBtn:Hide()
		if self.placeholder then
			self.placeholder:Show()
		end
	else
		clearSearchBtn:Show()
		if self.placeholder then
			self.placeholder:Hide()
		end
	end
	Ven.RefreshDBView()
end)

local headers = {
	{ "", "armory", 10 },
	{ "Name", "name", 30 },
	{ "Lvl", "level", 145 },
	{ "Kills", "kills", 185 },
	{ "Deaths", "deaths", 235 },
	{ "Note", "note", 295 },
	{ "Wanted By", "netOwner", 380 },
}
for _, h in ipairs(headers) do
	local btn = CreateFrame("Button", nil, DBFrame)
	btn:SetSize(40, 20)
	btn:SetPoint("TOPLEFT", h[3], -85)
	local txt = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	txt:SetPoint("LEFT")
	txt:SetText(h[1])
	txt:SetShadowOffset(1, -1)
	txt:SetShadowColor(0, 0, 0, 1)
	btn:SetScript("OnClick", function()
		if h[2] == "armory" then
			return
		end
		if currentSort == h[2] then
			sortAsc = not sortAsc
		else
			currentSort = h[2]
			sortAsc = false
		end
		local bar = _G["VendettaDBScrollFrameScrollBar"]
		if bar then
			bar:SetValue(0)
		end
		Ven.RefreshDBView()
	end)
	if h[2] == "netOwner" then
		Ven.DBFrame.wantedByHeader = btn
		btn:Hide()
	end
end

for i = 1, 10 do
	local r = CreateFrame("Frame", nil, DBFrame)
	r:SetSize(530, 20)
	r:SetPoint("TOPLEFT", 10, -110 - ((i - 1) * 20))

	r.armoryBtn = CreateFrame("Button", nil, r)
	r.armoryBtn:SetSize(14, 14)
	r.armoryBtn:SetPoint("LEFT")
	r.armoryBtn:SetNormalTexture("Interface\\Icons\\INV_Misc_Note_02")
	r.armoryBtn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
	r.armoryBtn:SetScript("OnClick", function(self)
		if Ven.ShowCopyBox then
			Ven.ShowCopyBox(self.link)
		end
	end)
	r.armoryBtn:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText("Copy Armory Link")
		GameTooltip:Show()
	end)
	r.armoryBtn:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	r.name = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	r.name:SetPoint("LEFT", 20, 0)
	r.name:SetShadowOffset(1, -1)
	r.name:SetShadowColor(0, 0, 0, 1)

	r.nameBtn = CreateFrame("Button", nil, r)
	r.nameBtn:SetSize(75, 20)
	r.nameBtn:SetPoint("LEFT", 55, 0)
	r.nameBtn:SetScript("OnClick", function()
		if r.playerName and Ven.ShowCopyBox then
			Ven.ShowCopyBox(r.playerName)
		end
	end)
	r.nameBtn:SetScript("OnEnter", function()
		GameTooltip:SetOwner(r.nameBtn, "ANCHOR_RIGHT")
		GameTooltip:SetText("Copy Name")
		GameTooltip:Show()
	end)
	r.nameBtn:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	r.level = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	r.level:SetPoint("LEFT", 145, 0)
	r.level:SetShadowOffset(1, -1)
	r.level:SetShadowColor(0, 0, 0, 1)
	r.kills = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	r.kills:SetPoint("LEFT", 185, 0)
	r.kills:SetShadowOffset(1, -1)
	r.kills:SetShadowColor(0, 0, 0, 1)
	r.deaths = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	r.deaths:SetPoint("LEFT", 235, 0)
	r.deaths:SetShadowOffset(1, -1)
	r.deaths:SetShadowColor(0, 0, 0, 1)
	r.note = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	r.note:SetPoint("LEFT", 295, 0)
	r.note:SetWidth(75)
	r.note:SetJustifyH("LEFT")
	r.note:SetWordWrap(false)
	r.note:SetShadowOffset(1, -1)
	r.note:SetShadowColor(0, 0, 0, 1)

	r.wantedByBtn = CreateFrame("Button", nil, r)
	r.wantedByBtn:SetSize(70, 20)
	r.wantedByBtn:SetPoint("LEFT", 380, 0)
	r.wantedByStr = r.wantedByBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	r.wantedByStr:SetPoint("LEFT")
	r.wantedByStr:SetWidth(70)
	r.wantedByStr:SetJustifyH("LEFT")
	r.wantedByStr:SetWordWrap(false)
	r.wantedByStr:SetShadowOffset(1, -1)
	r.wantedByStr:SetShadowColor(0, 0, 0, 1)
	r.wantedByBtn:SetScript("OnClick", function(self)
		if self.ownerName then
			ChatFrame_OpenChat("/w " .. self.ownerName .. " ")
		end
	end)
	r.wantedByBtn:SetScript("OnEnter", function(self)
		if self.ownerName then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText("Whisper " .. self.ownerName)
			GameTooltip:Show()
		end
	end)
	r.wantedByBtn:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	r.noteBtn = CreateFrame("Button", nil, r)
	r.noteBtn:SetSize(16, 16)
	r.noteBtn:SetPoint("LEFT", 440, 0)
	r.noteBtn:SetNormalTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
	r.noteBtn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
	r.noteBtn:SetScript("OnClick", function(self)
		Ven.ShowPopup(Ven.Popups["VENDETTA_SET_NOTE"], self:GetParent().playerName)
	end)
	r.noteBtn:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText("Edit Personal Note")
		GameTooltip:Show()
	end)
	r.noteBtn:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	r.wantedBtn = CreateFrame("Button", nil, r)
	r.wantedBtn:SetSize(16, 16)
	r.wantedBtn:SetPoint("LEFT", 460, 0)
	r.wantedBtn:SetNormalTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_8")
	r.wantedBtn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
	r.wantedBtn:SetScript("OnClick", function(self)
		local n = self:GetParent().playerName
		local db = Ven.InitHeroDB()
		local isCurrentlyWanted = false
		if db.showAccountWide then
			for heroName, heroEnemies in pairs(VendettaDB[GetRealmName() or "Unknown"]) do
				if
					heroName ~= "MyHeroes"
					and not reservedKeys[heroName]
					and type(heroEnemies) == "table"
					and heroEnemies[n]
					and heroEnemies[n].isWanted
				then
					isCurrentlyWanted = true
					break
				end
			end
		else
			isCurrentlyWanted = db[n] and db[n].isWanted
		end
		local newState = not isCurrentlyWanted

		if db.showAccountWide then
			for heroName, heroEnemies in pairs(VendettaDB[GetRealmName() or "Unknown"]) do
				if
					heroName ~= "MyHeroes"
					and not reservedKeys[heroName]
					and type(heroEnemies) == "table"
					and heroEnemies[n]
				then
					heroEnemies[n].isWanted = newState
					heroEnemies[n].wantedSince = newState and time() or nil
				end
			end
		end

		if newState then
			if not db[n] then
				local pc = Ven.playerCache[n] or Ven.SyncPlayerDataFromOtherHeroes(n) or {}
				db[n] = {
					kills = 0,
					deaths = 0,
					level = pc.level or "?",
					class = pc.class or "?",
					classFile = pc.classFile,
					race = pc.race or "?",
					faction = pc.faction or "?",
					note = "",
					bountyNote = "",
					isWanted = true,
					isBounty = false,
					wantedSince = time(),
					timeAdded = time(),
					lastCombat = 0,
				}
			else
				db[n].isWanted = true
				db[n].wantedSince = time()
			end
			if Ven.Broadcast then
				local noteStr = string.gsub(db[n].note or "", "~", "-")
				local _, myClass = UnitClass("player")
				Ven.Broadcast(
					"WANTED",
					n,
					db[n].faction or "?",
					db[n].level or "?",
					db[n].classFile or "?",
					db[n].race or "?",
					noteStr,
					myClass or "?"
				)
			end
		else
			if db[n] then
				db[n].isWanted = false
				db[n].wantedSince = nil
			end
			if Ven.Broadcast then
				Ven.Broadcast("UNWANTED", n)
			end
		end
		Ven.RefreshDBView()
		Ven.UpdateTrackerUI()
	end)
	r.wantedBtn:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText("Toggle Wanted Status (Shared to Whitelist)")
		GameTooltip:Show()
	end)
	r.wantedBtn:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	r.bountyBtn = CreateFrame("Button", nil, r)
	r.bountyBtn:SetSize(16, 16)
	r.bountyBtn:SetPoint("LEFT", 480, 0)
	r.bountyBtn:SetNormalTexture("Interface\\Icons\\INV_Misc_Coin_02")
	r.bountyBtn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
	r.bountyBtn:SetScript("OnClick", function(self)
		local n = self:GetParent().playerName
		if not n then
			return
		end
		local db = Ven.InitHeroDB()
		local isCurrentlyBounty = false
		if db.showAccountWide then
			for heroName, heroEnemies in pairs(VendettaDB[GetRealmName() or "Unknown"]) do
				if
					heroName ~= "MyHeroes"
					and not reservedKeys[heroName]
					and type(heroEnemies) == "table"
					and heroEnemies[n]
					and heroEnemies[n].isBounty
				then
					isCurrentlyBounty = true
					break
				end
			end
		else
			isCurrentlyBounty = db[n] and db[n].isBounty
		end

		if isCurrentlyBounty then
			if db.showAccountWide then
				for heroName, heroEnemies in pairs(VendettaDB[GetRealmName() or "Unknown"]) do
					if
						heroName ~= "MyHeroes"
						and not reservedKeys[heroName]
						and type(heroEnemies) == "table"
						and heroEnemies[n]
					then
						heroEnemies[n].isBounty = false
						heroEnemies[n].bountyNote = nil
						heroEnemies[n].bountySince = nil
					end
				end
			end
			if db[n] then
				db[n].isBounty = false
				db[n].bountyNote = nil
				db[n].bountySince = nil
			end
			if Ven.Broadcast then
				Ven.Broadcast("UNBOUNTY", n)
			end
			Ven.RefreshDBView()
			if Ven.UpdateTrackerUI then
				Ven.UpdateTrackerUI()
			end
		else
			Ven.ShowPopup(Ven.Popups["VENDETTA_SET_BOUNTY"], n)
		end
	end)
	r.bountyBtn:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText("Set/Remove Bounty (Shared to Network)")
		GameTooltip:Show()
	end)
	r.bountyBtn:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	r.deleteBtn = CreateFrame("Button", nil, r)
	r.deleteBtn:SetSize(16, 16)
	r.deleteBtn:SetPoint("LEFT", 500, 0)
	r.deleteBtn:SetNormalTexture("Interface\\BUTTONS\\UI-GroupLoot-Pass-Up")
	r.deleteBtn:SetHighlightTexture("Interface\\BUTTONS\\UI-GroupLoot-Pass-Highlight", "ADD")
	r.deleteBtn:SetScript("OnClick", function(self)
		Ven.ShowPopup(Ven.Popups["VENDETTA_CONFIRM_DELETE"], self:GetParent().playerName)
	end)
	r.deleteBtn:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText("Delete Player")
		GameTooltip:Show()
	end)
	r.deleteBtn:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	r:EnableMouseWheel(true)
	r:SetScript("OnMouseWheel", HandleScroll)
	r:EnableMouse(true)
	r:SetScript("OnEnter", function(self)
		Ven.ShowPlayerTooltip(self, self.playerName)
	end)
	r:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	dbRows[i] = r
end

SLASH_VENDETTA1 = "/ven"
SLASH_VENDETTA2 = "/vendetta"
SlashCmdList["VENDETTA"] = function()
	if DBFrame:IsShown() then
		DBFrame:Hide()
	else
		if Ven.RefreshDBView then
			Ven.RefreshDBView()
		end
		DBFrame:Show()
	end
end
