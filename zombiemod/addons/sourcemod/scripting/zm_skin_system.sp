#include <zombiemod>
#include <zm_database>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name = "[ZM] Skin System",
	author = "0kEmo",
	version = "1.0"
};

Database m_Database;
int m_AccountID[MAXPLAYERS+1];
int m_SkinID[MAXPLAYERS+1] = {-1, ...};
int m_SkinExpire[MAXPLAYERS+1];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("SKIN_GiveClientSKIN", Native_GiveClientSKIN);
	RegPluginLibrary("zm_skin_system");
	return APLRes_Success;
}

public int Native_GiveClientSKIN(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int target = GetNativeCell(2);
	
	static char skin[32];
	GetNativeString(3, skin, sizeof(skin));
	int day = GetNativeCell(4);
	
	if (day < 1)
	{
		LogError("Error: day[0] == 1");
		return false;
	}
	
	if (!skin[0])
	{
		LogError("Error: skin[0] == null");
		return false;
	}
	
	SetClientSkin(client, target, GetNativeCell(5), day, skin);
	return true;
}

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("zombiemod_chat.phrases");
	LoadTranslations("zm_skin_system.phrases");
	LoadTranslations("utils.phrases");

	RegAdminCmd("give_skin", Command_GiveSkin, ADMFLAG_BAN);
	RegAdminCmd("del_skin", Command_DelSkin, ADMFLAG_UNBAN);
	
	if (SQL_CheckConfig("zm_skin_system"))
	{
		Database.Connect(DBConnect, "zm_skin_system");
	}
	else
	{
		char error[256];
		m_Database = SQLite_UseDatabase("zm_skin-sqlite", error, sizeof(error));
		DBConnect(m_Database, error, 0);
	}
}

public void OnClientPostAdminCheck(int client)
{
	if (IsValidClient(client) && !IsClientSourceTV(client) && !IsFakeClient(client))
	{
		m_AccountID[client] = GetSteamAccountID(client);
		m_SkinExpire[client] = 0;
		
		if (m_AccountID[client])
		{
			char query[512];
			m_Database.Format(query, sizeof(query), "SELECT `skin`, `expires` FROM `zm_skin_system` WHERE `aid` = %d", m_AccountID[client]);
			m_Database.Query(DB_SelectCallback, query, GetClientUserId(client), DBPrio_High);
		}
	}
}

public void OnClientDisconnect(int client)
{
	m_AccountID[client] = 0;
	m_SkinID[client] = -1;
	m_SkinExpire[client] = 0;
}

