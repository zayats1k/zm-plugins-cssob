#include <zombiemod>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name = "[ZM] Weapon Ethereal",
	author = "0kEmo",
	version = "1.0"
};

static const char g_model[][] = {
	"models/zombiecity/weapons/ethereal_fix/ethereal_world.phy",
	"models/zombiecity/weapons/ethereal_fix/ethereal_world.sw.vtx",
	"models/zombiecity/weapons/ethereal_fix/ethereal_world.vvd",
	"models/zombiecity/weapons/ethereal_fix/ethereal_world.dx80.vtx",
	"models/zombiecity/weapons/ethereal_fix/ethereal_world.dx90.vtx",
	"models/zombiecity/weapons/ethereal_fix/ethereal_world.mdl",
	"models/zombiecity/weapons/ethereal_fix/ethereal_view.dx80.vtx",
	"models/zombiecity/weapons/ethereal_fix/ethereal_view.dx90.vtx",
	"models/zombiecity/weapons/ethereal_fix/ethereal_view.mdl",
	"models/zombiecity/weapons/ethereal_fix/ethereal_view.sw.vtx",
	"models/zombiecity/weapons/ethereal_fix/ethereal_view.vvd",
	"materials/models/zombiecity/weapons/ethereal_fix/sf ethereal body.vmt",
	"materials/models/zombiecity/weapons/ethereal_fix/sf ethereal ammo d.vmt",
	"materials/models/zombiecity/weapons/ethereal_fix/sf ethereal ammo d.vtf",
	"materials/models/zombiecity/weapons/ethereal_fix/sf ethereal ammo n.vtf",
	"materials/models/zombiecity/weapons/ethereal_fix/sf ethereal ammo.vmt",
	"materials/models/zombiecity/weapons/ethereal_fix/sf ethereal body d.vmt",
	"materials/models/zombiecity/weapons/ethereal_fix/sf ethereal body d.vtf",
	"materials/models/zombiecity/weapons/ethereal_fix/sf ethereal body n.vtf"
};

#define SOUND_WEAPON_RELOAD "zombie-plague/weapons/ethereal/reload.wav"
#define SOUND_WEAPON_FIRE "zombie-plague/weapons/ethereal/fire.wav"
#define SOUND_WEAPON_DRAW "zombie-plague/weapons/ethereal/draw.wav"

int m_Weapon;
float m_fNextShootTime[MAXPLAYERS+1];
float m_fNextReloadTime[MAXPLAYERS+1];

// public void OnPluginStart()
// {
// 	HookEvent("player_death", Event_PlayerDeath);
// }

public void OnMapStart()
{
	char mapname[PLATFORM_MAX_PATH];
	GetCurrentMap(mapname, sizeof(mapname));
	if (!strncmp(mapname, "ze_", 3, false)) {
		return;
	}

	for (int i = 0; i < sizeof(g_model); i++) {
		AddFileToDownloadsTable(g_model[i]);
	}

	AddFileToDownloadsTable("sound/" ... SOUND_WEAPON_RELOAD);
	PrecacheSound(SOUND_WEAPON_RELOAD);
	AddFileToDownloadsTable("sound/" ... SOUND_WEAPON_FIRE);
	PrecacheSound(SOUND_WEAPON_FIRE);
	AddFileToDownloadsTable("sound/" ... SOUND_WEAPON_DRAW);
	PrecacheSound(SOUND_WEAPON_DRAW);
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
	m_Weapon = ZM_GetWeaponNameID("weapon_ethereal");
}

