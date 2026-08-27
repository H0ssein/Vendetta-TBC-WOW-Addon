local addonName, Ven = ...

local MAX_TOASTS = 3
local toastPool = {}
local activeToasts = {}

local mover = CreateFrame("Button", "VendettaToastMover", UIParent, "BackdropTemplate")
mover:SetSize(280, 65)
mover:SetPoint("TOP", UIParent, "TOP", 0, -100)
mover:SetMovable(true)
mover:EnableMouse(true)
mover:EnableMouseWheel(true)
mover:RegisterForDrag("LeftButton")
mover:SetFrameStrata("MEDIUM")
mover:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
mover:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
mover:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

local mIcon = mover:CreateTexture(nil, "ARTWORK")
mIcon:SetSize(40, 40)
mIcon:SetPoint("LEFT", 10, 0)
mIcon:SetTexture("Interface\\TargetingFrame\\UI-Classes-Circles")
mIcon:SetTexCoord(unpack(CLASS_ICON_TCOORDS["ROGUE"]))

local mTitle = mover:CreateFontString(nil, "OVERLAY", "GameFontNormal")
mTitle:SetPoint("TOPLEFT", mIcon, "TOPRIGHT", 10, 0)
mTitle:SetPoint("RIGHT", -10, 0)
mTitle:SetJustifyH("LEFT")
mTitle:SetText("TARGET SPOTTED")

local mMsg = mover:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
mMsg:SetPoint("TOPLEFT", mTitle, "BOTTOMLEFT", 0, -4)
mMsg:SetPoint("RIGHT", -10, 0)
mMsg:SetJustifyH("LEFT")
mMsg:SetWordWrap(true)
mMsg:SetText("Drag: Move | Scroll: Resize | R-Click: Border\nShift+Scroll: Opacity | ESC to save")

mover:SetScript("OnDragStart", mover.StartMoving)
mover:SetScript("OnDragStop", function(self)
	self:StopMovingOrSizing()
	local db = Ven.InitHeroDB()
	local point, relativeTo, relativePoint, xOfs, yOfs = self:GetPoint()
	db.toastAnchor = point
	db.toastX = xOfs
	db.toastY = yOfs
end)

mover:SetScript("OnMouseWheel", function(self, delta)
	local db = Ven.InitHeroDB()
	if IsShiftKeyDown() then
		local bg = db.toastBgColor or { r=0.05, g=0.05, b=0.05, a=0.95 }
		local newAlpha = bg.a + (delta * 0.05)
		if newAlpha < 0.1 then newAlpha = 0.1 end
		if newAlpha > 1.0 then newAlpha = 1.0 end
		bg.a = newAlpha
		db.toastBgColor = bg
		self:SetBackdropColor(bg.r, bg.g, bg.b, bg.a)
	else
		local currentScale = db.toastScale or 1.0
		local newScale = currentScale + (delta * 0.05)
		if newScale < 0.5 then newScale = 0.5 end
		if newScale > 2.5 then newScale = 2.5 end
		db.toastScale = newScale
		self:SetScale(newScale)
	end
end)

mover:SetScript("OnMouseUp", function(self, btn)
	if btn == "RightButton" then
		local db = Ven.InitHeroDB()
		local bc = db.toastBorderColor or { r=0.3, g=0.3, b=0.3, a=1.0 }
		if bc.a > 0 then
			bc.a = 0
		else
			bc.a = 1.0
		end
		db.toastBorderColor = bc
		self:SetBackdropBorderColor(bc.r, bc.g, bc.b, bc.a)
	end
end)


mover:SetScript("OnKeyDown", function(self, key)
	if key == "ESCAPE" then
		self:SetPropagateKeyboardInput(false)
		Ven.ToggleToastMover()
		if VendettaOptionsFrame then VendettaOptionsFrame:Show() end
	else
		self:SetPropagateKeyboardInput(true)
	end
end)
mover:Hide()

local function UpdateMoverPosition()
	local db = Ven.InitHeroDB()
	mover:ClearAllPoints()
	mover:SetPoint(db.toastAnchor or "TOP", UIParent, db.toastAnchor or "TOP", db.toastX or 0, db.toastY or -90)
	mover:SetScale(db.toastScale or 1.0)
	local bg = db.toastBgColor or { r=0.05, g=0.05, b=0.05, a=0.95 }
	local bc = db.toastBorderColor or { r=0.3, g=0.3, b=0.3, a=1.0 }
	mover:SetBackdropColor(bg.r, bg.g, bg.b, bg.a)
	mover:SetBackdropBorderColor(bc.r, bc.g, bc.b, bc.a)
end

function Ven.ToggleToastMover()
	if mover:IsShown() then
		mover:EnableKeyboard(false)
		mover:Hide()
	else
		UpdateMoverPosition()
		mover:Show()
		mover:EnableKeyboard(true)
	end
end

function Ven.ResetToastSettings()
	local db = Ven.InitHeroDB()
	db.toastDuration = 5.0
	db.toastScale = 1.0
	db.toastBgColor = { r = 0.05, g = 0.05, b = 0.05, a = 0.95 }
	db.toastBorderColor = { r = 0.3, g = 0.3, b = 0.3, a = 1.0 }
	db.toastAnchor = "TOP"
	db.toastX = 0
	db.toastY = -90
	UpdateMoverPosition()
	Ven.ShowToast("Settings Reset", "Notification settings restored to default.")