public Action Command_GiveSkin(int client, int args)
{
	if (args < 3)
	{
		ReplyToCommand(client, "Usage give_skin <#userid|name|steamid> <skin name> <day>");
		return Plugin_Handled;
	}
	
	int[] target_list = new int[MaxClients];
	char arg1[64], skinname[32], day[10], target_name[MAX_TARGET_LENGTH];
	int target_count, AccountID = 0; bool tn_is_ml;
	
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, skinname, sizeof(skinname));
	GetCmdArg(3, day, sizeof(day));
	int daynum = StringToInt(day);
	
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
			if (IsValidClient(client))
			{
				if (daynum != -1)
				{
					PrintToChat(client, "\x07FFFF00added skin: \"%L\"(skinname: %s)", target_list[i], skinname);
				}
				else
				{
					PrintToChat(client, "\x07FFFF00deleted skin: \"%L\"", target_list[i]);
				}
			}
			
			if (daynum != -1)
			{
				UTIL_LogToFile("zm_skins", "Admin: \"%L\" added skin: \"%L\"(skinname: %s)", client, target_list[i], skinname);
			}
			else
			{
				UTIL_LogToFile("zm_skins", "Admin: \"%L\" deleted skin: \"%L\"", client, target_list[i]);
			}
			
			SetClientSkin(client, target_list[i], 0, daynum, skinname);
		}
		return Plugin_Handled;
	}
	
	int target = GetPlayerOnline(AccountID);
	
	if (IsValidClient(target) && !IsFakeClient(target))
	{
		UTIL_LogToFile("zm_skins", "admin: \"%L\" added skin: \"%L\"(skinname: %s)", client, target, skinname);
		if (IsValidClient(client)) {
			PrintToChat(client, "\x07FFFF00added skin: \"%L\"(skinname: %s)", target, skinname);
		}
		
		ZM_PrintToChatAll(target, "%T", "CHAT_STEAMID_GIVE_SKIN", target, skinname);
		ZM_PrintToChatAll(target, "%T", "CHAT_STEAMID_GIVE_SKIN", target, skinname);
		ZM_PrintToChatAll(target, "%T", "CHAT_STEAMID_GIVE_SKIN", target, skinname);
		
		SetClientSkin(client, target, 0, daynum, skinname);
	}
	else
	{
		Format(arg1, sizeof(arg1), "[U:1:%u]", AccountID);
		UTIL_LogToFile("zm_skins", "Admin: \"%L\" added skin: \"%s\"(skinname: %s)", client, arg1, skinname);
		if (IsValidClient(client)) {
			PrintToChat(client, "\x07FFFF00added skin: \"%s\"(skinname: %s)", arg1, skinname);
		}
	
		SetClientSkin(client, -1, AccountID, daynum, skinname);
	}
	return Plugin_Handled;
}

public Action Command_DelSkin(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Usage del_skin <#userid|name|steamid>");
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
				PrintToChat(client, "\x07FFFF00deleted skin: \"%L\"", target_list[i]);
			}
			
			UTIL_LogToFile("zm_skins", "Admin: \"%L\" deleted skin: \"%L\"", client, target_list[i]);
			SetClientSkin(client, target_list[i], 0, -1, "");
		}
		return Plugin_Handled;
	}
	
	int target = GetPlayerOnline(AccountID);
	if (IsValidClient(target) && !IsFakeClient(target))
	{
		UTIL_LogToFile("zm_skins", "Admin: \"%L\" deleted skin: \"%L\"", client, target);
		if (IsValidClient(client)) {
			PrintToChat(client, "\x07FFFF00deleted skin: \"%L\"", target);
		}
		
		SetClientSkin(client, target, 0, -1, "");
	}
	else
	{
		Format(arg1, sizeof(arg1), "[U:1:%u]", AccountID);
		UTIL_LogToFile("zm_skins", "Admin: \"%L\" deleted skin: \"%s\"", client, arg1);
		if (IsValidClient(client)) {
			PrintToChat(client, "\x07FFFF00deleted skin: \"%s\"", arg1);
		}
		
		SetClientSkin(client, -1, AccountID, -1, "");
	}
	return Plugin_Handled;
}

void SetClientSkin(int client, int target, int accountID, int daynum, const char[] skinname)
{
	static char buffer[512];
	DataPack data = new DataPack();
	data.WriteString(skinname);
	data.WriteCell(daynum);
	data.WriteCell(client ? GetClientUserId(client):0);
	
	if (accountID != 0)
	{
		data.WriteCell(accountID);
		m_Database.Format(buffer, sizeof(buffer), "SELECT `skin`, `expires` FROM `zm_skin_system` WHERE `aid` = %d", accountID);
		m_Database.Query(DB_SelectGiveSkinCallback, buffer, data);
	}
	else
	{
		data.WriteCell(m_AccountID[target]);
		m_Database.Format(buffer, sizeof(buffer), "SELECT `skin`, `expires` FROM `zm_skin_system` WHERE `aid` = %d", m_AccountID[target]);
		m_Database.Query(DB_SelectGiveSkinCallback, buffer, data);
	}
}

