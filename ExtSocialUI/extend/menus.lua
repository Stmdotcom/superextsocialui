--[[
	(C) 2014-2016 Bor Blasthammer <bor@blasthammer.net>

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]

-- This adds "Roleplay Profile" menu entries to several menus for a more
-- convenient way to access profiles (including chat names, guild lists, and
-- chat rosters).
--
-- Also adds a name copy window
--
-- Note: Depends on totalRP3

local EXTSOC_HAS_TP3 = false
local newTimer = nil
local player_realm = GetRealmName()
local Buttons_Profile = { text = "Show RP" }
local Buttons_Profile_Copy = { text = "Copy Name" }
local isHooked, standard

if TRP3_API then
	EXTSOC_HAS_TP3 = true
	newTimer = C_Timer.NewTimer;
end

local function UnitPopup_OnClick_Hook(self)
	if not standard and not units then return end

	if self.value == "EXTSOC_RP_VIEW_CHARACTER" then
		the_server = UIDROPDOWNMENU_INIT_MENU.server or player_realm

		Open_TRP3_Frame(UIDROPDOWNMENU_INIT_MENU.name, the_server)
	elseif self.value == "EXTSOC_RP_VIEW_BN" then
		local gameAccountInfo = UIDROPDOWNMENU_INIT_MENU.accountInfo.gameAccountInfo
		if gameAccountInfo.clientProgram == BNET_CLIENT_WOW and gameAccountInfo.realmName ~= "" then
			Open_TRP3_Frame(gameAccountInfo.characterName, gameAccountInfo.realmName)
		end
	elseif self.value == "EXTSOC_COPY_NAME" then
		TRP3_API.Ellyb.Popups:OpenURL(UIDROPDOWNMENU_INIT_MENU.accountInfo.gameAccountInfo.characterName, "COPY NAME");
	end
end

function Open_TRP3_Frame(name, server)
	the_unit = name .. "-" .. server
	the_unit = the_unit:gsub("%s+", "")

	if TRP3_API.register.isUnitIDKnown(the_unit) and TRP3_API.register.hasProfile(the_unit) then
		TRP3_API.navigation.openMainFrame();
		TRP3_API.register.openPageByUnitID(the_unit);
	else
		TRP3_API.r.sendQuery(the_unit);
		--TODO: Make this a callback watching the 'Events.REGISTER_DATA_UPDATED' event in trp3
		newTimer(5, function()
			if TRP3_API.register.isUnitIDKnown(the_unit) and TRP3_API.register.hasProfile(the_unit) then
				TRP3_API.navigation.openMainFrame();
				TRP3_API.register.openPageByUnitID(the_unit);
			else
				TRP3_API.utils.message.displayMessage("Could not load profile, try again or they don't have RP addon")
			end
		end)
	end
end

local function UnitPopup_HideButtons_Hook()
	if not standard or UIDROPDOWNMENU_INIT_MENU.which ~= "BN_FRIEND" or UIDROPDOWNMENU_MENU_VALUE and UIDROPDOWNMENU_MENU_VALUE ~= "BN_FRIEND" then return end
	for i, button in ipairs(UnitPopupMenus["BN_FRIEND"]) do
		if button == "EXTSOC_RP_VIEW_BN" then
			if not UIDROPDOWNMENU_INIT_MENU.bnetIDAccount then
				UnitPopupShown[UIDROPDOWNMENU_MENU_LEVEL][i] = 0
			else
				--table.foreach(UIDROPDOWNMENU_INIT_MENU, print)
				if UIDROPDOWNMENU_INIT_MENU.accountInfo.gameAccountInfo.clientProgram ~= BNET_CLIENT_WOW or UIDROPDOWNMENU_INIT_MENU.accountInfo.gameAccountInfo.realmName == "" then
					UnitPopupShown[UIDROPDOWNMENU_MENU_LEVEL][i] = 0
				else
					UnitPopupShown[UIDROPDOWNMENU_MENU_LEVEL][i] = 1
				end
			end
			break
		end
	end
end

extmenu_standard = function(setting)
	if setting then
		if not isHooked then
			hooksecurefunc("UnitPopup_OnClick", UnitPopup_OnClick_Hook)
			isHooked = true
		end

		if standard == nil then
			hooksecurefunc("UnitPopup_HideButtons", UnitPopup_HideButtons_Hook)
			for i, button in ipairs(UnitPopupMenus["FRIEND"]) do
				if button == "PVP_REPORT_AFK" then
					table.remove(UnitPopupMenus["FRIEND"], i)
				end
			end
		end
		if not standard then
			UnitPopupButtons["EXTSOC_RP_VIEW_CHARACTER"] = Buttons_Profile
			UnitPopupButtons["EXTSOC_RP_VIEW_BN"] = Buttons_Profile
			UnitPopupButtons["EXTSOC_COPY_NAME"] = Buttons_Profile_Copy

			if EXTSOC_HAS_TP3 then
				table.insert(UnitPopupMenus["FRIEND"], 1, "EXTSOC_RP_VIEW_CHARACTER")
				table.insert(UnitPopupMenus["GUILD"], 1, "EXTSOC_RP_VIEW_CHARACTER")
				table.insert(UnitPopupMenus["CHAT_ROSTER"], 1, "EXTSOC_RP_VIEW_CHARACTER")
				table.insert(UnitPopupMenus["BN_FRIEND"], 1, "EXTSOC_RP_VIEW_BN")

				table.insert(UnitPopupMenus["FRIEND"], 1, "EXTSOC_COPY_NAME")
				table.insert(UnitPopupMenus["GUILD"], 1, "EXTSOC_COPY_NAME")
				table.insert(UnitPopupMenus["CHAT_ROSTER"], 1, "EXTSOC_COPY_NAME")
				table.insert(UnitPopupMenus["BN_FRIEND"], 1, "EXTSOC_COPY_NAME")
				table.insert(UnitPopupMenus["FRIEND_OFFLINE"], 1, "EXTSOC_COPY_NAME")
				table.insert(UnitPopupMenus["BN_FRIEND_OFFLINE"], 1, "EXTSOC_COPY_NAME")
			end
		end
		standard = true
	elseif standard ~= nil then
		UnitPopupButtons["XRP_VIEW_CHARACTER"] = nil
		UnitPopupButtons["XRP_VIEW_BN"] = nil
		for i, button in ipairs(UnitPopupMenus["FRIEND"]) do
			if button == "XRP_VIEW_CHARACTER" then
				table.remove(UnitPopupMenus["FRIEND"], i)
				break
			end
		end
		for i, button in ipairs(UnitPopupMenus["GUILD"]) do
			if button == "XRP_VIEW_CHARACTER" then
				table.remove(UnitPopupMenus["GUILD"], i)
				break
			end
		end
		for i, button in ipairs(UnitPopupMenus["CHAT_ROSTER"]) do
			if button == "XRP_VIEW_CHARACTER" then
				table.remove(UnitPopupMenus["CHAT_ROSTER"], i)
				break
			end
		end
		for i, button in ipairs(UnitPopupMenus["BN_FRIEND"]) do
			if button == "XRP_VIEW_BN" then
				table.remove(UnitPopupMenus["BN_FRIEND"], i)
				break
			end
		end
		standard = false
	end
end
extmenu_standard(true)
