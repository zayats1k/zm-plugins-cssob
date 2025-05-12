#include <zombiemod>
#include <zm_database>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name = "[ZM] Gamemode: Sniper",
	author = "0kEmo",
	version = "1.0"
};

int m_Mode, m_Human, m_Weapon;

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
	bool HumanClass;
	float HudTimeLoad;
	int EntRef;
	
	float damange;
	
	void Clear()
	{
		this.HumanClass = false;
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

	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_death", Hook_PlayerDeath);
}

public void OnPluginEnd()
{
	UnhookEvent("round_start", Event_RoundStart);
	UnhookEvent("player_death", Hook_PlayerDeath);
	
	sServerData.Clear();
}

public void OnMapStart()
{
	PrecacheModel("models/gibs/hgibs.mdl", true);
	PrecacheModel("models/gibs/hgibs_rib.mdl", true);
	PrecacheModel("models/gibs/hgibs_scapula.mdl", true);
	PrecacheModel("models/gibs/hgibs_spine.mdl", true);
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
	m_Human = ZM_GetClassNameID("human_sniper");
	m_Mode = ZM_GetGameModeNameID("sniper mode");
	m_Weapon = ZM_GetWeaponNameID("weapon_awp_buff");
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	sServerData.Clear();
}

public Action Hook_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid")),
	attacker = GetClientOfUserId(event.GetInt("attacker"));
	
	if (IsValidClient(client) && ZM_IsClientZombie(client) && IsValidClient(attacker) && IsPlayerAlive(attacker) && ZM_IsClientHuman(attacker) && sClientData[attacker].HumanClass)
	{
		float origin[3]; GetClientEyePosition(client, origin);
		static float vGib[3]; float vShoot[3];
		
		for (int x = 1; x <= 4; x++)
		{
			vShoot[1] += 90.0; vGib[0] = GetRandomFloat(0.0, 360.0); vGib[1] = GetRandomFloat(-15.0, 15.0); vGib[2] = GetRandomFloat(-15.0, 15.0); 
			switch (x)
			{
				case 1:
				{
					UTIL_CreateShooter(client, "models/gibs/hgibs.mdl", origin, vShoot, vGib, 1.0, 0.05, 100.0, 1.0, 10.0);
					origin[2] -= 25.0;
				}
				case 2: UTIL_CreateShooter(client, "models/gibs/hgibs_rib.mdl", origin, vShoot, vGib, 1.0, 0.05, 100.0, 1.0, 10.0);
				case 3: UTIL_CreateShooter(client, "models/gibs/hgibs_scapula.mdl", origin, vShoot, vGib, 1.0, 0.05, 100.0, 1.0, 10.0);
				case 4: UTIL_CreateShooter(client, "models/gibs/hgibs_spine.mdl", origin, vShoot, vGib, 1.0, 0.05, 100.0, 1.0, 10.0);
			}
		}
		
		origin[2] += 60.0;
		int effect = UTIL_CreateParticle2(client, origin, _, _, "infected", 0.1);
		SetVariantString("!activator");
		AcceptEntityInput(effect, "SetParent", client, effect);
		
		int ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
		if (ragdoll != -1)
		{
			static char classname[SMALL_LINE_LENGTH];
			GetEdictClassname(ragdoll, classname, sizeof(classname));
			if (!strcmp(classname, "cs_ragdoll", false)) {
				AcceptEntityInput(ragdoll, "Kill");
			}
		}
	}
	
	if (IsValidClient(client) && ZM_IsClientHuman(client) && sClientData[client].HumanClass)
	{
		ClearSyncHud(client, ZM_GetHudSync());
		OnClientDisconnect_Post(client);
	}
	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (IsValidClient(client) && IsFakeClient(client) && IsPlayerAlive(client) && sClientData[client].HumanClass)
	{
		int awp = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if (awp != -1 && GetEntProp(awp, Prop_Data, "m_iMaxHealth") == m_Weapon)
		{
			int target = GetClientAimTarget(client, false);
			
			if (IsValidClient(target) && IsPlayerAlive(target) && ZM_IsClientZombie(target))
			{
				buttons |= IN_ATTACK;
			}
		}
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
				if (sClientData[i].damange >= 1.0)
				{
					pt.damange = sClientData[i].damange;
					pt.clients = i;
					
					sServerData.ArrayClients.PushArray(pt);
				}
				
				if (ZM_GetClientClass(i) == m_Human)
				{
					SetClientExp(i, 100);
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
					SetClientExp(pt.clients, 50);
				}
				
				if (i == 1)
				{
					TranslationPrintToChatAll("chat round top players", i+1 , pt.clients, pt.damange, 100);
					SetClientAmmoPacks2(pt.clients, 100);
					SetClientExp(pt.clients, 30);
				}
				
				if (i == 2)
				{
					TranslationPrintToChatAll("chat round top players", i+1 , pt.clients, pt.damange, 50);
					SetClientAmmoPacks2(pt.clients, 50);
					SetClientExp(pt.clients, 10);
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
	
	if (IsValidClient(client) && IsPlayerAlive(client) && ZM_GetClientClass(client) == m_Human)
	{
		sClientData[attacker].damange += damage;
	}
}

public void ZM_OnClientValidateDamage(int client, int& attacker, int& inflicter, float& damage, int& damagetype)
{
	if (ZM_GetCurrentGameMode() == m_Mode)
	{
		if (IsValidClient(attacker) && IsPlayerAlive(attacker))
		{
			if (ZM_IsClientHuman(attacker) && ZM_GetClientClass(attacker) == m_Human)
			{
				int weapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
				
				if (weapon != -1 && GetEntProp(weapon, Prop_Data, "m_iMaxHealth") == m_Weapon)
				{
					if (IsValidClient(client) && IsPlayerAlive(client) && ZM_IsClientZombie(client))
					{
						damage += 1000.0;
					}
				}
			}
			// else if (IsValidClient(client) && IsPlayerAlive(client))
			// {
			// 	damage *= 8.0;
			// }
		}
	}
}

public void ZM_OnClientUpdated(int client, int attacker)
{
	if (IsValidClient(client))
	{
		if (sClientData[client].HumanClass)
		{
			ClearSyncHud(client, ZM_GetHudSync());
			OnClientDisconnect_Post(client);
		}
	
		if (ZM_IsClientHuman(client))
		{
			if (ZM_GetClientClass(client) == m_Human)
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
					DispatchKeyValue(entity, "_light", "0 255 255 255");
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
				
				SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.2);
				RequestFrame(Frame_OnClientUpdate, GetClientUserId(client));
				
				sClientData[client].HumanClass = true;
			}
			else
			{
				RequestFrame(Frame_WeaponAwp, GetClientUserId(client));
			}
		}
		else
		{
			if (ZM_GetCurrentGameMode() == m_Mode)
			{
				SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.2);
			}
		}
	}
}