public void DB_SelectGiveSkinCallback(Database db, DBResultSet results, const char[] error, DataPack data)
{
	static char buffer2[264], buffer[512], skinname[32];
	
	data.Reset();
	data.ReadString(skinname, sizeof(skinname));
	int daynum = data.ReadCell();
	int client = GetClientOfUserId(data.ReadCell());
	int AccountID = data.ReadCell();
	delete data;
	
	if (db == null || results == null || error[0])
	{
		LogError("DB_SelectGiveSkinCallback: %s", error);
		return;
	}
	
	int target = GetPlayerOnline(AccountID);
	
	int time = GetTime();
	
	if (results.FetchRow())
	{
		results.FetchString(0, buffer, sizeof(buffer));
	
		int expires = results.FetchInt(1);
	
		if (daynum == -1)
		{
			m_Database.Format(buffer, sizeof(buffer), "DELETE FROM `zm_skin_system` WHERE `aid` = %d;", AccountID);
			m_Database.Query(DB_UpdateCallback, buffer);
			
			if (IsValidClient(target) && !IsFakeClient(target))
			{
				m_SkinExpire[target] = 0;
				m_SkinID[target] = -1;
				ZM_SetClientSkin(target, -1);
				PrintToChat_Lang(target, "%t", "CHAT_SKIN_EXPIRED");
			}
			
			FormatEx(buffer, sizeof(buffer), "[U:1:%u]", AccountID);
			UTIL_LogToFile("zm_skins", "[Database] Deleted skin: \"%s\"", buffer);
			return;
		}
		
		if (strcmp(buffer, skinname) != 0)
		{
			if (IsValidClient(target) && !IsFakeClient(target))
			{
				m_SkinExpire[target] = time+daynum*86400;
				
				if (IsValidClient(client))
				{
					SecondsToTime(m_SkinExpire[target]-time, buffer2, sizeof(buffer2), client);
					UTIL_LogToFile("zm_skins", "Admin: \"%L\" added skin: \"%L\"(skinname: %s, expires: %s)", client, target, skinname, buffer2);
					PrintToChat(client, "\x07FFFF00added skin: %N(skinname: %s, expires: %s)", target, skinname, buffer2);
				}
				
				SecondsToTime(m_SkinExpire[target]-time, buffer2, sizeof(buffer2), target);
				PrintToChat_Lang(target, "%t", "CHAT_GIVE_SKIN", skinname, buffer2);
				
				for (int i = 0; i < ZM_GetNumberSkin(); i++)
				{
					ZM_GetSkinName(i, buffer2, sizeof(buffer2));
					if (!strcmp(skinname, buffer2, false)) {
						ZM_SetClientSkin(target, i);
						m_SkinID[target] = i;
						break;
					}
				}
			}
			
			m_Database.Format(buffer, sizeof(buffer), "UPDATE `zm_skin_system` SET `skin` = '%s', `expires` = %d WHERE `aid` = %d;", skinname, time+daynum*86400, AccountID);
			m_Database.Query(DB_UpdateCallback, buffer, _, DBPrio_Low);
			
			FormatEx(buffer, sizeof(buffer), "[U:1:%u]", AccountID);
			SecondsToTime((time+daynum*86400) - time, buffer2, sizeof(buffer2));
			UTIL_LogToFile("zm_skins", "[Database] Added skin: \"%s\"(skinname: %s, expires: %s)", buffer, skinname, buffer2);
		}
		else
		{
			if (IsValidClient(target) && !IsFakeClient(target))
			{
				m_SkinExpire[target] = expires+daynum*86400;
				
				if (IsValidClient(client))
				{
					SecondsToTime(m_SkinExpire[target]-time, buffer2, sizeof(buffer2), client);
					UTIL_LogToFile("zm_skins", "Admin: \"%L\" updated skin: \"%L\"(expires: %s)", client, target, buffer2);
					PrintToChat(client, "\x07FFFF00updated skin: %N(expires: %s)", target, buffer2);
				}
				
				SecondsToTime(m_SkinExpire[target]-time, buffer2, sizeof(buffer2), target);
				PrintToChat_Lang(target, "%t", "CHAT_GIVE_SKIN_UPDATE", buffer2);
			}
			
			m_Database.Format(buffer, sizeof(buffer), "UPDATE `zm_skin_system` SET `expires` = %d WHERE `aid` = %d;", expires+daynum*86400, AccountID);
			m_Database.Query(DB_UpdateCallback, buffer, _, DBPrio_Low);
			
			FormatEx(buffer, sizeof(buffer), "[U:1:%u]", AccountID);
			SecondsToTime((expires+daynum*86400) - time, buffer2, sizeof(buffer2));
			UTIL_LogToFile("zm_skins", "[Database] Update skin: \"%s\"(skinname: %s, expires: %s)", buffer, skinname, buffer2);
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
			UTIL_LogToFile("zm_skins", "[Database] No SteamID: \"%s\"()", buffer);
			return;
		}
		
		if (IsValidClient(target) && !IsFakeClient(target))
		{
			m_SkinExpire[target] = time+daynum*86400;
			
			if (IsValidClient(client))
			{
				SecondsToTime(m_SkinExpire[target]-time, buffer2, sizeof(buffer2), client);
				UTIL_LogToFile("zm_skins", "Admin: \"%L\" added skin: \"%L\"(skinname: %s, expires: %s)", client, target, skinname, buffer2);
				PrintToChat(client, "\x07FFFF00added skin: %N(skinname: %s, expires: %s)", target, skinname, buffer2);
			}
			
			SecondsToTime(m_SkinExpire[target]-time, buffer2, sizeof(buffer2), target);
			PrintToChat_Lang(target, "%t", "CHAT_GIVE_SKIN", skinname, buffer2);
			
			for (int i = 0; i < ZM_GetNumberSkin(); i++)
			{
				ZM_GetSkinName(i, buffer2, sizeof(buffer2));
				if (!strcmp(skinname, buffer2, false)) {
					ZM_SetClientSkin(target, i);
					m_SkinID[target] = i;
					break;
				}
			}
		}
	
		m_Database.Format(buffer, sizeof(buffer), "INSERT INTO `zm_skin_system` (`aid`, `skin`, `expires`) VALUES (%d, '%s', %d);", AccountID, skinname, time+daynum*86400);
		m_Database.Query(DB_UpdateCallback, buffer, _, DBPrio_High);
		
		FormatEx(buffer, sizeof(buffer), "[U:1:%u]", AccountID);
		SecondsToTime((time+daynum*86400) - time, buffer2, sizeof(buffer2));
		UTIL_LogToFile("zm_skins", "[Database] Added skin: \"%s\"(skinname: %s, expires: %s)", buffer, skinname, buffer2);
		
		if (IsValidClient(client)) {
			ClientCommand(client, "zp_admin_adds");
		}
	}
}

