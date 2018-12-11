local L = LibStub("AceLocale-3.0"):GetLocale("ExtSocialUI", true);

-- ********** variables for storing previous values **********
local OLD_CONFIG = {
    ["show_load_message"] = false,
};
-- ***********************************************************

local CONFIG_SHOWN = false;

--========================================
-- Setting up the config frame
--========================================
function ExtSocialUIConfig_OnLoad(self)
    self.name = L["ADDON_TITLE"];
    self.okay = function(self) ExtSocialUIConfig_Close(); end;
    self.cancel = function(self) ExtSocialUIConfig_Cancel(); end;
    self.refresh = function(self) ExtSocialUIConfig_Refresh(); end;
    self.default = function(self) ExtSocialUIConfig_SetDefaults(); end;
    InterfaceOptions_AddCategory(self);

    ExtSocialUIConfigTitle:SetText(string.format(L["VERSION_TEXT"], "|cffffffffv" .. EXTSOCIALUI_VERSION));

    -- ********** General Options **********

    ExtSocialUIConfig_GeneralContainerTitle:SetText(L["CONFIG_HEADING_GENERAL"]);

	ExtSocialUIConfig_GeneralContainer_ShowLoadMsgText:SetText(L["OPTION_STARTUP_MESSAGE"]);
	ExtSocialUIConfig_GeneralContainer_ShowLoadMsg.tooltip = L["OPTION_STARTUP_MESSAGE_TOOLTIP"];

end

--==================================================
-- Handle when the configuration is opened
--==================================================
function ExtSocialUIConfig_OnShow()
    if (CONFIG_SHOWN) then return; end
    ExtSocialUIConfig_StoreCurrentSettings();
    CONFIG_SHOWN = true;
end

--========================================
-- Sets the values of the controls to
-- reflect currently loaded settings
--========================================
function ExtSocialUIConfig_Refresh()
    ExtSocialUIConfig_OnShow();
	ExtSocialUIConfig_GeneralContainer_ShowLoadMsg:SetChecked(EXTSOCIALUI_DATA['config']['show_load_message']);
end

--==================================================
-- Store current settings to restore if the user
-- presses cancel
--==================================================
function ExtSocialUIConfig_StoreCurrentSettings()
    ExtSocialUIConfig_StoreOldSetting("show_load_message");
end

--==================================================
-- Copies a config setting to the 'backup' table
--==================================================
function ExtSocialUIConfig_StoreOldSetting(key)
    if (EXTSOCIALUI_DATA['config'][key]) then
        OLD_CONFIG[key] = EXTSOCIALUI_DATA['config'][key];
    end
end

--==================================================
-- Restores a config setting from the backup table
--==================================================
function ExtSocialUIConfig_RestoreConfigSetting(key)
    if (OLD_CONFIG[key]) then
        EXTSOCIALUI_DATA['config'][key] = OLD_CONFIG[key];
    end
end

--========================================
-- Closing the config window
--========================================
function ExtSocialUIConfig_Close()
    CONFIG_SHOWN = false;
end

--==================================================
-- Handle clicking the Cancel button; restore
-- all settings to their previous values
--==================================================
function ExtSocialUIConfig_Cancel()
    ExtSocialUIConfig_RestoreConfigSetting("show_load_message");
    ExtSocialUIConfig_Close();
end

--========================================
-- Handler for checking/unchecking
-- checkbox(es)
--========================================
function ExtSocialUIConfig_CheckBox_OnClick(self, id)
	if (id == 1) then
		if (self:GetChecked()) then
		    EXTSOCIALUI_DATA['config']['show_load_message'] = true;
		else
		    EXTSOCIALUI_DATA['config']['show_load_message'] = false;
		end

	end
end

--========================================
-- Handler for mousing over options
-- on the config window
--========================================
function ExtSocialUIConfig_Option_OnEnter(self)
	if (self.tooltip) then
        GameTooltip:SetOwner(self, "ANCHOR_NONE");
		GameTooltip:SetPoint("TOPLEFT", self:GetName(), "BOTTOMLEFT", -10, -4);
        GameTooltip:SetText(self.tooltip, 1, 1, 1);
        GameTooltip:Show();
	end
end

--========================================
-- Moving the mouse away from config
-- options
--========================================
function ExtSocialUIConfig_Option_OnLeave(self)
	GameTooltip:Hide();
end
