-- BlueShift: puts the blue notifications (Battle.net toasts such as friend online or offline,
-- broadcasts and friend requests, the voice chat prompts, the play time alert and the layer
-- change warning) where the user wants them and keeps them there.
--
-- Blizzard stacks the toasts above the chat frame every time it lays out its chat alerts.
-- A hook on that layout moves the lowest visible blue one to the saved position right
-- afterwards; the others stay stacked on it. The layer change warning is not part of that
-- stack: Blizzard anchors it once, so it has a position of its own. Unlocked, a stand-in for
-- each of the two can be dragged around; where it is dropped becomes the position, saved in
-- BlueShiftDB.pos and BlueShiftDB.layerPos as the offset of the bottom left corner on the screen.

local ADDON = ...

-- English everywhere, German on German clients
local L = {
	MOVER_TITLE = "Blue notifications",
	MOVER_LAYER = "Layer change warning",
	MOVER_HINT = "Drag to move, right click to lock",
	UNLOCKED = "Positions unlocked. Drag the two blue boxes to where the notifications and the layer change warning should appear, then right click one or type /blueshift to lock them.",
	LOCKED = "Positions locked.",
	RESET = "Positions reset. The notifications appear above the chat again.",
	USAGE = "/blueshift (unlock or lock) | unlock | lock | reset",
	OPT_HEADER = "Position of the blue notifications",
	OPT_UNLOCK = "Unlock positions",
	OPT_UNLOCK_TIP = "Shows two blue boxes: one where the blue notifications appear (friend online, broadcasts, friend requests), one for the layer change warning. Close the options and drag each box to the place you want. Uncheck this, or right click a box, to lock the positions.",
	OPT_RESET = "Default positions",
	OPT_RESET_BUTTON = "Reset",
	OPT_RESET_TIP = "Puts the notifications and the layer change warning back above the chat, where the game shows them by default.",
}
if GetLocale() == "deDE" then
	L.MOVER_TITLE = "Blaue Benachrichtigungen"
	L.MOVER_LAYER = "Hinweis auf Layer-Wechsel"
	L.MOVER_HINT = "Ziehen zum Verschieben, Rechtsklick fixiert"
	L.UNLOCKED = "Positionen entsperrt. Zieh die beiden blauen Kästen dorthin, wo die Benachrichtigungen und der Hinweis auf den Layer-Wechsel erscheinen sollen, und fixiere sie mit Rechtsklick oder /blueshift."
	L.LOCKED = "Positionen fixiert."
	L.RESET = "Positionen zurückgesetzt. Die Benachrichtigungen erscheinen wieder über dem Chat."
	L.USAGE = "/blueshift (entsperren oder fixieren) | unlock | lock | reset"
	L.OPT_HEADER = "Position der blauen Benachrichtigungen"
	L.OPT_UNLOCK = "Positionen entsperren"
	L.OPT_UNLOCK_TIP = "Zeigt zwei blaue Kästen: einen an der Stelle, an der die blauen Benachrichtigungen erscheinen (Freund online, Rundnachrichten, Freundschaftsanfragen), einen für den Hinweis auf den Layer-Wechsel. Schließ die Optionen und zieh jeden Kasten an die gewünschte Stelle. Nimm den Haken wieder heraus oder klick mit rechts auf einen Kasten, um die Positionen zu fixieren."
	L.OPT_RESET = "Standardpositionen"
	L.OPT_RESET_BUTTON = "Zurücksetzen"
	L.OPT_RESET_TIP = "Setzt die Benachrichtigungen und den Hinweis auf den Layer-Wechsel zurück über den Chat, wo das Spiel sie von sich aus zeigt."
end

-- The blue toasts in Blizzard's chat alert stack, lowest first
local TOASTS = {
	"BNToastFrame",
	"TimeAlertFrame",
	"VoiceChatPromptActivateChannel",
	"VoiceChatChannelActivatedNotification",
}
-- Where Blizzard anchors the layer change warning, relative to the top left of ChatAlertFrame
local LAYER_DEFAULT_X, LAYER_DEFAULT_Y = 30, 55
-- Its minimize button hangs out to the left of it (24 wide, 5 apart)
local LAYER_MIN_X = 29

-- BlueShiftDB: pos and layerPos = { x, y } of the bottom left corner of the toasts and of the
-- layer change warning, nil for Blizzard's place
local db
local mover, layerMover

local function Print(text)
	DEFAULT_CHAT_FRAME:AddMessage("|cff82c5ffBlueShift:|r " .. text)
end

-- Keeps it on screen when the resolution or the UI scale has changed since the position was saved
local function Place(frame, pos, minX)
	local x = math.max(minX or 0, math.min(pos.x, UIParent:GetWidth() - frame:GetWidth()))
	local y = math.max(0, math.min(pos.y, UIParent:GetHeight() - frame:GetHeight()))
	frame:ClearAllPoints()
	frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y)
end