// public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
// {
// 	int client = GetClientOfUserId(event.GetInt("userid"));
// 	int attacker = GetClientOfUserId(event.GetInt("attacker"));
// 	
// 	if (!IsValidClient(attacker) || attacker == client) {
// 		return Plugin_Continue;
// 	}
// 	
// 	if (IsValidClient(client))
// 	{
// 		if (ZM_IsClientZombie(client))
// 		{
// 			int weapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
// 			if (weapon != -1 && GetEntProp(weapon, Prop_Data, "m_iMaxHealth") == m_Weapon)
// 			{
// 				int ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
// 				if (ragdoll != -1)
// 				{
// 					static char classname[SMALL_LINE_LENGTH];
// 					GetEdictClassname(ragdoll, classname, sizeof(classname));
// 					if (!strcmp(classname, "cs_ragdoll", false))
// 					{
// 						static char dissolve[SMALL_LINE_LENGTH];
// 						FormatEx(dissolve, sizeof(dissolve), "dissolve%d", ragdoll);
// 						DispatchKeyValue(ragdoll, "targetname", dissolve);
// 			
// 						int iDissolver = CreateEntityByName("env_entity_dissolver");
// 						
// 						PrintToChatAll("test");
// 						
// 						if (iDissolver != -1)
// 						{
// 							DispatchKeyValue(iDissolver, "target", dissolve);
// 							DispatchKeyValue(iDissolver, "dissolvetype", "2");
// 							AcceptEntityInput(iDissolver, "Dissolve");
// 							AcceptEntityInput(iDissolver, "Kill");
// 						}
// 					}
// 				}
// 			}
// 		}
// 	}
// 	return Plugin_Continue;
// }

void OnPrimaryAttack(int client, int weapon, int clip, float time)
{
	if (clip <= 0)
	{
		OnEndAttack(weapon, time);
		return;
	}

	if (m_fNextShootTime[client] > time)
	{
		return;
	}
	
	m_fNextShootTime[client] = time + 0.17;
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", time + 0.17);
	
	SetEntProp(client, Prop_Send, "m_iShotsFired", GetEntProp(client, Prop_Send, "m_iShotsFired") + 1);
	SetEntProp(weapon, Prop_Send, "m_iClip1", clip - 1); 
	
	ZM_SetWeaponAnimation(client, 2); 
	
	// int rand = GetRandomInt(0, 2);
	// if (rand == 0) ZM_SetWeaponAnimation(client, 1);
	// else if (rand == 1) ZM_SetWeaponAnimation(client, 2);
	// else if (rand == 2) ZM_SetWeaponAnimation(client, 3);
	
	EmitSoundToAll(SOUND_WEAPON_FIRE, weapon, SNDCHAN_WEAPON);
	
	static float velocity[3]; int flags = GetEntityFlags(client); 
	float kickback[] = { /*upBase = */0.5, /* lateralBase = */0.10, /* upMod = */0.1, /* lateralMod = */0.5, /* upMax = */2.0, /* lateralMax = */0.5, /* directionChange = */1.0 };
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);

	if (GetVectorLength(velocity, true) <= 0.0) { }
	else if (!(flags & FL_ONGROUND))
		for (int i = 0; i < sizeof(kickback); i++) kickback[i] *= 1.3;
	else if (flags & FL_DUCKING)
		for (int i = 0; i < sizeof(kickback); i++) kickback[i] *= 0.75;
	else for (int i = 0; i < sizeof(kickback); i++) kickback[i] *= 1.15;
	ZM_CreateWeaponKickBack(client, kickback[0], kickback[1], kickback[2], kickback[3], kickback[4], kickback[5], RoundFloat(kickback[6]));
	
	ZM_FireBullets(client, view_as<int>(CS_AliasToWeaponID("weapon_m4a1")), 0, GetURandomInt() & 255, _, 0.01, 0.02);
	// PrintToChatAll("STATE_ATTACK(%d, %d, %d, %d, %.1f)", client, weapon, clip, mode, time);
}

void OnDeploy(int client, int weapon, float time)
{
	m_fNextShootTime[client] = time + 1.0;
	
	ZM_SendWeaponAnim(weapon, ACT_VM_DRAW);
	SetEntPropFloat(client, Prop_Send, "m_flNextAttack", 9999999.0);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", 9999999.0);
	SetEntProp(client, Prop_Send, "m_iShotsFired", 0);
	EmitSoundToAll(SOUND_WEAPON_DRAW, weapon, SNDCHAN_WEAPON);
}

