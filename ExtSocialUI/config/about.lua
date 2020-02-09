local L = LibStub("AceLocale-3.0"):GetLocale("ExtSocialUI", true);

local ABOUT = {
    author = "Germbread (Deathwing-US)",
    email = GetAddOnMetadata("ExtSocialUI", "X-Email"),
    hosts = {
        "https://www.curseforge.com/wow/addons",
        "https://www.curseforge.com/wow/addons/extended-social-ui",
    },
};

local CONFIG_SHOWN = false;

--========================================
-- Setting up the config frame
--========================================
function ExtSocialUIConfig_About_OnLoad(self)
    self.name = L["ABOUT"];
    self.parent = L["ADDON_TITLE"];
    self.okay = function(self) ExtSocialUIConfig_About_OnClose(); end;
    self.cancel = function(self) ExtSocialUIConfig_About_OnClose(); end;
    self.refresh = function(self) ExtSocialUIConfig_About_OnRefresh(); end;
    InterfaceOptions_AddCategory(self);

    ExtSocialUIConfigAboutTitle:SetText(string.format(L["VERSION_TEXT"], "|cffffffffv" .. EXTSOCIALUI_VERSION));
    ExtSocialUIConfigAboutAuthor:SetText(L["LABEL_AUTHOR"] .. ": |cffffffff" .. ABOUT.author);
    ExtSocialUIConfigAboutEmail:SetText(L["LABEL_EMAIL"] .. ": |cffffffff" .. ABOUT.email);
    ExtSocialUIConfigAboutURLs:SetText(L["LABEL_HOSTS"] .. ":");
end

--========================================
-- Refresh
--========================================
function ExtSocialUIConfig_About_OnRefresh()
    if (CONFIG_SHOWN) then return; end

    for i = 1, table.maxn(ABOUT.hosts), 1 do
        local fontString = _G["ExtSocialUIConfigAbout_SiteList" .. i];
        if (not fontString) then
            fontString = ExtSocialUIConfigAbout:CreateFontString("ExtSocialUIConfigAbout_SiteList" .. i, "ARTWORK", "GameFontHighlight");
        end
        fontString:ClearAllPoints();
        fontString:SetPoint("TOPLEFT", ExtSocialUIConfigAbout, "TOPLEFT", 60, -(145 + (i * 20)));
        fontString:SetText(ABOUT.hosts[i]);
    end

    CONFIG_SHOWN = true;
end

--========================================
-- Closing the window
--========================================
function ExtSocialUIConfig_About_OnClose()
    CONFIG_SHOWN = false;
end
