local addonName, Ven = ...

local f = CreateFrame("Frame", "VendettaOptionsFrame", UIParent, "BackdropTemplate")
Ven.OptionsFrame = f
f:SetSize(430, 420) 
f:SetPoint("CENTER")
f:SetFrameStrata("DIALOG") 
f:SetMovable(true); f:EnableMouse(true)
f:RegisterForDrag("LeftButton"); f:SetScript("OnDragStart", f.StartMoving); f:SetScript("OnDragStop", f.StopMovingOrSizing)
f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1})
f:SetBackdropColor(0.05, 0.05, 0.05, 0.92); f:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.9); f:Hide()

f.title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
f.title:SetPoint("TOP", 0, -12); f.title:SetText("Vendetta Configuration")
f.title:SetShadowOffset(1, -1); f.title:SetShadowColor(0, 0, 0, 1)

local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton"); closeBtn:SetPoint("TOPRIGHT", -5, -5)

local function CreateHeader(parent, text, yOffset)
    local h = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    h:SetPoint("TOPLEFT", 20, yOffset); h:SetText("|cFFFFAA00" .. text .. "|r")
    h:SetShadowOffset(1, -1); h:SetShadowColor(0, 0, 0, 1)
    return h
end

local function CreateCheck(parent, text, dbKey, yOffset, defaultVal, tooltip)
    local cb = CreateFrame("CheckButton", "VenOpt_"..dbKey, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", 15, yOffset)
    local txt = _G[cb:GetName().."Text"]; txt:SetText(" " .. text); txt:SetShadowOffset(1, -1); txt:SetShadowColor(0, 0, 0, 1)
    
    cb:SetScript("OnShow", function(self) local val = Ven.InitHeroDB()[dbKey]; if val == nil then val = defaultVal end; self:SetChecked(val) end)
    cb:SetScript("OnClick", function(self) 
        Ven.InitHeroDB()[dbKey] = self:GetChecked()
        if Ven.UpdateTrackerUI then Ven.UpdateTrackerUI() end
        if Ven.RefreshDBView and Ven.DBFrame and Ven.DBFrame:IsShown() then Ven.RefreshDBView() end
        if Ven.UpdateMinimapButtonPosition then Ven.UpdateMinimapButtonPosition() end
    end)
    if tooltip then
        cb:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText(text); GameTooltip:AddLine(tooltip, 1, 1, 1, true); GameTooltip:Show() end)
        cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    return cb
end

local tabs = {}
local function CreateTab(id, name, width, xOffset)
    local btn = CreateFrame("Button", nil, f)
    btn:SetSize(width, 26); btn:SetPoint("TOPLEFT", xOffset, -40)
    local bg = btn:CreateTexture(nil, "BACKGROUND"); bg:SetAllPoints(); btn.bg = bg
    local txt = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal"); txt:SetPoint("CENTER")
    txt:SetText(name); txt:SetShadowOffset(1, -1); txt:SetShadowColor(0, 0, 0, 1); btn.txt = txt
    local panel = CreateFrame("Frame", nil, f)
    panel:SetPoint("TOPLEFT", 0, -70); panel:SetPoint("BOTTOMRIGHT", 0, 0); panel:Hide()
    tabs[id] = {btn = btn, bg = bg, txt = txt, panel = panel}
    return panel
end

local panel1 = CreateTab(1, "Target Tracking", 100, 12); local panel2 = CreateTab(2, "Wanteds", 90, 115)
local panel3 = CreateTab(3, "Bounties", 110, 208); local panel4 = CreateTab(4, "General", 80, 321)

local function SelectTab(id)
    for i=1, 4 do tabs[i].panel:Hide(); tabs[i].bg:SetColorTexture(0.15, 0.15, 0.15, 0.5); tabs[i].txt:SetTextColor(0.5, 0.5, 0.5) end
    tabs[id].panel:Show(); tabs[id].bg:SetColorTexture(0.4, 0.1, 0.1, 0.9); tabs[id].txt:SetTextColor(1, 0.82, 0)
