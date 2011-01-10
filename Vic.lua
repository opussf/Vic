-- Colours
COLOR_RED = "|cffff0000";
COLOR_GREEN = "|cff00ff00";
COLOR_BLUE = "|cff0000ff";
COLOR_PURPLE = "|cff700090";
COLOR_YELLOW = "|cffffff00";
COLOR_ORANGE = "|cffff6d00";
COLOR_GREY = "|cff808080";
COLOR_GOLD = "|cffcfb52b";
COLOR_NEON_BLUE = "|cff4d4dff";
COLOR_END = "|r";

Vic = {};

function Rested_OnLoad()
	RestedFrame:RegisterEvent("PLAYER_XP_UPDATE");
	RestedFrame:RegisterEvent("UPDATE_EXHAUSTION");
	RestedFrame:RegisterEvent("CHANNEL_UI_UPDATE");
	RestedFrame:RegisterEvent("ADDON_LOADED");
	RestedFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
	RestedFrame:RegisterEvent("PLAYER_UPDATE_RESTING");
	--RestedFrame:RegisterEvent("PLAYER_LEAVING_WORLD");
	--RestedFrame:RegisterEvent("PLAYER_REGEN_ENABLED");
	
	--register slash commands
	SLASH_RESTED1 = "/rested";
	SlashCmdList["RESTED"] = function(msg) Rested.Command(msg); end
	Rested.debug = false;
	Rested.info = false;
end

function Rested.ADDON_LOADED()
	Rested.name = UnitName("player");
	Rested.realm = GetRealmName();

	-- init unsaved variables
	-- Global
	if not Rested_options.ignoreTime then
		Rested_options.ignoreTime = 3600;
	end
--[[
	if Rested_restedState == nil then
		Rested_restedState = {};
		Rested.Print("restedState init");
	end
]]--

	-- find or init the realm
	realmFound, playerFound = false, false;
	for k,v in pairs(Rested_restedState) do
		if (k == Rested.realm) then
			realmFound = true;
			break;
		end
	end
	if not realmFound then
		Rested_restedState[Rested.realm] = {};
	end

	-- find or init the player
	for k,v in pairs(Rested_restedState[Rested.realm]) do
		if (k == Rested.name) then
			playerFound = true;
			v.ignore = nil;
			break;
		end
	end
	if not playerFound then
		Rested_restedState[Rested.realm][Rested.name] = {};
		Rested_restedState[Rested.realm][Rested.name].initAt = time();
		Rested_restedState[Rested.realm][Rested.name].restedPC = 0;
		Rested_restedState[Rested.realm][Rested.name].class = UnitClass("player");
		Rested_restedState[Rested.realm][Rested.name].faction = select(2, UnitFactionGroup("player"));  -- localized string
		Rested_restedState[Rested.realm][Rested.name].race = UnitRace("player");
		Rested.Print(Rested.name.." added to rested list.");
		Rested.PrintToonCount();
	end

	Rested_restedState[Rested.realm][Rested.name].updated = time();
	
	if not Rested.bars then
		Rested.BuildBars();
		--Rested.Print("Built Bars");
	end
	
	if not Rested_restedState[Rested.realm][Rested.name].race then  -- added these 3 at the same time
		Rested_restedState[Rested.realm][Rested.name].class = UnitClass("player");
		Rested_restedState[Rested.realm][Rested.name].faction = select(2, UnitFactionGroup("player"));  -- localized string
		Rested_restedState[Rested.realm][Rested.name].race = UnitRace("player");
	end
	
	--Rested.Print("Addon_Loaded End");
end

function Rested.Print( msg, showName)
	-- print to the chat frame
	-- set showName to false to suppress the addon name printing
	if (showName == nil) or (showName) then
		msg = COLOR_RED..RESTED_MSG_ADDONNAME.."> "..COLOR_END..msg;
	end
	DEFAULT_CHAT_FRAME:AddMessage( msg );
end

function Rested.PrintStatus()
	Rested.Print("Version: "..RESTED_MSG_VERSION);
