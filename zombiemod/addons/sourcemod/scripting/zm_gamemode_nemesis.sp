#include <zombiemod>
#include <zm_database>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name = "[ZM] Gamemode: Nemesis",
	author = "0kEmo",
	version = "1.0"
};

int m_Zombie;
int m_Mode;

enum struct ServerData
{
	ArrayList ArrayClients;
	
	void Clear()
	{
		this.ArrayClients.Clear();
	}
}
ServerData sServerData;

enum struct ClientData
{
	bool ZombieClass;
	float HudTimeLoad;
	int EntRef;
	
	float damange;
	
	void Clear()
	{
		this.ZombieClass = false;
		this.HudTimeLoad = 0.0;
		this.damange = 0.0;
	}
	void ResetLight()
	{
		if (IsValidEntityf(this.EntRef))
		{
			int ent = EntRefToEntIndex(this.EntRef);
			
			if (IsValidEntityf(ent))
			{
				AcceptEntityInput(ent, "Kill");
			}
			
			this.EntRef = INVALID_ENT_REFERENCE;
		}
	}
}
ClientData sClientData[MAXPLAYERS+1];

enum struct PlayerTop
{
	float damange;
	int clients;
}

public void OnPluginStart()
{
	LoadTranslations("zombiemod_gamemodes.phrases");

	sServerData.ArrayClients = new ArrayList(sizeof(PlayerTop));

	HookEvent("round_start", Hook_RoundStart);
	HookEvent("player_death", Hook_PlayerDeath);
}

public void OnPluginEnd()
{
	UnhookEvent("round_start", Hook_RoundStart);
	UnhookEvent("player_death", Hook_PlayerDeath);
	
	sServerData.Clear();
}

public void OnClientConnected(int client)
{
	sClientData[client].EntRef = INVALID_ENT_REFERENCE;
}

public void OnClientPutInServer(int client)
{
	sClientData[client].EntRef = INVALID_ENT_REFERENCE;
}

public void OnClientDisconnect_Post(int client)
{
	sClientData[client].Clear();
	sClientData[client].ResetLight();
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
	m_Zombie = ZM_GetClassNameID("zombie_nemesis"); // zombie_classic // zombie_nemesis
	m_Mode = ZM_GetGameModeNameID("nemesis mode"); // nemesis mode // normal mode
}

public void Hook_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	sServerData.Clear();
}

public Action Hook_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidClient(client) && ZM_IsClientZombie(client) && sClientData[client].ZombieClass)
	{
		ClearSyncHud(client, ZM_GetHudSync());
		OnClientDisconnect_Post(client);
	}
	return Plugin_Continue;
}

public void ZM_OnGameModeEnd(CSRoundEndReason reason)
{
	if (ZM_GetCurrentGameMode() == m_Mode)
	{
		PlayerTop pt;
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i))
			{
				if (reason == CSRoundEnd_CTWin)
				{
					if (sClientData[i].damange >= 1.0)
					{
						pt.damange = sClientData[i].damange;
						pt.clients = i;
						
						sServerData.ArrayClients.PushArray(pt);
					}
					
					if (ZM_GetClientClass(i) == m_Zombie)
					{
						SetClientExp(i, 30);
					}
				}
			}
			
			sClientData[i].damange = 0.0;
		}
		
		int index = sServerData.ArrayClients.Length;
		
		if (index)
		{
			sServerData.ArrayClients.SortCustom(sortfunc);
		
			TranslationPrintToChatAll("chat round rewards");
			
			for (int i = 0; i < index; i++)
			{
				sServerData.ArrayClients.GetArray(i, pt);
				
				if (i == 0)
				{
					TranslationPrintToChatAll("chat round top players", i+1 , pt.clients, pt.damange, 150);
					SetClientAmmoPacks2(pt.clients, 150);
					SetClientExp(pt.clients, 150);
				}
				if (i == 1)
				{
					TranslationPrintToChatAll("chat round top players", i+1 , pt.clients, pt.damange, 100);
					SetClientAmmoPacks2(pt.clients, 100);
					SetClientExp(pt.clients, 100);
				}
				if (i == 2 && i < 3)
				{
					TranslationPrintToChatAll("chat round top players", i+1 , pt.clients, pt.damange, 50);
					SetClientAmmoPacks2(pt.clients, 50);
					SetClientExp(pt.clients, 50);
				}
			}
		}
		
		// sServerData.Clear();
	}
}