end
for i=1, 4 do tabs[i].btn:SetScript("OnClick", function() SelectTab(i) end) end; SelectTab(1)

local divLine = f:CreateTexture(nil, "BACKGROUND")
divLine:SetSize(400, 1); divLine:SetPoint("TOP", 0, -68); divLine:SetColorTexture(0.4, 0.4, 0.4, 0.7)

Ven.killSoundList = {
    {name = "Disabled", id = -1},
    {name = "Random", id = "RANDOM"},
    {name = "Your fate", id = 563656},
    {name = "Not prepared!", id = 552503},
    {name = "What a waste", id = 556458},
    {name = "Scream for me", id = 543825},
    {name = "Who's next? (1)", id = 546067},
    {name = "Who's next? (2)", id = 546779},
    {name = "Mission accomplished", id = 546345},
    {name = "Ashes to ashes", id = 548399},
    {name = "Die, die!", id = 551253},
    {name = "I want more!", id = 551377},
    {name = "You are nothing", id = 553052},
    {name = "Who's the master?", id = 553787},
    {name = "It is done", id = 555834},
    {name = "Looks like you lose", id = 558111},
    {name = "Justice is done", id = 559564},
    {name = "It is finished", id = 561216},
    {name = "Bring more friends", id = 561834},
    {name = "Your days are done", id = 563635},
    {name = "Over, finished", id = 563639},
    {name = "Much too easy", id = 564064},
    {name = "Say farewell", id = 564057}
}

local Ven_SoundMenu = CreateFrame("Frame", "VendettaSoundMenu", UIParent, "BackdropTemplate")
Ven_SoundMenu:SetSize(180, 25) 
Ven_SoundMenu:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1})
Ven_SoundMenu:SetBackdropColor(0.05, 0.05, 0.05, 0.95); Ven_SoundMenu:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
Ven_SoundMenu:SetFrameStrata("TOOLTIP"); Ven_SoundMenu:Hide()

Ven_SoundMenu:SetScript("OnUpdate", function(self)
    if IsMouseButtonDown("LeftButton") or IsMouseButtonDown("RightButton") then
        if not self:IsMouseOver() and not (self.currentDrop and self.currentDrop:IsMouseOver()) then self:Hide() end
    end
end)
Ven_SoundMenu.buttons = {}

local function ToggleSoundMenu(dbKey, dropFrame, defaultIdx, soundList, forceCB)
    if Ven_SoundMenu:IsShown() and Ven_SoundMenu.currentKey == dbKey then Ven_SoundMenu:Hide(); return end
    Ven_SoundMenu.currentKey = dbKey; Ven_SoundMenu.currentDrop = dropFrame
    Ven_SoundMenu:SetHeight(#soundList * 16 + 10)
    for _, btn in pairs(Ven_SoundMenu.buttons) do btn:Hide() end
    local currentSel = Ven.InitHeroDB()[dbKey] or defaultIdx
    if not soundList[currentSel] then currentSel = defaultIdx end
    
    for i, sData in ipairs(soundList) do
        local btn = Ven_SoundMenu.buttons[i]
        if not btn then
            btn = CreateFrame("Button", nil, Ven_SoundMenu)
            btn:SetSize(170, 16); btn:SetPoint("TOPLEFT", 5, -5 - ((i-1)*16))
            local hl = btn:CreateTexture(nil, "HIGHLIGHT"); hl:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight"); hl:SetBlendMode("ADD"); hl:SetAllPoints(btn)
            local check = btn:CreateTexture(nil, "ARTWORK"); check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check"); check:SetSize(16, 16); check:SetPoint("LEFT")
            btn.check = check
            btn.txt = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); btn.txt:SetPoint("LEFT", check, "RIGHT", 4, 0)
            btn.txt:SetShadowOffset(1, -1); btn.txt:SetShadowColor(0, 0, 0, 1)
            local playBtn = CreateFrame("Button", nil, btn)
            playBtn:SetSize(16, 16); playBtn:SetPoint("RIGHT", -5, 0); playBtn:SetNormalTexture("Interface\\Common\\VoiceChat-Speaker"); playBtn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
            btn.playBtn = playBtn; Ven_SoundMenu.buttons[i] = btn
        end
        btn.txt:SetText(sData.name)
        if i == currentSel then btn.check:Show() else btn.check:Hide() end
        
        if sData.id == nil or sData.id == "RANDOM" or sData.id == -1 then 
            btn.playBtn:Hide() 
        else
            btn.playBtn:Show()
            btn.playBtn:SetScript("OnClick", function() Ven.AlertPlaySound(sData.id, true) end)
        end
        
        btn:SetScript("OnClick", function()
            Ven.InitHeroDB()[Ven_SoundMenu.currentKey] = i; _G[Ven_SoundMenu.currentDrop:GetName().."Text"]:SetText(sData.name)
            if forceCB then if i == 1 then forceCB:SetAlpha(0.3); forceCB:Disable() else forceCB:SetAlpha(1); forceCB:Enable() end end
            Ven_SoundMenu:Hide()
        end)
        btn:Show()
    end
    Ven_SoundMenu:SetPoint("TOPLEFT", dropFrame, "BOTTOMLEFT", 15, 0); Ven_SoundMenu:Show()
