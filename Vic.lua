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
Vic_options = {["enabled"] = true,};
Vic.raidIconValues = {
	["star"] = 1,
	["circle"] = 2,
	["diamond"] = 3,
	["triangle"] = 4,
	["moon"] = 5,
	["square"] = 6,
	["cross"] = 7,
	["skull"] = 8,
}

function Vic.OnLoad()
	VicFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
	
	SLASH_VIC1 = "/vic";
	SlashCmdList["VIC"] = function(msg) Vic.Command(msg); end
end

function Vic.PartyPrint( msg )
	-- prints to Party
	-- 1.19 - update to output to guild, raid / party or none.
	if (GetNumRaidMembers() > 0) then
		SendChatMessage( msg, "RAID" );
	elseif (GetNumPartyMembers() > 0) then
		SendChatMessage( msg, "PARTY" );
	else
		Vic.Print( COLOR_RED.."Vic_ToParty: "..COLOR_END..msg, false );
	end
end

function Vic.Print( msg, showName)
	-- print to the chat frame
	-- set showName to false to suppress the addon name printing
	if (showName == nil) or (showName) then
		msg = COLOR_RED.."Vic> "..COLOR_END..msg;
	end
	DEFAULT_CHAT_FRAME:AddMessage( msg );
end

function Vic.COMBAT_LOG_EVENT_UNFILTERED(...)
	-- http://www.wowwiki.com/API_COMBAT_LOG_EVENT
	_, _, Vic.event = select(1, ...);  -- frame, ts, event
	local _, srcName, _, _, _, _, spellID, spellName = select(4, ...);
	--local srcGUID, srcName, srcFlags, targetGUID, targetName, targetFlags = select(4, ...);
	if (Vic_options.enabled and spellID == 32216) then
		if (string.find(Vic.event, "SPELL_AURA_APPLIED")) then
			if Vic_options.symbol then
				SetRaidTarget(srcName, Vic.raidIconValues[Vic_options.symbol]);
			else
				Vic.PartyPrint(spellName.." applied to "..srcName);
			end
		elseif (string.find(Vic.event, "SPELL_AURA_REFRESH")) then
			if Vic_options.symbol then
				SetRaidTarget(srcName, Vic.raidIconValues[Vic_options.symbol]);
			else
				Vic.PartyPrint(spellName.." refreshed on "..srcName);
			end
		elseif (string.find(Vic.event, "SPELL_AURA_REMOVED")) then
			if Vic_options.symbol then
				SetRaidTarget(srcName, 0);
			else
				Vic.PartyPrint(spellName.." removed from "..srcName);
			end
		else
			Vic.Print(Vic.event.." :: "..spellName);
		end
	end
end

Vic.commandList = {
	["enable"] = {
		["func"] = function()
				Vic_options.enabled = true;
				Vic.Print("Vic is now enabled.");
			end,
		["help"] = "Enable",
	},
	["disable"] = {
		["func"] = function()
				Vic_options.enabled = nil;
				Vic.Print("Vic is now disabled.");
			end,
		["help"] = "Disable",
	},
	["status"] = {
		["func"] = function()
				outStr = "disabled.";
				outStr = Vic_options.enabled and "enabled.";
				Vic.Print("Vic status is "..outStr);
				if Vic_options.symbol then
					Vic.Print("Vic will set {"..Vic_options.symbol.."} when active.");
				else
					Vic.Print("No symbol will be set.");
				end
			end,
		["help"] = "Show status",
	},
	["help"] = {
		["func"] = function()
				for k, val in pairs(Vic.commandList) do
					Vic.Print(string.format("%s %-8s -> %s", SLASH_VIC1, k, val.help));
				end
			end,
		["help"] = "Print this help.",
	},
	["symbol"] = {
		["func"] = function( param )
				if Vic.raidIconValues[param] then
					Vic_options.symbol = param;
					Vic.Print("Symbol set to: {"..param.."}");
				else
					Vic_options.symbol = nil;
					Vic.Print("No Symbol will be set");
				end
			end,
		["help"] = "Sets the given symbol to put on the warrior.",
	},
}

function Vic.Command(msg)
	local cmd, param = Vic.ParseCmd(msg);
	cmd = string.lower(cmd);
	
	local cmdFunc = Vic.commandList[cmd];
	
	if cmdFunc then
		cmdFunc.func(param);
	else
		Vic.commandList.help.func();
	end
end

function Vic.ParseCmd(msg)
	if msg then
		local a,b,c = strfind(msg, "(%S+)");  --contiguous string of non-space characters
		if a then
			return c, strsub(msg, b+2);
		else
			return "";
		end
	end
end
