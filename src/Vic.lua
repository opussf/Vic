VIC_MSG_VERSION = GetAddOnMetadata("Vic","Version");
	
Vic = {};
Vic_options = {["enabled"] = true,["symbol"] = "star",};
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
	VicFrame:RegisterEvent("VARIABLES_LOADED");
	
	SLASH_VIC1 = "/vic";
	SlashCmdList["VIC"] = Vic.Command;
end

function Vic.OptionsOnLoad(frame)
	local ristring = '|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_%d:0:0:0:-1|t %s'

	frame.name = "Victorious Reporter";
	VicOptionsFrame_Title:SetText("Victorious Reporter "..VIC_MSG_VERSION);
	for symbol, v in pairs(Vic.raidIconValues) do
		getglobal("VicOptionsFrame_RadioSymbol"..v.."Text"):SetText(ristring:format(v, symbol));
	end
	frame.okay = Vic.OptionsOkay;
	frame.cancel = Vic.OptionsCancel;
	
	InterfaceOptions_AddCategory(frame);
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

function Vic.VARIABLES_LOADED(...)
	VicFrame:UnregisterEvent("VARIABLES_LOADED");
	Vic.OptionsSetOptions();
end

function Vic.COMBAT_LOG_EVENT_UNFILTERED(...)
	-- http://www.wowwiki.com/API_COMBAT_LOG_EVENT
	_, _, Vic.event = select(1, ...);  -- frame, ts, event
	_, _, Vic.srcName, _, _, _, _, _, _, Vic.spellID, Vic.spellName = select(4, ...);
	if (Vic_options.enabled and Vic.spellID == 32216) then
		--Vic.Print(Vic.event .. ":"..Vic.spellID..":"..Vic.spellName..":"..Vic.srcName);
		if (string.find(Vic.event, "SPELL_AURA_APPLIED")) then
			if Vic_options.symbol then
				SetRaidTarget(Vic.srcName, Vic.raidIconValues[Vic_options.symbol]);
			else
				Vic.PartyPrint(Vic.spellName.." applied to "..Vic.srcName);
			end
		elseif (string.find(Vic.event, "SPELL_AURA_REFRESH")) then
			if Vic_options.symbol then
				SetRaidTarget(Vic.srcName, Vic.raidIconValues[Vic_options.symbol]);
			else
				Vic.PartyPrint(Vic.spellName.." refreshed on "..Vic.srcName);
			end
		elseif (string.find(Vic.event, "SPELL_AURA_REMOVED")) then
			if Vic_options.symbol then
				SetRaidTarget(Vic.srcName, 0);
			else
				Vic.PartyPrint(Vic.spellName.." removed from "..Vic.srcName);
			end
		else
			Vic.Print(Vic.event.." :: "..Vic.spellName);
		end
	end
end

function Vic.OptionsSetOptions()
	for text, v in pairs(Vic.raidIconValues) do
		if text == Vic_options["symbol"] then
			getglobal("VicOptionsFrame_RadioSymbol"..v):SetChecked(true);
		else
			getglobal("VicOptionsFrame_RadioSymbol"..v):SetChecked(false);
		end
	end
	if Vic_options["enabled"] then
		VicOptionsFrame_EnableBox:SetChecked(true);
	end
end

function Vic.OptionsRadioButtonClick(button)
	--Vic.Print("Post Click:"..button:GetName():sub(-1));
	clickValue = tonumber(button:GetName():sub(-1));
	for _,v in pairs(Vic.raidIconValues) do
		if v == clickValue then
			getglobal("VicOptionsFrame_RadioSymbol"..v):SetChecked(true);
		else
			getglobal("VicOptionsFrame_RadioSymbol"..v):SetChecked(false);
		end
	end
end

function Vic.OptionsOkay()
	--Vic.Print("OKAY");
	for symbol,v in pairs(Vic.raidIconValues) do
		if getglobal("VicOptionsFrame_RadioSymbol"..v):GetChecked() then
			--Vic.Print(symbol.." is checked.");
			Vic_options["symbol"] = symbol;
		end
	end
	Vic_options.enabled = VicOptionsFrame_EnableBox:GetChecked();
end

function Vic.OptionsCancel()
	-- When options CANCEL is pressed.
	Vic.OptionsSetOptions();
end

function Vic.Command(msg)
	InterfaceOptionsFrame_OpenToCategory("Victorious Reporter");
end