end

local function CreateSoundDrop(parent, label, dbKey, forceDbKey, yOffset, defaultIdx, soundList)
    local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetPoint("TOPLEFT", 25, yOffset); lbl:SetText(label)
    lbl:SetShadowOffset(1, -1); lbl:SetShadowColor(0, 0, 0, 1)
    local drop = CreateFrame("Button", "VenOptDrop_"..dbKey, parent, "UIDropDownMenuTemplate")
    drop:SetPoint("TOPLEFT", 185, yOffset + 7); UIDropDownMenu_SetWidth(drop, 110)
    local forceCB = CreateFrame("CheckButton", "VenOptForce_"..dbKey, parent, "UICheckButtonTemplate")
    forceCB:SetSize(24, 24); forceCB:SetPoint("LEFT", drop, "RIGHT", -10, 3)
    local fTxt = _G[forceCB:GetName().."Text"]; fTxt:SetFontObject("GameFontHighlightSmall"); fTxt:SetText("Force Play")
    fTxt:SetShadowOffset(1, -1); fTxt:SetShadowColor(0, 0, 0, 1)
    forceCB:SetScript("OnClick", function(self) Ven.InitHeroDB()[forceDbKey] = self:GetChecked() end)

    _G[drop:GetName().."Button"]:SetScript("OnClick", function() ToggleSoundMenu(dbKey, drop, defaultIdx, soundList, forceCB) end)
    drop:HookScript("OnShow", function(self)
        local idx = Ven.InitHeroDB()[dbKey] or defaultIdx
        if not soundList[idx] then idx = defaultIdx end
        _G[self:GetName().."Text"]:SetText(soundList[idx].name); forceCB:SetChecked(Ven.InitHeroDB()[forceDbKey] or false)
        if idx == 1 then forceCB:SetAlpha(0.3); forceCB:Disable() else forceCB:SetAlpha(1); forceCB:Enable() end
    end)
end

CreateHeader(panel1, "Radar Settings", -15)
CreateCheck(panel1, "Track Enemies Targeting You (Open World)", "trackTargetsWorld", -35, true)
CreateCheck(panel1, "Track Friendly Players Targeting You (Open World)", "trackAlliesWorld", -65, false)
CreateCheck(panel1, "Track Enemies Targeting You (Battlegrounds & Arenas)", "trackTargetsInst", -95, true)
CreateCheck(panel1, "Track Friendly Players Targeting You (Battlegrounds & Arenas)", "trackAlliesInst", -125, false)
CreateCheck(panel1, "Include Party/Raid Members", "trackGroupMembers", -155, false)
CreateHeader(panel1, "Audio Alerts", -195)
CreateSoundDrop(panel1, "Enemy Targeting You:", "targetSoundIdx", "targetForceBG", -220, 2, Ven.soundList)
CreateSoundDrop(panel1, "Friendly Targeting You:", "friendlySoundIdx", "friendlyForceBG", -260, 14, Ven.soundList)

