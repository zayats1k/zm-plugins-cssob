#include <zombiemod>
#include <zm_database>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name = "[ZM] VIP System",
	author = "0kEmo",
	version = "1.0"
};

#define SOUND_ITEMICKUP "items/itempickup.wav"
#define SOUND_PICKUP "items/ammopickup.wav"

enum struct ServerData
{
	Database Database;
	bool IsMapZE;
	
	void Clear()
	{
		delete this.Database;
		this.IsMapZE = false;
	}
}
ServerData sServerData;

enum struct ClientData
{
	bool Loaded;
	int AccountID;
	int PickMenu;
	
	bool IsPlayerVIP;
	char group[SMALL_LINE_LENGTH];
	int expires;
	
	float LastMovement;
	
	void Clear()
	{
		this.Loaded = false;
		this.AccountID = 0;
		this.PickMenu = false;
		
		this.IsPlayerVIP = false;
		this.group = NULL_STRING;
		this.expires = 0;
		
		this.LastMovement = 0.0;
	}
}
ClientData sClientData[MAXPLAYERS+1];

int m_HumanSniper, m_HumanSurvivor;

#include "zm_vip/api.sp"
#include "zm_vip/items.sp"

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("zombiemod_chat.phrases");
	LoadTranslations("zm_vip_system.phrases");
	LoadTranslations("utils.phrases");
	
	RegConsoleCmd("vip", Command_VIPMenu);
	RegConsoleCmd("vipmenu", Command_VIPMenu);
	RegAdminCmd("give_vip", Command_GiveVIP, ADMFLAG_ROOT);
	RegAdminCmd("del_vip", Command_RemoveVIP, ADMFLAG_ROOT);
	
	AddCommandListener(command_VIPBuy, "rebuy");
	RegConsoleCmd("vipinfo", command_VIPInfo);
	
	if (SQL_CheckConfig("zm_vip_system"))
	{
		Database.Connect(DBConnect, "zm_vip_system");
	}
	else
	{
		char error[256];
		sServerData.Database = SQLite_UseDatabase("zm_vip-sqlite", error, sizeof(error));
		DBConnect(sServerData.Database, error, 0);
	}
}

public void OnLibraryAdded(const char[] name)
{
	if (!strcmp(name, "zombiemod", false))
	{
		if (ZM_IsMapLoaded())
		{
			ZM_OnEngineExecute();
		}
	}
}

public void ZM_OnEngineExecute()
{
	m_HumanSniper = ZM_GetClassNameID("human_sniper");
	m_HumanSurvivor = ZM_GetClassNameID("human_survivor");
}

public void OnMapStart()
{
	char mapname[PLATFORM_MAX_PATH];
	GetCurrentMap(mapname, sizeof(mapname));
	sServerData.IsMapZE = strncmp(mapname, "ze_", 3, false) != 0;

	PrecacheSound(SOUND_ITEMICKUP, true);
	PrecacheSound(SOUND_PICKUP, true);
}

public void OnClientPostAdminCheck(int client)
{
	if (IsValidClient(client) && !IsClientSourceTV(client) && !IsFakeClient(client))
	{
		sClientData[client].AccountID = GetSteamAccountID(client);
		sClientData[client].LastMovement = GetGameTime();
		
		if (sClientData[client].AccountID)
		{
			char query[512];
			sServerData.Database.Format(query, sizeof(query), "SELECT `expires`, `groups` FROM `zm_vip_system` WHERE `aid` = '%d'", sClientData[client].AccountID);
			sServerData.Database.Query(DB_SelectCallback, query, GetClientUserId(client), DBPrio_High);
		}
	}
}

public void OnClientDisconnect(int client)
{
	sClientData[client].Clear();
}

