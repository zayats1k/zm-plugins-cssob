#include <zombiemod>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name = "[ZM] Player Stuck",
	author = "0kEmo",
	version = "2.0"
};

Handle m_StuckTimer[MAXPLAYERS+1], m_HudSync;
bool m_StuckPlayer[MAXPLAYERS+1];
int m_CollisionOffset;

public void OnPluginStart()
{
	LoadTranslations("zm_player_stuck.phrases");
	m_HudSync = CreateHudSynchronizer();
	
	m_CollisionOffset = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
}

public void OnClientDisconnect(int client)
{
	if (m_StuckTimer[client])
	{
		KillTimer(m_StuckTimer[client]);
		m_StuckTimer[client] = null;
		m_StuckPlayer[client] = false;
	}
}

public Action OnPlayerRunCmd(int client, int& buttons)
{
	if (IsValidClient(client) && IsPlayerAlive(client) && GetEntityMoveType(client) != MOVETYPE_NOCLIP && IsClientStuck(client))
	{
		bool bBot = IsFakeClient(client);
	
		if (!m_StuckTimer[client])
		{
			m_StuckTimer[client] = CreateTimer(bBot ? GetRandomFloat(2.0, 8.0):1.0, Timer_PlayerStuck, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
		
		if (bBot)
		{
			buttons |= IN_RELOAD;
			buttons |= IN_USE;
		}
		
		if (m_StuckPlayer[client] && buttons & IN_RELOAD && buttons & IN_USE)
		{
			ZM_SpawnTeleportToRespawn(client);
			UTIL_ScreenFade(client, 1.0, 0.3, FFADE_IN, {0, 0, 0, 255});
			ClearSyncHud(client, m_HudSync);
			
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && IsClientObserver(i) && !(GetEntProp(i, Prop_Send, "m_iObserverMode") > 6))
				{
					int target = GetEntPropEnt(i, Prop_Send, "m_hObserverTarget");
					if (target == client) UTIL_ScreenFade(i, 1.0, 0.3, FFADE_IN, {0, 0, 0, 255});
				}
			}
		}
	}
	else OnClientDisconnect(client);
	return Plugin_Continue;
}

public Action Timer_PlayerStuck(Handle timer, int userid) // test "log errors"
{
	int client = GetClientOfUserId(userid);
	
	if (IsValidClient(client) && GetEntityMoveType(client) != MOVETYPE_NOCLIP && IsClientStuck(client))
	{
		m_StuckPlayer[client] = true;
	
		SetHudTextParams(-1.0, 0.2, 1.1, 255, 0, 0, 255, 2, 1.0, 0.0, 0.0);
		ShowSyncHudText(client, m_HudSync, "%T", "HUD_STUCK_BUTTON", client);
		return Plugin_Continue;
	}
	
	m_StuckTimer[client] = null;
	return Plugin_Stop;
}

bool IsClientStuck(int client)
{
	static float origin[3], maxs[3], mins[3];
	GetClientAbsOrigin(client, origin);
	GetClientMins(client, mins);
	GetClientMaxs(client, maxs);
	TR_TraceHullFilter(origin, origin, mins, maxs, MASK_SOLID, TraceEntityFilter, client);

	if (TR_DidHit())
	{
		int victim = TR_GetEntityIndex();
		if (victim > 0)
		{
			switch (view_as<Collision_Group_t>(GetEntData(victim, m_CollisionOffset)))
			{
				case COLLISION_GROUP_DEBRIS, COLLISION_GROUP_DEBRIS_TRIGGER, COLLISION_GROUP_INTERACTIVE_DEBRIS,
				COLLISION_GROUP_IN_VEHICLE, COLLISION_GROUP_WEAPON, COLLISION_GROUP_VEHICLE_CLIP, COLLISION_GROUP_DISSOLVING,
				COLLISION_GROUP_PUSHAWAY: return false;
			}
			
			if (GetEntPropEnt(victim, Prop_Data, "m_hOwnerEntity") == client)
			{
				return false;
			}
			
			// static char classname[64];
			// GetEntityClassname(victim, classname, sizeof(classname));
			// PrintToChatAll("[5] %s - %d", classname, GetEntPropEnt(victim, Prop_Data, "m_hOwnerEntity"));
		}
		return true;
	}
	return false;
}

public bool TraceEntityFilter(int entity, int contentsMask, int client) 
{
	return (entity != client);
}