CreateHeader(panel2, "Radar Settings", -15)
CreateCheck(panel2, "Track Wanted Players (Open World)", "trackWantedsWorld", -35, true)
CreateCheck(panel2, "Track Wanted Players (Battlegrounds/Arenas)", "trackWantedsInst", -65, true)
CreateHeader(panel2, "Audio Alerts", -105)
CreateSoundDrop(panel2, "Wanted Player Spotted:", "wantedSoundIdx", "wantedForceBG", -130, 3, Ven.soundList)
CreateSoundDrop(panel2, "Wanted Player Killed:", "wantedKillSoundIdx", "wantedKillForceBG", -170, 3, Ven.killSoundList)

CreateHeader(panel3, "Bounty Network", -15)
CreateCheck(panel3, "Enable Bounty Network", "enableNetwork", -35, false)
CreateCheck(panel3, "Track Bounties", "trackNetworkBounties", -65, true)
CreateCheck(panel3, "Track Whitelist Wanteds", "trackNetworkWanteds", -95, true)

local openWlBtn = CreateFrame("Button", nil, panel3, "UIPanelButtonTemplate")
openWlBtn:SetSize(150, 22); openWlBtn:SetPoint("TOPLEFT", 25, -125)
openWlBtn:SetText("Manage Whitelist")

CreateHeader(panel3, "Audio Alerts", -190)
CreateSoundDrop(panel3, "Network Bounty Spotted:", "bountySpottedSoundIdx", "bountySpottedForceBG", -215, 4, Ven.soundList)
CreateSoundDrop(panel3, "Network Bounty Killed:", "bountyKillSoundIdx", "bountyKillForceBG", -255, 3, Ven.killSoundList)
CreateHeader(panel3, "Data Management", -295)
local clearBountiesBtn = CreateFrame("Button", nil, panel3, "UIPanelButtonTemplate")
clearBountiesBtn:SetSize(180, 22); clearBountiesBtn:SetPoint("TOPLEFT", 25, -315)
clearBountiesBtn:SetText("Clear Network Data")
clearBountiesBtn:SetScript("OnClick", function() StaticPopup_Show("VENDETTA_CONFIRM_CLEAR_BOUNTIES") end)

CreateHeader(panel4, "General & UI Settings", -15)
CreateCheck(panel4, "Hide Tracker UI During Combat", "hideInCombat", -35, false)
CreateCheck(panel4, "Enable Radar in Safe Zones (e.g. Cities)", "trackInSafeZones", -65, false)
CreateCheck(panel4, "Ignore Kills/Deaths inside Battlegrounds", "ignoreInstKills", -95, true)
CreateCheck(panel4, "Use Server Time (ST) for UI", "useServerTime", -125, true, "Display all times and dates according to Realm Server Time.")
CreateCheck(panel4, "Hide Minimap Button Completely", "hideMinimapBtn", -155, false, "Hide the minimap button completely.")


local wlFrame = CreateFrame("Frame", "Ven_WhitelistFrame", UIParent, "BackdropTemplate")
Ven.WhitelistFrame = wlFrame
wlFrame:SetSize(300, 340)
wlFrame:SetPoint("CENTER", 50, 0)
wlFrame:SetFrameStrata("FULLSCREEN_DIALOG")
wlFrame:SetMovable(true); wlFrame:EnableMouse(true)
wlFrame:RegisterForDrag("LeftButton"); wlFrame:SetScript("OnDragStart", wlFrame.StartMoving); wlFrame:SetScript("OnDragStop", wlFrame.StopMovingOrSizing)
wlFrame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1})
wlFrame:SetBackdropColor(0.05, 0.05, 0.05, 0.95); wlFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.9)
wlFrame:Hide()

wlFrame.title = wlFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
wlFrame.title:SetPoint("TOP", 0, -10); wlFrame.title:SetText("Whitelist Manager")
local wlClose = CreateFrame("Button", nil, wlFrame, "UIPanelCloseButton"); wlClose:SetPoint("TOPRIGHT", -2, -2)