public int sortfunc(int index1, int index2, Handle array, Handle hndl)
{
    PlayerTop pt1, pt2;
    view_as<ArrayList>(array).GetArray(index1, pt1);
    view_as<ArrayList>(array).GetArray(index2, pt2);
    return (pt1.damange < pt2.damange);
}

public void ZM_OnClientDamaged(int client, int attacker, int inflictor, float damage, int damagetype)
{
	if (!IsValidClient(attacker) || !IsPlayerAlive(attacker))
	{
		return;
	}
	
	if (IsValidClient(client) && IsPlayerAlive(client) && ZM_GetClientClass(client) == m_Zombie)
	{
		sClientData[attacker].damange += damage;
	}
}

public void ZM_OnClientUpdated(int client, int attacker)
{
	if (IsValidClient(client))
	{
		if (sClientData[client].ZombieClass)
		{
			ClearSyncHud(client, ZM_GetHudSync());
			OnClientDisconnect_Post(client);
		}
	
		if (ZM_GetClientClass(client) == m_Zombie)
		{
			if (!IsValidEntityf(sClientData[client].EntRef))
			{
				char name[128], light_name[128];
				
				float origin[3]; GetClientAbsOrigin(client, origin);
				
				Format(name, sizeof(name), "target_9_%d", client);
				DispatchKeyValue(client, "targetname", name);
				Format(light_name, sizeof(light_name), "light_9_%d", client);
				
				int entity = CreateEntityByName("light_dynamic");
				DispatchKeyValue(entity,"targetname", light_name);
				DispatchKeyValue(entity, "parentname", name);
				DispatchKeyValue(entity, "inner_cone", "0");
				DispatchKeyValue(entity, "cone", "80");
				DispatchKeyValueFloat(entity, "distance", 600.0);
				DispatchKeyValue(entity, "_light", "255 0 0 255");
				DispatchKeyValue(entity, "brightness", "0");
				DispatchKeyValueFloat(entity, "spotlight_radius", 150.0);
				DispatchKeyValue(entity, "pitch", "90");
				DispatchKeyValue(entity, "style", "5");
				DispatchSpawn(entity);
				
				TeleportEntity(entity, origin, NULL_VECTOR, NULL_VECTOR);
				
				SetVariantString(name);
				AcceptEntityInput(entity, "SetParent", entity, entity, 0);
				
				SetEntProp(entity, Prop_Data, "m_Flags", 2);
				SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", client);
				
				AcceptEntityInput(entity, "TurnOn");
				
				sClientData[client].EntRef = EntIndexToEntRef(entity);
			}
			
			RequestFrame(Frame_OnClientUpdate, GetClientUserId(client));
			sClientData[client].ZombieClass = true;
		}
	}
}

public Action ZM_OnPlayFootStep(int client, const char[] sound, int channel, int level, int flags, float volume, int pitch)
{
	if (IsValidClient(client) && sClientData[client].ZombieClass)
	{
		float origin[3]; GetClientAbsOrigin(client, origin);
		UTIL_ScreenShake(origin, 4.0, 0.9, 0.1, 700.0, 0, false);
	}
	return Plugin_Continue;
}

public void Frame_OnClientUpdate(int userid)
{
	int client = GetClientOfUserId(userid);
	
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		ZM_SetPlayerSpotted(client, false, true);
	}
}

stock void SetClientAmmoPacks2(int client, int ammo)
{
	if (GetFeatureStatus(FeatureType_Native, "SetClientAmmoPacks") == FeatureStatus_Available)
	{
		if (IsValidClient(client))
		{
			SetClientAmmoPacks(client, ammo);
		}
	}
}

stock void TranslationPrintToChatAll(any ...)
{
	static char translation[PLATFORM_LINE_LENGTH];
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && !IsFakeClient(i))
		{
			SetGlobalTransTarget(i);
			VFormat(translation, PLATFORM_LINE_LENGTH, "%t", 1);
			TranslationPluginFormatString(translation, PLATFORM_LINE_LENGTH);
			PrintToChat(i, translation);
		}
	}
}

stock void TranslationPluginFormatString(char[] text, int maxlen)
{
	ReplaceString(text, maxlen, "##", "\x07");
	ReplaceString(text, maxlen, "\\n", "\n");
}