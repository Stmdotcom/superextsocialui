EXTSOCIALUI_VERSION = GetAddOnMetadata("ExtSocialUI", "Version");
EXTSOCIALUI_VERSION_ID = 10007;
EXTSOCIALUI_DATA = {};

local EXT_LOADED = false;
local BLIZZ_RAID_LOADED = false;
local RAID_REBUILT = false;
local QJR_QUEUE = 0;
local WHOS_FILTER_GENDER = -1;

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
    FriendsListFrameScrollFrame.update = ExtSocialUI_FriendsFrame_UpdateFriends;
    FriendsFrame_UpdateFriends = ExtSocialUI_FriendsFrame_UpdateFriends;

    HOOKS["FriendsFrameWhoButton_OnClick"] = FriendsFrameWhoButton_OnClick;
    FriendsFrameWhoButton_OnClick = ExtSocialUI_FriendsFrameWhoButton_OnClick;

    ExtSocialUI_RebuildFrame();
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
    FriendsListFrameScrollFrame.buttonHeight = NEW_FRIEND_BUTTON_HEIGHT;

    local i;

    FriendsFrame:SetWidth(600);

    -- ********** Friends Tab **********

    FriendsFrameBattlenetFrame:ClearAllPoints();
    FriendsFrameBattlenetFrame:SetPoint("TOP", FriendsTabHeader, "TOP", 0, -27);
    FriendsFrameStatusDropDown:ClearAllPoints();
    FriendsFrameStatusDropDown:SetPoint("TOPLEFT", FriendsTabHeader, "TOPLEFT", 140, -27);

    FriendsListFrameScrollFrame:SetWidth(564);
    for i = 1, #FriendsListFrameScrollFrame.buttons do
        local btn = _G["FriendsListFrameScrollFrameButton" .. i];
        if (btn) then
            local name = btn:GetName();
            btn:SetWidth(562);
            btn:SetHeight(NEW_FRIEND_BUTTON_HEIGHT);
            local nameText = _G[name .. "Name"];
            nameText:SetWidth(500);
            local infoText = _G[name .. "Info"];
            infoText:SetWidth(125);
            local noteIcon = btn:CreateTexture(name .. "NoteIcon", "ARTWORK");
            noteIcon:SetWidth(14);
            noteIcon:SetHeight(12);
            noteIcon:SetPoint("LEFT", infoText, "RIGHT", 0, 0);
            noteIcon:SetTexture("Interface/FriendsFrame/UI-FriendsFrame-Note");
            local noteText = btn:CreateFontString(name .. "Note", "ARTWORK", "FriendsFont_Small");
            noteText:SetPoint("LEFT", noteIcon, "RIGHT", 0, 0);
            noteText:SetWidth(484);
            noteText:SetJustifyH("LEFT");
            local charInfoText = btn:CreateFontString(name .. "CharInfo", "ARTWORK", "FriendsFont_Small");
            charInfoText:SetPoint("TOPRIGHT", name .. "GameIcon", "TOPLEFT", -5, -2);
            charInfoText:SetWidth(200);
            charInfoText:SetJustifyH("RIGHT");
            charInfoText:SetTextColor(0.5, 0.5, 0.5);
        end
    end

    IgnoreListFrameScrollFrame:ClearAllPoints();
    IgnoreListFrameScrollFrame:SetPoint("TOPRIGHT", FriendsFrame, "TOPRIGHT", -32, -86);
    IgnoreListFrameScrollFrame:SetWidth(560);
    IgnoreListFrameScrollFrame:SetHeight(311);
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
    WhoFrameColumn_SetWidth(WhoFrameColumnHeader3, 140);
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
    WhoFrameColumn_SetWidth(WhoFrameColumnHeader6, 60);
    WhoFrameColumnHeader6:SetText(CLASS);
    WhoFrameColumnHeader6.sortType = "class";

    -- create column 7 and set it to rp
    WhoFrameColumnHeader7 = CreateFrame("Button", "WhoFrameColumnHeader7", WhoFrame, "WhoFrameColumnHeaderTemplate");
    WhoFrameColumnHeader7:SetPoint("LEFT", WhoFrameColumnHeader6, "RIGHT", -2, 0);
    WhoFrameColumn_SetWidth(WhoFrameColumnHeader7, 25);
    WhoFrameColumnHeader7:SetText("RP");
    WhoFrameColumnHeader7.sortType = "rp";

    -- create column 8 and set it to sex
    WhoFrameColumnHeader8 = CreateFrame("Button", "WhoFrameColumnHeader8", WhoFrame, "WhoFrameColumnHeaderTemplate");
    WhoFrameColumnHeader8:SetPoint("LEFT", WhoFrameColumnHeader7, "RIGHT", -2, 0);
    WhoFrameColumn_SetWidth(WhoFrameColumnHeader8, 30);
    WhoFrameColumnHeader8:SetText("Sex");
    WhoFrameColumnHeader8.sortType = "sex";

    -- create new who frame list buttons
    for i = 1, 17, 1 do
        local btn = _G["WhoListScrollFrameButton" .. i];
        if (btn) then
            btn:Hide();
        end

        local btn2 = CreateFrame("Button", "NewWhoFrameButton" .. i, WhoListScrollFrame, "ExtSocialUI_WhoButtonTemplate");
        btn2:SetID(i);
        if (i == 1) then
            btn2:SetPoint("TOPLEFT", WhoFrame, "TOPLEFT", 6, -82);
        else
            btn2:SetPoint("TOP", _G["NewWhoFrameButton" .. (i - 1)], "BOTTOM");
        end
    end

    local searchDropDown = CreateFrame("Frame", "NewWhoSearchDropdown", WhoFrame, "UIDropDownMenuTemplate")
    searchDropDown:SetPoint("BOTTOMLEFT")
    UIDropDownMenu_SetWidth(searchDropDown, 100) -- Use in place of dropDown:SetWidth
    -- Bind an initializer function to the dropdown; see previous sections for initializer function examples.
    UIDropDownMenu_Initialize(searchDropDown, NewWhoSearchDropDown_Menu)
    UIDropDownMenu_SetText(searchDropDown, "Search Options")

    local filterDropDown = CreateFrame("Frame", "NewWhoFilterDropdown", WhoFrame, "UIDropDownMenuTemplate")
    filterDropDown:SetPoint("BOTTOMLEFT", 120, 0)
    UIDropDownMenu_SetWidth(filterDropDown, 100) -- Use in place of dropDown:SetWidth
    -- Bind an initializer function to the dropdown; see previous sections for initializer function examples.
    UIDropDownMenu_Initialize(filterDropDown, NewWhoFilterDropDown_Menu)
    UIDropDownMenu_SetText(filterDropDown, "Filter Options")


    WhoFrameEditBox:SetWidth(560);

    -- then hook the who list update function

    WhoListScrollFrame.update = ExtSocialUI_WhoList_Update;
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
-- Char sex filter
--========================================
function NewWhoFilterDropDown_Menu(frame, level, menuList)
    local info = UIDropDownMenu_CreateInfo()

    if level == 1 then
        -- Outermost menu level
        info.text, info.hasArrow = "Clear", nil
        info.func = ClearWhoFilter
        UIDropDownMenu_AddButton(info)

        info.text, info.hasArrow, info.menuList = "Sex", true, "Sexes"
        UIDropDownMenu_AddButton(info)

    elseif menuList == "Sexes" then
        for s in ("Unknown; Male; Female"):gmatch("[^;%s][^;]*") do
            info.text = s
            info.func = SetWhoGender
            UIDropDownMenu_AddButton(info, level)
        end
    end
