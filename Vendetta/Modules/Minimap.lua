local addonName, Ven = ...

local Ven_MinimapBtn = CreateFrame("Button", "VendettaMinimapButton", Minimap)
Ven_MinimapBtn:SetSize(32, 32)
Ven_MinimapBtn:SetFrameStrata("MEDIUM")
Ven_MinimapBtn:SetFrameLevel(8)
Ven_MinimapBtn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

local Ven_MinimapIcon = Ven_MinimapBtn:CreateTexture(nil, "BACKGROUND")
Ven_MinimapIcon:SetTexture("Interface\\AddOns\\Vendetta\\Vendetta.tga")
Ven_MinimapIcon:SetSize(20, 20)
Ven_MinimapIcon:SetPoint("CENTER", 0, 0)

local Ven_MinimapBorder = Ven_MinimapBtn:CreateTexture(nil, "OVERLAY")
Ven_MinimapBorder:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
Ven_MinimapBorder:SetSize(54, 54)
Ven_MinimapBorder:SetPoint("TOPLEFT", 0, 0)

local function UpdateMinimapButtonPosition()
    local db = Ven.InitHeroDB()
    local angle = db.minimapAngle or 45
    local radius = 80
    local x = math.cos(math.rad(angle)) * radius
    local y = math.sin(math.rad(angle)) * radius
    Ven_MinimapBtn:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

Ven_MinimapBtn:RegisterForClicks("AnyUp")
Ven_MinimapBtn:RegisterForDrag("LeftButton")

Ven_MinimapBtn:SetScript("OnDragStart", function(self)
    self:LockHighlight()
    self:SetScript("OnUpdate", function()
        local cx, cy = GetCursorPosition()
        local mx, my = Minimap:GetCenter()
        local scale = Minimap:GetEffectiveScale()
        cx, cy = cx / scale, cy / scale
        local dx, dy = cx - mx, cy - my
        local db = Ven.InitHeroDB()
        db.minimapAngle = math.deg(math.atan2(dy, dx))
        UpdateMinimapButtonPosition()
    end)
end)

Ven_MinimapBtn:SetScript("OnDragStop", function(self)
    self:UnlockHighlight()
    self:SetScript("OnUpdate", nil)
end)

Ven_MinimapBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("|cFF880000Vendetta|r")
    GameTooltip:AddLine("|cFFFFFFFFLeft Click:|r Toggle Tracker")
    GameTooltip:AddLine("|cFFFFFFFFRight Click:|r Toggle Database")
    GameTooltip:AddLine("|cFFFFFFFFShift + Left Click:|r Enable/Disable Addon")
    GameTooltip:AddLine("|cFFFFFFFFShift + Right Click:|r Toggle Normal/Wanted Mode")
    GameTooltip:Show()
end)
Ven_MinimapBtn:SetScript("OnLeave", function(self) GameTooltip:Hide() end)

Ven_MinimapBtn:SetScript("OnClick", function(self, button)
    local db = Ven.InitHeroDB()
    if IsShiftKeyDown() then
        if button == "LeftButton" then
            if db.trackerModeWorld == 3 then
                db.trackerModeWorld = 1; db.trackerModeInst = 1
                UIErrorsFrame:AddMessage("Vendetta: Addon ENABLED", 1, 1, 0, 1)
            else
                db.trackerModeWorld = 3; db.trackerModeInst = 3
                UIErrorsFrame:AddMessage("Vendetta: Addon DISABLED", 1, 0, 0, 1)
            end
        elseif button == "RightButton" then
            if db.trackerModeWorld == 1 then
                db.trackerModeWorld = 2; db.trackerModeInst = 2
                UIErrorsFrame:AddMessage("Vendetta Mode: WANTED ONLY", 1, 0.5, 0, 1)
            else
                db.trackerModeWorld = 1; db.trackerModeInst = 1
                UIErrorsFrame:AddMessage("Vendetta Mode: NORMAL", 0, 1, 0, 1)
            end
        end
        if Ven.DBFrame and Ven.DBFrame:IsShown() and Ven.RefreshDBView then Ven.RefreshDBView() end
        if Ven.UpdateTrackerUI then Ven.UpdateTrackerUI() end
    else
        if button == "LeftButton" then
            Ven.isTrackerHidden = not Ven.isTrackerHidden
            db.isTrackerHidden = Ven.isTrackerHidden
            if not Ven.isTrackerHidden then 
                if Ven.UpdateTrackerUI then Ven.UpdateTrackerUI() end
                UIErrorsFrame:AddMessage("Vendetta Tracker: Shown", 1, 1, 0, 1)
            else 
                if Ven.TrackerFrame then Ven.TrackerFrame:Hide() end
                UIErrorsFrame:AddMessage("Vendetta Tracker: Hidden", 1, 0, 0, 1)
            end
        elseif button == "RightButton" then
            if Ven.DBFrame and Ven.DBFrame:IsShown() then Ven.DBFrame:Hide() 
            else if Ven.RefreshDBView then Ven.RefreshDBView() end; if Ven.DBFrame then Ven.DBFrame:Show() end end
        end
    end
end)

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", UpdateMinimapButtonPosition)