void OnReloadFinish(int client, int weapon, int clip, int ammo)
{
	int amount = UTIL_Clamp(ZM_GetWeaponClip(m_Weapon) - clip, 0, ammo);

	m_fNextReloadTime[client] = 0.0;
	SetEntProp(weapon, Prop_Send, "m_iClip1", clip + amount);
	UTIL_SetReserveAmmo(client, weapon, ammo - amount);
}

void OnReload(int client, int weapon, int clip, int ammo, float time)
{
	if (UTIL_Clamp(ZM_GetWeaponClip(m_Weapon) - clip, 0, ammo) <= 0)
	{
		return;
	}
	
	if (m_fNextShootTime[client] > time)
	{
		return;
	}
	
	if (clip > 0)
	{
		ZM_EventWeaponReload(client);
	}
	
	time += 2.4;
	m_fNextShootTime[client] = time;
	m_fNextReloadTime[client] = time - 0.6;
	
	ZM_SetWeaponAnimation(client, 5); 
	ZM_SetPlayerAnimation(client, 4);
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", time);
	SetEntProp(client, Prop_Send, "m_iShotsFired", 0);
	
	EmitSoundToAll(SOUND_WEAPON_RELOAD, weapon, SNDCHAN_WEAPON);
}

void OnEndAttack(int weapon, float time)
{
	// ZM_SetWeaponAnimation(client, 8);
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", time + 1.0);
}

void OnIdle(int client, int weapon, int clip, int ammo, float time)
{
	if (clip <= 0)
	{
		if (ammo)
		{
			OnReload(client, weapon, clip, ammo, time);
			return;
		}
	}
	
	if (GetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle") > time)
	{
		return;
	}
	
	ZM_SetWeaponAnimation(client, ANIM_IDLE); 
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", time + 2.0);
}

public void ZM_OnWeaponBullet(int client, int weapon, const float bullet[3], int id)
{	
	if (id == m_Weapon)
	{
		ZM_CreateWeaponTracer(client, weapon, "0", "0", "ethereal_beam", bullet, 0.15);
		
		TE_SetupSparks(bullet, NULL_VECTOR, 1, 0);
		TE_SendToAll();
	}
}

public void ZM_OnWeaponHolster(int client, int weapon, int id)
{
	if (id == m_Weapon)
	{
		StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_RELOAD);
		StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_FIRE);
		StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_DRAW);
	
		m_fNextReloadTime[client] = 0.0;
	}
}

public void ZM_OnWeaponDeploy(int client, int weapon, int id)
{
	if (id == m_Weapon)
	{
		OnDeploy(client, weapon, GetGameTime());
	}
}

public void ZM_OnWeaponDrop(int client, int weapon, int id)
{
	if (id == m_Weapon)
	{
		m_fNextReloadTime[client] = 0.0;
	}
}

public Action ZM_OnWeaponRunCmd(int client, int& buttons, int LastButtons, int weapon, int id)
{
	if (id == m_Weapon)
	{
		float time = GetGameTime();
		int clip = GetEntProp(weapon, Prop_Send, "m_iClip1");
		int ammo = UTIL_GetReserveAmmo(client, weapon);
	
		static float flReloadTime;
		if ((flReloadTime = m_fNextReloadTime[client]) && flReloadTime <= GetGameTime())
		{
			OnReloadFinish(client, weapon, clip, ammo);
		}
		else
		{
			if (buttons & IN_RELOAD)
			{
				OnReload(client, weapon, clip, ammo, time);
				buttons &= (~IN_RELOAD);
				return Plugin_Changed;
			}
		}
		
		if (GetEntProp(client, Prop_Data, "m_nWaterLevel") > 2)
		{
			return Plugin_Continue;
		}
		
		if (buttons & IN_ATTACK)
		{
			OnPrimaryAttack(client, weapon, clip, time);
			buttons &= (~IN_ATTACK);
			return Plugin_Changed;
		}
		else if (LastButtons & IN_ATTACK)
		{
			OnEndAttack(weapon, time);
		}
		
		OnIdle(client, weapon, clip, ammo, time);
	}
	return Plugin_Continue;
}