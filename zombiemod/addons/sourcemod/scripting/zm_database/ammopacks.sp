// public void HS_OnClientHudSettings(int client, int id, const char[] name)
// {
// 	if (id != 4)
// 	{
// 		return;
// 	}
// 	
// 	if (strcmp(name, "1") != 0)
// 	{
// 		return;
// 	}
// 	
// 	if (IsValidClient(client))
// 	{
// 		if (HS_GetClientCookie(client, id) == 3)
// 		{
// 			SetEntProp(client, Prop_Send, "m_iAccount", sClientData[client].AmmoPacks);
// 		}
// 		else
// 		{
// 			SetEntProp(client, Prop_Send, "m_iAccount", 0);
// 		}
// 	}
// }

public Action Command_GiveAmmo(int client, int args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "Usage give_ap <#userid|name|steamid> <amount>");
		return Plugin_Handled;
	}
	
	int[] target_list = new int[MaxClients];
	char arg1[64], args2[10], target_name[MAX_TARGET_LENGTH];
	int target_count, m_AccountID = 0; bool tn_is_ml;
	
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, args2, sizeof(args2));
	int ammo = StringToInt(args2);
	
	if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED|COMMAND_FILTER_NO_BOTS, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		m_AccountID = UTIL_GetAccountIDFromSteamID(arg1);
		if (!m_AccountID)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
	}
	
	if (target_count > 0)
	{
		for (int i = 0; i < target_count; i++)
		{
			UTIL_LogToFile("zm_database", "[AMMOPACKS] Online Player: \"%L\"(AmmoPacks: +%d (%d/60000))", target_list[i], ammo, UTIL_Clamp(sClientData[target_list[i]].AmmoPacks + ammo, 0, 60000));
			
			SetClientAmmoPacks(target_list[i], ammo);
		}
		return Plugin_Handled;
	}
	
	int target = GetPlayerOnline(m_AccountID);
	
	if (IsValidClient(target) && !IsFakeClient(target))
	{
		UTIL_LogToFile("zm_database", "[AMMOPACKS] Online SteamID: \"%L\"(AmmoPacks: +%d (%d/60000))", target, ammo, UTIL_Clamp(sClientData[target].AmmoPacks + ammo, 0, 60000));
		
		ZM_PrintToChatAll(target, "%T", "CHAT_STEAMID_GIVE_AMMOPACKS", target, ammo);
		ZM_PrintToChatAll(target, "%T", "CHAT_STEAMID_GIVE_AMMOPACKS", target, ammo);
		ZM_PrintToChatAll(target, "%T", "CHAT_STEAMID_GIVE_AMMOPACKS", target, ammo);
		
		SetClientAmmoPacks(target, ammo);
	}
	else
	{
		DataPack data = new DataPack();
		
		data.WriteCell(ammo);
		data.WriteCell(m_AccountID);
		
		static char buffer[512];
		sServerData.Database.Format(buffer, sizeof(buffer), "SELECT `ammopacks` FROM `zm_core` WHERE `aid` = '%d'", m_AccountID);
		sServerData.Database.Query(DB_SelectGiveAmmoCallback, buffer, data);
	}
	return Plugin_Handled;
}

public void DB_SelectGiveAmmoCallback(Database db, DBResultSet results, const char[] error, DataPack data)
{
	data.Reset();
	int m_ammo = data.ReadCell();
	int m_AccountID = data.ReadCell();
	delete data;
	
	if (db == null || results == null || error[0])
	{
		LogError("DB_SelectGiveAmmoCallback: %s", error);
		return;
	}
	
	char buffer[512];
	if (results.FetchRow())
	{
		int ammo = results.FetchInt(0);
		
		FormatEx(buffer, sizeof(buffer), "[U:1:%u]", m_AccountID);
		UTIL_LogToFile("zm_database", "[AMMOPACKS] Offline SteamID: %s(ammopack: +%d (%d/60000))", buffer, m_ammo, UTIL_Clamp(m_ammo + ammo, 0, 60000));
		sServerData.Database.Format(buffer, sizeof(buffer), "UPDATE `zm_core` SET `ammopacks` = %d WHERE `aid` = %d;", UTIL_Clamp(m_ammo + ammo, 0, 60000), m_AccountID);
		sServerData.Database.Query(DB_UpdateCallback, buffer, _, DBPrio_Low);
	}
	else
	{
		FormatEx(buffer, sizeof(buffer), "[U:1:%u]", m_AccountID);
		UTIL_LogToFile("zm_database", "[AMMOPACKS.ERROR] Not Found SteamID: %s(ammopack: %d)", buffer, m_ammo);
	}
}

void SetClientAmmoPacks(int client, int ammo)
{
	float time = GetGameTime();
	
	if (sClientData[client].HudGameTime < time)
	{
		sClientData[client].HudAmmo = 0;
	}
	
	sClientData[client].AmmoPacks = UTIL_Clamp(sClientData[client].AmmoPacks + ammo, 0, 60000);
	sClientData[client].HudAmmo += ammo;
	
	// if (HS_GetClientCookie(client, 4) == 3)
	// {
	// 	SetEntProp(client, Prop_Send, "m_iAccount", sClientData[client].AmmoPacks);
	// }
	// else if (HS_GetClientCookie(client, 4) == 2)
	{
		if (sClientData[client].AmmoPacks < 60000)
		{
			if (ammo >= 0 && ammo < 35)
			{
				SetHudTextParams(-1.0, 0.20, 2.0, 70, 70, 70, 255, 0, 0.0, 0.0, 1.3);
			}
			else SetHudTextParams(-1.0, 0.20, 2.0, 255, 255, 255, 255, 0, 0.0, 0.0, 1.3);
			
			if (ammo <= 0)
			{
				if (sClientData[client].HudAmmo > ammo)
				{
					sClientData[client].HudAmmo = ammo;
				}
				
				ShowSyncHudText(client, sServerData.SyncHudAmmo, "[%d %T]", sClientData[client].HudAmmo, "ammopack 1", client);
			}
			else
			{
				if (sClientData[client].HudAmmo <= ammo)
				{
					sClientData[client].HudAmmo = ammo;
				}
				
				ShowSyncHudText(client, sServerData.SyncHudAmmo, "[+%d %T]", sClientData[client].HudAmmo, "ammopack 1", client);
			}
			
			sClientData[client].HudGameTime = 0.0;
			sClientData[client].HudGameTime = time + 2.8;
		}
	}
}