// sql
public void DBConnect(Database db, const char[] error, any data)
{
	if (db == null || error[0]) {
		LogError("DBConnect: %s", error);
		return;
	}
	m_Database = db;
	
	m_Database.Query(DB_CreateTableCallback, "CREATE TABLE IF NOT EXISTS `zm_skin_system` (\
			`aid` INTEGER PRIMARY KEY NOT NULL, \
			`skin` TEXT NOT NULL DEFAULT 'unknown', \
			`expires` INTEGER UNSIGNED NOT NULL default 0);", _, DBPrio_High);
}

public void DB_CreateTableCallback(Database db, DBResultSet results, const char[] error, any data)
{
	if (db == null || error[0]) {
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
	if (db == null || results == null || error[0]) {
		LogError("DB_SelectCallback: %s", error);
		return;
	}
	
	int client = GetClientOfUserId(userid);
	if (IsValidClient(client) && !IsFakeClient(client) && !IsClientSourceTV(client))
	{
		if (results.FetchRow())
		{
			char KeyName[SMALL_LINE_LENGTH], buffer[264];
			int time = GetTime();
			 
			results.FetchString(0, KeyName, sizeof(KeyName));
			m_SkinExpire[client] = results.FetchInt(1);
			
			if (m_SkinExpire[client]-time > 0)
			{
				SecondsToTime(m_SkinExpire[client]-time, buffer, sizeof(buffer), client);
				PrintToChat_Lang(client, "%t", "CHAT_SKIN_CONNECT", buffer);
				
				for (int i = 0; i < ZM_GetNumberSkin(); i++)
				{
					ZM_GetSkinName(i, buffer, sizeof(buffer));
					
					if (!strcmp(KeyName, buffer, false)) {
						ZM_SetClientSkin(client, i);
						m_SkinID[client] = i;
						break;
					}
				}
			}
			else
			{
				m_Database.Format(buffer, sizeof(buffer), "DELETE FROM `zm_skin_system` WHERE `aid` = '%d';", m_AccountID[client]);
				m_Database.Query(DB_UpdateCallback, buffer);
				
				UTIL_LogToFile("zm_skins", "connect skin: \"%L\" deleted(skin, expired)", client);
				PrintToChat_Lang(client, "%t", "CHAT_SKIN_EXPIRED");
				
				m_SkinExpire[client] = 0;
				m_SkinID[client] = -1;
			}
		}
	}
}

public void OnClientTransfer(int client, int accountID1, int accountID2)
{
	DataPack data = new DataPack();
	data.WriteCell(accountID1);
	data.WriteCell(accountID2);

	static char buffer[512];
	m_Database.Format(buffer, sizeof(buffer), "SELECT * FROM `zm_skin_system` WHERE `aid` = '%d'", accountID1);
	m_Database.Query(DB_SelectTransferCallback, buffer, data);
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
		data.WriteString(buffer); // 1, skin
		data.WriteCell(results.FetchInt(2)); // 2, expires
		data.WriteCell(accountID1);
		data.WriteCell(accountID2);
		
		m_Database.Format(buffer, sizeof(buffer), "SELECT * FROM `zm_skin_system` WHERE `aid` = '%d'", accountID2);
		m_Database.Query(DB_SelectTransfer2Callback, buffer, data);
	}
}

