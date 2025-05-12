#include <zombiemod>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name = "[ZM] Weapon hegrenade effect",
	author = "0kEmo",
	version = "1.0"
};

#define WEAPON_HEGRENADE_RADIUS 280.0
#define WEAPON_HEGRENADE_IGNITE 5.0

ConVar WEAPONS_HEGRENADE_NAPALM;

int m_Weapon;
int m_vecOrigin = -1;

public void OnPluginStart()
{
	WEAPONS_HEGRENADE_NAPALM = CreateConVar("zm_weapons_hegrenade_napalm", "0");

	m_vecOrigin = FindSendPropInfo("CBaseEntity", "m_vecOrigin");
	
	HookEvent("player_hurt", Event_PlayerHurt);
}

bool m_IsMapZm;
public void OnMapStart()
{
	char mapname[PLATFORM_MAX_PATH];
	GetCurrentMap(mapname, sizeof(mapname));
	m_IsMapZm = (strncmp(mapname, "ze_", 3, false) != 0);
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
	m_Weapon = ZM_GetWeaponNameID("weapon_hegrenade");
}

public void OnEntityDestroyed(int entity)
{
	if (!m_IsMapZm) {
		return;
	}

	if (IsValidEntity(entity))
	{
		static char classname[32];
		GetEntityClassname(entity, classname, sizeof(classname));
		
		if (strcmp(classname, "hegrenade_projectile") == 0)
		{
			if (!ZM_IsMapLoaded())
			{
				return;
			}
		
			if (GetEntProp(entity, Prop_Data, "m_iMaxHealth") == m_Weapon)
			{
				float origin[3];
				GetEntDataVector(entity, m_vecOrigin, origin);
				UTIL_CreateParticle(-2, "hegrenade_effect", "grenade_explosion_01", origin, true);
			}
		}
	}
}

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	if (WEAPONS_HEGRENADE_NAPALM.BoolValue != true) {
		return;
	}
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	if (!IsValidClient(attacker)) {
		return;
	}
	
	char weapon[34];
	event.GetString("weapon", weapon, sizeof(weapon));
	if (strcmp(weapon, "hegrenade", false) != 0) {
		return;
	}
	
	if (IsValidClient(client) && IsPlayerAlive(client) && ZM_IsClientZombie(client))
	{
		ExtinguishEntity(client);
		IgniteEntity(client, WEAPON_HEGRENADE_IGNITE);
	}
}