public void Frame_WeaponAwp(int userid)
{
	int client = GetClientOfUserId(userid);
	
	if (IsValidClient(client) && IsPlayerAlive(client) && ZM_IsClientHuman(client))
	{
		static char classname[32]; int awp = GetPlayerWeaponSlot(client, 0);
		if (awp != -1 && GetEntityClassname(awp, classname, sizeof(classname)) && StrEqual(classname, "weapon_awp_buff")) {
			UTIL_SetReserveAmmo(client, awp, ZM_GetWeaponAmmo(m_Weapon));
		}
	}
}

public void Frame_OnClientUpdate(int userid)
{
	int client = GetClientOfUserId(userid);
	
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		float EntityOrigin[3], PlayerOrigin[3];
		GetClientAbsOrigin(client, EntityOrigin);
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && IsPlayerAlive(i))
			{
				GetClientAbsOrigin(i, PlayerOrigin);
				
				if (GetVectorDistance(EntityOrigin, PlayerOrigin) <= 800.0)
				{
					if (ZM_IsClientZombie(i))
					{
						ZM_SpawnTeleportToRespawn(i);
					}
				}
			}
		}
		
		ZM_SetPlayerSpotted(client, false, true);
		
		int weapon = GetPlayerWeaponSlot(client, 0);
		if (weapon != -1) UTIL_SetReserveAmmo(client, weapon, 230);
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