public Action Command_GiveVIP(int client, int args)
{
	if (args < 3)
	{
		ReplyToCommand(client, "Usage give_vip <#userid|name|steamid> <group> <day>");
		ReplyToCommand(client, "group: VIP, SUPERVIP, MAXIMUM, ...");
		return Plugin_Handled;
	}
	
	int[] target_list = new int[MaxClients];
	char buffer[64], group[32], day[10], target_name[MAX_TARGET_LENGTH];
	int target_count, AccountID = 0; bool tn_is_ml;
	
	GetCmdArg(1, buffer, sizeof(buffer));
	GetCmdArg(2, group, sizeof(group));
	GetCmdArg(3, day, sizeof(day));
	int daynum = StringToInt(day);
	
	if ((target_count = ProcessTargetString(buffer, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED | COMMAND_FILTER_NO_BOTS, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		AccountID = UTIL_GetAccountIDFromSteamID(buffer);
		if (!AccountID)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
	}
	
	if (target_count > 0)
	{
		for (int i = 0; i < target_count; i++)
		{
			if (IsValidClient(client))
			{
				if (daynum != -1)
				{
					PrintToChat(client, "\x07FFFF00added vip: \"%L\"(group: %s)", target_list[i], group);
				}
				else
				{
					PrintToChat(client, "\x07FFFF00deleted vip: \"%L\"", target_list[i]);
				}
			}
			
			if (daynum != -1)
			{
				UTIL_LogToFile("vip_system", "Admin: \"%L\" added vip: \"%L\"(group: %s)", client, target_list[i], group);
			}
			else
			{
				UTIL_LogToFile("vip_system", "Admin: \"%L\" deleted vip: \"%L\"", client, target_list[i]);
			}
			
			SetClientVIP(client, target_list[i], 0, daynum, group);
		}
		return Plugin_Handled;
	}
	
	int target = GetPlayerOnline(AccountID);
	
	if (IsValidClient(target) && !IsFakeClient(target))
	{
		UTIL_LogToFile("vip_system", "admin: \"%L\" added vip: \"%L\"(group: %s)", client, target, group);
		if (IsValidClient(client)) {
			PrintToChat(client, "\x07FFFF00added vip: \"%L\"(group: %s)", target, group);
		}
		
		ZM_PrintToChatAll(target, "%T", "CHAT_STEAMID_GIVE_VIP", target, group);
		ZM_PrintToChatAll(target, "%T", "CHAT_STEAMID_GIVE_VIP", target, group);
		ZM_PrintToChatAll(target, "%T", "CHAT_STEAMID_GIVE_VIP", target, group);
		
		SetClientVIP(client, target, 0, daynum, group);
	}
	else
	{
		Format(buffer, sizeof(buffer), "[U:1:%u]", AccountID);
		UTIL_LogToFile("vip_system", "Admin: \"%L\" added vip: \"%s\"(group: %s)", client, buffer, group);
		if (IsValidClient(client)) {
			PrintToChat(client, "\x07FFFF00added vip: \"%s\"(group: %s)", buffer, group);
		}
		
		SetClientVIP(client, -1, AccountID, daynum, group);
	}
	return Plugin_Handled;
}

public Action Command_RemoveVIP(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Usage del_vip <#userid|name|steamid>");
		return Plugin_Handled;
	}
	
	int[] target_list = new int[MaxClients];
	char arg1[64], target_name[MAX_TARGET_LENGTH];
	int target_count, AccountID = 0; bool tn_is_ml;
	
	GetCmdArg(1, arg1, sizeof(arg1));
	
	if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED | COMMAND_FILTER_NO_BOTS, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		AccountID = UTIL_GetAccountIDFromSteamID(arg1);
		if (!AccountID)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
	}
	
	if (target_count > 0)
	{
		for (int i = 0; i < target_count; i++)
		{
			if (IsValidClient(client)) {
				PrintToChat(client, "\x07FFFF00deleted vip: \"%L\"", target_list[i]);
			}
			
			UTIL_LogToFile("vip_system", "Admin: \"%L\" deleted vip: \"%L\"", client, target_list[i]);
			SetClientVIP(client, target_list[i], 0, -1, "");
		}
		return Plugin_Handled;
	}
	
	int target = GetPlayerOnline(AccountID);
	if (IsValidClient(target) && !IsFakeClient(target))
	{
		UTIL_LogToFile("vip_system", "Admin: \"%L\" deleted vip: \"%L\"", client, target);
		if (IsValidClient(client)) {
			PrintToChat(client, "\x07FFFF00deleted vip: \"%L\"", target);
		}
		
		SetClientVIP(client, target, 0, -1, "");
	}
	else
	{
		Format(arg1, sizeof(arg1), "[U:1:%u]", AccountID);
		UTIL_LogToFile("vip_system", "Admin: \"%L\" deleted vip: \"%s\"", client, arg1);
		if (IsValidClient(client)) {
			PrintToChat(client, "\x07FFFF00deleted vip: \"%s\"", arg1);
		}
		
		SetClientVIP(client, -1, AccountID, -1, "");
	}
	return Plugin_Handled;
}

