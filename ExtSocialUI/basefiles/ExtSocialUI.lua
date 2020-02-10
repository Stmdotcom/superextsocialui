EXTSOCIALUI_VERSION = GetAddOnMetadata("ExtSocialUI", "Version");
EXTSOCIALUI_VERSION_ID = 10007;
EXTSOCIALUI_DATA = {};

local EXT_LOADED = false;
local BLIZZ_RAID_LOADED = false;
local RAID_REBUILT = false;
local QJR_QUEUE = 0;

local HOOKS = {};

local L = LibStub("AceLocale-3.0"):GetLocale("ExtSocialUI", true);

local _E;

local NEW_FRIEND_BUTTON_HEIGHT = 45;

--========================================
-- Initial load routine
--========================================
function ExtSocialUI_OnLoad(self)

    self:RegisterEvent("ADDON_LOADED");
    self:RegisterEvent("SOCIAL_QUEUE_UPDATE");
    self:RegisterEvent("LFG_LIST_SEARCH_RESULT_UPDATED");
    self:RegisterEvent("GROUP_JOINED");
    self:RegisterEvent("GROUP_LEFT");
    self:RegisterEvent("PVP_BRAWL_INFO_UPDATED");
    self:RegisterEvent("GUILD_ROSTER_UPDATE");

    SLASH_EXTSOCIALUI1 = "/esui";
    SlashCmdList["EXTSOCIALUI"] = ExtSocialUI_CommandHandler;

end

--========================================
-- Update handler
--========================================
function ExtSocialUI_OnUpdate(self, elapsed)
    if (QJR_QUEUE > 0) then
        QJR_QUEUE = QJR_QUEUE - 1;
        if (QJR_QUEUE == 0) then
            ExtSocialUI_ReanchorQuickJoinIcons();
        end
    end
end

--========================================
-- Event handler
--========================================
function ExtSocialUI_OnEvent(self, event, ...)
    
    if (event == "ADDON_LOADED") then
        local arg1 = ...;
        if (arg1 == "ExtSocialUI") then
            ExtSocialUI_Setup();
            EXT_LOADED = true;
            ExtSocialUI_CheckLoadState();
        elseif (arg1 == "Blizzard_RaidUI") then
            BLIZZ_RAID_LOADED = true;
            ExtSocialUI_CheckLoadState();
        end
    else
        ExtSocialUI_ReanchorQuickJoinIcons_Queue()
        ExtSocialUI_ReanchorQuickJoinIcons();
    end

end

--========================================
-- Post-load setup
--========================================
function ExtSocialUI_Setup()

    local version = ExtSocialUI_CheckSetting("version", EXTSOCIALUI_VERSION_ID);

    EXTSOCIALUI_DATA['config']['version'] = EXTSOCIALUI_VERSION_ID;

    ExtSocialUI_CheckSetting("show_load_message", false);

    ChannelFrame:HookScript("OnShow", ExtSocialUI_RebuildChatTab);

    HOOKS["ChannelRoster_Update"] = ChannelRoster_Update;
    ChannelRoster_Update = ExtSocialUI_ChannelRoster_Update;
    HOOKS["ChannelList_Update"] = ChannelList_Update;
    ChannelList_Update = ExtSocialUI_ChannelList_Update;
    ChannelList_SetScroll = function() end;
    HOOKS["FriendsFrame_UpdateFriends"] = FriendsFrame_UpdateFriends;
    FriendsFrameFriendsScrollFrame.update = ExtSocialUI_FriendsFrame_UpdateFriends;
    FriendsFrame_UpdateFriends = ExtSocialUI_FriendsFrame_UpdateFriends;

    HOOKS["FriendsFrameWhoButton_OnClick"] = FriendsFrameWhoButton_OnClick;
    FriendsFrameWhoButton_OnClick = ExtSocialUI_FriendsFrameWhoButton_OnClick;
    
    ExtSocialUI_RebuildFrame();

    if (EXTSOCIALUI_DATA['config']['show_load_message']) then
        ExtSocialUI_Message(string.format(L["LOADED_MESSAGE"], EXTSOCIALUI_VERSION));
    end

    hooksecurefunc("CreateFrame", ExtSocialUI_CreateFrame);

end

