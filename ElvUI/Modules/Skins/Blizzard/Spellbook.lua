local E, L, V, P, G = unpack(select(2, ...)) --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local S = E:GetModule("Skins")

--Lua functions
local _G = _G
local unpack = unpack
local pairs = pairs
--WoW API / Variables
local MAX_SKILLLINE_TABS = MAX_SKILLLINE_TABS

S:AddCallback("Skin_Spellbook", function()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.spellbook then return end

	SpellBookFrame:StripTextures(true)
	SpellBookFrame:CreateBackdrop("Transparent")
	SpellBookFrame.backdrop:Point("TOPLEFT", 0, 0)
	SpellBookFrame.backdrop:Point("BOTTOMRIGHT", 0, -4)

	S:SetUIPanelWindowInfo(SpellBookFrame, "width", nil, 31)
	S:SetBackdropHitRect(SpellBookFrame)

	-- 1. Aggressively Nuke the Custom Server "Retail-Style" Frames & Insets
	local customFrames = {
		"SpellBookFrameNineSlice",
		"SpellBookPageNavigationFrame",
		"SpellBookSideTabsFrame",
		"SpellBookSpellIconsFrame",
		"SpellBookFrameInset",          -- Kills the inner border on Tab 2
		"SpellBookProfessionFrame"      -- Kills the custom Tradeskill background
	}
	
	for _, frameName in pairs(customFrames) do
		local frame = _G[frameName]
		if frame then
			if frame.StripTextures then frame:StripTextures(true) end
			-- NineSlice and Bg elements in retail ports are notoriously stubborn
			if frame.NineSlice then frame.NineSlice:SetAlpha(0) frame.NineSlice:Hide() end
			if frame.Bg then frame.Bg:SetAlpha(0) frame.Bg:Hide() end
		end
	end

	-- Forcefully hide the Inset just in case StripTextures fails
	if SpellBookFrameInset then 
		SpellBookFrameInset:SetAlpha(0) 
		SpellBookFrameInset:Hide()
	end

	if SpellBookFrameNineSlice then 
		SpellBookFrameNineSlice:SetAlpha(0) 
		SpellBookFrameNineSlice:Hide()
	end

	-- Hide default portrait
	if SpellBookFramePortrait then SpellBookFramePortrait:SetAlpha(0) SpellBookFramePortrait:Hide() end
	if SpellBookFrame.portrait then SpellBookFrame.portrait:SetAlpha(0) SpellBookFrame.portrait:Hide() end

	-- Handle Custom Search Box
	if SpellBookSearchBox then
		SpellBookSearchBox:StripTextures()
		S:HandleEditBox(SpellBookSearchBox)
	end

	-- Standard Bottom Tabs
	for i = 1, 3 do
		local tab = _G["SpellBookFrameTabButton"..i]
		if tab then
			tab:Size(122, 32)
			tab:GetNormalTexture():SetTexture(nil)
			tab:GetDisabledTexture():SetTexture(nil)
			tab:GetRegions():SetPoint("CENTER", 0, 2)
			S:HandleTab(tab)
		end
	end

	if SpellBookFrameTabButton1 then 
		SpellBookFrameTabButton1:ClearAllPoints()
		SpellBookFrameTabButton1:Point("TOPLEFT", SpellBookFrame.backdrop, "BOTTOMLEFT", 15, 2)
	end
	if SpellBookFrameTabButton2 then 
		SpellBookFrameTabButton2:ClearAllPoints()
		SpellBookFrameTabButton2:Point("LEFT", SpellBookFrameTabButton1, "RIGHT", -15, 0) 
	end
	if SpellBookFrameTabButton3 then 
		SpellBookFrameTabButton3:ClearAllPoints()
		SpellBookFrameTabButton3:Point("LEFT", SpellBookFrameTabButton2, "RIGHT", -15, 0) 
	end

	if SpellBookPrevPageButton then S:HandleNextPrevButton(SpellBookPrevPageButton, nil, nil, true) end
	if SpellBookNextPageButton then S:HandleNextPrevButton(SpellBookNextPageButton, nil, nil, true) end
	if SpellBookCloseButton then S:HandleCloseButton(SpellBookCloseButton, SpellBookFrame.backdrop) end
	if ShowAllSpellRanksCheckBox then S:HandleCheckBox(ShowAllSpellRanksCheckBox) end

	-- 2. Dynamic Skinning Engine for Buttons
	local function SkinSpellButton(button)
		if not button or button.isSkinned then return end

		local name = button:GetName()
		local icon = _G[name.."IconTexture"]
		local autoCast = _G[name.."AutoCastable"]

		button:StripTextures()

		if autoCast then
			autoCast:SetTexture("Interface\\Buttons\\UI-AutoCastableOverlay")
			autoCast:SetOutside(icon, 16, 16)
		end

		if not button.backdrop then
			button:CreateBackdrop("Default", true)
		end
		
		-- Isolate backdrop to the icon ONLY so it doesn't span across the text
		button.backdrop:ClearAllPoints()
		button.backdrop:SetOutside(icon)

		if icon then
			icon:SetTexCoord(unpack(E.TexCoords))
			icon:SetParent(button.backdrop) 
		end

		if _G[name.."Cooldown"] then
			E:RegisterCooldown(_G[name.."Cooldown"])
		end

		button.isSkinned = true
	end

	-- 3. Intercept Server Updates (Fixes Text Layering and Golden Dragons dynamically)
	local function UpdateSpellTextColors(self)
		if not self then return end
		SkinSpellButton(self)

		local name = self:GetName()
		local spellName = _G[name.."SpellName"]
		local subSpellName = _G[name.."SubSpellName"]
		local highlight = _G[name.."Highlight"]
		local slotFrame = _G[name.."SlotFrame"]
		local emptySlot = _G[name.."EmptySlot"]
		local normal = self:GetNormalTexture()

		-- Aggressively kill the golden borders every time the server tries to draw them
		if normal then normal:SetTexture(nil) normal:SetAlpha(0) end
		if slotFrame then slotFrame:SetTexture(nil) slotFrame:SetAlpha(0) slotFrame:Hide() end
		if emptySlot then emptySlot:SetTexture(nil) emptySlot:SetAlpha(0) emptySlot:Hide() end

		-- Force crisp fonts and overlay layers so text doesn't fall behind backdrops
		if spellName then
			spellName:FontTemplate(nil, 14, "OUTLINE")
			spellName:SetTextColor(1, 0.82, 0)
			spellName:SetDrawLayer("OVERLAY", 7)
		end

		if subSpellName then
			subSpellName:FontTemplate(nil, 12, "OUTLINE")
			subSpellName:SetTextColor(0.6, 0.6, 0.6)
			subSpellName:SetDrawLayer("OVERLAY", 7)
		end

		-- Constrain highlight to icon only
		if highlight then
			local icon = _G[name.."IconTexture"]
			if icon then
				highlight:SetColorTexture(1, 1, 1, 0.3)
				highlight:ClearAllPoints()
				highlight:SetAllPoints(icon)
			end
		end
	end

	-- Hook the game's internal button update loop
	if _G.SpellButton_UpdateButton then
		hooksecurefunc("SpellButton_UpdateButton", UpdateSpellTextColors)
	end
	
	-- Fallback loop to catch buttons that are already generated on open
	for i = 1, 20 do
		if _G["SpellButton"..i] then
			UpdateSpellTextColors(_G["SpellButton"..i])
		end
	end

	-- 4. Handle Side Tabs
	for i = 1, MAX_SKILLLINE_TABS do
		local tab = _G["SpellBookSkillLineTab"..i]
		if tab then
			tab:StripTextures()
			tab:StyleButton(nil, true)
			tab:SetTemplate("Default", true)

			local normalTexture = tab:GetNormalTexture()
			if normalTexture then
				normalTexture:SetInside()
				normalTexture:SetTexCoord(unpack(E.TexCoords))
			end
		end
	end

	if SpellBookSkillLineTab1 then
		SpellBookSkillLineTab1:Point("TOPLEFT", SpellBookFrame, "TOPRIGHT", -33, -65)
	end

	-- 5. Force text colors on page turn & Kill Frames on Show
	if SpellBookPageText then
		SpellBookPageText:SetTextColor(1, 1, 1)
		
		if _G.SpellBook_UpdatePageArrows then
			hooksecurefunc("SpellBook_UpdatePageArrows", function()
				SpellBookPageText:SetTextColor(1, 1, 1)
			end)
		end
	end

	SpellBookFrame:HookScript("OnShow", function()
		if SpellBookFrameNineSlice then SpellBookFrameNineSlice:SetAlpha(0) SpellBookFrameNineSlice:Hide() end
		if SpellBookFrameInset then SpellBookFrameInset:SetAlpha(0) SpellBookFrameInset:Hide() end
		if SpellBookPageText then SpellBookPageText:SetTextColor(1, 1, 1) end
	end)
end)