// =================== [Database] =====================
public void DBConnect(Database db, const char[] error, any data)
{
	if (db == null || error[0])
	{
		LogError("DBConnect: %s", error);
		return;
	}
	
	sServerData.Database = db;
	
	// `aid` INTEGER UNIQUE NOT NULL,
	sServerData.Database.Query(DB_CreateTableCallback, "CREATE TABLE IF NOT EXISTS `zm_vip_system` (\
			`aid` INTEGER PRIMARY KEY NOT NULL, \
			`groups` TEXT NOT NULL DEFAULT 'unknown', \
			`expires` INTEGER UNSIGNED NOT NULL default 0);", _, DBPrio_High);
}

public void DB_CreateTableCallback(Database db, DBResultSet results, const char[] error, any data)
{
	if (db == null || error[0])
	{
		LogError("DB_CreateTableCallback: %s", error);
		return;
	}
	
	for (int i = 1; i <= MaxClients; ++i)
	{
		OnClientPostAdminCheck(i);
	}
}

public void DB_SelectCallback(Database db, DBResultSet results, const char[] error, int userid)
{
	if (db == null || results == null || error[0])
	{
		LogError("DB_SelectCallback: %s", error);
		return;
	}
	
	int client = GetClientOfUserId(userid);
	if (IsValidClient(client) && !IsClientSourceTV(client) && results.FetchRow())
	{
		static char buffer[264]; int time = GetTime();
		
		sClientData[client].expires = results.FetchInt(0);
		
		if (sClientData[client].expires-time > 0)
		{
			results.FetchString(1, buffer, sizeof(buffer));
			strcopy(sClientData[client].group, SMALL_LINE_LENGTH, buffer);
			sClientData[client].IsPlayerVIP = true;
			
			SecondsToTime(sClientData[client].expires-time, buffer, sizeof(buffer), client);
			PrintToChat_Lang(client, "%t", "CHAT_VIP_CONNECT", buffer);
		}
		else
		{
			sServerData.Database.Format(buffer, sizeof(buffer), "DELETE FROM `zm_vip_system` WHERE `aid` = '%d';", sClientData[client].AccountID);
			sServerData.Database.Query(DB_UpdateCallback, buffer);
			
			SecondsToTime(sClientData[client].expires-time, buffer, sizeof(buffer));
			UTIL_LogToFile("vip_system", "Online Player: \"%L\"(deleted VIP, expires: %s)", client, buffer);
			PrintToChat_Lang(client, "%t", "CHAT_VIP_EXPIRED");
			
			sClientData[client].IsPlayerVIP = false;
			sClientData[client].expires = 0;
			sClientData[client].group = NULL_STRING;
		}
		
		sClientData[client].Loaded = true;
	}
}

