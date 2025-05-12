#include <zombiemod>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name = "[ZM] Weapon MP5gitar",
	author = "0kEmo",
	version = "1.0"
};

static const char g_model[][] = {
	"models/zombiecity/weapons/mp5gitar/v_smg_mp5.dx80.vtx",
	"models/zombiecity/weapons/mp5gitar/v_smg_mp5.dx90.vtx",
	"models/zombiecity/weapons/mp5gitar/v_smg_mp5.mdl",
	"models/zombiecity/weapons/mp5gitar/v_smg_mp5.sw.vtx",
	"models/zombiecity/weapons/mp5gitar/v_smg_mp5.vvd",
	"models/zombiecity/weapons/mp5gitar/w_smg_mp5.dx80.vtx",
	"models/zombiecity/weapons/mp5gitar/w_smg_mp5.dx90.vtx",
	"models/zombiecity/weapons/mp5gitar/w_smg_mp5.mdl",
	"models/zombiecity/weapons/mp5gitar/w_smg_mp5.phy",
	"models/zombiecity/weapons/mp5gitar/w_smg_mp5.sw.vtx",
	"models/zombiecity/weapons/mp5gitar/w_smg_mp5.vvd",
	"materials/models/weapons/w_models/request cso/frame guitar.vmt",
	"materials/models/weapons/v_models/request cso/frame guitar.vmt",
	"materials/models/weapons/v_models/request cso/frame guitar d.vtf",
	"materials/models/weapons/v_models/request cso/frame guitar n.vtf"
};

#define SOUND_WEAPON_SHOOT "zombiecity/weapons/mp5gitar/guitar_fire.wav"
#define SOUND_WEAPON_DRAW "zombiecity/weapons/mp5gitar/guitar_deploy.wav"
#define SOUND_WEAPON_CLIPIN "zombiecity/weapons/mp5gitar/guitar_in.wav"
#define SOUND_WEAPON_CLIPON "zombiecity/weapons/mp5gitar/guitar_on.wav"
#define SOUND_WEAPON_CLIPOUT "zombiecity/weapons/mp5gitar/guitar_out.wav"

int m_Weapon;
bool m_bFireRight[MAXPLAYERS+1];
float m_fNextShootTime[MAXPLAYERS+1];
float m_fNextReloadTime[MAXPLAYERS+1];

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

	AddFileToDownloadsTable("sound/" ... SOUND_WEAPON_SHOOT);
	PrecacheSound(SOUND_WEAPON_SHOOT);
	AddFileToDownloadsTable("sound/" ... SOUND_WEAPON_DRAW);
	PrecacheSound(SOUND_WEAPON_DRAW);
	AddFileToDownloadsTable("sound/" ... SOUND_WEAPON_CLIPIN);
	PrecacheSound(SOUND_WEAPON_CLIPIN);
	AddFileToDownloadsTable("sound/" ... SOUND_WEAPON_CLIPON);
	PrecacheSound(SOUND_WEAPON_CLIPON);
	AddFileToDownloadsTable("sound/" ... SOUND_WEAPON_CLIPOUT);
	PrecacheSound(SOUND_WEAPON_CLIPOUT);
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
	m_Weapon = ZM_GetWeaponNameID("weapon_mp5gitar");
}

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
	
	SetEntProp(client, Prop_Send, "m_iShotsFired", GetEntProp(client, Prop_Send, "m_iShotsFired") + 1);
	SetEntProp(weapon, Prop_Send, "m_iClip1", clip - 1); 
	EmitSoundToAll(SOUND_WEAPON_SHOOT, weapon, SNDCHAN_WEAPON);
	float kickback[] = { /*upBase = */20.5, /* lateralBase = */0.0, /* upMod = */20.1, /* lateralMod = */0.0, /* upMax = */1.5, /* lateralMax = */1.0, /* directionChange = */1.0 };
	
	m_bFireRight[client] = !m_bFireRight[client];
	m_fNextShootTime[client] = time + 0.1;
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", time + 0.13);
	// ZM_SetWeaponAnimation(client, m_bFireRight[client] ? 3:4);
	
	ZM_SendWeaponAnim(weapon, ACT_VM_PRIMARYATTACK);
	
	static float velocity[3]; int flags = GetEntityFlags(client); 
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
	if (GetVectorLength(velocity, true) <= 0.0) { }
	else if (!(flags & FL_ONGROUND))
		for (int i = 0; i < sizeof(kickback); i++) kickback[i] *= 1.3;
	else if (flags & FL_DUCKING)
		for (int i = 0; i < sizeof(kickback); i++) kickback[i] *= 0.75;
	else for (int i = 0; i < sizeof(kickback); i++) kickback[i] *= 1.15;
	ZM_CreateWeaponKickBack(client, kickback[0], kickback[1], kickback[2], kickback[3], kickback[4], kickback[5], RoundFloat(kickback[6]));
	ZM_FireBullets(client, view_as<int>(CS_AliasToWeaponID("weapon_mp5navy")), 0, GetURandomInt() & 255, _, 0.01, 0.015);
}

