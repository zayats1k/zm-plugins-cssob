#include <zombiemod>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name = "[ZM] Weapon M134",
	author = "0kEmo",
	version = "1.0"
};

static const char g_model[][] = {
	"models/zschool/rustambadr/weapon/m136_xmas/v_m134_xmas.dx80.vtx",
	"models/zschool/rustambadr/weapon/m136_xmas/v_m134_xmas.dx90.vtx",
	"models/zschool/rustambadr/weapon/m136_xmas/v_m134_xmas.mdl",
	"models/zschool/rustambadr/weapon/m136_xmas/v_m134_xmas.sw.vtx",
	"models/zschool/rustambadr/weapon/m136_xmas/v_m134_xmas.vvd",
	"models/zschool/rustambadr/weapon/m136_xmas/w_m134_xmas.dx80.vtx",
	"models/zschool/rustambadr/weapon/m136_xmas/w_m134_xmas.dx90.vtx",
	"models/zschool/rustambadr/weapon/m136_xmas/w_m134_xmas.mdl",
	"models/zschool/rustambadr/weapon/m136_xmas/w_m134_xmas.phy",
	"models/zschool/rustambadr/weapon/m136_xmas/w_m134_xmas.sw.vtx",
	"models/zschool/rustambadr/weapon/m136_xmas/w_m134_xmas.vvd",
	"materials/models/weapons/v_models/request cso/m134[x-mas].vmt",
	"materials/models/weapons/v_models/request cso/m134[x-mas].vtf",
	"materials/models/weapons/v_models/request cso/m134[x-mas]_n.vtf",
	"materials/models/weapons/v_models/request cso/m134_deer_[x-mas].vmt",
	"materials/models/weapons/v_models/request cso/m134_deer_[x-mas].vtf",
	"materials/models/weapons/v_models/request cso/m134_deer_[x-mas]_n.vtf"
};

#define SOUND_WEAPON_SHOOT "zombie-plague/weapons/m136_xmas/m134-1.wav"
#define SOUND_WEAPON_SPINUP "zombie-plague/weapons/m136_xmas/m134_spinup.wav"
#define SOUND_WEAPON_SPINUP_LOOP "zombie-plague/weapons/m136_xmas/m134_spinup_loop.wav"
#define SOUND_WEAPON_SPINDOWN "zombie-plague/weapons/m136_xmas/m134_spindown.wav"
#define SOUND_WEAPON_BOXIN "zombie-plague/weapons/m136_xmas/m134_boxin.wav"
#define SOUND_WEAPON_BOXOUT "zombie-plague/weapons/m136_xmas/m134_boxout.wav"
#define SOUND_WEAPON_CHAIN "zombie-plague/weapons/m136_xmas/m134_chain.wav"
#define SOUND_WEAPON_CLIPOFF "zombie-plague/weapons/m136_xmas/m134_clipoff.wav"
#define SOUND_WEAPON_CLIPON "zombie-plague/weapons/m136_xmas/m134_clipon.wav"

int m_Weapon; // if (strcmp(weaponname, "weapon_m134") == 0)
float m_fLoopSound[MAXPLAYERS+1];
float m_fLoopAnimation[MAXPLAYERS+1];
float m_fNextShootTime[MAXPLAYERS+1];
float m_fNextReloadTime[MAXPLAYERS+1];
// bool m_FireRight[MAXPLAYERS+1];

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
	AddFileToDownloadsTable("sound/" ... SOUND_WEAPON_SPINUP);
	PrecacheSound(SOUND_WEAPON_SPINUP);
	AddFileToDownloadsTable("sound/" ... SOUND_WEAPON_SPINUP_LOOP);
	PrecacheSound(SOUND_WEAPON_SPINUP_LOOP);
	AddFileToDownloadsTable("sound/" ... SOUND_WEAPON_SPINDOWN);
	PrecacheSound(SOUND_WEAPON_SPINDOWN);
	
	AddFileToDownloadsTable("sound/" ... SOUND_WEAPON_BOXIN);
	PrecacheSound(SOUND_WEAPON_BOXIN);
	AddFileToDownloadsTable("sound/" ... SOUND_WEAPON_BOXOUT);
	PrecacheSound(SOUND_WEAPON_BOXOUT);
	AddFileToDownloadsTable("sound/" ... SOUND_WEAPON_CHAIN);
	PrecacheSound(SOUND_WEAPON_CHAIN);
	AddFileToDownloadsTable("sound/" ... SOUND_WEAPON_CLIPOFF);
	PrecacheSound(SOUND_WEAPON_CLIPOFF);
	AddFileToDownloadsTable("sound/" ... SOUND_WEAPON_CLIPON);
	PrecacheSound(SOUND_WEAPON_CLIPON);
}

public void OnLibraryAdded(const char[] name)
{
	if (!strcmp(name, "zombiemod", false))
	{
		if (ZM_IsMapLoaded()) {
			ZM_OnEngineExecute();
		}
	}
}