local function ApplyPosition()
	if db.pos then
		-- Blizzard has anchored every other visible toast onto the one below it
		for _, name in ipairs(TOASTS) do
			local toast = _G[name]
			if toast and toast:IsShown() then
				Place(toast, db.pos)
				break
			end
		end
	end
	if db.layerPos and ShardTransferImminentFrame then
		Place(ShardTransferImminentFrame, db.layerPos, LAYER_MIN_X)
	end
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
		layerMover:Hide()
		UpdateOptions()
		Print(L.LOCKED)
	end
end

-- The stand-in moved last lies on top of the other and hides what it covers of it. That takes
-- different frame levels: on the same level the texts of both would be drawn over both boxes.
local function BringToFront(frame)
	for _, other in ipairs({ mover, layerMover }) do
		other:SetFrameLevel(other == frame and 20 or 10)
	end
end

-- A stand-in looks like the toast (same size and backdrop) and saves where it is dropped
-- under the given key of the saved variables
local function CreateMover(name, title, key, minX)
	local frame = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
	frame:SetSize(250, 50)
	frame:SetFrameStrata("DIALOG")
	frame:SetBackdrop(BACKDROP_TOAST_12_12)
	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	-- Opaque, so that where the two stand-ins overlap only the upper one is seen
	local fill = frame:CreateTexture(nil, "BACKGROUND")
	fill:SetPoint("TOPLEFT", 3, -3)
	fill:SetPoint("BOTTOMRIGHT", -3, 3)
	fill:SetColorTexture(0.02, 0.05, 0.12, 1)
	local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	text:SetPoint("TOP", 0, -10)
	text:SetTextColor(0.51, 0.773, 1)
	text:SetText(title)
	local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	hint:SetPoint("BOTTOM", 0, 10)
	hint:SetText(L.MOVER_HINT)
	frame:SetScript("OnDragStart", function(self)
		BringToFront(self)
		self:StartMoving()
	end)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		-- The position is ours to save; keep the client from storing it in its layout cache
		self:SetUserPlaced(false)
		local x, y = math.max(minX or 0, self:GetLeft()), self:GetBottom()
		db[key] = { x = x, y = y }
		self:ClearAllPoints()
		self:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y)
		ApplyPosition()
	end)
	frame:SetScript("OnMouseUp", function(_, button)
		if button == "RightButton" then
			Lock()
		end
	end)
	return frame
end

-- A stand-in starts at the saved position or else where Blizzard shows the real thing
local function ShowMover(frame, pos, x, y)
	frame:ClearAllPoints()
	if pos then
		frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", pos.x, pos.y)
	elseif x and y then
		frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y)
	else
		frame:SetPoint("CENTER")
	end
	frame:Show()
end

local function Unlock()
	if IsUnlocked() then
		return
	end
	mover = mover or CreateMover("BlueShiftMover", L.MOVER_TITLE, "pos")
	if not layerMover then
		layerMover = CreateMover("BlueShiftLayerMover", L.MOVER_LAYER, "layerPos", LAYER_MIN_X)
		BringToFront(layerMover)
	end
	local left, bottom, top
	if ChatAlertFrame and ChatAlertFrame:GetLeft() then
		left, bottom, top = ChatAlertFrame:GetLeft(), ChatAlertFrame:GetBottom(), ChatAlertFrame:GetTop()
	end
	ShowMover(mover, db.pos, left, bottom)
	ShowMover(layerMover, db.layerPos, left and left + LAYER_DEFAULT_X, top and top + LAYER_DEFAULT_Y)
	UpdateOptions()
	Print(L.UNLOCKED)
end

local function Reset()
	db.pos = nil
	db.layerPos = nil
	if mover then
		mover:Hide()
		layerMover:Hide()
		UpdateOptions()
	end
	-- Blizzard lays the toasts out again, now without our correction
	if ChatAlertFrame then
		ChatAlertFrame:UpdateAnchors()
		if ShardTransferImminentFrame then
			-- Anchored only once by Blizzard, when it loads
			ShardTransferImminentFrame:ClearAllPoints()
			ShardTransferImminentFrame:SetPoint("BOTTOMLEFT", ChatAlertFrame, "TOPLEFT", LAYER_DEFAULT_X, LAYER_DEFAULT_Y)
		end
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
			for _, key in ipairs({ "pos", "layerPos" }) do
				local pos = db[key]
				if type(pos) ~= "table" or type(pos.x) ~= "number" or type(pos.y) ~= "number" then
					db[key] = nil
				end
			end
			if Settings and Settings.RegisterProxySetting then
				RegisterOptions()
			end
		end
	elseif event == "PLAYER_LOGIN" then
		if ChatAlertFrame then
			-- Runs after every layout by Blizzard, which happens whenever a toast shows or hides
			hooksecurefunc(ChatAlertFrame, "UpdateAnchors", ApplyPosition)
			ApplyPosition()
		end
	end
end)