void OnDeploy(int client, int weapon, float time)
{
	m_fNextShootTime[client] = time + 1.0;
	m_bFireRight[client] = false;
	
	EmitSoundToAll(SOUND_WEAPON_DRAW, weapon, SNDCHAN_WEAPON);
	ZM_SendWeaponAnim(weapon, ACT_VM_DRAW);
	
	// ZM_SetWeaponAnimation(client, 2);
	SetEntPropFloat(client, Prop_Send, "m_flNextAttack", 9999999.0);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", 9999999.0);
	SetEntProp(client, Prop_Send, "m_iShotsFired", 0);
}

void OnReloadFinish(int client, int weapon, int clip, int ammo, float time)
{
	int amount = UTIL_Clamp(ZM_GetWeaponClip(m_Weapon) - clip, 0, ammo);

	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", time);
	
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
	
	// if (clip > 0)
	// {
	// 	ZM_EventWeaponReload(client);
	// }
	
	ZM_SendWeaponAnim(weapon, ACT_VM_RELOAD);
	ZM_SetPlayerAnimation(client, 4);
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", time);
	SetEntProp(client, Prop_Send, "m_iShotsFired", 0);
	
	time += 3.2;
	m_fNextShootTime[client] = time;
	
	time -= 0.5;
	m_fNextReloadTime[client] = time;
}

void OnEndAttack(int weapon, float time)
{
	time += 1.0;
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", time);
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
	
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", time + 2.0);
}

public void ZM_OnWeaponAnimationEvent(int client, int weapon, int sequence, float fCycle, float fPrevCycle, int id)
{
	if (id == m_Weapon)
	{
		if (sequence == 1)
		{
			if(ZM_InRangeSound(0.11, fPrevCycle, fCycle))
				EmitSoundToAll(SOUND_WEAPON_CLIPOUT, weapon, SNDCHAN_WEAPON);
			else if(ZM_InRangeSound(0.455, fPrevCycle, fCycle))
				EmitSoundToAll(SOUND_WEAPON_CLIPON, weapon, SNDCHAN_WEAPON);
			else if(ZM_InRangeSound(0.67, fPrevCycle, fCycle))
				EmitSoundToAll(SOUND_WEAPON_CLIPIN, weapon, SNDCHAN_WEAPON);
		}
	}
}

public void ZM_OnWeaponHolster(int client, int weapon, int id)
{
	if (id == m_Weapon)
	{
		StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_SHOOT);
		StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_DRAW);
		StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_CLIPIN);
		StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_CLIPON);
		StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_CLIPOUT);
		
		m_fNextReloadTime[client] = 0.0;
		m_bFireRight[client] = false;
	}
}

public void ZM_OnWeaponDrop(int client, int weapon, int id)
{
	if (id == m_Weapon)
	{
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
			OnReloadFinish(client, weapon, clip, ammo, time);
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
		
		if (buttons & IN_ATTACK)
		{
			OnPrimaryAttack(client, weapon, clip, time);
			buttons &= (~IN_ATTACK);
			return Plugin_Changed;
		}
		
		OnIdle(client, weapon, clip, ammo, time);
	}
	return Plugin_Continue;
}