--	Rested.Print("Memory usage: "..collectgarbage("count").." kB");
	Rested.Print("Max Level nagtime: "..COLOR_GREEN..Rested_options.maxCutOff..COLOR_END.." Days.");
	Rested.Print("Max Level stale time: "..COLOR_GREEN..Rested_options.maxStale..COLOR_END.." Days.");
	Rested.PrintToonCount();
end

function Rested.GetToonCount()
	local realmCount = 0;
	local nameCount = 0;
	for r, v in pairs(Rested_restedState) do
		for n, _ in pairs(v) do
			nameCount = nameCount + 1;
		end
		realmCount = realmCount + 1;
	end
	return nameCount, realmCount;
end

function Rested.PrintToonCount()
	local nameCount, realmCount = Rested.GetToonCount();
	Rested.Print(nameCount .." toons found on ".. realmCount .." realms.");
end

function Rested_Debug( msg )
	-- Print Debug Messages
	if Rested.debug then
		msg = "debug-"..msg;
		Rested.Print( msg );
	end
end

function Rested_OnEvent(event, ...)
	if (event == "ADDON_LOADED") then
		Rested.ADDON_LOADED();
	elseif (event == "PLAYER_ENTERING_WORLD") then
		Rested.Print(date("%x %X")..":"..event);
		Rested.SaveRestedState();
		count = Rested.ForAllAlts( Rested.StaleCharacters );
		if (count > 0) then
			Rested.Print("Found "..count.." stale characters.");
			Rested.reportName = "Stale";
			Rested.ShowReport( Rested.StaleCharacters );
		end
		--Rested_Friend();
	else
		--Rested.Print("Rested Update");
		Rested.SaveRestedState();
	end
end

function Rested.ParseCmd(msg)
	if msg then
		local a,b,c = strfind(msg, "(%S+)");  --contiguous string of non-space characters
		if a then
			return c, strsub(msg, b+2);
		else
			return "";
		end
	end
end

Rested.commandList = {
	["help"] = function() Rested.PrintHelp(); end,
	["status"] = function() Rested.PrintStatus(); end,
	["max"] = function() 
			Rested.reportName = "Level "..Rested.maxLevel;	
			Rested.ShowReport( Rested.MaxCharacters ); 
		end,
	["nag"] = function()
			Rested.reportName = "Nag";
			Rested.ShowReport( Rested.NagCharacters );
		end,
	["stale"] = function()
			Rested.reportName = "Stale";
			Rested.ShowReport( Rested.StaleCharacters );
		end,
	["resting"] = function()
			Rested.SaveRestedState();
			Rested.reportName = "Resting";
			Rested.ShowReport( Rested.RestingCharacters );
		end,
	["ignore"] = function(param)
			if (param and strlen(param)>0) then
				Rested.SetIgnore(param);
			else
				Rested.reportName = "Ignored";
				Rested.ShowReport( Rested.IgnoredCharacters, true );  -- true is processIgnored
			end
		end,
	["config"] = function()
		end,
	["all"] = function()
			Rested.reportName = "All";
			Rested.ShowReport( Rested.AllCharacters );
		end,		
}

function Rested.Command(msg)
	local cmd, param = Rested.ParseCmd(msg);
	cmd = string.lower(cmd);
	func = Rested.commandList[cmd];
	if func then
		func(param);
	else
		if (cmd ~= nil) and (string.sub(cmd,1,1) == "-") then
			Rested.RemoveFromRested( string.sub(cmd,2) );
			return;
		end
		Rested.commandList["resting"]();
	end
end

-- slash function handle
function Rested.Command_old(msg)
	--cmd will be nothing
	local cmd, param = Rested.ParseCmd(msg);
	cmd = string.lower(cmd);
	
	if (cmd == "help") then
		Rested.PrintHelp();
		return;
	elseif (cmd == "nagtime") then
		Rested.setNagTime( param );
	elseif (cmd == "skills") then
		Rested.PrintSkills();
	elseif (cmd == "friend") then
		Rested.Friend();
	elseif (cmd == "find") then
		Rested.Search(param);
	else
		if (cmd ~= nil) and (string.sub(cmd,1,1) == "-") then
			Rested.RemoveFromRested( string.sub(cmd,2) );
			return;
		end
		Rested.SaveRestedState();
		Rested.reportName = "Resting";
		Rested.ShowReport( Rested.RestingCharacters );
	end
