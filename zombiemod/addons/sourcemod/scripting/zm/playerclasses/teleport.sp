void TeleportOnCommandInit()
{
	HookConVarChange(sCvarList.TELEPORT_MENU_COMMANDS, Hook_OnCvarTeleport);
	
	TeleportOnCvarLoad();
}

public void Hook_OnCvarTeleport(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (strcmp(oldValue, newValue, false) != 0)
	{
		TeleportOnCvarLoad();
	}
}

void TeleportOnCvarLoad()
{
	AddConVarCommand(sCvarList.TELEPORT_MENU_COMMANDS, Command_Teleport);
}

public Action Command_Teleport(int client, int args)
{
	char commands[2];
	sCvarList.TELEPORT_MENU_COMMANDS.GetString(commands, sizeof(commands));
	ReplaceString(commands, sizeof(commands), " ", "");
	if (!hasLength(commands)) {
		return Plugin_Continue;
	}

	TeleportClient(client);
	return Plugin_Handled;
}

bool TeleportClient(int client, bool force = false)
{
	if (IsValidClient(client) && IsPlayerAlive(client) && GetEntProp(client, Prop_Send, "m_iObserverMode") == 0)
	{
		if (!force && sCvarList.TELEPORT_ESCAPE.BoolValue && !ModesIsEscape(sServerData.RoundMode))
		{
			TranslationPrintToChat(client, "teleport restricted escape");
			return false;
		}
		
		bool infect = sClientData[client].Zombie;
		
		if (!force && infect && !sCvarList.TELEPORT_ZOMBIE.BoolValue)
		{
			TranslationPrintToChat(client, "teleport restricted zombie");
			return false;
		}
		
		if (!force && !infect && !sCvarList.TELEPORT_HUMAN.BoolValue)
		{
			TranslationPrintToChat(client, "teleport restricted human");
			return false;
		}
		
		int TeleportMax = infect ? sCvarList.TELEPORT_MAX_ZOMBIE.IntValue : sCvarList.TELEPORT_MAX_HUMAN.IntValue;
		if (!force && sClientData[client].TeleTimes >= TeleportMax)
		{
			TranslationPrintToChat(client, "teleport max", TeleportMax);
			return false;
		}
		
		if (sClientData[client].TeleTimer != null)
		{
			if (!force)
			{
				TranslationPrintToChat(client, "teleport in progress");
			}
			return false;
		}
		
		if (force)
		{
			SpawnTeleportToRespawn(client);
			return true;
		}
		
		ToolsGetOrigin(client, sClientData[client].TeleOrigin);
		
		sClientData[client].TeleCounter = infect ? sCvarList.TELEPORT_DELAY_ZOMBIE.IntValue : sCvarList.TELEPORT_DELAY_HUMAN.IntValue;
		if (sClientData[client].TeleCounter > 0)
		{
			TranslationPrintCenterText(client, "teleport countdown", sClientData[client].TeleCounter);
			
			sClientData[client].TeleTimer = CreateTimer(1.0, Timer_TeleportOnClientCount, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
		}
		else
		{
			SpawnTeleportToRespawn(client);
			
			sClientData[client].TeleTimes++;
			
			TranslationPrintCenterText(client, "teleport countdown end", sClientData[client].TeleTimes, TeleportMax);
		}
		return true;
	}
	return false;
}

public Action Timer_TeleportOnClientCount(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);

	if (client)
	{
		if (sCvarList.TELEPORT_AUTOCANCEL.BoolValue)
		{
			static float position[3];
			ToolsGetOrigin(client, position); 
			
			float flDistance = GetVectorDistance(position, sClientData[client].TeleOrigin, true);
			float flAutoCancelDist = sCvarList.TELEPORT_AUTOCANCEL_DIST.FloatValue;
  
			if (flDistance > flAutoCancelDist * flAutoCancelDist)
			{
				TranslationPrintCenterText(client, "teleport autocancel centertext");
				TranslationPrintToChat(client, "teleport autocancel text", RoundToNearest(flAutoCancelDist));
				
				sClientData[client].TeleTimer = null;
				return Plugin_Stop;
			}
		}

		sClientData[client].TeleCounter--;
		
		TranslationPrintCenterText(client, "teleport countdown", sClientData[client].TeleCounter);
		
		if (sClientData[client].TeleCounter <= 0)
		{
			SpawnTeleportToRespawn(client);
			
			sClientData[client].TeleTimes++;
			
			TranslationPrintToChat(client, "teleport countdown end", sClientData[client].TeleTimes, sClientData[client].Zombie ? sCvarList.TELEPORT_MAX_ZOMBIE.IntValue : sCvarList.TELEPORT_MAX_HUMAN.IntValue);
			
			sClientData[client].TeleTimer = null;
			return Plugin_Stop;
		}
		return Plugin_Continue;
	}
	
	sClientData[client].TeleTimer = null;
	return Plugin_Stop;
}