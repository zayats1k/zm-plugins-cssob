#include <sdktools>
#include <zm_database> // level_system
#include <zombiemod>

#pragma semicolon 1
#pragma newdecls required

public void OnPluginStart()
{
	LoadTranslations("zm_database.phrases");
}

public void OnClientLoaded(int client, bool row)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		char name[64], sid[32];
		GetClientName(client, name, sizeof(name));
		GetClientAuthId(client, AuthId_Steam2, sid, sizeof(sid));
		// ChangeClientTeam(client, CS_TEAM_SPECTATOR); // test
		
		if (row == false)
		{
			PrintToChat_Lang(client, name, "%T", "CHAT_WELCOME_CONNECTED", client);
			UTIL_PrintToAdmins2(client, name, ADMFLAG_ROOT, "%t", "ROOT_CHAT_PLAYER_WELCOME_CONNECTED", GetUserAdmin(client) != INVALID_ADMIN_ID ? "Админ":"Игрок", sid);
			PrintToChatAll_Lang(client, name, "%T", "CHAT_PLAYER_WELCOME_CONNECTED", client);
		}
		else
		{
			PrintToChat_Lang(client, name, "%T", "CHAT_CONNECTED", client, GetClientLevel(client), GetClientAmmoPacks(client));
			UTIL_PrintToAdmins2(client, name, ADMFLAG_ROOT, "%t", "ROOT_CHAT_PLAYER_CONNECTED", GetUserAdmin(client) != INVALID_ADMIN_ID ? "Админ":"Игрок", sid, GetClientLevel(client));
			PrintToChatAll_Lang(client, name, "%T", "CHAT_PLAYER_CONNECTED", client, GetClientLevel(client));
		}
	}
}

stock void UTIL_PrintToAdmins2(int client, const char[] name, int flags, const char[] format, any ...)
{
	char buffer[254];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && client != i && UTIL_IsValidAdmin(i, flags))
		{
			SetGlobalTransTarget(i);
			VFormat(buffer, sizeof(buffer), format, 5);
			ReplaceString(buffer, sizeof(buffer), "#", "\x07");
			ReplaceString(buffer, sizeof(buffer), "{default}", "\x01");
			ReplaceString(buffer, sizeof(buffer), "{name}", name);
			PrintToChat(i, "\x01%s", buffer);
		}
	}
}

stock void PrintToChatAll_Lang(int client, const char[] name, const char[] format, any ...)
{
	char buffer[254];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && client != i && !UTIL_IsValidAdmin(i, ADMFLAG_ROOT))
		{
			SetGlobalTransTarget(i);
			VFormat(buffer, sizeof(buffer), format, 4);
			ReplaceString(buffer, sizeof(buffer), "#", "\x07");
			ReplaceString(buffer, sizeof(buffer), "{default}", "\x01");
			ReplaceString(buffer, sizeof(buffer), "{name}", name);
			PrintToChat(i, "\x01%s", buffer);
		}
	}
}

stock void PrintToChat_Lang(int client, const char[] name, const char[] format, any ...)
{
	static char buffer[254];
	VFormat(buffer, sizeof(buffer), format, 4);
	ReplaceString(buffer, sizeof(buffer), "\\n", "\n");
	ReplaceString(buffer, sizeof(buffer), "#", "\x07");
	ReplaceString(buffer, sizeof(buffer), "{default}", "\x01");
	ReplaceString(buffer, sizeof(buffer), "{name}", name);
	
	SetGlobalTransTarget(client);
	PrintToChat(client, "\x01%s", buffer);
}