--========================================
-- Checks if both Extended Social UI and
-- Blizzard's Raid UI addons are loaded,
-- and rebuilds the raid UI
--========================================
function ExtSocialUI_CheckLoadState()
    if (EXT_LOADED and BLIZZ_RAID_LOADED and not RAID_REBUILT) then
        ExtSocialUI_RebuildRaidUI();
        RAID_REBUILT = true;
    end
end

--========================================
-- Check configuration setting, and
-- initialize with default value if not
-- present
--========================================
function ExtSocialUI_CheckSetting(field, default)

    if (not EXTSOCIALUI_DATA['config']) then
        EXTSOCIALUI_DATA['config'] = {};
    end
    if (EXTSOCIALUI_DATA['config'][field] == nil) then
        EXTSOCIALUI_DATA['config'][field] = default;
    end
    return EXTSOCIALUI_DATA['config'][field];
end

--========================================
-- Rebuilds the social frame into
-- the extended design
--========================================
function ExtSocialUI_RebuildFrame()

    --override stock values
    FRIENDS_BUTTON_NORMAL_HEIGHT = NEW_FRIEND_BUTTON_HEIGHT;
    FRIENDS_FRAME_FRIEND_HEIGHT = NEW_FRIEND_BUTTON_HEIGHT;
    FriendsFrameFriendsScrollFrame.buttonHeight = NEW_FRIEND_BUTTON_HEIGHT;

    local i;

    FriendsFrame:SetWidth(600);

    -- ********** Friends Tab **********

    FriendsFrameBattlenetFrame:ClearAllPoints();
    FriendsFrameBattlenetFrame:SetPoint("TOP", FriendsTabHeader, "TOP", 0, -27);
    FriendsFrameStatusDropDown:ClearAllPoints();
    FriendsFrameStatusDropDown:SetPoint("TOPLEFT", FriendsTabHeader, "TOPLEFT", 140, -27);

    FriendsFrameFriendsScrollFrame:SetWidth(564);
    for i = 1, #FriendsFrameFriendsScrollFrame.buttons do
        local btn = _G["FriendsFrameFriendsScrollFrameButton" .. i];
        if (btn) then
            local name = btn:GetName();
            btn:SetWidth(562);
            btn:SetHeight(NEW_FRIEND_BUTTON_HEIGHT);
            local nameText = _G[name .. "Name"];
            nameText:SetWidth(500);
            local infoText = _G[name .. "Info"];
            infoText:SetWidth(500);
            local noteIcon = btn:CreateTexture(name .. "NoteIcon", "ARTWORK");
            noteIcon:SetWidth(14);
            noteIcon:SetHeight(12);
            noteIcon:SetPoint("TOPLEFT", infoText, "BOTTOMLEFT", 0, -2);
            noteIcon:SetTexture("Interface/FriendsFrame/UI-FriendsFrame-Note");
            local noteText = btn:CreateFontString(name .. "Note", "ARTWORK", "FriendsFont_Small");
            noteText:SetPoint("LEFT", noteIcon, "RIGHT", 1, 0);
            noteText:SetWidth(484);
            noteText:SetJustifyH("LEFT");
            local charInfoText = btn:CreateFontString(name .. "CharInfo", "ARTWORK", "FriendsFont_Small");
            charInfoText:SetPoint("TOPRIGHT", name .. "GameIcon", "TOPLEFT", -5, -2);
            charInfoText:SetWidth(200);
            charInfoText:SetJustifyH("RIGHT");
            charInfoText:SetTextColor(0.5, 0.5, 0.5);
        end
    end

    FriendsFrameIgnoreScrollFrame:ClearAllPoints();
    FriendsFrameIgnoreScrollFrame:SetPoint("TOPRIGHT", FriendsFrame, "TOPRIGHT", -32, -86);
    FriendsFrameIgnoreScrollFrame:SetWidth(560);
    FriendsFrameIgnoreScrollFrame:SetHeight(311);
    for i = 1, 20, 1 do
        local btn = _G["FriendsFrameIgnoreButton" .. i];
        if (btn) then
            btn:SetWidth(564);
        end
    end

    -- ********** Who Tab **********

    WhoListScrollFrame:SetWidth(560);

    WhoFrameColumn_SetWidth(WhoFrameColumnHeader1, 90);

    -- change column 2 to zone
    WhoFrameDropDown:Hide();
    WhoFrameColumn_SetWidth(WhoFrameColumnHeader2, 130);
    WhoFrameColumnHeader2:SetText(ZONE);
    WhoFrameColumnHeader2.sortType = "zone";

    -- change column 3 to guild
    WhoFrameColumn_SetWidth(WhoFrameColumnHeader3, 160);
    WhoFrameColumnHeader3:SetText(GUILD);
    WhoFrameColumnHeader3.sortType = "guild";

    -- change column 4 to level
    WhoFrameColumn_SetWidth(WhoFrameColumnHeader4, 32);
    WhoFrameColumnHeader4:SetText(LEVEL_ABBR);
    WhoFrameColumnHeader4.sortType = "level";

    -- create column 5 and set it to race
    WhoFrameColumnHeader5 = CreateFrame("Button", "WhoFrameColumnHeader5", WhoFrame, "WhoFrameColumnHeaderTemplate");
    WhoFrameColumnHeader5:SetPoint("LEFT", WhoFrameColumnHeader4, "RIGHT", -2, 0);
    WhoFrameColumn_SetWidth(WhoFrameColumnHeader5, 70);
    WhoFrameColumnHeader5:SetText(RACE);
    WhoFrameColumnHeader5.sortType = "race";

    -- create column 6 and set it to class
    WhoFrameColumnHeader6 = CreateFrame("Button", "WhoFrameColumnHeader6", WhoFrame, "WhoFrameColumnHeaderTemplate");
    WhoFrameColumnHeader6:SetPoint("LEFT", WhoFrameColumnHeader5, "RIGHT", -2, 0);
    WhoFrameColumn_SetWidth(WhoFrameColumnHeader6, 85);
    WhoFrameColumnHeader6:SetText(CLASS);
    WhoFrameColumnHeader6.sortType = "class";

    -- create new who frame list buttons
    for i = 1, 17, 1 do
        local btn = _G["WhoFrameButton" .. i];
        if (btn) then
            btn:Hide();
        end

        local btn2 = CreateFrame("Button", "NewWhoFrameButton" .. i, WhoFrame, "ExtSocialUI_WhoButtonTemplate");
        btn2:SetID(i);
        if (i == 1) then
            btn2:SetPoint("TOPLEFT", WhoFrame, "TOPLEFT", 6, -82);
        else
            btn2:SetPoint("TOP", _G["NewWhoFrameButton" .. (i - 1)], "BOTTOM");
        end
    end

    WhoFrameEditBox:SetWidth(560);

    -- then hook the who list update function
    WhoList_Update = ExtSocialUI_WhoList_Update;

    -- ********** Raid Tab **********

    RaidFrameRaidDescription:SetWidth(566);

    -- ********** Quick Join **********
    
    QuickJoinScrollFrame:SetWidth(564);
    for i = 1, #QuickJoinScrollFrame.buttons, 1 do
        local button = QuickJoinScrollFrame.buttons[i];
        button:SetWidth(559);
        button.Members[1]:SetWidth(120);
        button.Queues[1]:SetWidth(400);
        button.Icon:ClearAllPoints();
        button.Icon:SetPoint("TOPLEFT", QuickJoinScrollFrame.buttons[i], "TOPLEFT", 127, -5);
        button.Queues[1]:ClearAllPoints();
        button.Queues[1]:SetPoint("TOPLEFT", button, "TOPLEFT", 146, -6);
    end
    
    QuickJoinFrame:HookScript("OnShow", ExtSocialUI_ReanchorQuickJoinIcons);