end

--========================================
-- Char zone/race filter
--========================================
function NewWhoSearchDropDown_Menu(frame, level, menuList)
    local info = UIDropDownMenu_CreateInfo()

    if level == 1 then
        -- Outermost menu level
        info.text, info.hasArrow = "Clear", nil
        info.func = ClearWhoSearch
        UIDropDownMenu_AddButton(info)

        info.text, info.hasArrow, info.menuList = "Zone", true, "Zones"
        UIDropDownMenu_AddButton(info)

        info.text, info.hasArrow, info.menuList = "Race", true, "Races"
        UIDropDownMenu_AddButton(info)

    elseif menuList == "Zones" then
        -- Show the "Zones" sub-menu
        -- TODO Add more zones
        for s in ("The Jade Forest; Ruins of Gilneas; Elwynn Forest; Stormwind; Silvermoon City; Orgrimmar; Thunder Bluff"):gmatch("[^;%s][^;]*") do
            info.text = s
            info.func = SetWhoZone
            UIDropDownMenu_AddButton(info, level)
        end

    elseif menuList == "Races" then
        -- Show the "Races" sub-menu
        -- TODO Add all the other races (Should be able to build from API?)
        for s in ("Pandaren; Tauren; Dwarf; Human; Worgen"):gmatch("[^;%s][^;]*") do
            info.text = s
            info.func = SetWhoRace
            UIDropDownMenu_AddButton(info, level)
        end
  --info.text, info.hasArrow, info.menuList = "Infinite menus", true, menuList
  --UIDropDownMenu_AddButton(info, level)
    end