end

local function GetAvailableToast()
	for _, toast in ipairs(toastPool) do
		if not toast.isActive then
			return toast
		end
	end
	if #toastPool >= MAX_TOASTS then return nil end

	local f = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
	f:SetSize(280, 65)
	f:SetFrameStrata("MEDIUM")
	f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })

	local icon = f:CreateTexture(nil, "ARTWORK")
	icon:SetSize(40, 40)
	icon:SetPoint("LEFT", 10, 0)
	icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
	f.icon = icon

	local factionIcon = f:CreateTexture(nil, "OVERLAY")
	factionIcon:SetSize(32, 32)
	factionIcon:SetPoint("CENTER", icon, "BOTTOMRIGHT", 0, 4)
	f.factionIcon = factionIcon

	local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, 0)
	title:SetPoint("RIGHT", -10, 0)
	title:SetJustifyH("LEFT")
	f.title = title

	local msg = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	msg:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
	msg:SetPoint("RIGHT", -10, 0)
	msg:SetJustifyH("LEFT")
	msg:SetWordWrap(true)
	f.msg = msg

	f.ag = f:CreateAnimationGroup()
    
	local alphaIn = f.ag:CreateAnimation("Alpha")
	alphaIn:SetFromAlpha(0)
	alphaIn:SetToAlpha(1)
	alphaIn:SetDuration(0.2)
	alphaIn:SetSmoothing("OUT")

	local scaleIn = f.ag:CreateAnimation("Scale")
	scaleIn:SetScaleFrom(0.95, 0.95)
	scaleIn:SetScaleTo(1, 1)
	scaleIn:SetDuration(0.2)
	scaleIn:SetSmoothing("OUT")

	f.fadeAg = f:CreateAnimationGroup()
	local fade = f.fadeAg:CreateAnimation("Alpha")
	fade:SetFromAlpha(1)
	fade:SetToAlpha(0)
	fade:SetDuration(0.4)
	fade:SetStartDelay(5)
	f.fade = fade

	local scaleOut = f.fadeAg:CreateAnimation("Scale")
	scaleOut:SetScaleFrom(1, 1)
	scaleOut:SetScaleTo(0.8, 0.8)
	scaleOut:SetDuration(0.4)
	scaleOut:SetStartDelay(5)
	f.scaleOut = scaleOut
	f.fadeAg:SetScript("OnFinished", function()
		f.isActive = false
		f:Hide()
		for i, v in ipairs(activeToasts) do
			if v == f then
				table.remove(activeToasts, i)
				break
			end
		end
		Ven.ReanchorToasts()
	end)

	f:Hide()
	table.insert(toastPool, f)
	return f
end

function Ven.ReanchorToasts()
	local db = Ven.InitHeroDB()
	local anchor = db.toastAnchor or "TOP"
	local x = db.toastX or 0
	local y = db.toastY or -90
	local direction = string.find(anchor, "BOTTOM") and 1 or -1
	local spacing = 70 * direction

	for i, toast in ipairs(activeToasts) do
		toast:ClearAllPoints()
		local currentY = y + ((i - 1) * spacing)
		toast:SetPoint(anchor, UIParent, anchor, x, currentY)
	end
end

function Ven.ShowToast(titleText, msgText, classFile, faction)
	local db = Ven.InitHeroDB()
	if not db.enableToasts then return end

	local toast = GetAvailableToast()
	if not toast then
		local oldestIdx = #activeToasts
		toast = activeToasts[oldestIdx]
		toast.fadeAg:Stop()
		table.remove(activeToasts, oldestIdx)
	end

	toast.isActive = true
	toast:SetScale(db.toastScale or 1.0)
	
	local bg = db.toastBgColor or {r=0.05, g=0.05, b=0.05, a=0.95}
	local bd = db.toastBorderColor or {r=0.3, g=0.3, b=0.3, a=1.0}
	toast:SetBackdropColor(bg.r, bg.g, bg.b, bg.a)
	toast:SetBackdropBorderColor(bd.r, bd.g, bd.b, bd.a)

	toast.title:SetText(titleText or "Vendetta")
	toast.msg:SetText(msgText or "")
	
	if classFile and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[classFile] then
		toast.icon:SetTexture("Interface\\TargetingFrame\\UI-Classes-Circles")
		local coords = CLASS_ICON_TCOORDS[classFile]
		toast.icon:SetTexCoord(unpack(coords))
	else
		toast.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
		toast.icon:SetTexCoord(0, 1, 0, 1)
	end

	if faction == "Horde" then
		toast.factionIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-Horde")
		toast.factionIcon:Show()
	elseif faction == "Alliance" then
		toast.factionIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-Alliance")
		toast.factionIcon:Show()
	else
		toast.factionIcon:Hide()
	end

	table.insert(activeToasts, 1, toast)
	Ven.ReanchorToasts()
	
	toast:Show()
	toast.ag:Play()
	
	toast.fadeAg:Stop()
	toast.fade:SetStartDelay(db.toastDuration or 5.0)
	toast.scaleOut:SetStartDelay(db.toastDuration or 5.0)
	toast.fadeAg:Play()
end