end

--========================================
-- Rebuild the Chat/Channels tab
--========================================
function ExtSocialUI_RebuildChatTab()
    local i;

    ChannelFrame:SetWidth(600);
    --ChannelFrameLeftInset:ClearAllPoints();
    --ChannelFrameLeftInset:SetPoint("TOPLEFT", ChannelFrame, "TOPLEFT", 4, -60);
    --ChannelFrameLeftInset:SetPoint("BOTTOMRIGHT", ChannelFrame, "BOTTOM", 0, 52);
    --ChannelFrameRightInset:ClearAllPoints();
    --ChannelFrameRightInset:SetPoint("TOPRIGHT", ChannelFrame, "TOPRIGHT", -8, -60);
    --ChannelFrameRightInset:SetPoint("BOTTOMLEFT", ChannelFrame, "BOTTOM", 0, 52);

    --ChannelListScrollFrame:SetWidth(290);

    for i = 1, 16, 1 do
        local btn = _G["ChannelButton" .. i];
        if (btn) then
            btn:SetWidth(290);
        end
    end

    --ChannelRoster:SetWidth(290);
    --ChannelRoster:ClearAllPoints();
    --ChannelRoster:SetPoint("TOPLEFT", ChannelListScrollFrame, "TOPRIGHT", 6, 0);
    --ChannelRosterScrollFrame:ClearAllPoints();
    --ChannelRosterScrollFrame:SetPoint("TOPLEFT", ChannelRoster, "TOPLEFT");
    --ChannelRosterScrollFrame:SetWidth(264);
    --ChannelRosterChannelName:ClearAllPoints();
    --ChannelRosterChannelName:SetPoint("TOPLEFT", ChannelRoster, "TOPLEFT", 0, 20);

    --ChannelMemberButton1:ClearAllPoints();
    --ChannelMemberButton1:SetPoint("TOPLEFT", ChannelRosterScrollFrame, "TOPLEFT");

    ExtSocialUI_ResizeChannelRosterButtons();

