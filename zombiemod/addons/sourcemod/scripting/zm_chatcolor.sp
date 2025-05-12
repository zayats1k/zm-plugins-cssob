#include <zombiemod>
#include <zm_vip_system>
#include <basecomm>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name = "[ZM] Chat Color",
	author = "0kEmo",
	version = "1.4"
};

GlobalForward hOnClientSay;
GlobalForward hOnClientSayPost;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	hOnClientSay = new GlobalForward("ZM_OnClientSay", ET_Hook, Param_Cell, Param_String);
	hOnClientSayPost = new GlobalForward("ZM_OnClientSayPost", ET_Hook, Param_Cell, Param_String);
	RegPluginLibrary("zm_chatcolor");
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("zm_chatcolor.phrases");
}

public Action OnClientSayCommand(int client, const char[] command, const char[] text)
{
	if (IsValidClient(client) && !BaseComm_IsClientGagged(client))
	{
		if (text[0] == '@') {
			if (CheckCommandAccess(client, "", ADMFLAG_CHAT)) return Plugin_Continue;
		}
		
		switch(CreateForward_OnClientSay(client, text))
		{
			case Plugin_Handled, Plugin_Stop:
			{
				UTIL_LogToFile("zm_chatcolor", "\"%L\" chat (say: %s)", client, text);
				return Plugin_Handled;
			}
		}
		
		CreateForward_OnClientSayPost(client, text);
		ChatColor(client, text);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

void ChatColor(int client, const char[] text)
{
	static char message[264], name[MAX_NAME_LENGTH], text2[264], buffer[164];
	
	bool zombie = ZM_IsClientZombie(client);
	bool alive = IsPlayerAlive(client);
	GetClientName(client, name, sizeof(name));
	
	strcopy(text2, sizeof(text2), text);
	ReplaceString(text2, sizeof(text2), "{#}", "\x07");
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			SetGlobalTransTarget(i);
		
			Handle buf = StartMessageOne("SayText2", i); // \x03 name TeamColor ?
			if (buf != null)
			{
				BfWriteByte(buf, client);
				BfWriteByte(buf, true);
				
				GetClientTags(client, buffer, sizeof(buffer));
				
				if (alive == false)
				{
					FormatEx(message, sizeof(message), "\x01\x07%s%t\x01%s \x01\x07%s%s: \x01%s", "8A2BE2", "DEAD", buffer, zombie ? "DC143C":"FFFFFF", name, text2);
				}
				else
				{
					FormatEx(message, sizeof(message), "\x01%s \x01\x07%s%s: \x01%s", buffer, zombie ? "DC143C":"FFFFFF", name, text2);
				}
				
				BfWriteString(buf, message);
				EndMessage();
			}
		}
	}
}

void GetClientTags(int client, char[] buffer, int maxLength)
{
	static char buffer2[64], buffer3[64];
	ZM_GetClassName(ZM_GetClientClass(client), buffer3, sizeof(buffer3));
	FormatEx(buffer2, sizeof(buffer2), IsTranslatedForLanguage(buffer3, GetServerLanguage()) ? "%t":"%s", buffer3);
	ReplaceString(buffer2, sizeof(buffer2), "#", "\x07");
	
	if (VIP_IsClientVIP(client))
	{
		GetClientGroup(client, buffer3, sizeof(buffer3));
		ReplaceString(buffer3, sizeof(buffer3), "#", "\x07");
		
		if (buffer3[0])
		{
			FormatEx(buffer, maxLength, "\x01%s%s", buffer3, buffer2);
			return;
		}
	}
	
	strcopy(buffer, maxLength, buffer2);
}

void GetClientGroup(int client, char[] buffer, int maxLength)
{
	static char group[SMALL_LINE_LENGTH];
	VIP_GetClientGroup(client, group, sizeof(group));

	if (strcmp(group, "VIP") == 0)
	{
		strcopy(buffer, maxLength, "#7FFF00[VIP]");
	}
	else if (strcmp(group, "SUPERVIP") == 0)
	{
		strcopy(buffer, maxLength, "#7FFF00[SUPERVIP]");
	}
	else if (strcmp(group, "MAXIMUM") == 0)
	{
		strcopy(buffer, maxLength, "#FFFF00[MAXIMUM]");
	}
	else
	{
		strcopy(buffer, maxLength, "#FF0000[VIP]");
	}
}

void CreateForward_OnClientSayPost(int client, const char[] text)
{
	Call_StartForward(hOnClientSayPost);
	Call_PushCell(client);
	Call_PushString(text);
	Call_Finish();
}

Action CreateForward_OnClientSay(int client, const char[] text)
{
	Action result = Plugin_Continue;
	Call_StartForward(hOnClientSay);
	Call_PushCell(client);
	Call_PushString(text);
	Call_Finish(result);
	return result;
}