public void ZM_OnEngineExecute()
{
	m_Weapon = ZM_GetWeaponNameID("weapon_m134");
}

void OnPrimaryAttack(int client, int weapon, int clip, int mode, float time)
{
	if (clip <= 0)
	{
		if (mode > 0)
		{
			OnEndAttack(client, weapon, mode, time);
		}
		return;
	}

	if (m_fNextShootTime[client] > time)
	{
		return;
	}
	
	switch (mode)
	{
		case 0:
		{
			m_fNextShootTime[client] = time + 1.9;
			EmitSoundToAll(SOUND_WEAPON_SPINUP, weapon, SNDCHAN_WEAPON);
			
			ZM_SetWeaponAnimation(client, 7);
			
			if (GetClientButtons(client) & IN_ATTACK)
				SetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoCount", 2);
			else SetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoCount", 1);
		}
		case 1:
		{
			if (m_fLoopSound[client] <= time)
			{
				m_fLoopSound[client] = time + 0.35;
				EmitSoundToAll(SOUND_WEAPON_SPINUP_LOOP, weapon, SNDCHAN_WEAPON);
			}
			
			if (m_fLoopAnimation[client] <= time)
			{
				m_fLoopAnimation[client] = time + 0.8;
				
				ZM_SetWeaponAnimation(client, 5);
			}
			
			if (GetClientButtons(client) & IN_ATTACK) {
				SetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoCount", 2);
			}
		}
		case 2:
		{
			int Button = GetClientButtons(client);
			if (!(Button & IN_ATTACK) && Button & IN_ATTACK2) {
				SetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoCount", 1);
				return;
			}
			
			m_fNextShootTime[client] = time + 0.05;
			SetEntProp(client, Prop_Send, "m_iShotsFired", GetEntProp(client, Prop_Send, "m_iShotsFired") + 1);
			SetEntProp(weapon, Prop_Send, "m_iClip1", clip - 1); 
			
			// m_FireRight[client] = !m_FireRight[client];
			
			ZM_SendWeaponAnim(weapon, ACT_VM_PRIMARYATTACK);
			// ZM_SetWeaponAnimation(client, m_FireRight[client] ? ANIM_SHOOT1:ANIM_SHOOT2);
			
			EmitSoundToAll(SOUND_WEAPON_SHOOT, weapon, SNDCHAN_WEAPON);
			
			SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", time + 0.05);
			
			static float velocity[3]; int flags = GetEntityFlags(client); 
			float kickback[] = {0.5, 0.10, 0.1, 0.5, 0.5, 0.5, 0.5 };
			GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);

			if (GetVectorLength(velocity, true) <= 0.0) { }
			else if (!(flags & FL_ONGROUND))
				for (int i = 0; i < sizeof(kickback); i++) kickback[i] *= 1.3;
			else if (flags & FL_DUCKING)
				for (int i = 0; i < sizeof(kickback); i++) kickback[i] *= 0.75;
			else for (int i = 0; i < sizeof(kickback); i++) kickback[i] *= 1.15;
			ZM_CreateWeaponKickBack(client, kickback[0], kickback[1], kickback[2], kickback[3], kickback[4], kickback[5], RoundFloat(kickback[6]));
			
			ZM_FireBullets(client, view_as<int>(CS_AliasToWeaponID("weapon_m249")), 0, GetURandomInt() & 255, _, 0.01, 0.013);
		}
	}
}

stock void ZM_SetWeaponAnimationPair(int client, int weapon, int sequence[2])
{
    int view = ZM_GetClientViewModel(client, false);
    if (view != -1)
    {
        bool PrevAnim = view_as<bool>(GetEntProp(weapon, Prop_Data, "m_bSilencerOn"));
        SetEntProp(view, Prop_Send, "m_nSequence", sequence[PrevAnim ? 0 : 1]);
        SetEntProp(weapon, Prop_Data, "m_bSilencerOn", !PrevAnim);
    }
}

void OnDeploy(int client, int weapon, float time)
{
	m_fNextShootTime[client] = time + 1.23;
	
	ZM_SetWeaponAnimation(client, ANIM_DRAW);
	SetEntPropFloat(client, Prop_Send, "m_flNextAttack", 9999999.0);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", 9999999.0);
	SetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoCount", 0);
	SetEntProp(client, Prop_Send, "m_iShotsFired", 0);
}

void OnReloadFinish(int client, int weapon, int clip, int ammo)
{
	int amount = UTIL_Clamp(ZM_GetWeaponClip(m_Weapon) - clip, 0, ammo);

	m_fNextReloadTime[client] = 0.0;
	SetEntProp(weapon, Prop_Send, "m_iClip1", clip + amount);
	UTIL_SetReserveAmmo(client, weapon, ammo - amount);
}