end

function Rested.PrintHelp()
	Rested.Print("/Rested           -> Rested Report");
	Rested.Print("/Rested -name     -> Remove name from tracking");
	Rested.Print("/Rested help      -> Shows this menu");
	Rested.Print("/Rested status    -> Shows status info");
	Rested.Print("/Rested max       -> Shows list of max level toons");
	Rested.Print("/Rested stale     -> Shows list of stale toons");
	Rested.Print("/Rested nagtime # -> Set # of nag days for max lvl toons");
	Rested.Print("/Rested ignore name -> Ignore for "..SecondsToTime(Rested_options.ignoreTime));
end

function Rested.SaveRestedState()
	--Rested.Print("Save Rested State");
	Rested.rested = GetXPExhaustion();		-- XP till Exhaustion
	if (Rested.rested == nil) then
		Rested.rested = 0;
	end
	if (Rested.rested > 0) then
		Rested.restedPC = (Rested.rested / UnitXPMax("player")) * 100;
	else
		Rested.restedPC = 0;
	end

	if (Rested.info) then
		Rested.Print("UPDATE_EXHAUSTION fired at "..time()..": "..Rested.restedPC.."%");
	end
	if (Rested.realm ~= nil) and (Rested.name ~= nil) then
		Rested_restedState[Rested.realm][Rested.name].restedPC = Rested.restedPC;
		Rested_restedState[Rested.realm][Rested.name].updated = time();
		Rested_restedState[Rested.realm][Rested.name].lvlNow = UnitLevel("player");
		Rested_restedState[Rested.realm][Rested.name].xpMax = UnitXPMax("player");
		Rested_restedState[Rested.realm][Rested.name].xpNow = UnitXP("player");
		Rested_restedState[Rested.realm][Rested.name].isResting = IsResting();
	else
		Rested.Print("Realm and name not known");
	end
end

function Rested.ForAllAlts( action, processIgnored )
	-- loops through all the alts, using the action to return count and to build
	-- Rested.charList
	Rested.charList = {};
	count = 0;
	for realm in pairs(Rested_restedState) do
		for name,vals in pairs(Rested_restedState[realm]) do
			if (vals.ignore) then  -- character is being ignored
				Rested.updateIgnore(vals);
				if processIgnored then
					count = count + action( realm, name, vals );
				end
			elseif (Rested.filter) then -- there is a filter value
				
				if (string.find(string.upper(realm), Rested.filter)  or        -- match realm
					string.find(string.upper(name), Rested.filter)) then      -- match name
					count = count + action( realm, name, vals );
				else  -- search the keys that exist that I'm searching
					match = false;
					for _, key in pairs( Rested.searchKeys ) do
						if (vals[key] and string.find(string.upper(vals[key]), Rested.filter)) then
							match = true;
						end
					end
					if match then
						count = count + action( realm, name, vals );
					end
				end
			else  -- no filter class, not ignored
				count = count + action(realm, name, vals);
			end
		end
	end
	return count;
end

function Rested.RestingCharacters( realm, name, charStruct )
	-- takes the realm, name, charStruct
	-- appends to the global Rested.charList
	-- returns 1 on success, 0 on fail
	if (charStruct.lvlNow ~= Rested.maxLevel and charStruct.restedPC ~= 150) or
			(realm == Rested.realm and name == Rested.name) then
		timeSince = time() - charStruct.updated;
		if charStruct.isResting then  -- http://www.wowwiki.com/Rested
			restRate = (5/(8*3600));  -- 5% every 8 hours (5 seems a tad too much)
			code = "+";
		else
			restRate = (5/(32*3600));  -- quarter rate 5% every 32 hours
			code = "-";
		end
		restAdded = restRate * timeSince;
		Rested.strOut = string.format("% 2d%s ", charStruct.lvlNow, code);
		restedVal = charStruct.restedPC + restAdded;
		if restedVal >= 150 then
			Rested.strOut = Rested.strOut .. COLOR_GREEN.."Fully Rested"..COLOR_END;
		else
			restedStr = string.format("%0.1f%%", restedVal);
			if (charStruct.xpNow) then  -- did not always store xpNow
				lvlPCLeft = ((charStruct.xpMax - charStruct.xpNow) / charStruct.xpMax) * 100;
				if (restedVal >= lvlPCLeft) then
					restedStr = COLOR_GREEN..restedStr..COLOR_END;
				end
			end
			timeTilRested = (150-restedVal) / restRate;
			Rested.strOut = Rested.strOut .. restedStr .." ".. SecondsToTime(timeTilRested);
		end
		
		rn = realm..":"..name;
		if (realm == Rested.realm and name == Rested.name) then
			rn = COLOR_GREEN..rn..COLOR_END;
		end
		Rested.strOut = Rested.strOut..": "..rn;
		table.insert( Rested.charList, {restedVal, Rested.strOut} );
		return 1;
	end
	return 0;
