-- BlueShift: puts the blue Battle.net notifications (BNToastFrame: friend online or offline,
-- broadcasts, friend requests) where the user wants them and keeps them there.
--
-- Blizzard anchors the toast above the chat frame every time it lays out its chat alerts.
-- A hook on the toast's SetPoint moves it to the saved position right afterwards. Unlocked,
-- a stand-in of the toast's size can be dragged around; where it is dropped becomes the
-- position, saved in BlueShiftDB.pos as the offset of the bottom left corner on the screen.

local ADDON = ...

-- English everywhere, German on German clients
local L = {
	MOVER_TITLE = "Battle.net notifications",
	MOVER_HINT = "Drag to move, right click to lock",
	UNLOCKED = "Position unlocked. Drag the blue box to where the notifications should appear, then right click it or type /blueshift to lock it.",
	LOCKED = "Position locked.",
	RESET = "Position reset. The notifications appear above the chat again.",
	USAGE = "/blueshift (unlock or lock) | unlock | lock | reset",
	OPT_HEADER = "Position of the Battle.net notifications",
	OPT_UNLOCK = "Unlock position",
	OPT_UNLOCK_TIP = "Shows a blue box where the Battle.net notifications appear (friend online, broadcasts, friend requests). Close the options and drag the box to the place you want. Uncheck this, or right click the box, to lock the position.",
	OPT_RESET = "Default position",
	OPT_RESET_BUTTON = "Reset",
	OPT_RESET_TIP = "Puts the notifications back above the chat, where the game shows them by default.",
}
if GetLocale() == "deDE" then
	L.MOVER_TITLE = "Battle.net-Benachrichtigungen"
	L.MOVER_HINT = "Ziehen zum Verschieben, Rechtsklick fixiert"
	L.UNLOCKED = "Position entsperrt. Zieh den blauen Kasten dorthin, wo die Benachrichtigungen erscheinen sollen, und fixiere ihn mit Rechtsklick oder /blueshift."
	L.LOCKED = "Position fixiert."
	L.RESET = "Position zurückgesetzt. Die Benachrichtigungen erscheinen wieder über dem Chat."
	L.USAGE = "/blueshift (entsperren oder fixieren) | unlock | lock | reset"
	L.OPT_HEADER = "Position der Battle.net-Benachrichtigungen"
	L.OPT_UNLOCK = "Position entsperren"
	L.OPT_UNLOCK_TIP = "Zeigt einen blauen Kasten an der Stelle, an der die Battle.net-Benachrichtigungen erscheinen (Freund online, Rundnachrichten, Freundschaftsanfragen). Schließ die Optionen und zieh den Kasten an die gewünschte Stelle. Nimm den Haken wieder heraus oder klick mit rechts auf den Kasten, um die Position zu fixieren."
	L.OPT_RESET = "Standardposition"
	L.OPT_RESET_BUTTON = "Zurücksetzen"
	L.OPT_RESET_TIP = "Setzt die Benachrichtigungen zurück über den Chat, wo das Spiel sie von sich aus zeigt."
end

local db -- BlueShiftDB: pos = { x, y } of the toast's bottom left corner, nil for Blizzard's place
local mover
local applying = false

local function Print(text)
	DEFAULT_CHAT_FRAME:AddMessage("|cff82c5ffBlueShift:|r " .. text)
end

local function ApplyPosition()
	if not db.pos or not BNToastFrame then
		return
	end
	-- Keep it on screen when the resolution or the UI scale has changed since it was saved
	local x = math.max(0, math.min(db.pos.x, UIParent:GetWidth() - BNToastFrame:GetWidth()))
	local y = math.max(0, math.min(db.pos.y, UIParent:GetHeight() - BNToastFrame:GetHeight()))
	applying = true
	BNToastFrame:ClearAllPoints()
	BNToastFrame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y)
	applying = false
end

local function IsUnlocked()
	return mover ~= nil and mover:IsShown()
end

-- The checkbox on the options page follows when the state changes by command or click
local function UpdateOptions()
	if Settings and Settings.NotifyUpdate then
		Settings.NotifyUpdate("BLUESHIFT_UNLOCK")
	end
end

