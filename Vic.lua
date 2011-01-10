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

function Vic.OnLoad()
	VicFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
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
	if (spellID == 32216) then
		if (string.find(Vic.event), "SPELL_AURA_APPLIED") then
			Vic.PartyPrint(spellName.." applied to "..srcName);
		elseif (string.find(Vic.event), "SPELL_AURA_REFRESH") then
			Vic.PartyPrint(spellName.." refreshed on "..srcName);
		elseif (string.find(Vic.event), "SPELL_AURA_REMOVED") then
			Vic.PartyPrint(spellName.." removed from "..srcName);
		else
			Vic.Print(Vic.event.." :: "..spellName);
		end
	end
end