void SetClientVIP(int client, int target, int accountID, int daynum, const char[] group)
{
	static char buffer[512];
	DataPack data = new DataPack();
	data.WriteString(group);
	data.WriteCell(daynum);
	data.WriteCell(client ? GetClientUserId(client):0);
	
	if (accountID != 0)
	{
		data.WriteCell(accountID);
		sServerData.Database.Format(buffer, sizeof(buffer), "SELECT `expires`, `groups` FROM `zm_vip_system` WHERE `aid` = %d", accountID);
		sServerData.Database.Query(DB_SelectGiveVIPCallback, buffer, data);
	}
	else
	{
		data.WriteCell(sClientData[target].AccountID);
		sServerData.Database.Format(buffer, sizeof(buffer), "SELECT `expires`, `groups` FROM `zm_vip_system` WHERE `aid` = %d", sClientData[target].AccountID);
		sServerData.Database.Query(DB_SelectGiveVIPCallback, buffer, data);
	}
}

public void DB_SelectGiveVIPCallback(Database db, DBResultSet results, const char[] error, DataPack data)
{
	static char buffer2[264], buffer[512], group[SMALL_LINE_LENGTH];
	
	data.Reset();
	data.ReadString(group, sizeof(group));
	int daynum = data.ReadCell();
	int client = GetClientOfUserId(data.ReadCell());
	int AccountID = data.ReadCell();
	delete data;
	
	if (db == null || results == null || error[0])
	{
		LogError("DB_SelectGiveVIPCallback: %s", error);
		return;
	}
	
	int target = GetPlayerOnline(AccountID);
	
	int time = GetTime();
	
	if (results.FetchRow())
	{
		int expires = results.FetchInt(0);
		results.FetchString(1, buffer, sizeof(buffer));
	
		if (daynum == -1)
		{
			sServerData.Database.Format(buffer, sizeof(buffer), "DELETE FROM `zm_vip_system` WHERE `aid` = %d;", AccountID);
			sServerData.Database.Query(DB_UpdateCallback, buffer);
			
			if (IsValidClient(target) && !IsFakeClient(target))
			{
				sClientData[target].IsPlayerVIP = false;
				sClientData[target].expires = 0;
				sClientData[target].group = NULL_STRING;
				PrintToChat_Lang(target, "%t", "CHAT_VIP_EXPIRED");
			}
			
			FormatEx(buffer, sizeof(buffer), "[U:1:%u]", AccountID);
			UTIL_LogToFile("vip_system", "[Database] Deleted vip: \"<%s><%d>\"", buffer, AccountID);
			return;
		}
		
		if (strcmp(buffer, group) != 0)
		{
			if (IsValidClient(target) && !IsFakeClient(target))
			{
				strcopy(sClientData[target].group, SMALL_LINE_LENGTH, group);
				sClientData[target].expires = time+daynum*86400;
				sClientData[target].IsPlayerVIP = true;
				sClientData[target].PickMenu = false;
				CreateForward_OnClientGiveVIP(target, 1);
				
				Command_VIPMenu(target, 0);
				
				if (IsValidClient(client))
				{
					SecondsToTime(sClientData[target].expires-time, buffer2, sizeof(buffer2), client);
					UTIL_LogToFile("vip_system", "Admin: \"%L\" added vip: \"%L\"(group: %s, expires: %s)", client, target, group, buffer2);
					PrintToChat(client, "\x07FFFF00added vip: %N(group: %s, expires: %s)", target, group, buffer2);
				}
				
				SecondsToTime(sClientData[target].expires-time, buffer2, sizeof(buffer2), target);
				PrintToChat_Lang(target, "%t", "CHAT_GIVE_VIP", group, buffer2);
			}
			
			sServerData.Database.Format(buffer, sizeof(buffer), "UPDATE `zm_vip_system` SET `groups` = '%s', `expires` = %d WHERE `aid` = %d;", group, time+daynum*86400, AccountID);
			sServerData.Database.Query(DB_UpdateCallback, buffer, _, DBPrio_Low);
			
			FormatEx(buffer, sizeof(buffer), "[U:1:%u]", AccountID);
			SecondsToTime((time+daynum*86400) - time, buffer2, sizeof(buffer2));
			UTIL_LogToFile("vip_system", "[Database] Added vip: \"<%s><%d>\"(group: %s, expires: %s)", buffer, AccountID, group, buffer2);
		}
		else
		{
			if (IsValidClient(target) && !IsFakeClient(target))
			{
				sClientData[target].expires = expires+daynum*86400;
				sClientData[target].IsPlayerVIP = true;
				CreateForward_OnClientGiveVIP(target, 2);
				
				if (IsValidClient(client))
				{
					SecondsToTime(sClientData[target].expires-time, buffer2, sizeof(buffer2), client);
					UTIL_LogToFile("vip_system", "Admin: \"%L\" updated vip: \"%L\"(expires: %s)", client, target, buffer2);
					PrintToChat(client, "\x07FFFF00updated vip: %N(expires: %s)", target, buffer2);
				}
				
				SecondsToTime(sClientData[target].expires-time, buffer2, sizeof(buffer2), target);
				PrintToChat_Lang(target, "%t", "CHAT_GIVE_VIP_UPDATE", buffer2);
			}
			
			sServerData.Database.Format(buffer, sizeof(buffer), "UPDATE `zm_vip_system` SET `expires` = %d WHERE `aid` = %d;", expires+daynum*86400, AccountID);
			sServerData.Database.Query(DB_UpdateCallback, buffer, _, DBPrio_Low);
			
			FormatEx(buffer, sizeof(buffer), "[U:1:%u]", AccountID);
			SecondsToTime((expires+daynum*86400) - time, buffer2, sizeof(buffer2));
			UTIL_LogToFile("vip_system", "[Database] Update vip: \"<%s><%d>\"(group: %s, expires: %s)", buffer, AccountID, group, buffer2);
		}
		
		if (IsValidClient(client)) {
			ClientCommand(client, "zp_admin_adds");
		}
	}
	else
	{
		if (daynum == -1)
		{
			FormatEx(buffer, sizeof(buffer), "[U:1:%u]", AccountID);
			UTIL_LogToFile("vip_system", "[Database] No SteamID: \"<%s><%d>\"()", buffer, AccountID);
			return;
		}
	
		if (IsValidClient(target) && !IsFakeClient(target))
		{
			strcopy(sClientData[target].group, SMALL_LINE_LENGTH, group);
			sClientData[target].expires = time+daynum*86400;
			sClientData[target].IsPlayerVIP = true;
			sClientData[target].PickMenu = false;
			CreateForward_OnClientGiveVIP(target, 0);
			
			Command_VIPMenu(target, 0);
			
			if (IsValidClient(client))
			{
				SecondsToTime(sClientData[target].expires-time, buffer2, sizeof(buffer2), client);
				UTIL_LogToFile("vip_system", "Admin: \"%L\" added vip: \"%L\"(group: %s, expires: %s)", client, target, group, buffer2);
				PrintToChat(client, "\x07FFFF00added vip: %N(group: %s, expires: %s)", target, group, buffer2);
			}
			
			SecondsToTime(sClientData[target].expires-time, buffer2, sizeof(buffer2), target);
			PrintToChat_Lang(target, "%t", "CHAT_GIVE_VIP", group, buffer2);
		}
	
		sServerData.Database.Format(buffer, sizeof(buffer), "INSERT INTO `zm_vip_system` (`aid`, `groups`, `expires`) VALUES (%d, '%s', %d);", AccountID, group, time+daynum*86400);
		sServerData.Database.Query(DB_UpdateCallback, buffer, _, DBPrio_High);
		
		FormatEx(buffer, sizeof(buffer), "[U:1:%u]", AccountID);
		SecondsToTime((time+daynum*86400) - time, buffer2, sizeof(buffer2));
		UTIL_LogToFile("vip_system", "[Database] Added vip: \"<%s><%d>\"(group: %s, expires: %s)", buffer, AccountID, group, buffer2);
		
		if (IsValidClient(client)) {
			ClientCommand(client, "zp_admin_adds");
		}
	}
}