public void DB_SelectTransfer2Callback(Database db, DBResultSet results, const char[] error, DataPack data)
{
	char skin[SMALL_LINE_LENGTH], skin2[SMALL_LINE_LENGTH];

	data.Reset();
	data.ReadString(skin2, sizeof(skin2)); // 1, skin
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
		results.FetchString(1, skin, sizeof(skin)); // 1, skin
		int expires = results.FetchInt(2); // 2, expires
		
		m_Database.Format(buffer, sizeof(buffer), "UPDATE `zm_skin_system` SET `skin` = '%s', `expires` = %d WHERE `aid` = %d;", skin, expires, accountID1);
		m_Database.Query(DB_UpdateCallback, buffer, _, DBPrio_Low);
		m_Database.Format(buffer, sizeof(buffer), "UPDATE `zm_skin_system` SET `skin` = '%s', `expires` = %d WHERE `aid` = %d;", skin2, expires2, accountID2);
		m_Database.Query(DB_UpdateCallback, buffer, _, DBPrio_Low);
		
		int target = GetPlayerOnline(accountID1);
		if (IsValidClient(target) && !IsFakeClient(target))
		{
			if (skin[0])
			{
				m_SkinExpire[target] = expires;
				
				for (int i = 0; i < ZM_GetNumberSkin(); i++)
				{
					ZM_GetSkinName(i, buffer, sizeof(buffer));
					
					if (!strcmp(skin, buffer, false)) {
						ZM_SetClientSkin(target, i);
						m_SkinID[target] = i;
						break;
					}
				}
				
				SecondsToTime(expires-time, buffer, sizeof(buffer));
				PrintToChat_Lang(target, "%t", "CHAT_SKIN_CONNECT", buffer);
			}
		}
	
		int target2 = GetPlayerOnline(accountID2);
		if (IsValidClient(target2) && !IsFakeClient(target2))
		{
			if (skin2[0])
			{
				m_SkinExpire[target2] = expires2;
			
				for (int i = 0; i < ZM_GetNumberSkin(); i++)
				{
					ZM_GetSkinName(i, buffer, sizeof(buffer));
					
					if (!strcmp(skin2, buffer, false)) {
						ZM_SetClientSkin(target2, i);
						m_SkinID[target2] = i;
						break;
					}
				}
				
				SecondsToTime(expires2-time, buffer, sizeof(buffer));
				PrintToChat_Lang(target2, "%t", "CHAT_SKIN_CONNECT", buffer);
			}
		}
	}
	else
	{
		m_Database.Format(buffer, sizeof(buffer), "DELETE FROM `zm_skin_system` WHERE `aid` = '%d';", accountID1);
		m_Database.Query(DB_UpdateCallback, buffer);
		m_Database.Format(buffer, sizeof(buffer), "INSERT INTO `zm_skin_system` (`aid`, `skin`, `expires`) VALUES (%d, '%s', %d);", accountID2, skin2, expires2);
		m_Database.Query(DB_UpdateCallback, buffer, _, DBPrio_High);
		
		int target = GetPlayerOnline(accountID1);
		if (IsValidClient(target) && !IsFakeClient(target) && m_SkinExpire[target])
		{
			m_SkinExpire[target] = 0;
			m_SkinID[target] = -1;
			ZM_SetClientSkin(target, -1);
			PrintToChat_Lang(target, "%t", "CHAT_SKIN_EXPIRED");
		}
	
		int target2 = GetPlayerOnline(accountID2);
		if (IsValidClient(target2) && !IsFakeClient(target2))
		{
			if (skin2[0])
			{
				m_SkinExpire[target2] = expires2;
				
				for (int i = 0; i < ZM_GetNumberSkin(); i++)
				{
					ZM_GetSkinName(i, buffer, sizeof(buffer));
					
					if (!strcmp(skin2, buffer, false)) {
						ZM_SetClientSkin(target2, i);
						m_SkinID[target2] = i;
						break;
					}
				}
				
				SecondsToTime(expires2-time, buffer, sizeof(buffer));
				PrintToChat_Lang(target2, "%t", "CHAT_SKIN_CONNECT", buffer);
			}
		}
	}
	
	UTIL_LogToFile("zm_skins", "[SKIN.TRANSFER] Transfer AccountID1: %d to AccountID2: %d", accountID1, accountID2);
}

