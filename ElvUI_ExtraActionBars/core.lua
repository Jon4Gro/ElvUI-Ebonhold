local E, L, V, P, G, _ = unpack(ElvUI)
local EAB = E:GetModule("ExtraActionBars")
local EP = LibStub("LibElvUIPlugin-1.0")
local addon, ns = ...

-- Ensure ElvUI_Bar1 exists before anchoring extra bars to it
local function GetBarAnchor()
	local bar1 = _G["ElvUI_Bar1"]
	if bar1 then
		return "BOTTOM", "ElvUI_Bar1", "TOP", 0, 82
	end
	return "BOTTOM", "UIParent", "BOTTOM", 0, 400
end

function EAB:UpdateButtonSettings()
	for i = 7, 10 do
		self.AB:PositionAndSizeBar("bar"..i)
	end
end

function EAB:CreateBars()
	-- Use fallback anchor if ElvUI_Bar1 doesn't exist yet
	local anchorPoint, anchorTarget, attachTo, xOff, yOff = GetBarAnchor()
	self.AB["barDefaults"]["bar7"] = {
		["page"] = 7,
		["bindButtons"] = "EXTRABAR7BUTTON",
		["conditions"] = "",
		["position"] = string.format("%s,%s,%s,%s,%s", anchorPoint, anchorTarget, attachTo, xOff, yOff)
	}
	self.AB["barDefaults"]["bar8"] = {
		["page"] = 8,
		["bindButtons"] = "EXTRABAR8BUTTON",
		["conditions"] = "",
		["position"] = string.format("%s,%s,%s,%s,%s", anchorPoint, anchorTarget, attachTo, xOff, yOff + 40)
	}
	self.AB["barDefaults"]["bar9"] = {
		["page"] = 9,
		["bindButtons"] = "EXTRABAR9BUTTON",
		["conditions"] = "",
		["position"] = string.format("%s,%s,%s,%s,%s", anchorPoint, anchorTarget, attachTo, xOff, yOff + 80)
	}
	self.AB["barDefaults"]["bar10"] = {
		["page"] = 10,
		["bindButtons"] = "EXTRABAR10BUTTON",
		["conditions"] = "",
		["position"] = string.format("%s,%s,%s,%s,%s", anchorPoint, anchorTarget, attachTo, xOff, yOff + 120)
	}

	for i = 7, 10 do
		self.AB:CreateBar(i)
	end

	for b, _ in pairs(self.AB["handledbuttons"]) do
		self.AB:RegisterButton(b, true)
	end

	self.AB:UpdateButtonSettings()
	self.AB:ReassignBindings()

	hooksecurefunc(self.AB, 'UpdateButtonSettings', EAB.UpdateButtonSettings)
end

function EAB:PLAYER_REGEN_ENABLED()
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")

	EAB:CreateBars()
end

function EAB:PLAYER_ENTERING_WORLD()
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")

	if(InCombatLockdown()) then self:RegisterEvent("PLAYER_REGEN_ENABLED") return end

	EAB:CreateBars()
end

function EAB:OnInitialize()
	EP:RegisterPlugin(addon, EAB.InsertOptions)

	if(E.private.actionbar.enable ~= true) then return end

	local AB = E:GetModule("ActionBars")
	self.AB = AB
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
end