end

Rested.reportFunction = Rested.RestingCharacters;

function Rested.StaleCharacters( realm, name, charStruct )
	-- takes the realm, name, charStruct
	-- appends to the global Rested.charList
	-- returns 1 on success, 0 on fail
	local stale = Rested_options.maxStale * 86400;
	timeSince = time() - charStruct.updated;
	if (timeSince > stale) then 
		Rested.strOut = format("%d :: %s : %s:%s", charStruct.lvlNow, SecondsToTime(timeSince), realm, name);
		table.insert(Rested.charList, {timeSince, Rested.strOut});
		return 1;
	end
	return 0;
end

function Rested.NagCharacters( realm, name, charStruct )
	-- takes the realm, name, charStruct
	-- appends to the global Rested.charList
	-- returns 1 on success, 0 on fail
	local timeSince = time() - charStruct.updated;
	if (charStruct.lvlNow == Rested.maxLevel and
			timeSince >= Rested_options.maxCutOff*86400 and
			timeSince <= Rested_options.maxStale * 86400) then
		Rested.strOut = format("%d :: %s : %s:%s", charStruct.lvlNow, SecondsToTime(timeSince), realm, name);
		table.insert(Rested.charList, {timeSince, Rested.strOut});
		return 1;
	end
	return 0;
end

function Rested.MaxCharacters( realm, name, charStruct )
	-- takes the realm, name, charStruct
	-- appends to the global Rested.charList
	-- returns 1 on success, 0 on fail
	if (charStruct.lvlNow == Rested.maxLevel) then
		timeSince = time() - charStruct.updated;
		rn = realm..":"..name;
		if (realm == Rested.realm and name == Rested.name) then
			rn = COLOR_GREEN..rn..COLOR_END;
			Rested.strOut = rn;
		else
			Rested.strOut = SecondsToTime(timeSince) ..": ".. rn;
		end
		--[[
		Rested.Print(string.format("%s: %s is %0.2f%% of %s", rn, timeSince, 
				(timeSince / (Rested_options.maxStale*86400)) * 150, 
				Rested_options.maxStale*86400));
		]]--
		table.insert( Rested.charList, {(timeSince / (Rested_options.maxStale*86400)) * 150, Rested.strOut} );
		return 1;
	end
	return 0;
end

function Rested.IgnoredCharacters( realm, name, charStruct )
	if (charStruct.ignore) then
		timeToGo = charStruct.ignore - time();
		Rested.strOut = SecondsToTime(timeToGo) ..": "..realm..":"..name;
		table.insert( Rested.charList, {timeToGo, Rested.strOut} );
		return 1;
	end
	return 0;
end

function Rested.AllCharacters( realm, name, charStruct )
	-- 80 (15.5%): Realm:Name
	rn = realm..":"..name;
	if (realm == Rested.realm and name == Rested.name) then
		rn = COLOR_GREEN..rn..COLOR_END;
	end
	Rested.strOut = string.format("%d (%0.1f%%): %s",
		charStruct.lvlNow, (charStruct.xpNow / charStruct.xpMax) * 100, rn);
	table.insert( Rested.charList, {(charStruct.lvlNow / Rested.maxLevel) * 150, Rested.strOut} );
	return 1;
end