public void DB_UpdateCallback(Database db, DBResultSet results, const char[] error, any data)
{
	if (db == null || results == null || error[0])
	{
		LogError("DB_UpdateCallback: %s", error);
	}
}

public void OnClientTransfer(int client, int accountID1, int accountID2)
{
	DataPack data = new DataPack();
	data.WriteCell(accountID1);
	data.WriteCell(accountID2);

	static char buffer[512];
	sServerData.Database.Format(buffer, sizeof(buffer), "SELECT * FROM `zm_vip_system` WHERE `aid` = '%d'", accountID1);
	sServerData.Database.Query(DB_SelectTransferCallback, buffer, data);
}

public void DB_SelectTransferCallback(Database db, DBResultSet results, const char[] error, DataPack data)
{
	data.Reset();
	int accountID1 = data.ReadCell();
	int accountID2 = data.ReadCell();
	delete data;
	
	if (db == null || results == null || error[0])
	{
		LogError("DB_SelectTransferCallback: %s", error);
		return;
	}
	
	char buffer[512];
	if (results.FetchRow())
	{
		results.FetchString(1, buffer, sizeof(buffer));
	
		data = new DataPack();
		data.WriteString(buffer); // 1, group
		data.WriteCell(results.FetchInt(2)); // 2, expires
		data.WriteCell(accountID1);
		data.WriteCell(accountID2);
		
		sServerData.Database.Format(buffer, sizeof(buffer), "SELECT * FROM `zm_vip_system` WHERE `aid` = '%d'", accountID2);
		sServerData.Database.Query(DB_SelectTransfer2Callback, buffer, data);
	}
}