end

function ClearWhoFilter(newValue)
    WHOS_FILTER_GENDER = -1
    ExtSocialUI_WhoList_Update()
    --TODO
end

function ClearWhoSearch(newValue)
    WhoFrameEditBox:SetText("")
end

function SetWhoGender(newValue)
    WHOS_FILTER_GENDER = newValue.value
    ExtSocialUI_WhoList_Update()
end

function SetWhoZone(newValue)
    local _beforetext = WhoFrameEditBox:GetText()
    WhoFrameEditBox:Insert(" z-" .. '"' .. newValue.value .. '"')
end

function SetWhoRace(newValue)
    local _beforetext = WhoFrameEditBox:GetText()
    WhoFrameEditBox:Insert(" r-" .. '"' .. newValue.value .. '"')
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
    print("Raid!")
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

function GetWhoInfoFilteredAll()
    local whoList = {};
    local filteredCount = 0;

    for i = 1, MAX_WHOS_FROM_SERVER, 1 do
        local who = C_FriendList.GetWhoInfo(i);
        if who ~= nil then
            local showChar = false;

            -- Add more filters here
            if (WHOS_FILTER_GENDER == -1) then
                showChar = true
            elseif (WHOS_FILTER_GENDER == "Male" and who.gender == 2) then
                showChar = true
            elseif (WHOS_FILTER_GENDER == "Female" and who.gender == 3) then
                showChar = true
            end

            if showChar then
                filteredCount = filteredCount + 1;
                table.insert (whoList, { who.fullName, who.fullGuildName, who.level, who.raceStr, who.classStr, who.area, who.filename, who.gender})
            end
        end
    end
    return whoList, filteredCount
end

function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