openWlBtn:SetScript("OnClick", function()
    if wlFrame:IsShown() then wlFrame:Hide() else wlFrame:Show() end
end)

local wlNameBox = CreateFrame("EditBox", "VenWlNameBox", wlFrame, "InputBoxTemplate")
wlNameBox:SetSize(90, 20); wlNameBox:SetPoint("TOPLEFT", 15, -45); wlNameBox:SetAutoFocus(false)
local wlNameLbl = wlFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
wlNameLbl:SetPoint("BOTTOMLEFT", wlNameBox, "TOPLEFT", 0, 3); wlNameLbl:SetText("Name:")

local wlNoteBox = CreateFrame("EditBox", "VenWlNoteBox", wlFrame, "InputBoxTemplate")
wlNoteBox:SetSize(100, 20); wlNoteBox:SetPoint("LEFT", wlNameBox, "RIGHT", 15, 0); wlNoteBox:SetAutoFocus(false)
wlNoteBox:SetMaxLetters(15)
local wlNoteLbl = wlFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
wlNoteLbl:SetPoint("BOTTOMLEFT", wlNoteBox, "TOPLEFT", 0, 3); wlNoteLbl:SetText("Note (Max 15):")

local wlAddBtn = CreateFrame("Button", nil, wlFrame, "UIPanelButtonTemplate")
wlAddBtn:SetSize(50, 22); wlAddBtn:SetPoint("LEFT", wlNoteBox, "RIGHT", 10, 0); wlAddBtn:SetText("Add")

local wlDiv = wlFrame:CreateTexture(nil, "BACKGROUND")
wlDiv:SetSize(270, 1); wlDiv:SetPoint("TOP", 0, -75); wlDiv:SetColorTexture(0.4, 0.4, 0.4, 0.7)

local hName = wlFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
hName:SetPoint("TOPLEFT", 15, -85); hName:SetText("Player Name")
local hNote = wlFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
hNote:SetPoint("TOPLEFT", 125, -85); hNote:SetText("Whitelist Note")

local wlScroll = CreateFrame("ScrollFrame", "VenWlScrollFrame", wlFrame, "FauxScrollFrameTemplate")
wlScroll:SetPoint("TOPLEFT", 5, -105); wlScroll:SetPoint("BOTTOMRIGHT", -25, 10)

local wlRows = {}
for i=1, 8 do
    local r = CreateFrame("Frame", nil, wlFrame)
    r:SetSize(250, 24); r:SetPoint("TOPLEFT", 15, -105 - ((i-1)*24))
    
    r.nameTxt = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    r.nameTxt:SetPoint("LEFT", 0, 0); r.nameTxt:SetWidth(100); r.nameTxt:SetJustifyH("LEFT")
    
    r.noteTxt = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    r.noteTxt:SetPoint("LEFT", 110, 0); r.noteTxt:SetWidth(110); r.noteTxt:SetJustifyH("LEFT")
    r.noteTxt:SetWordWrap(false)
    
    r.delBtn = CreateFrame("Button", nil, r)
    r.delBtn:SetSize(16, 16); r.delBtn:SetPoint("RIGHT", 0, 0)
    r.delBtn:SetNormalTexture("Interface\\BUTTONS\\UI-GroupLoot-Pass-Up")
    r.delBtn:SetHighlightTexture("Interface\\BUTTONS\\UI-GroupLoot-Pass-Highlight", "ADD")
    r.delBtn:SetScript("OnClick", function(self)
        local n = self:GetParent().playerName
        if n then
            local db = Ven.InitHeroDB()
            if db.whitelistData then db.whitelistData[n] = nil end
            Ven.UpdateWhitelistString(); Ven.RefreshWhitelistView()
        end
    end)
    
    local line = r:CreateTexture(nil, "BACKGROUND")
    line:SetSize(260, 1); line:SetPoint("BOTTOMLEFT", 0, 0); line:SetColorTexture(0.2, 0.2, 0.2, 0.5)
    
    r:EnableMouseWheel(true)
    r:SetScript("OnMouseWheel", function(self, delta)
        local offset = FauxScrollFrame_GetOffset(wlScroll)
        local maxItems = Ven.numWlItems or 0
        if maxItems <= 8 then return end
        local maxOffset = maxItems - 8
        local newOffset = math.min(math.max(0, offset - delta), maxOffset)
        FauxScrollFrame_SetOffset(wlScroll, newOffset)
        local sBar = _G[wlScroll:GetName().."ScrollBar"]
        if sBar then 
            local minV, maxV = sBar:GetMinMaxValues()
            sBar:SetValue(math.min(math.max(sBar:GetValue() - (delta*24), minV or 0), maxV or 100))
        end
        Ven.RefreshWhitelistView()
    end)
    
    wlRows[i] = r