function Rested.RemoveFromRested( cName )
	cName = string.upper( cName );
	if (cName == string.upper(Rested.name)) then
		Rested.Print("Cannot remove current toon from rested list");
		return
	end
	local numRemoved = 0;
	for r,v in pairs( Rested_restedState ) do
		for n,v in pairs( Rested_restedState[r] ) do
			if (string.upper( n ) == cName) then
				Rested.Print(COLOR_RED.."Removing "..r..":"..n.." from the rested list"..COLOR_END);
				Rested_restedState[r][n] = nil;
				numRemoved = numRemoved + 1;
			end
		end
		local count = 0;
		for n,v in pairs( Rested_restedState[r] ) do
			count = count + 1;
		end
		if (count == 0) then
			Rested.Print(COLOR_RED.."Pruning realm "..r..COLOR_END);
			Rested_restedState[r] = nil;
		end
	end
	if ( numRemoved == 0 ) then
		Rested.Print("No rested record was removed");
	end
	Rested.PrintToonCount();
end

function Rested.setNagTime( param )
	-- need to check for integer value
	a = strfind( param, "[^0-9]" );
	if a then
		Rested_Debug("Bad Data. Nothing changed.");
	else
		Rested_options.maxCutOff = param * 1;
		Rested.Print("Max level nagtime set to "..Rested_options.maxCutOff.." days.");
	end
end

function Rested.PrintSkills()
	numskills =	GetNumSkillLines();
	local profs = nil;
	for i=1, numskills do
		skillname, isHeader, isExpanded, skillRank, _, _, skillMaxRank = GetSkillLineInfo(i);
		if isHeader then
			profs = (skillname == "Professions");
		end
		if not isHeader and profs then
			Rested.Print(skillname..": ".. skillRank.."/"..skillMaxRank);
		end
	end
end

function Rested_Friend()
	-- adds alts to the friend list
	for n, v in pairs(Rested_restedState[Rested.realm]) do
		if (n ~= Rested.name) then
			found = nil;
			for i=1, GetNumFriends() do
				name = GetFriendInfo(i);
				if n == name then found = true; end
			end
			if not found then
				Rested.Print("Adding: "..n);
				AddFriend(n);
			end
		end
		for i=1, GetNumFriends() do
			name, lvl, class, loc, connected, status, note = GetFriendInfo(i);
			if (name == n) then
--				Rested.Print("Update "..n);
				SetFriendNotes(i, "Last on: "..COLOR_GREEN..date("%x", v.updated)..COLOR_END);
			end
		end
	end
end

function Rested.Search( toFind )
	toFind = string.upper( toFind );
	count = 0;
	charList = {};
	for r,v in pairs( Rested_restedState ) do
		for n,v in pairs( Rested_restedState[r] ) do
			if (string.find(string.upper(r), toFind)) or (string.find(string.upper(n), toFind)) then
				Rested.strOut = v.lvlNow .." :: ".. SecondsToTime(time() - v.updated) .." : ".. r ..":".. n;
				if v.lvlNow < Rested.maxLevel then
					Rested.strOut = string.format("%s (%0.2f%%)", Rested.strOut, v.restedPC);
				end
				table.insert(charList, {time() - v.updated, Rested.strOut});
				count = count + 1;
			end
		end
	end
	if (count > 0) then
		Rested.Print("Toons found");
		table.sort(charList, function(a, b) return a[1] < b[1] end);
		table.foreach(charList, function(k, v) Rested.Print(" "..v[2], false) end);
	else
		Rested.Print("No tracked toons were found.", false);
	end
end

function Rested.BuildBars()
	Rested.bars = {};
	for idx = 1,Rested.showNumBars do
		Rested.bars[idx] = {};
		local item = CreateFrame("StatusBar", "Rested_ItemBar"..idx, RestedScrollContents, "Rested_RestedBarTemplate");
		Rested.bars[idx].bar = item;
		if idx==1 then
			item:SetPoint("TOPLEFT", "RestedScrollFrame", "TOPLEFT", 5, -5);
		else
			item:SetPoint("TOPLEFT", Rested.bars[idx-1].bar, "BOTTOMLEFT", 0, 0);
		end
		item:SetMinMaxValues(0, 150);
		item:SetValue(0);
		local text = item:CreateFontString("Rested_ItemText"..idx, "OVERLAY", "Rested_RestedBarTextTemplate");
		Rested.bars[idx].text = text;
		text:SetPoint("TOPLEFT", item, "TOPLEFT", 5, 0);
	end