void OnEndAttack(int client, int weapon, int mode, float time)
{
	if (mode > 0)
	{
		m_fLoopAnimation[client] = 0.0;
		m_fLoopSound[client] = 0.0;
		
		// ZM_SetWeaponAnimation(client, 8);
		SetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoCount", 0);
		SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", time + 1.0);
		
		EmitSoundToAll(SOUND_WEAPON_SPINDOWN, weapon, SNDCHAN_WEAPON);
	}
}

void OnIdle(int client, int weapon, int clip, int ammo, int mode, float time)
{
	if (clip <= 0)
	{
		if (ammo)
		{
			OnReload(client, weapon, clip, ammo, mode, time);
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

void OnReload(int client, int weapon, int clip, int ammo, int mode, float time)
{
	if (mode > 0)
	{
		OnEndAttack(client, weapon, mode, time);
		return;
	}
	
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
	
	time += 5.0;
	m_fNextShootTime[client] = time;
	m_fNextReloadTime[client] = time - 1.5;
	m_fLoopAnimation[client] = 0.0;
	m_fLoopSound[client] = 0.0;
	
	ZM_SetWeaponAnimation(client, ANIM_RELOAD); 
	ZM_SetPlayerAnimation(client, 4);
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", time);
	SetEntProp(client, Prop_Send, "m_iShotsFired", 0);
}

public void ZM_OnWeaponAnimationEvent(int client, int weapon, int sequence, float fCycle, float fPrevCycle, int id)
{
	if (id == m_Weapon)
	{
		if (sequence == 3)
		{
			if(ZM_InRangeSound(0.053333, fPrevCycle, fCycle))
				EmitSoundToAll(SOUND_WEAPON_CHAIN, weapon, SNDCHAN_WEAPON);
			else if(ZM_InRangeSound(0.265, fPrevCycle, fCycle))
				EmitSoundToAll(SOUND_WEAPON_CLIPOFF, weapon, SNDCHAN_WEAPON);
			else if(ZM_InRangeSound(0.373333, fPrevCycle, fCycle))
				EmitSoundToAll(SOUND_WEAPON_BOXOUT, weapon, SNDCHAN_WEAPON);
			else if(ZM_InRangeSound(0.63, fPrevCycle, fCycle))
				EmitSoundToAll(SOUND_WEAPON_BOXIN, weapon, SNDCHAN_WEAPON);
			else if(ZM_InRangeSound(0.68, fPrevCycle, fCycle))
				EmitSoundToAll(SOUND_WEAPON_CLIPON, weapon, SNDCHAN_WEAPON);
			else if(ZM_InRangeSound(0.85, fPrevCycle, fCycle))
				EmitSoundToAll(SOUND_WEAPON_CHAIN, weapon, SNDCHAN_WEAPON);
		}
	}
}

public void ZM_OnWeaponCreated(int client, int weapon, int id)
{
	if (id == m_Weapon)
	{
		SetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoCount", 0);
	}
}

public void ZM_OnWeaponDeploy(int client, int weapon, int id)
{
	if (id == m_Weapon)
	{
		OnDeploy(client, weapon, GetGameTime());
	}
}

public void ZM_OnWeaponHolster(int client, int weapon, int id)
{
	if (id == m_Weapon)
	{
		StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_SHOOT);
		StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_SPINUP);
		StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_SPINUP_LOOP);
		StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_SPINDOWN);
		StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_BOXIN);
		StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_BOXOUT);
		StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_CLIPOFF);
		StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_CLIPON);
		
		m_fNextReloadTime[client] = 0.0;
		m_fLoopAnimation[client] = 0.0;
		m_fLoopSound[client] = 0.0;
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
		if (IsFakeClient(client))
		{
			buttons |= IN_ATTACK2;
		
			int target = GetClientAimTarget(client, false);
			if (IsValidClient(target) && IsPlayerAlive(target) && ZM_IsClientZombie(target))
			{
				buttons |= IN_ATTACK;
			}
		}
	
		float time = GetGameTime();
		int clip = GetEntProp(weapon, Prop_Send, "m_iClip1");
		int ammo = UTIL_GetReserveAmmo(client, weapon);
		int mode = GetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoCount");
	
		static float flReloadTime;
		if ((flReloadTime = m_fNextReloadTime[client]) && flReloadTime <= time)
		{
			OnReloadFinish(client, weapon, clip, ammo);
		}
		else
		{
			if (buttons & IN_RELOAD)
			{
				OnReload(client, weapon, clip, ammo, mode, time);
				buttons &= (~IN_RELOAD);
				return Plugin_Changed;
			}
		}
		
		if (buttons & IN_ATTACK || buttons & IN_ATTACK2)
		{
			OnPrimaryAttack(client, weapon, clip, mode, time);
			return Plugin_Changed;
		}
		else if (LastButtons & IN_ATTACK || LastButtons & IN_ATTACK2)
		{
			OnEndAttack(client, weapon, mode, time);
		}
		
		OnIdle(client, weapon, clip, ammo, mode, time);
	}
	return Plugin_Continue;
}