public void DB_SelectTransfer2Callback(Database db, DBResultSet results, const char[] error, DataPack data)
{
	char group[SMALL_LINE_LENGTH], group2[SMALL_LINE_LENGTH];

	data.Reset();
	data.ReadString(group2, sizeof(group2)); // 1, group
	int expires2 = data.ReadCell(); // 2, expires
	int accountID1 = data.ReadCell();
	int accountID2 = data.ReadCell();
	delete data;
	
	if (db == null || results == null || error[0])
	{
		LogError("DB_SelectTransfer2Callback: %s", error);
		return;
	}
	
	int time = GetTime();
	
	char buffer[512];
	if (results.FetchRow())
	{
		results.FetchString(1, group, sizeof(group)); // 1, group
		int expires = results.FetchInt(2); // 2, expires
		
		sServerData.Database.Format(buffer, sizeof(buffer), "UPDATE `zm_vip_system` SET `groups` = '%s', `expires` = %d WHERE `aid` = %d;", group, expires, accountID1);
		sServerData.Database.Query(DB_UpdateCallback, buffer, _, DBPrio_Low);
		sServerData.Database.Format(buffer, sizeof(buffer), "UPDATE `zm_vip_system` SET `groups` = '%s', `expires` = %d WHERE `aid` = %d;", group2, expires2, accountID2);
		sServerData.Database.Query(DB_UpdateCallback, buffer, _, DBPrio_Low);
		
		int target = GetPlayerOnline(accountID1);
		if (IsValidClient(target) && !IsFakeClient(target))
		{
			if (group[0])
			{
				strcopy(sClientData[target].group, SMALL_LINE_LENGTH, group);
				sClientData[target].expires = expires;
				sClientData[target].IsPlayerVIP = true;
				CreateForward_OnClientGiveVIP(target, 0);
				
				SecondsToTime(expires-time, buffer, sizeof(buffer));
				PrintToChat_Lang(target, "%t", "CHAT_VIP_CONNECT", buffer);
			}
		}
	
		int target2 = GetPlayerOnline(accountID2);
		if (IsValidClient(target2) && !IsFakeClient(target2))
		{
			if (group2[0])
			{
				strcopy(sClientData[target2].group, SMALL_LINE_LENGTH, group2);
				sClientData[target2].expires = expires2;
				sClientData[target2].IsPlayerVIP = true;
				CreateForward_OnClientGiveVIP(target2, 0);
				
				SecondsToTime(expires2-time, buffer, sizeof(buffer));
				PrintToChat_Lang(target2, "%t", "CHAT_VIP_CONNECT", buffer);
			}
		}
	}
	else
	{
		sServerData.Database.Format(buffer, sizeof(buffer), "DELETE FROM `zm_vip_system` WHERE `aid` = '%d';", accountID1);
		sServerData.Database.Query(DB_UpdateCallback, buffer);
		sServerData.Database.Format(buffer, sizeof(buffer), "INSERT INTO `zm_vip_system` (`aid`, `groups`, `expires`) VALUES (%d, '%s', %d);", accountID2, group2, expires2);
		sServerData.Database.Query(DB_UpdateCallback, buffer, _, DBPrio_High);
		
		int target = GetPlayerOnline(accountID1);
		if (IsValidClient(target) && !IsFakeClient(target) && sClientData[target].IsPlayerVIP)
		{
			sClientData[target].IsPlayerVIP = false;
			sClientData[target].expires = 0;
			sClientData[target].group = NULL_STRING;
			PrintToChat_Lang(target, "%t", "CHAT_VIP_EXPIRED");
		}
	
		int target2 = GetPlayerOnline(accountID2);
		if (IsValidClient(target2) && !IsFakeClient(target2))
		{
			if (group2[0])
			{
				strcopy(sClientData[target2].group, SMALL_LINE_LENGTH, group2);
				sClientData[target2].expires = expires2;
				sClientData[target2].IsPlayerVIP = true;
				CreateForward_OnClientGiveVIP(target2, 0);
				
				SecondsToTime(expires2-time, buffer, sizeof(buffer));
				PrintToChat_Lang(target2, "%t", "CHAT_VIP_CONNECT", buffer);
			}
		}
	}
	
	UTIL_LogToFile("vip_system", "[VIP.TRANSFER] Transfer AccountID1: %d to AccountID2: %d", accountID1, accountID2);
}

