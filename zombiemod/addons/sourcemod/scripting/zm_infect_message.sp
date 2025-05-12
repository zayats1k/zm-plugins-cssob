#include <zombiemod>

public Plugin myinfo = {
	name = "[ZM] Infect message",
	author = "0kEmo",
	version = "1.0"
};

#pragma semicolon 1
#pragma newdecls required

public void OnPluginStart()
{
	LoadTranslations("zm_infect_message.phrases");
}

public void ZM_OnClientUpdated(int client, int attacker)
{
	if (!IsValidClient(client) || !IsPlayerAlive(client))
	{
		return;
	}
	
	if (IsValidClient(attacker) && IsPlayerAlive(attacker) && ZM_IsClientZombie(attacker))
	{
		float origin[3]; GetClientAbsOrigin(client, origin); origin[2] -= 5.0;
		TE_DynamicLight(origin, 255, 0, 0, 2, 700.0, 0.35, 768.0);
		TE_SendToAll();
	
		KeyValues kv = new KeyValues("Stuff", "title");
		kv.SetColor("color", 255, 0, 0, 255);
		kv.SetNum("level", 1);
		kv.SetNum("time", 1);
		
		char temp[164];
		int rand = UTIL_GetRandomInt(0, 3);
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && !IsFakeClient(i))
			{
				if (rand == 0) Format(temp, sizeof(temp), "%T", "infected_message_1", i, client);
				else if (rand == 1) Format(temp, sizeof(temp), "%T", "infected_message_2", i, client);
				else if (rand == 2) Format(temp, sizeof(temp), "%T", "infected_message_3", i, client, attacker);
				else if (rand == 3) Format(temp, sizeof(temp), "%T", "infected_message_4", i, client, attacker);
				
				kv.SetString("title", temp);
				CreateDialog(i, kv, DialogType_Msg); // cl_showpluginmessages 1
			}
		}
		delete kv;
	}
}