local function Lock()
	if IsUnlocked() then
		mover:Hide()
		UpdateOptions()
		Print(L.LOCKED)
	end
end

-- The stand-in looks like the toast (same size and backdrop) and saves where it is dropped
local function CreateMover()
	local frame = CreateFrame("Frame", "BlueShiftMover", UIParent, "BackdropTemplate")
	frame:SetSize(250, 50)
	frame:SetFrameStrata("DIALOG")
	frame:SetBackdrop(BACKDROP_TOAST_12_12)
	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title:SetPoint("TOP", 0, -10)
	title:SetTextColor(0.51, 0.773, 1)
	title:SetText(L.MOVER_TITLE)
	local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	hint:SetPoint("BOTTOM", 0, 10)
	hint:SetText(L.MOVER_HINT)
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		-- The position is ours to save; keep the client from storing it in its layout cache
		self:SetUserPlaced(false)
		db.pos = { x = self:GetLeft(), y = self:GetBottom() }
		ApplyPosition()
	end)
	frame:SetScript("OnMouseUp", function(_, button)
		if button == "RightButton" then
			Lock()
		end
	end)
	return frame
end

local function Unlock()
	if IsUnlocked() then
		return
	end
	mover = mover or CreateMover()
	mover:ClearAllPoints()
	if db.pos then
		mover:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", db.pos.x, db.pos.y)
	elseif ChatAlertFrame and ChatAlertFrame:GetLeft() then
		-- Where Blizzard's layout starts
		mover:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", ChatAlertFrame:GetLeft(), ChatAlertFrame:GetBottom())
	else
		mover:SetPoint("CENTER")
	end
	mover:Show()
	UpdateOptions()
	Print(L.UNLOCKED)
end

local function Reset()
	db.pos = nil
	if mover then
		mover:Hide()
		UpdateOptions()
	end
	-- Blizzard lays the toast out again, now without our correction
	if ChatAlertFrame then
		ChatAlertFrame:UpdateAnchors()
	end
	Print(L.RESET)
end

SLASH_BLUESHIFT1 = "/blueshift"
SlashCmdList.BLUESHIFT = function(msg)
	if not db then
		return
	end
	local cmd = (msg or ""):lower():match("^%s*(.-)%s*$")
	if cmd == "" then
		if IsUnlocked() then
			Lock()
		else
			Unlock()
		end
	elseif cmd == "unlock" then
		Unlock()
	elseif cmd == "lock" then
		Lock()
	elseif cmd == "reset" then
		Reset()
	else
		Print(L.USAGE)
	end
end

local function RegisterOptions()
	local category, layout = Settings.RegisterVerticalLayoutCategory("BlueShift")
	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L.OPT_HEADER))
	local setting = Settings.RegisterProxySetting(category, "BLUESHIFT_UNLOCK", Settings.VarType.Boolean,
		L.OPT_UNLOCK, false, IsUnlocked, function(value)
			if value then
				Unlock()
			else
				Lock()
			end
		end)
	Settings.CreateCheckbox(category, setting, L.OPT_UNLOCK_TIP)
	layout:AddInitializer(CreateSettingsButtonInitializer(L.OPT_RESET, L.OPT_RESET_BUTTON, Reset, L.OPT_RESET_TIP, true))
	Settings.RegisterAddOnCategory(category)
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(self, event, arg1)
	if event == "ADDON_LOADED" then
		if arg1 == ADDON then
			self:UnregisterEvent("ADDON_LOADED")
			if type(BlueShiftDB) ~= "table" then
				BlueShiftDB = {}
			end
			db = BlueShiftDB
			if type(db.pos) ~= "table" or type(db.pos.x) ~= "number" or type(db.pos.y) ~= "number" then
				db.pos = nil
			end
			if Settings and Settings.RegisterProxySetting then
				RegisterOptions()
			end
		end
	elseif event == "PLAYER_LOGIN" then
		if BNToastFrame then
			-- Runs after every anchoring by Blizzard; our own SetPoint must not loop
			hooksecurefunc(BNToastFrame, "SetPoint", function()
				if not applying then
					ApplyPosition()
				end
			end)
			ApplyPosition()
		end
	end
end)