--========================================
-- Hook for updating the /who list
--========================================
function ExtSocialUI_WhoList_Update()
    local genderTable = { "U", "M", "F" };
	local numWhos, totalCount = C_FriendList.GetNumWhoResults();
    local whoList, numWhosFiltered = GetWhoInfoFilteredAll();

    local player_realm = GetRealmName()
	local name, guild, level, race, class, zone, sex;
	local button, buttonWorking, buttonText, classTextColor, classFileName, character;
	local whoOffset = FauxScrollFrame_GetOffset(WhoListScrollFrame);
    local whoIndex;
    local showScrollBar = nil;
    local usedHeight = 0;

	if (numWhosFiltered > WHOS_TO_DISPLAY) then
		showScrollBar = 1;
	end

	local displayedText = "";

    if ( totalCount > MAX_WHOS_FROM_SERVER ) then
        displayedText = format(WHO_FRAME_SHOWN_TEMPLATE, MAX_WHOS_FROM_SERVER);
    end

	if ( totalCount == MAX_WHOS_FROM_SERVER ) then
		displayedText = " (+)";
	end

	WhoFrameTotals:SetText(format(WHO_FRAME_TOTAL_TEMPLATE, numWhosFiltered) .. displayedText);

    --local realpos = 1

    for i = 1, WHOS_TO_DISPLAY, 1 do

         local btn = _G["WhoListScrollFrameButton" .. i];
         if (btn) then
             btn:Hide();
         end


		whoIndex = whoOffset + i;

		button = _G["NewWhoFrameButton" .. i];
		button.whoIndex = whoIndex;
        --button:Hide();

        local whoChar = whoList[whoIndex]

        if whoChar then

            name = whoChar[1];
            guild = whoChar[2];
            level = whoChar[3];
            race = whoChar[4];
            class = whoChar[5];
            zone = whoChar[6];
            classFileName = whoChar[7];
            sex = whoChar[8];

            button.name = name;
            if ( classFileName ) then
                classTextColor = RAID_CLASS_COLORS[classFileName];
            else
                classTextColor = HIGHLIGHT_FONT_COLOR;
            end

            button.Name:SetText(name);
            button.Zone:SetText(zone);
            button.Guild:SetText(guild);
            button.Level:SetText(level);
            button.Race:SetText(race);
            button.Class:SetText(class);
            button.Class:SetTextColor(classTextColor.r, classTextColor.g, classTextColor.b);

            if name and xrp then -- Extend UI for xrp
                character = xrp.characters.byName[name]
                if (character.fields and character.fields.VA) then
                    button.RP:SetText("Y")
                else
                    button.RP:SetText("N")
                end
            elseif name and TRP3_API then  -- Extend UI for trp3
                the_unit = name .. "-" .. player_realm
                the_unit = the_unit:gsub("%s+", "")
                if TRP3_API.register.isUnitIDKnown(the_unit) and TRP3_API.register.hasProfile(the_unit) then
                    button.RP:SetText("Y")
                else
                    button.RP:SetText("N")
                end
            else
                button.RP:SetText("-")
            end
            button.Sex:SetText(genderTable[sex])

            -- Highlight the correct who
            if ( WhoFrame.selectedWho == whoIndex ) then
                button:LockHighlight();
            else
                button:UnlockHighlight();
            end
        end

        if ( whoIndex > numWhosFiltered ) then
            button:Hide();
        else
            button:Show();
            usedHeight = usedHeight + FRIENDS_FRAME_WHO_HEIGHT;
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
	HybridScrollFrame_Update(WhoListScrollFrame, numWhos * FRIENDS_FRAME_WHO_HEIGHT, usedHeight);


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
        for i = 1, #FriendsListFrameScrollFrame.buttons do
            local btn = _G["FriendsListFrameScrollFrameButton" .. i];
            if (btn) then
                local noteString = _G["FriendsListFrameScrollFrameButton" .. i .. "Note"];
                local noteIcon = _G["FriendsListFrameScrollFrameButton" .. i .. "NoteIcon"];
                local note = "";
                local charInfo = "";
                local isOnline = false;
                if (btn:IsVisible()) then
                    if (btn.buttonType == FRIENDS_BUTTON_TYPE_WOW) then
                        local friendInfo = C_FriendList.GetFriendInfoByIndex(btn.id);
                        note = friendInfo.notes;
                        isOnline = friendInfo.conneted;
                    elseif (btn.buttonType == FRIENDS_BUTTON_TYPE_BNET) then
                        local accountInfo = C_BattleNet.GetFriendAccountInfo(btn.id);
                        gameAccountInfo = accountInfo.gameAccountInfo;
                        note = accountInfo.note;
                        isOnline = gameAccountInfo.isOnline;

                        if (gameAccountInfo.gameAccountID and gameAccountInfo.isOnline) then
                            if (gameAccountInfo.clientProgram == BNET_CLIENT_WOW) then
                                local color = "";
                                if (gameAccountInfo.factionName ~= UnitFactionGroup("player")) then
                                    color = "|cffff6060";
                                end

                                local realmName = '';
                                if gameAccountInfo.realmDisplayName then
                                    realmName = gameAccountInfo.realmDisplayName;
                                end

                                local raceName = '';
                                if gameAccountInfo.raceName then
                                    raceName = gameAccountInfo.raceName;
                                end

                                local className = '';
                                if gameAccountInfo.className then
                                    className = gameAccountInfo.className
                                end

                                charInfo = color .. string.format(L["FRIEND_INFO_TEMPLATE_WOW"], gameAccountInfo.characterLevel, raceName, className) .. "\n" .. realmName;
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
                    -- btn:SetHeight(NEW_FRIEND_BUTTON_HEIGHT + 5);
                else
                    noteString:Hide();
                    noteIcon:Hide();
                end
                local infoString = _G["FriendsListFrameScrollFrameButton" .. i .. "CharInfo"];
                infoString:SetText(charInfo);
            end
        end
    end

end


function ExtSocialUI_FriendsFrameWhoButton_OnClick(self, button)
    local clickedButton = _G["NewWhoFrameButton" .. self:GetID()];
    if (button == "LeftButton") then
        WhoFrame.selectedWho = clickedButton.whoIndex;
        WhoFrame.selectedName = clickedButton.Name:GetText();
        ExtSocialUI_WhoList_Update();
    else
        local name = clickedButton.Name:GetText();
        FriendsFrame_ShowDropdown(name, 1);
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
