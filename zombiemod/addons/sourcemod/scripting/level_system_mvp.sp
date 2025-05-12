#include <zombiemod>
#include <zm_database> // level_system

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name = "[LevelSystem] Mvp",
	author = "0kEmo",
	version = "1.0"
};

public void OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn);
}

public void OnPluginEnd()
{
	UnhookEvent("player_spawn", Event_PlayerSpawn);
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	OnClientLevelUp(GetClientOfUserId(event.GetInt("userid")));
}

public void ZM_OnClientUpdated(int client, int attacker)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		OnClientLevelUp(client);
	}
	
	if (IsValidClient(attacker) && !IsFakeClient(attacker))
	{
		OnClientLevelUp(attacker);
	}
}

public void OnClientLoaded(int client)
{
	OnClientLevelUp(client);
}

public void OnClientLevelUp(int client)
{	
	if (IsValidClient(client))
	{
		CreateTimer(0.4, Timer_MVP, client);
	}
}

public Action Timer_MVP(Handle timer, int client)
{
	if (IsValidClient(client))
	{
		CS_SetMVPCount(client, GetClientLevel(client));	
	}
	return Plugin_Stop;
}