end

--========================================
-- Rebuild the Raid tab
--========================================
function ExtSocialUI_RebuildRaidUI()

    local i, j;

    for i = 1, 8, 1 do
        local btn = _G["RaidGroup" .. i];
        if (btn) then
            btn:SetWidth(292);
            ExtSocialUI_HideUnnamedTextures(btn);
            local btnBg = btn:CreateTexture("RaidGroup" .. i .. "Background", "BACKGROUND");
            btnBg:SetTexture("Interface\\RaidFrame\\UI-RaidFrame-GroupOutline");
            btnBg:SetTexCoord(0, 0.6640625, 0, 0.625);
            btnBg:SetPoint("TOPLEFT", btn, "TOPLEFT");
            btnBg:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT");

            for j = 1, 5, 1 do
                local slot = _G["RaidGroup" .. i .. "Slot" .. j];
                if (slot) then
                    slot:SetWidth(286);
                end
            end
        end
    end

    for i = 1, 40, 1 do
        local btn = _G["RaidGroupButton" .. i];
        if (btn) then
            btn:SetWidth(286);
            local name = _G["RaidGroupButton" .. i .. "Name"];
            name:SetWidth(155);
        end
    end

end

--========================================
-- Hides unnamed texture elements on the
-- specified parent frame
--========================================
function ExtSocialUI_HideUnnamedTextures(parent)
    local list = { parent:GetRegions() };
    for i, j in pairs(list) do
        if (j:IsObjectType("Texture") and not j:GetName()) then
            j:Hide();
        end
    end
end

--========================================
-- Toggles a boolean config setting
--========================================
function ExtSocialUI_ToggleSetting(name)
    if (EXTSOCIALUI_DATA['config'][name]) then
        EXTSOCIALUI_DATA['config'][name] = false;
    else
        EXTSOCIALUI_DATA['config'][name] = true;
    end
end