public void DB_UpdateCallback(Database db, DBResultSet results, const char[] error, int client)
{
	if (db == null || results == null || error[0]) LogError("DB_UpdateCallback: %s", error);
}

stock int GetPlayerOnline(int AccountID)
{
	int target = 0;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && !IsFakeClient(i))
		{
			if (AccountID == m_AccountID[i])
			{
				target = i;
			}
		}
	}
	
	return target;
}

stock void SecondsToTime(int time, char[] buffer, int maxLen, int client = LANG_SERVER)
{
	char gtime[64];
	
	if (time >= 0)
	{
		int len = 0;
		if (time >= 86400) len += Format(gtime[len], sizeof(gtime)-len, "%2d%T", time/86400, "days", client);
		if (time >= 3600) len += Format(gtime[len], sizeof(gtime)-len, "%2d%T", time/3600%24,"hours", client);
		if (time >= 60) len += Format(gtime[len], sizeof(gtime)-len, "%02d%T", time/60%60, "mines", client);
		if (time < 86400) len += Format(gtime[len], sizeof(gtime)-len, "%2d%T", time%60, "sec", client);
	}
	else
	{
		Format(gtime, sizeof(gtime), "0%T", "sec", client);
	}
	
	FormatEx(buffer, maxLen, "%s", gtime);
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