end

function Rested.ShowReport( report )
	Rested.reportFunction = report;
	RestedFrame:Show();
	Rested_ResetFrame();
	Rested.UpdateFrame();
	UIDropDownMenu_SetText( RestedFrame.DropDownMenu, Rested.reportName );
end

function Rested_OnDragStart()
	RestedFrame:StartMoving();
end

function Rested_OnDragStop()
	RestedFrame:StopMovingOrSizing();
end

function Rested_ResetFrame()
	for i = 1, Rested.showNumBars do
		Rested.bars[i].bar:SetValue(0);
		Rested.bars[i].text:SetText("");
		Rested.bars[i].bar:Hide();
	end
end

function Rested.UpdateFrame()
	if (RestedFrame:IsVisible()) then
		--count = Rested.BuildRestedReport();
		count = Rested.ForAllAlts( Rested.reportFunction, (Rested.reportName == "Ignored") );
		RestedFrame_TitleText:SetText("Rested - "..Rested.reportName.." - "..count);
		if count > 0 then
			table.sort( Rested.charList, function( a,b ) return a[1] > b[1] end );			
			offset = RestedScrollFrame_VSlider:GetValue();
			for i = 1, Rested.showNumBars do
				idx = i+offset;
				if idx<=count then
				--if i<=count then
				--	idx = i+offset;
					Rested.bars[i].bar:SetValue(max(0,Rested.charList[idx][1]));
					Rested.bars[i].text:SetText(Rested.charList[idx][2]);
					Rested.bars[i].bar:Show();
				else
					Rested.bars[i].bar:Hide();
				end
			end
		elseif (Rested.bars and count == 0) then
			for i = 1, Rested.showNumBars do
				Rested.bars[i].bar:Hide();
			end
		end
		RestedScrollFrame_VSlider:SetMinMaxValues(0, max(0,count-Rested.showNumBars));
	end
end

function Rested_OnUpdate()
	-- only gets called when this is shown
	if Rested.lastUpdate + 1 <= time() then
		Rested.lastUpdate = time();
		Rested.UpdateFrame();
	end
end

function Rested.SetIgnore(param)
	param = string.upper(param);
	Rested.Print("SetIgnore: "..param);
	for realm in pairs( Rested_restedState ) do
		for name,vals in pairs( Rested_restedState[realm] ) do
			if ((string.find(string.upper(realm), param)) or (string.find(string.upper(name), param))) then
				vals.ignore = time() + Rested_options.ignoreTime;
				Rested.Print(format("Ignoring %s:%s for %s", realm, name, SecondsToTime(Rested_options.ignoreTime)));
			end
		end
	end
end

function Rested.updateIgnore( alt )
	if (alt.ignore and time()>=alt.ignore) then
		alt.ignore = nil;
	end
end

function Rested.updateFilter()
	if RestedEditBox:GetNumLetters() then
		Rested.filter = string.upper(RestedEditBox:GetText());
		--Rested.Print("updateFilter ("..RestedEditBox:GetNumLetters().."):"..Rested.filter);
		Rested.UpdateFrame();
	else
		Rested.filter = nil;
	end
end

Rested.dropDownMenuTable = {
	["Resting"] = "resting",
	["All"] = "all",
	["Max"] = "max",
	["Nag"] = "nag",
	["Stale"] = "stale",
	["Ignored"] = "ignore",
}

function Rested.DropDownOnLoad( self )
	UIDropDownMenu_Initialize( RestedFrame.DropDownMenu, Rested.DropDownInitialize );
	UIDropDownMenu_JustifyText( RestedFrame.DropDownMenu, "LEFT" );
end

function Rested.DropDownInitialize( self, level )
	local info = UIDropDownMenu_CreateInfo();
	for text, f in pairs( Rested.dropDownMenuTable ) do
		info = UIDropDownMenu_CreateInfo();
		info.text = text;
		info.notCheckable = true;
		info.arg1 = f;
		info.func = Rested.DropDownOnClick;

		UIDropDownMenu_AddButton(info, level);
	end
end

function Rested.DropDownOnClick( self, func )
	Rested.commandList[func]();
end