--========================================
-- Output message to chat frame
--========================================
function ExtSocialUI_Message(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cffe000ff<" .. L["ADDON_TITLE"] .. ">|r " .. msg);
end

--========================================
-- Slash command handler
--========================================
function ExtSocialUI_CommandHandler(cmd)

    InterfaceOptionsFrame_OpenToCategory(ExtSocialUIConfigContainer);
    InterfaceOptionsFrame_OpenToCategory(ExtSocialUIConfigContainer);

end


--========================================
-- Hook for updating the /who list
--========================================
function ExtSocialUI_WhoList_Update()
    local numWhos, totalCount = C_FriendList.GetNumWhoResults();
    --local name, guild, level, race, class, zone, classFileName;
    local button, buttonText, classTextColor;
    local whoOffset = FauxScrollFrame_GetOffset(WhoListScrollFrame);
    local whoIndex;
    local showScrollBar = nil;

    if (numWhos > WHOS_TO_DISPLAY) then
        showScrollBar = 1;
    end

    local displayedText = "";
    if ( totalCount > MAX_WHOS_FROM_SERVER ) then
        displayedText = format(WHO_FRAME_SHOWN_TEMPLATE, MAX_WHOS_FROM_SERVER);
    end

    WhoFrameTotals:SetText(format(WHO_FRAME_TOTAL_TEMPLATE, totalCount) .. "  " .. displayedText);
    for i = 1, WHOS_TO_DISPLAY, 1 do
        whoIndex = whoOffset + i;
        button = _G["NewWhoFrameButton" .. i];
        button.whoIndex = whoIndex;
        --name, guild, level, race, class, zone, classFileName = C_FriendList.GetWhoInfo(whoIndex);
        local who = C_FriendList.GetWhoInfo(whoIndex);
        if (who) then
            button.name = who.fullName;

            if (who.filename) then
                classTextColor = RAID_CLASS_COLORS[who.filename];
            else
                classTextColor = HIGHLIGHT_FONT_COLOR;
            end
            _G["NewWhoFrameButton"..i.."Name"]:SetText(who.fullName);
            _G["NewWhoFrameButton"..i.."Zone"]:SetText(who.area);
            _G["NewWhoFrameButton"..i.."Guild"]:SetText(who.fullGuildName);
            _G["NewWhoFrameButton"..i.."Level"]:SetText(who.level);
            _G["NewWhoFrameButton"..i.."Race"]:SetText(who.raceStr);
            buttonText = _G["NewWhoFrameButton"..i.."Class"];
            buttonText:SetText(who.classStr);
            buttonText:SetTextColor(classTextColor.r, classTextColor.g, classTextColor.b);
        end
        
        -- Highlight the correct who
        if ( WhoFrame.selectedWho == whoIndex ) then
            button:LockHighlight();
        else
            button:UnlockHighlight();
        end
        
        if ( whoIndex > numWhos ) then
            button:Hide();
        else
            button:Show();
        end
    end

    if ( not WhoFrame.selectedWho ) then
        WhoFrameGroupInviteButton:Disable();
        WhoFrameAddFriendButton:Disable();
    else
        WhoFrameGroupInviteButton:Enable();
        WhoFrameAddFriendButton:Enable();
        WhoFrame.selectedName = C_FriendList.GetWhoInfo(WhoFrame.selectedWho); 
    end

    -- ScrollFrame update
    FauxScrollFrame_Update(WhoListScrollFrame, numWhos, WHOS_TO_DISPLAY, FRIENDS_FRAME_WHO_HEIGHT );

    PanelTemplates_SetTab(FriendsFrame, 2);
    ShowUIPanel(FriendsFrame);
end


--========================================
-- Hook for Chat tab update (1)
--========================================
function ExtSocialUI_ChannelList_Update(id)
    HOOKS["ChannelList_Update"](id);
    ExtSocialUI_ResizeChannelRosterButtons();
end

--========================================
-- Hook for Chat tab update (2)
--========================================
function ExtSocialUI_ChannelRoster_Update(id)
    HOOKS["ChannelRoster_Update"](id);
    ExtSocialUI_ResizeChannelRosterButtons();
end

--========================================
-- Resize Chat tab roster list buttons
--========================================
function ExtSocialUI_ResizeChannelRosterButtons()
    local i;
    for i = 1, 22, 1 do
        local btn = _G["ChannelMemberButton" .. i];
        if (btn) then
            btn:SetWidth(264);
        end
    end
end

--========================================
-- Update friends list entries with notes
--========================================
function ExtSocialUI_FriendsFrame_UpdateFriends()

    if FriendsFrame_UpdateFriends == ExtSocialUI_FriendsFrame_UpdateFriends then
        HOOKS["FriendsFrame_UpdateFriends"]();
    end
    --HOOKS["FriendsFrame_UpdateFriends"]();

    if (FriendsFrame.selectedTab == 1) then
        local i;
        for i = 1, #FriendsFrameFriendsScrollFrame.buttons do
            local btn = _G["FriendsFrameFriendsScrollFrameButton" .. i];
            if (btn) then
                local noteString = _G["FriendsFrameFriendsScrollFrameButton" .. i .. "Note"];
                local noteIcon = _G["FriendsFrameFriendsScrollFrameButton" .. i .. "NoteIcon"];
                local note = "";
                local charInfo = "";
                local isOnline = false;
                if (btn:IsVisible()) then
                    if (btn.buttonType == FRIENDS_BUTTON_TYPE_WOW) then
                        local name, level, class, area, connected, status, noteText = GetFriendInfo(btn.id);
                        note = noteText;
                        isOnline = connected;
                    elseif (btn.buttonType == FRIENDS_BUTTON_TYPE_BNET) then
                        local presenceID, presenceName, battleTag, isBattleTagPresence, toonName, toonID, client, connected, lastOnline, isAFK, isDND, broadcastText, noteText,
                        isRIDFriend, broadcastTime, canSoR = BNGetFriendInfo(btn.id);
                        note = noteText;
                        isOnline = connected;
                        if (toonID and isOnline) then
                            if (client == BNET_CLIENT_WOW) then
                                local hasFocus, toonName, client, realmName, realmID, faction, race, class, guild, zoneName, level, gameText = BNGetGameAccountInfo(toonID);
                                local color = "";
                                if (faction ~= UnitFactionGroup("player")) then
                                    color = "|cffff6060";
                                end
                                charInfo = color .. string.format(L["FRIEND_INFO_TEMPLATE_WOW"], level, race, class) .. "\n" .. realmName;
                            end
                        end
                    end
                end
                note = (note or "");
                if (isOnline) then
                    noteString:SetTextColor(1, 0.82, 0);
                    noteIcon:SetVertexColor(1, 0.82, 0);
                else
                    noteString:SetTextColor(0.75, 0.75, 0.75);
                    noteIcon:SetVertexColor(0.75, 0.75, 0.75);
                end
                if (note ~= "") then
                    noteString:SetText(note);
                    noteString:Show();
                    noteIcon:Show();
                    btn:SetHeight(NEW_FRIEND_BUTTON_HEIGHT + 5);
                else
                    noteString:Hide();
                    noteIcon:Hide();
                end
                local infoString = _G["FriendsFrameFriendsScrollFrameButton" .. i .. "CharInfo"];
                infoString:SetText(charInfo);
            end
        end
    end

end


function ExtSocialUI_FriendsFrameWhoButton_OnClick(self, button)
    if (button == "LeftButton") then
        WhoFrame.selectedWho = _G["NewWhoFrameButton" .. self:GetID()].whoIndex;
        WhoFrame.selectedName = _G["NewWhoFrameButton" .. self:GetID() .. "Name"]:GetText();
        WhoList_Update();
    else
        local name = _G["NewWhoFrameButton" .. self:GetID() .. "Name"]:GetText();
        FriendsFrame_ShowDropdown(name, 1);
    end
end

function ExtSocialUI_CreateFrame(frameType, name, parent, template)
    if template == "FriendsFrameButtonTemplate" then
        local btn = _G[name];
        btn:SetWidth(562);
        btn:SetHeight(NEW_FRIEND_BUTTON_HEIGHT);
        local nameText = _G[name .. "Name"];
        nameText:SetWidth(500);
        local infoText = _G[name .. "Info"];
        infoText:SetWidth(500);
        local noteIcon = btn:CreateTexture(name .. "NoteIcon", "ARTWORK");
        noteIcon:SetWidth(14);
        noteIcon:SetHeight(12);
        noteIcon:SetPoint("TOPLEFT", infoText, "BOTTOMLEFT", 0, -2);
        noteIcon:SetTexture("Interface/FriendsFrame/UI-FriendsFrame-Note");
        local noteText = btn:CreateFontString(name .. "Note", "ARTWORK", "FriendsFont_Small");
        noteText:SetPoint("LEFT", noteIcon, "RIGHT", 1, 0);
        noteText:SetWidth(484);
        noteText:SetJustifyH("LEFT");
        local charInfoText = btn:CreateFontString(name .. "CharInfo", "ARTWORK", "FriendsFont_Small");
        charInfoText:SetPoint("RIGHT", name .. "GameIcon", "LEFT", -5, -2);
        charInfoText:SetWidth(200);
        charInfoText:SetJustifyH("RIGHT");
        charInfoText:SetText(name .. "CharInfo");
        charInfoText:SetTextColor(0.5, 0.5, 0.5);
    end
end

function ExtSocialUI_ReanchorQuickJoinIcons_Queue()
    if (QJR_QUEUE > 0) then return; end
    QJR_QUEUE = 1;
end

function ExtSocialUI_ReanchorQuickJoinIcons()
    for i = 1, #QuickJoinScrollFrame.buttons, 1 do
        local button = QuickJoinScrollFrame.buttons[i];
        button.Icon:ClearAllPoints();
        button.Icon:SetPoint("TOPLEFT", button, "TOPLEFT", 127, -5);
    end
end