/// 
stock void SecondsToTime(int time, char[] buffer, int maxLen, int client = LANG_SERVER)
{
	char gtime[64]; int len = 0;
	if (time >= 86400) len += FormatEx(gtime[len], sizeof(gtime)-len, "%2d%T", time/86400, "days", client);
	if (time >= 3600) len += FormatEx(gtime[len], sizeof(gtime)-len, "%2d%T", time/3600%24,"hours", client);
	if (time >= 60) len += FormatEx(gtime[len], sizeof(gtime)-len, "%02d%T", time/60%60, "mines", client);
	if (time < 86400) len += FormatEx(gtime[len], sizeof(gtime)-len, "%2d%T", time%60, "sec", client);
	FormatEx(buffer, maxLen, "%s", gtime);
}

stock int GetPlayerOnline(int AccountID)
{
	int target = 0;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && !IsFakeClient(i))
		{
			if (AccountID == sClientData[i].AccountID)
			{
				target = i;
			}
		}
	}
	
	return target;
}

stock void PrintToChat_Lang(int client, const char[] format, any ...)
{
	SetGlobalTransTarget(client);

	static char buffer[264];
	VFormat(buffer, sizeof(buffer), format, 3);
	ReplaceString(buffer, sizeof(buffer), "\\n", "\n");
	ReplaceString(buffer, sizeof(buffer), "#", "\x07");
	ReplaceString(buffer, sizeof(buffer), "{default}", "\x01");
	PrintToChat(client, "%s", buffer);
}

stock int VIP_GetClientCount()
{
    int count = 0;
	
    for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsValidClient(i) && IsPlayerAlive(i) && !IsFakeClient(i))
		{
			count++;
		}
	}
    return count;
}