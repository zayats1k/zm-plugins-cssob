public Action Command_GiveExp(int client, int args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "Usage give_exp <#userid|name|steamid> <amount>");
		return Plugin_Handled;
	}
	
	char arg1[64], target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], m_AccountID = 0, target_count;
	bool tn_is_ml;
	
	GetCmdArg(1, arg1, sizeof(arg1));
	
	if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		m_AccountID = UTIL_GetAccountIDFromSteamID(arg1);
		if (!m_AccountID)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
	}
	
	char args2[10];
	GetCmdArg(2, args2, sizeof(args2));
	
	int exp = StringToInt(args2);
	if (exp <= 0)
	{
		return Plugin_Handled;
	}
	
	if (target_count > 0)
	{
		for (int i = 0; i < target_count; i++)
		{
			int target = target_list[i];
			
			UTIL_LogToFile("zm_database", "[LEVELSYSTEM] Online Player: \"%L\"(lvl: %d | exp: +%d (%d/%d))", target, sClientData[target].Level, exp, sClientData[target].Exp, GetClientExpUp(target));
			
			SetClientExp(target, -1, exp);
		}
		return Plugin_Handled;
	}
	
	int target = GetPlayerOnline(m_AccountID);
	
	if (IsValidClient(target) && !IsFakeClient(target))
	{
		UTIL_LogToFile("zm_database", "[LEVELSYSTEM] Online SteamID: \"%L\"(lvl: %d | exp: +%d (%d/%d))", target, sClientData[target].Level, exp, sClientData[target].Exp, GetClientExpUp(target));
		
		// PrintToChatAll("\x0798FB98[ZM]\x07FFA500 Игрок \x0798FB98%N \x07FFA500купил \x0798FB98+%d Аммо паков \x07FFA500через сайт.", target, exp);
		// PrintToChatAll("\x0798FB98[ZM]\x07FFA500 Игрок \x0798FB98%N \x07FFA500купил \x0798FB98+%d Аммо паков \x07FFA500через сайт.", target, exp);
		// PrintToChatAll("\x0798FB98[ZM]\x07FFA500 Игрок \x0798FB98%N \x07FFA500купил \x0798FB98+%d Аммо паков \x07FFA500через сайт.", target, exp);
		
		PrintToChat(target, "+%d (exp: %d/%d)", exp, sClientData[target].Exp, GetClientExpUp(target));
		
		SetClientExp(target, -1, exp);
	}
	else
	{
		DataPack data = new DataPack();
		
		data.WriteCell(exp);
		data.WriteCell(m_AccountID);
		
		static char buffer[512];
		sServerData.Database.Format(buffer, sizeof(buffer), "SELECT `exp` FROM `zm_core` WHERE `account_id` = '%d'", m_AccountID);
		sServerData.Database.Query(DB_SelectGiveExpCallback, buffer, data);
	}
	return Plugin_Handled;
}

public void DB_SelectGiveExpCallback(Database db, DBResultSet results, const char[] error, DataPack data)
{
	data.Reset();
	int m_exp = data.ReadCell();
	int m_AccountID = data.ReadCell();
	delete data;
	
	if (db == null || results == null || error[0])
	{
		LogError("DB_SelectGiveExpCallback: %s", error);
		return;
	}
	
	char buffer[512];
	if (results.FetchRow())
	{
		int exp = results.FetchInt(0);
		
		FormatEx(buffer, sizeof(buffer), "[U:1:%u]", m_AccountID);
		UTIL_LogToFile("zm_database", "[LEVELSYSTEM] Offline SteamID: %s(exp: +%d (%d))", buffer, m_exp, m_exp+exp);
		sServerData.Database.Format(buffer, sizeof(buffer), "UPDATE `zm_core` SET `exp` = %d WHERE `account_id` = %d;", m_exp+exp, m_AccountID);
		sServerData.Database.Query(DB_UpdateCallback, buffer, _, DBPrio_Low);
	}
	else
	{
		FormatEx(buffer, sizeof(buffer), "[U:1:%u]", m_AccountID);
		UTIL_LogToFile("zm_database", "[LEVELSYSTEM.ERROR] Not Found SteamID: %s(exp: %d)", buffer, m_exp);
	}
}

void SetClientExp(int client, int attacker, int exp)
{
	if (IsValidClient(attacker) && VIP_IsClientVIP(attacker) && DB_GetClientCount() >= 5)
	{
		static char group[SMALL_LINE_LENGTH];
		VIP_GetClientGroup(attacker, group, sizeof(group));
		if (strcmp(group, "VIP") == 0)
		{
			exp *= 2;
		}
		else if (strcmp(group, "SUPERVIP") == 0)
		{
			exp *= 3;
		}
		else if (strcmp(group, "MAXIMUM") == 0)
		{
			exp *= 4;
		}
	}
	
	CreateForward_OnClientExp(client, exp);
	
	sClientData[client].Exp += exp;
	if (sClientData[client].Exp < 0) {
		sClientData[client].Exp = cellmax;
	}
	
	int size = sServerData.ArrayLevels.Length;
	if (sClientData[client].Level == size && sClientData[client].Exp > GetClientExpUp(client))
	{
		sClientData[client].Exp = GetClientExpUp(client); // max exp
	}
	else
	{
		while (sClientData[client].Level < size && sClientData[client].Exp >= GetClientExpUp(client))
		{
			SetClientLevel(client, 1);
		}
		
		CreateForward_OnClientExp_Post(client);
	}
}