end

wlScroll:EnableMouseWheel(true)
wlScroll:SetScript("OnMouseWheel", function(self, delta) wlRows[1]:GetScript("OnMouseWheel")(wlRows[1], delta) end)
wlFrame:EnableMouseWheel(true)
wlFrame:SetScript("OnMouseWheel", function(self, delta) wlRows[1]:GetScript("OnMouseWheel")(wlRows[1], delta) end)

function Ven.UpdateWhitelistString()
    local db = Ven.InitHeroDB(); local str = ""
    if db.whitelistData then
        for k, _ in pairs(db.whitelistData) do if str == "" then str = k else str = str .. "," .. k end end
    end
    db.whitelist = str
end

function Ven.RefreshWhitelistView()
    local db = Ven.InitHeroDB(); db.whitelistData = db.whitelistData or {}
    local wlStr = db.whitelist or ""
    if wlStr ~= "" and not db.whitelistMigrated then
        for wName in string.gmatch(wlStr, "([^,%s]+)") do
            wName = string.upper(string.sub(wName, 1, 1)) .. string.lower(string.sub(wName, 2))
            if not db.whitelistData[wName] then db.whitelistData[wName] = "" end
        end
        db.whitelistMigrated = true; Ven.UpdateWhitelistString()
    end
    
    local sorted = {}
    for k, v in pairs(db.whitelistData) do table.insert(sorted, {name=k, note=v}) end
    table.sort(sorted, function(a,b) return a.name < b.name end)
    
    Ven.numWlItems = #sorted
    FauxScrollFrame_Update(wlScroll, #sorted, 8, 24)
    local offset = FauxScrollFrame_GetOffset(wlScroll)
    
    for i=1, 8 do
        local r = wlRows[i]; local idx = offset + i
        if sorted[idx] then
            r.playerName = sorted[idx].name; r.nameTxt:SetText(sorted[idx].name)
            r.noteTxt:SetText(sorted[idx].note and sorted[idx].note ~= "" and "|cFF00FFFF" .. sorted[idx].note .. "|r" or "")
            r:Show()
        else r:Hide() end
    end
end

wlScroll:SetScript("OnVerticalScroll", function(self, offset) FauxScrollFrame_OnVerticalScroll(self, offset, 24, Ven.RefreshWhitelistView) end)

wlAddBtn:SetScript("OnClick", function()
    local n = wlNameBox:GetText()
    local note = string.sub(wlNoteBox:GetText() or "", 1, 15)
    if n and n ~= "" then
        n = string.upper(string.sub(n, 1, 1)) .. string.lower(string.sub(n, 2))
        local db = Ven.InitHeroDB(); db.whitelistData = db.whitelistData or {}
        db.whitelistData[n] = note; Ven.UpdateWhitelistString()
        wlNameBox:SetText(""); wlNoteBox:SetText("")
        wlNameBox:ClearFocus(); wlNoteBox:ClearFocus()
        Ven.RefreshWhitelistView()
    end
end)

wlNameBox:SetScript("OnEnterPressed", function(self) wlAddBtn:Click() end)
wlNoteBox:SetScript("OnEnterPressed", function(self) wlAddBtn:Click() end)
wlFrame:SetScript("OnShow", function() Ven.RefreshWhitelistView() end)