void SetClientLevel(int client, int level)
{
	int size = sServerData.ArrayLevels.Length;
	
	if (sClientData[client].Level > size)
	{
		sClientData[client].Level = size; // max level
	}
	else
	{
		sClientData[client].Level += level;
		
		// SetHudTextParamsEx(-1.0, 0.30, 3.0, {0, 255, 255, 255}, {255, 255, 0, 255}, 2, 2.0, 0.0, 1.0);
		// ShowSyncHudText(client, sServerData.SyncHud, "[ LEVEL UP ]");
		
		CreateForward_OnClientLevelUp(client);
		
		OnClientLevelUp(client);
	}
	
	DB_CheckCallbackRankPlace(client);
	DB_ClientUpdate(client, "`lvl` = %d, `exp` = %d, `playtime` = %d", sClientData[client].Level, sClientData[client].Exp, sClientData[client].PlayTime);
}

stock int GetClientExpUp(int client)
{
	int size = sServerData.ArrayLevels.Length;
	if (sClientData[client].Level > size) {
		sClientData[client].Level = size; // max level
	}

	return sServerData.ArrayLevels.Get(sClientData[client].Level-1);
}

stock int GetExpUp(int level)
{
	int size = sServerData.ArrayLevels.Length;
	if (level > size) {
		level = size; // max level
	}

	return sServerData.ArrayLevels.Get(level-1);
}

void OnClientLevelUp(int client)
{
	int level = sClientData[client].Level-1;
	
	int index = sServerData.ArrayReward.FindValue(level);
	if (index != -1)
	{
		LevelData cd;
		sServerData.ArrayReward.GetArray(index, cd, sizeof(cd));
		
		if (cd.params[0])
		{
			char exp[15][50]; 
			for (int i; i < ExplodeString(cd.params, "; ", exp, sizeof(exp), sizeof(exp[])); i++)
			{
				if (strncmp(exp[i], "ap", 2) == 0)
				{
					SetClientAmmoPacks(client, StringToInt(exp[i][3]));
				}
				else if (strncmp(exp[i], "vip", 3) == 0)
				{
					char buffer[2][34];
					ExplodeString(exp[i][4], "|", buffer, sizeof(buffer), sizeof(buffer[]));
					
					if (!VIP_IsClientVIP(client))
					{
						VIP_GiveClientVIP(0, client, buffer[0], StringToInt(buffer[1]));
					}
				}
			}
		}
		
		char buffer[264];
		if (cd.chat_player[0])
		{
			ReplaceString(cd.chat_player, sizeof(cd.chat_player), "\\n", "\n");
			ReplaceString(cd.chat_player, sizeof(cd.chat_player), "#", "\x07");
			ReplaceString(cd.chat_player, sizeof(cd.chat_player), "{default}", "\x01");
			GetClientName(client, buffer, sizeof(buffer));
			ReplaceString(cd.chat_all, sizeof(cd.chat_all), "{NAME}", buffer);
			
			SetGlobalTransTarget(client);
			FormatEx(buffer, sizeof(buffer), IsTranslatedForLanguage(cd.chat_player, GetServerLanguage()) ? "%t":"%s", cd.chat_player);
			PrintToChat(client, "\x01%s", buffer);
		}
		if (cd.chat_all[0])
		{
			ReplaceString(cd.chat_all, sizeof(cd.chat_all), "\\n", "\n");
			ReplaceString(cd.chat_all, sizeof(cd.chat_all), "#", "\x07");
			ReplaceString(cd.chat_all, sizeof(cd.chat_all), "{default}", "\x01");
			GetClientName(client, buffer, sizeof(buffer));
			ReplaceString(cd.chat_all, sizeof(cd.chat_all), "{NAME}", buffer);
			
			if (cd.chat_player[0])
			{
				for (int i = 1; i <= MaxClients; i++)
				{
					if (IsValidClient(i) && !IsFakeClient(i) && i != client)
					{
						SetGlobalTransTarget(i);
						FormatEx(buffer, sizeof(buffer), IsTranslatedForLanguage(cd.chat_all, GetServerLanguage()) ? "%t":"%s", cd.chat_all);
						PrintToChat(i, "\x01%s", buffer);
					}
				}
			}
			else
			{
				FormatEx(buffer, sizeof(buffer), IsTranslatedForLanguage(cd.chat_all, GetServerLanguage()) ? "%t":"%s", cd.chat_all);
				PrintToChatAll("\x01%s", buffer);
			}
		}
	}
}