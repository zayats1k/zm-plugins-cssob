#include <zombiemod>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name = "[ZM] Weapon Laserfist",
	author = "0kEmo",
	version = "1.0"
};

#define RPG_DAMAGE_DISTANCE 180.0
#define RPG_DAMAGE_PRE_SEC 850.0

static const char g_Downloads[][] = {
	"models/zombiecity/weapons/laserfirst/v_laserfist.dx80.vtx",
	"models/zombiecity/weapons/laserfirst/v_laserfist.dx90.vtx",
	"models/zombiecity/weapons/laserfirst/v_laserfist.mdl",
	"models/zombiecity/weapons/laserfirst/v_laserfist.sw.vtx",
	"models/zombiecity/weapons/laserfirst/v_laserfist.vvd",
	"models/zombiecity/weapons/laserfirst/w_laserfist.dx80.vtx",
	"models/zombiecity/weapons/laserfirst/w_laserfist.dx90.vtx",
	"models/zombiecity/weapons/laserfirst/w_laserfist.mdl",
	"models/zombiecity/weapons/laserfirst/w_laserfist.phy",
	"models/zombiecity/weapons/laserfirst/w_laserfist.sw.vtx",
	"models/zombiecity/weapons/laserfirst/w_laserfist.vvd",
	"models/zombiecity/weapons/laserfirst/w_laserfist_dropped.dx80.vtx",
	"models/zombiecity/weapons/laserfirst/w_laserfist_dropped.dx90.vtx",
	"models/zombiecity/weapons/laserfirst/w_laserfist_dropped.mdl",
	"models/zombiecity/weapons/laserfirst/w_laserfist_dropped.phy",
	"models/zombiecity/weapons/laserfirst/w_laserfist_dropped.sw.vtx",
	"models/zombiecity/weapons/laserfirst/w_laserfist_dropped.vvd",
	"materials/models/zombiecity/weapons/laserfirst/$0b_y19s2_lmg_blue.vmt",
	"materials/models/zombiecity/weapons/laserfirst/$0b_y19s2_lmg_blue.vtf",
	"materials/models/zombiecity/weapons/laserfirst/$0b_y19s2_lmg_ef.vmt",
	"materials/models/zombiecity/weapons/laserfirst/$0b_y19s2_lmg_ef.vtf",
	"materials/models/zombiecity/weapons/laserfirst/$0b_y19s2_lmg_ef2.vmt",
	"materials/models/zombiecity/weapons/laserfirst/$0b_y19s2_lmg_ef2.vtf",
	"materials/models/zombiecity/weapons/laserfirst/$20@003y19s2_lmg_gold.vmt",
	"materials/models/zombiecity/weapons/laserfirst/$20@003y19s2_lmg_gold.vtf",
	"materials/models/zombiecity/weapons/laserfirst/$20@003y19s2_lmg_gold_n.vtf",
	"materials/models/zombiecity/weapons/laserfirst/$20@004y19s2_lmg.vmt",
	"materials/models/zombiecity/weapons/laserfirst/$20@004y19s2_lmg.vtf",
	"materials/models/zombiecity/weapons/laserfirst/$20@004y19s2_lmg_n.vtf",
	"materials/models/zombiecity/weapons/laserfirst/dragon tmp s.vtf"
};

#define MODEL_WEAPON_DROP "models/zombiecity/weapons/laserfirst/w_laserfist_dropped.mdl"

#define SOUND_WEAPON_DRAW1 "zombiecity/weapons/laserfirst/laserfist_draw1.wav"
#define SOUND_WEAPON_IDLE "zombiecity/weapons/laserfirst/laserfist_idle.wav"
#define SOUND_WEAPON_SHOOTA "zombiecity/weapons/laserfirst/laserfist_shoota-1.wav"
#define SOUND_WEAPON_SHOOTB "zombiecity/weapons/laserfirst/laserfist_shootb-1.wav"
#define SOUND_WEAPON_SHOOTB_READY "zombiecity/weapons/laserfirst/laserfist_shootb_ready.wav"
#define SOUND_WEAPON_SHOOTB_LOOP "zombiecity/weapons/laserfirst/laserfist_shootb_loop.wav"
#define SOUND_WEAPON_SHOOTB_EXP "zombiecity/weapons/laserfirst/laserfist_shootb_exp.wav"

#define SOUND_WEAPON_B1 "zombiecity/weapons/laserfirst/laserfist_b1.wav"
#define SOUND_WEAPON_CLIPOUT "zombiecity/weapons/laserfirst/laserfist_clipout.wav"
#define SOUND_WEAPON_CLIPIN1 "zombiecity/weapons/laserfirst/laserfist_clipin1.wav"
#define SOUND_WEAPON_CLIPIN2 "zombiecity/weapons/laserfirst/laserfist_clipin2.wav"

int m_Weapon;
int m_ExplosionSprite;
int m_WorldModelEntity[2048];
bool m_bFireRight[MAXPLAYERS+1];
float m_fNextShootTime[MAXPLAYERS+1];
float m_fNextShootTime2[MAXPLAYERS+1];
float m_fNextReloadTime[MAXPLAYERS+1];

int m_hIdle_vm[MAXPLAYERS+1], m_hIdle[MAXPLAYERS+1];
int m_hActive_vm[MAXPLAYERS+1], m_hActive[MAXPLAYERS+1];

public void OnMapStart()
{
	char mapname[PLATFORM_MAX_PATH];
	GetCurrentMap(mapname, sizeof(mapname));
	if (!strncmp(mapname, "ze_", 3, false)) {
		return;
	}

	for (int i = 0; i < sizeof(g_Downloads); i++) {
		AddFileToDownloadsTable(g_Downloads[i]);
	}
	
	AddFileToDownloadsTable("sound/" ... SOUND_WEAPON_DRAW1);
	PrecacheSound(SOUND_WEAPON_DRAW1);
	AddFileToDownloadsTable("sound/" ... SOUND_WEAPON_IDLE);
	PrecacheSound(SOUND_WEAPON_IDLE);
	AddFileToDownloadsTable("sound/" ... SOUND_WEAPON_SHOOTA);
	PrecacheSound(SOUND_WEAPON_SHOOTA);
	AddFileToDownloadsTable("sound/" ... SOUND_WEAPON_SHOOTB);
	PrecacheSound(SOUND_WEAPON_SHOOTB);
	AddFileToDownloadsTable("sound/" ... SOUND_WEAPON_SHOOTB_READY);
	PrecacheSound(SOUND_WEAPON_SHOOTB_READY);
	AddFileToDownloadsTable("sound/" ... SOUND_WEAPON_SHOOTB_LOOP);
	PrecacheSound(SOUND_WEAPON_SHOOTB_LOOP);
	AddFileToDownloadsTable("sound/" ... SOUND_WEAPON_SHOOTB_EXP);
	PrecacheSound(SOUND_WEAPON_SHOOTB_EXP);
	AddFileToDownloadsTable("sound/" ... SOUND_WEAPON_B1);
	PrecacheSound(SOUND_WEAPON_B1);
	AddFileToDownloadsTable("sound/" ... SOUND_WEAPON_CLIPOUT);
	PrecacheSound(SOUND_WEAPON_CLIPOUT);
	AddFileToDownloadsTable("sound/" ... SOUND_WEAPON_CLIPIN1);
	PrecacheSound(SOUND_WEAPON_CLIPIN1);
	AddFileToDownloadsTable("sound/" ... SOUND_WEAPON_CLIPIN2);
	PrecacheSound(SOUND_WEAPON_CLIPIN2);
	
	PrecacheModel(MODEL_WEAPON_DROP, true);
	m_ExplosionSprite = PrecacheModel("sprites/sprite_fire01.vmt", true);
}

public void OnClientDisconnect_Post(int client)
{
	SDKUnhook(client, SDKHook_WeaponEquipPost, Hook_WeaponEquipPost);
}

public void OnEntityDestroyed(int entity)
{
	if (entity > MaxClients && entity <= 2048)
    {
		if (IsValidEntityf(m_WorldModelEntity[entity]))
		{
			int weapon = EntRefToEntIndex(m_WorldModelEntity[entity]);
			if (IsValidEntityf(weapon))
			{
				SetVariantString("");
				AcceptEntityInput(weapon, "ClearParent");
				AcceptEntityInput(weapon, "Kill");
			}
			
			m_WorldModelEntity[entity] = 0;
		}
	}
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
	m_Weapon = ZM_GetWeaponNameID("weapon_laserfist");
}

public void OnClientConnected(int client)
{
	m_fNextShootTime2[client] = 0.0;
	m_hIdle[client] = INVALID_ENT_REFERENCE;
	m_hActive[client] = INVALID_ENT_REFERENCE;
	m_hIdle_vm[client] = INVALID_ENT_REFERENCE;
	m_hActive_vm[client] = INVALID_ENT_REFERENCE;
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponEquipPost, Hook_WeaponEquipPost);

	m_fNextShootTime2[client] = 0.0;
	m_hIdle[client] = INVALID_ENT_REFERENCE;
	m_hActive[client] = INVALID_ENT_REFERENCE;
	m_hIdle_vm[client] = INVALID_ENT_REFERENCE;
	m_hActive_vm[client] = INVALID_ENT_REFERENCE;
}

public void Hook_WeaponEquipPost(int client, int weapon)
{
	if (weapon > MaxClients)
	{
		if (IsValidEntityf(m_WorldModelEntity[weapon]))
		{
			int entity = EntRefToEntIndex(m_WorldModelEntity[weapon]);
			if (IsValidEntityf(entity))
			{
				SetEntityRenderColor(weapon, 255, 255, 255, 255);
				
				SetVariantString("");
				AcceptEntityInput(entity, "ClearParent");
				AcceptEntityInput(entity, "Kill");
			}
			
			m_WorldModelEntity[weapon] = 0;
		}
	}
}

public void ZM_OnWeaponAnimationEvent(int client, int weapon, int sequence, float fCycle, float fPrevCycle, int id)
{
	if (id == m_Weapon)
	{
		if (sequence == 8)
		{
			if(ZM_InRangeSound(0.05, fPrevCycle, fCycle))
				EmitSoundToAll(SOUND_WEAPON_CLIPOUT, weapon, SNDCHAN_WEAPON);
			else if(ZM_InRangeSound(0.31, fPrevCycle, fCycle))
				EmitSoundToAll(SOUND_WEAPON_CLIPIN1, weapon, SNDCHAN_WEAPON);
			else if(ZM_InRangeSound(0.60, fPrevCycle, fCycle))
				EmitSoundToAll(SOUND_WEAPON_CLIPIN2, weapon, SNDCHAN_WEAPON);
		}
		else if (sequence == 5)
		{
			if(ZM_InRangeSound(0.25, fPrevCycle, fCycle))
				EmitSoundToAll(SOUND_WEAPON_B1, weapon, SNDCHAN_WEAPON);
		}
	}
}

void OnPrimaryAttack(int client, int weapon, int clip, float time)
{
	if (clip <= 0)
	{
		OnEndAttack(client, weapon, time);
		return;
	}

	if (m_fNextShootTime[client] > time)
	{
		return;
	}
	
	SetEntProp(client, Prop_Send, "m_iShotsFired", GetEntProp(client, Prop_Send, "m_iShotsFired") + 1);
	SetEntProp(weapon, Prop_Send, "m_iClip1", clip - 1);
	
	m_fNextShootTime[client] = time + 0.04;
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", time + 0.05);
	
	if (!m_bFireRight[client])
	{
		ZM_SetWeaponAnimation(client, 3);
		
		OnCreateEffect1(client, weapon, "Start");
		OnCreateEffect2(client, weapon, "Start");
		m_bFireRight[client] = true;
	}
	
	EmitSoundToAll(SOUND_WEAPON_SHOOTA, weapon, SNDCHAN_WEAPON);
	// ZM_SendWeaponAnim(weapon, m_bFireRight[client] ? ACT_VM_PRIMARYATTACK:ACT_VM_SECONDARYATTACK);
	// ZM_SetPlayerAnimation(client, m_bFireRight[client] ? 1:2);
	
	float kickback[] = { /*upBase = */15.5, /* lateralBase = */0.0, /* upMod = */20.1, /* lateralMod = */0.0, /* upMax = */1.5, /* lateralMax = */1.0, /* directionChange = */1.0};
	for (int i = 0; i < sizeof(kickback); i++) kickback[i] *= 1.0;
	
	static float velocity[3]; int flags = GetEntityFlags(client); 
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
	if (GetVectorLength(velocity, true) <= 0.0) { }
	else if (!(flags & FL_ONGROUND))
		for (int i = 0; i < sizeof(kickback); i++) kickback[i] *= 1.3;
	else if (flags & FL_DUCKING)
		for (int i = 0; i < sizeof(kickback); i++) kickback[i] *= 0.75;
	else for (int i = 0; i < sizeof(kickback); i++) kickback[i] *= 1.15;
	ZM_CreateWeaponKickBack(client, kickback[0], kickback[1], kickback[2], kickback[3], kickback[4], kickback[5], RoundFloat(kickback[6]));
	ZM_FireBullets(client, view_as<int>(CS_AliasToWeaponID("weapon_elite")), 0, GetURandomInt() & 255, _, 0.01, 0.015);
}

void OnSecondaryAttack(int client, int weapon,  int ammo, int mode, float time)
{
	if (ammo < 50)
	{
		return;
	}

	if (m_fNextShootTime[client] > time)
	{
		return;
	}
	
	if (m_fNextShootTime2[client] > time)
	{
		return;
	}
	
	switch (mode)
	{
		case 0:
		{
			m_fNextShootTime[client] = time + 1.0;
			SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", time + 1.0);
			
			OnCreateEffect1(client, weapon, "Stop");
			OnCreateEffect2(client, weapon, "Stop");
			
			// ZM_SetWeaponAnimation(client, 5);
			ZM_SendWeaponAnim(weapon, ACT_VM_ATTACH_SILENCER);
			EmitSoundToAll(SOUND_WEAPON_SHOOTB_READY, weapon, SNDCHAN_WEAPON);
			
			SetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoCount", 1);
		}
		case 1:
		{
			if (GetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle") > time)
			{
				return;
			}
			
			// ZM_CreateWeaponTracer3(client, weapon, "0", "laserfist_2_2", 1.0);
			// ZM_CreateWeaponTracer3(client, weapon, "1", "laserfist_2_2", 1.0);
			
			EmitSoundToAll(SOUND_WEAPON_SHOOTB_LOOP, weapon, SNDCHAN_WEAPON);
			SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", time + 1.0);
		}
	}
}

void OnPrimaryStop(int client, int weapon, int clip, float time)
{
	if (clip <= 0)
	{
		return;
	}

	if (m_fNextShootTime[client] > time && !m_bFireRight[client])
	{
		return;
	}
	
	SetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoCount", 0);
	
	m_fNextShootTime[client] = time + 1.0;
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", time + 1.0);
	m_bFireRight[client] = false;
	
	OnCreateEffect1(client, weapon, "Stop");
	OnCreateEffect2(client, weapon, "Stop");
	
	ZM_SetWeaponAnimation(client, 2);
	// ZM_SendWeaponAnim(weapon, ACT_VM_DRYFIRE_LEFT);
}

void OnOnSecondaryStop(int client, int weapon, int ammo, int mode, float time)
{
	if (mode == 0) {
		return;
	}
	
	if (m_fNextShootTime[client] > time)
	{
		return;
	}
	
	m_fNextShootTime2[client] = time + 5.0;
	m_fNextShootTime[client] = time + 1.3;
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", time + 1.3);
	SetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoCount", 0);
	
	m_bFireRight[client] = false;
	
	ZM_SetWeaponAnimation(client, 4);
	
	// ZM_SetWeaponAnimation(client, 7);
	ZM_SendWeaponAnim(weapon, ACT_VM_PRIMARYATTACK_SILENCED);
	
	float pos[3], angle[3], position[3]; // , m_PlayerOrigin[3]
	
	GetClientEyePosition(client, pos);
	GetClientEyeAngles(client, angle);
	Handle trace = TR_TraceRayFilterEx(pos, angle, MASK_SOLID, RayType_Infinite, TraceEntityFilter, client);
	
	if (TR_DidHit(trace) == true)
	{
		TR_GetEndPosition(position, trace);
		
		EmitSoundToAll(SOUND_WEAPON_SHOOTB, weapon, SNDCHAN_WEAPON);
		UTIL_SetReserveAmmo(client, weapon, UTIL_Clamp(ammo - 50, 0, ammo));
		UTIL_ScreenFade(client, 0.2, 0.0, FFADE_IN, {255, 100, 100, 10});
	
		// int effect = UTIL_CreateParticle(-2, "lf_explode_", "grenade_explosion", position, true);
		// UTIL_RemoveEntity(effect, 0.2);
		
		TE_SetupExplosion(position, m_ExplosionSprite, 5.0, 0, 0, 250, 5000);
		TE_SendToAll();
		
		ZM_CreateWeaponTracer(client, weapon,  "0", "0", "laserfist_2", position, 0.25);
		ZM_CreateWeaponTracer(client, weapon,  "1", "1", "laserfist_2", position, 0.25);
		ZM_CreateWeaponTracer3(client, "0", "laserfist_2_2", 1.0);
		ZM_CreateWeaponTracer3(client, "1", "laserfist_2_2", 1.0);
		
		int test = UTIL_CreateExplosion(position, CS_TEAM_CT, 64, _, RPG_DAMAGE_PRE_SEC, RPG_DAMAGE_DISTANCE, client);
		EmitSoundToAll(SOUND_WEAPON_SHOOTB_EXP, test);
		
		// float flDist = 0.0, flPercent = 0.0;
		// for (int i = 1; i <= MaxClients; i++)
		// {
		// 	if (IsValidClient(i) && IsPlayerAlive(i) && ZM_IsClientZombie(i))
		// 	{
		// 		GetClientEyePosition(i, m_PlayerOrigin);
		// 		
		// 		flDist = GetVectorDistance(position, m_PlayerOrigin);
		// 		if (flDist > RPG_DAMAGE_DISTANCE)
		// 		{
		// 			continue;
		// 		}
		// 		
		// 		flPercent = 1.0 - flDist/RPG_DAMAGE_DISTANCE;
		// 		if (flPercent < 0.1) {
		// 			flPercent = 0.1;
		// 		}
		// 		
		// 		TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, view_as<float>({0.0, 0.0, 0.0}));
		// 		ZM_TakeDamage(i, client, client, flPercent*RPG_DAMAGE_PRE_SEC, DMG_SONIC);
		// 	}
		// }
	}
	delete trace;
	
	static float velocity[3]; int flags = GetEntityFlags(client); 
	float kickback[] = { /*upBase = */9.5, /* lateralBase = */6.45, /* upMod = */0.2, /* lateralMod = */0.05, /* upMax = */8.5, /* lateralMax = */0.5, /* directionChange = */6.0 };
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
	
	if (GetVectorLength(velocity, true) <= 0.0) { }
	else if (!(flags & FL_ONGROUND))
		for (int i = 0; i < sizeof(kickback); i++) kickback[i] *= 1.3;
	else if (flags & FL_DUCKING)
		for (int i = 0; i < sizeof(kickback); i++) kickback[i] *= 0.75;
	else for (int i = 0; i < sizeof(kickback); i++) kickback[i] *= 1.15;
	ZM_CreateWeaponKickBack(client, kickback[0], kickback[1], kickback[2], kickback[3], kickback[4], kickback[5], RoundFloat(kickback[6]));
}

void OnDeploy(int client, int weapon, float time)
{
	m_fNextShootTime[client] = time + 1.6;
	m_bFireRight[client] = false;
	
	EmitSoundToAll(SOUND_WEAPON_DRAW1, weapon, SNDCHAN_WEAPON);
	ZM_SendWeaponAnim(weapon, ACT_VM_DRAW);
	
	OnCreateEffect1(client, weapon);
	OnCreateEffect2(client, weapon);
	
	SetEntPropFloat(client, Prop_Send, "m_flNextAttack", 9999999.0);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", 9999999.0);
	SetEntProp(client, Prop_Send, "m_iShotsFired", 0);
	SetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoCount", 0);
	Hook_WeaponEquipPost(0, weapon);
}

void OnReloadFinish(int client, int weapon, int clip, int ammo)
{
	int amount = UTIL_Clamp(ZM_GetWeaponClip(m_Weapon) - clip, 0, ammo);

	// SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", time);
	
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
	
	OnCreateEffect1(client, weapon, "Stop");
	OnCreateEffect2(client, weapon, "Stop");
	
	ZM_SetPlayerAnimation(client, 4);
	ZM_SendWeaponAnim(weapon, ACT_VM_RELOAD);
	m_bFireRight[client] = false;
	
	SetEntProp(client, Prop_Send, "m_iShotsFired", 0);
	
	time += 2.6;
	m_fNextShootTime[client] = time;
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", time);
	SetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoCount", 0);
	
	time -= 0.5;
	m_fNextReloadTime[client] = time;
}

void OnEndAttack(int client, int weapon, float time)
{
	if (m_bFireRight[client])
	{
		m_bFireRight[client] = false;
		
		// ZM_SetWeaponAnimation(client, 2);
		ZM_SendWeaponAnim(weapon, ACT_VM_PRIMARYATTACK);
		
		OnCreateEffect1(client, weapon, "Stop");
		OnCreateEffect2(client, weapon, "Stop");
		
		time += 1.0;
		SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", time);
		// m_fNextShootTime[client] = time;
		return;
	}
	
	if (GetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle") <= time)
	{
		ZM_SendWeaponAnim(weapon, ACT_VM_IDLE);
		SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", time + 5.0);
	}
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
	
	EmitSoundToAll(SOUND_WEAPON_IDLE, weapon, SNDCHAN_WEAPON);
	ZM_SendWeaponAnim(weapon, ACT_VM_IDLE);
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", time + 1.0);
}

public void ZM_OnWeaponHolster(int client, int weapon, int id)
{
	if (id == m_Weapon)
	{
		StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_DRAW1);
		StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_IDLE);
		StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_SHOOTA);
		StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_SHOOTB);
		StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_SHOOTB_READY);
		StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_SHOOTB_LOOP);
		StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_B1);
		StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_CLIPOUT);
		StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_CLIPIN1);
		StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_CLIPIN2);
		
		m_fNextReloadTime[client] = 0.0;
		m_bFireRight[client] = false;
		
		OnCreateEffect1(client, weapon, "Kill");
		OnCreateEffect2(client, weapon, "Kill");
		
		m_hIdle[client] = INVALID_ENT_REFERENCE;
		m_hActive[client] = INVALID_ENT_REFERENCE;
		m_hIdle_vm[client] = INVALID_ENT_REFERENCE;
		m_hActive_vm[client] = INVALID_ENT_REFERENCE;
	}
}

public void ZM_OnWeaponDrop(int client, int weapon, int id)
{
	if (id == m_Weapon)
	{
		StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_DRAW1);
		StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_IDLE);
		StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_SHOOTA);
		StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_SHOOTB);
		StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_SHOOTB_READY);
		StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_SHOOTB_LOOP);
		StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_B1);
		StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_CLIPOUT);
		StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_CLIPIN1);
		StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_CLIPIN2);
	
		m_fNextReloadTime[client] = 0.0;
		m_bFireRight[client] = false;
		
		OnCreateEffect1(client, weapon, "Kill");
		OnCreateEffect2(client, weapon, "Kill");
		
		m_hIdle[client] = INVALID_ENT_REFERENCE;
		m_hActive[client] = INVALID_ENT_REFERENCE;
		m_hIdle_vm[client] = INVALID_ENT_REFERENCE;
		m_hActive_vm[client] = INVALID_ENT_REFERENCE;
	}
}

public void ZM_OnWeaponDrop2(int weapon, int id)
{
	if (id == m_Weapon)
	{
		if (IsValidEntityf(m_WorldModelEntity[weapon]))
		{
			return;
		}
		
		static float origin[3], ang[3];
		GetEntPropVector(weapon, Prop_Send, "m_vecOrigin", origin);
		GetEntPropVector(weapon, Prop_Send, "m_angRotation", ang);
		
		int entity = CreateEntityByName("cycler");
		if (entity != -1)
		{
			SetEntityModel(entity, MODEL_WEAPON_DROP);
		
			int spawnFlags = GetEntProp(entity, Prop_Data, "m_spawnflags");
			spawnFlags |= 0x0001;
			SetEntProp(entity, Prop_Data, "m_spawnflags", spawnFlags);
		
			DispatchSpawn(entity);
			
			TeleportEntity(entity, origin, ang, NULL_VECTOR);
			
			SetVariantString("!activator");
			AcceptEntityInput(entity, "SetParent", weapon, entity);
			
			SetEntProp(entity, Prop_Send, "m_nSolidType", SOLID_NONE);
			
			SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
			SetEntityRenderColor(weapon, 0, 0, 0, 0);
			
			m_WorldModelEntity[weapon] = EntIndexToEntRef(entity);
		}
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
		if (IsFakeClient(client))
		{
			buttons |= IN_ATTACK;
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
				OnReload(client, weapon, clip, ammo, time);
				buttons &= (~IN_RELOAD);
				return Plugin_Changed;
			}
		}
		
		if (mode == 0)
		{
			if (buttons & IN_ATTACK)
			{
				if (clip <= 0)
				{
					OnEndAttack(client, weapon, time);
				}
			
				OnPrimaryAttack(client, weapon, clip, time);
				buttons &= (~IN_ATTACK);
				return Plugin_Changed;
			}
			else if (LastButtons & IN_ATTACK)
			{
				OnPrimaryStop(client, weapon, clip, time);
			}
		}
		
		if (buttons & IN_ATTACK2)
		{
			OnSecondaryAttack(client, weapon, ammo, mode, time);
		}
		else // if (LastButtons & IN_ATTACK2)
		{
			OnOnSecondaryStop(client, weapon, ammo, mode, time);
		}
		
		OnIdle(client, weapon, clip, ammo, time);
	}
	return Plugin_Continue;
}

public bool TraceEntityFilter(int entity, int mask, any data)
{
	if (entity != data && GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") != data)
		return true;
	else return false;
}

// ublic void ZM_OnWeaponBullet(int client, int weapon, const float bullet[3], int id)
// 	
// 	if (id == m_Weapon)
// 	{
// 		// TE_SetupSparks(bullet, NULL_VECTOR, 1, 0);
// 		// TE_SendToAll();
// 		
// 		// OnCreateEffect1(client, weapon, "bullet", bullet);
// 		// OnCreateEffect2(client, weapon, "bullet", bullet);
// 	}
// 

void OnCreateEffect1(int client, int weapon, const char[] input = "") // const float bullet[3] = NULL_VECTOR)
{
	if (!hasLength(input))
	{
		if (IsValidEntity(m_hActive[client]) && m_hActive[client] != INVALID_ENT_REFERENCE)
		{
			return;
		}
		
		// ZM_CreateWeaponTracer2(client, weapon, "0", "0", "laserfirst_1", bullet, true);
		ZM_CreateWeaponTracer2(client, weapon, "0", "0", "laserfist_shoot", "laserfist_shoot", true);
	}
	else
	{
		// if (strcmp(input, "bullet") == 0)
		// {
		// 	float angle[3];
		// 	GetEntPropVector(client, Prop_Data, "m_angAbsRotation", angle);
		// 
		// 	if (IsValidEntity(m_hActive[client]) && m_hActive[client] != INVALID_ENT_REFERENCE)
		// 	{
		// 		TeleportEntity(m_hActive[client], bullet, angle, NULL_VECTOR);
		// 	}
		// 	if (IsValidEntity(m_hActive_vm[client]) && m_hActive_vm[client] != INVALID_ENT_REFERENCE)
		// 	{
		// 		TeleportEntity(m_hActive_vm[client], bullet, angle, NULL_VECTOR);
		// 	}
		// 	return;
		// }
	
		if (IsValidEntity(m_hActive[client]) && m_hActive[client] != INVALID_ENT_REFERENCE)
		{
			AcceptEntityInput(m_hActive[client], input); 
		}
		
		if (IsValidEntity(m_hActive_vm[client]) && m_hActive_vm[client] != INVALID_ENT_REFERENCE)
		{
			AcceptEntityInput(m_hActive_vm[client], input); 
		}
	}
}

void OnCreateEffect2(int client, int weapon, const char[] input = "") // const float bullet[3] = NULL_VECTOR)
{
	if (!hasLength(input))
	{
		if (IsValidEntity(m_hIdle[client]) && m_hIdle[client] != INVALID_ENT_REFERENCE)
		{
			return;
		}
		
		// ZM_CreateWeaponTracer2(client, weapon, "1", "1", "laserfirst_1", bullet, false);
		ZM_CreateWeaponTracer2(client, weapon, "1", "1", "laserfist_shoot", "laserfist_shoot", false);
	}
	else
	{
		// if (strcmp(input, "bullet") == 0)
		// {
		// 	float angle[3];
		// 	GetEntPropVector(client, Prop_Data, "m_angAbsRotation", angle);
		// 	
		// 	if (IsValidEntity(m_hIdle[client]) && m_hIdle[client] != INVALID_ENT_REFERENCE)
		// 	{
		// 		TeleportEntity(m_hIdle[client], bullet, angle, NULL_VECTOR);
		// 	}
		// 	if (IsValidEntity(m_hIdle_vm[client]) && m_hIdle_vm[client] != INVALID_ENT_REFERENCE)
		// 	{
		// 		TeleportEntity(m_hIdle_vm[client], bullet, angle, NULL_VECTOR);
		// 	}
		// 	
		// 	return;
		// }
	
		if (IsValidEntity(m_hIdle[client]) && m_hIdle[client] != INVALID_ENT_REFERENCE)
		{
			AcceptEntityInput(m_hIdle[client], input); 
		}
		
		if (IsValidEntity(m_hIdle_vm[client]) && m_hIdle_vm[client] != INVALID_ENT_REFERENCE)
		{
			AcceptEntityInput(m_hIdle_vm[client], input); 
		}
	}
}
stock void ZM_CreateWeaponTracer2(int client, int weapon, const char[] sAttach1, char[] sAttach2, const char[] sEffect1, const char[] sEffect2, bool effect)
{
	int view = ZM_GetClientViewModel(client, false);
	if (view == -1) {    
		return;
	}

	static int entity[2];
	entity[0] = CreateEntityByName("info_particle_system");
	entity[1] = CreateEntityByName("info_particle_system");

	if (entity[0] != -1)
	{
		float angles[3];
		GetClientEyeAngles(client, angles);
		
		static char sClassname[SMALL_LINE_LENGTH];
		FormatEx(sClassname, sizeof(sClassname), "w_particle_%d", entity[0]);
		DispatchKeyValue(entity[0], "targetname", sClassname);
		DispatchKeyValue(entity[0], "effect_name", sEffect1);
		DispatchKeyValue(entity[0], "cpoint1", sClassname);
		
		DispatchSpawn(entity[0]);
		SetEntPropEnt(entity[0], Prop_Data, "m_hOwnerEntity", client);
		
		FormatEx(sClassname, sizeof(sClassname), "w_particle_%d", entity[1]);
		DispatchKeyValue(entity[1], "targetname", sClassname);
		DispatchKeyValue(entity[1], "effect_name", sEffect2);
		DispatchKeyValue(entity[1], "cpoint1", sClassname);
		
		DispatchSpawn(entity[1]);
		SetEntPropEnt(entity[1], Prop_Data, "m_hOwnerEntity", client);
		
		SetVariantString("!activator");
		AcceptEntityInput(entity[1], "SetParent", weapon, entity[1], 0);
		SetVariantString(sAttach1);
		AcceptEntityInput(entity[1], "SetParentAttachment", entity[1], entity[1], 0);

		SetVariantString("!activator");
		AcceptEntityInput(entity[0], "SetParent", view, entity[0], 0);
		SetVariantString(sAttach2);
		AcceptEntityInput(entity[0], "SetParentAttachment", entity[0], entity[0], 0);
		
		if (ZM_GetFRightHand(client) != true)
		{
			angles[0] = 0.0;
			angles[1] = -90.0;
			angles[2] = 0.0;
		}
		else
		{
			angles[0] = 0.0;
			angles[1] = 90.0;
			angles[2] = 0.0;
		}
		
		TeleportEntity(entity[0], NULL_VECTOR, angles, NULL_VECTOR);
		
		/*______________________________________________________________________________*/
		
		SetEdictFlags(entity[0], GetEdictFlags(entity[0]) & ~(FL_EDICT_ALWAYS|FL_EDICT_DONTSEND|FL_EDICT_PVSCHECK));
		SetEdictFlags(entity[1], GetEdictFlags(entity[1]) & ~(FL_EDICT_ALWAYS|FL_EDICT_DONTSEND|FL_EDICT_PVSCHECK));
		SDKHook(entity[0], SDKHook_SetTransmit, TracerClientTransmit);
		SDKHook(entity[1], SDKHook_SetTransmit, TracerViewerTransmit);
		
		if (effect == true)
		{
			ActivateEntity(entity[0]);
			AcceptEntityInput(entity[0], "Stop"); 
			m_hActive[client] = EntIndexToEntRef(entity[0]);
			
			// ActivateEntity(entity[1]);
			// AcceptEntityInput(entity[1], "Stop");
			// m_hActive_vm[client] = EntIndexToEntRef(entity[1]);
		}
		else
		{
			ActivateEntity(entity[0]);
			AcceptEntityInput(entity[0], "Stop"); 
			m_hIdle[client] = EntIndexToEntRef(entity[0]);
			
			// ActivateEntity(entity[1]);
			// AcceptEntityInput(entity[1], "Stop");
			// m_hIdle_vm[client] = EntIndexToEntRef(entity[1]);
		}
	}
}

stock void ZM_CreateWeaponTracer3(int client, const char[] sAttach1, const char[] sEffect1, float flDurationTime)
{
	int view = ZM_GetClientViewModel(client, false);
	if (view == -1) {    
		return;
	}

	static int entity[1];
	entity[0] = CreateEntityByName("info_particle_system");

	if (entity[0] != -1)
	{
		static char sClassname[SMALL_LINE_LENGTH];
		FormatEx(sClassname, sizeof(sClassname), "w_particle_%d", entity[0]);
		DispatchKeyValue(entity[0], "targetname", sClassname);
		DispatchKeyValue(entity[0], "effect_name", sEffect1);
		DispatchKeyValue(entity[0], "cpoint1", sClassname);
		
		DispatchSpawn(entity[0]);
		SetEntPropEnt(entity[0], Prop_Data, "m_hOwnerEntity", client);

		SetVariantString("!activator");
		AcceptEntityInput(entity[0], "SetParent", view, entity[0], 0);
		SetVariantString(sAttach1);
		AcceptEntityInput(entity[0], "SetParentAttachment", entity[0], entity[0], 0);
		
		/*______________________________________________________________________________*/
		
		SetEdictFlags(entity[0], GetEdictFlags(entity[0]) & ~(FL_EDICT_ALWAYS|FL_EDICT_DONTSEND|FL_EDICT_PVSCHECK));
		SDKHook(entity[0], SDKHook_SetTransmit, TracerClientTransmit);
		
		ActivateEntity(entity[0]);
		AcceptEntityInput(entity[0], "Start"); 
		
		UTIL_RemoveEntity(entity[0], flDurationTime);
	}
}

// stock void ZM_CreateWeaponTracer2(int client, int weapon, const char[] sAttach1, char[] sAttach2, const char[] sEffect, const float vBullet[3], bool effect)
// {
// 	if (!hasLength(sEffect)) {
// 		return;
// 	}
// 	
// 	int view = ZM_GetClientViewModel(client, false);
// 	if (view == -1) {    
// 		return;
// 	}
// 
// 	static int entity[4];
// 	entity[0] = CreateEntityByName("info_particle_system");
// 	entity[1] = CreateEntityByName("info_particle_system");
// 	entity[2] = CreateEntityByName("info_particle_system");
// 	entity[3] = CreateEntityByName("info_particle_system");
// 
// 	if (entity[3] != -1) /// Check the last entity ;)
// 	{
// 		float angle[3]; // , vEmpty[3]
// 		GetEntPropVector(client, Prop_Data, "m_angAbsRotation", angle);
// 		
// 		TeleportEntity(entity[1], vBullet, angle, NULL_VECTOR);
// 		TeleportEntity(entity[3], vBullet, angle, NULL_VECTOR);
// 		
// 		static char sClassname[SMALL_LINE_LENGTH];
// 		FormatEx(sClassname, sizeof(sClassname), "w_particle_%d", entity[0]);
// 		DispatchKeyValue(entity[0], "targetname", sClassname);
// 		DispatchKeyValue(entity[1], "effect_name", sEffect);
// 		DispatchKeyValue(entity[1], "cpoint1", sClassname);
// 		
// 		DispatchSpawn(entity[1]);
// 		
// 		SetEntPropEnt(entity[1], Prop_Data, "m_hOwnerEntity", client);
// 		
// 		FormatEx(sClassname, sizeof(sClassname), "w_particle_%d", entity[2]);
// 		DispatchKeyValue(entity[2], "targetname", sClassname);
// 		DispatchKeyValue(entity[3], "effect_name", sEffect);
// 		DispatchKeyValue(entity[3], "cpoint1", sClassname);
// 		
// 		DispatchSpawn(entity[3]);
// 		SetEntPropEnt(entity[3], Prop_Data, "m_hOwnerEntity", client);
// 		TeleportEntity(entity[2], NULL_VECTOR, angle, NULL_VECTOR);
// 		
// 		SetVariantString("!activator");
// 		AcceptEntityInput(entity[2], "SetParent", weapon, entity[2], 0);
// 		SetVariantString(sAttach2);
// 		AcceptEntityInput(entity[2], "SetParentAttachment", entity[2], entity[2], 0);
// 
// 		SetVariantString("!activator");
// 		AcceptEntityInput(entity[0], "SetParent", view, entity[0], 0);
// 		SetVariantString(sAttach1);
// 		AcceptEntityInput(entity[0], "SetParentAttachment", entity[0], entity[0], 0);
// 		
// 		/*______________________________________________________________________________*/
// 		
// 		SetEdictFlags(entity[0], GetEdictFlags(entity[0]) & ~(FL_EDICT_ALWAYS|FL_EDICT_DONTSEND|FL_EDICT_PVSCHECK));
// 		SetEdictFlags(entity[1], GetEdictFlags(entity[1]) & ~(FL_EDICT_ALWAYS|FL_EDICT_DONTSEND|FL_EDICT_PVSCHECK));
// 		SetEdictFlags(entity[2], GetEdictFlags(entity[2]) & ~(FL_EDICT_ALWAYS|FL_EDICT_DONTSEND|FL_EDICT_PVSCHECK));
// 		SetEdictFlags(entity[3], GetEdictFlags(entity[3]) & ~(FL_EDICT_ALWAYS|FL_EDICT_DONTSEND|FL_EDICT_PVSCHECK));
// 		
// 		SDKHook(entity[1], SDKHook_SetTransmit, TracerClientTransmit);
// 		SDKHook(entity[3], SDKHook_SetTransmit, TracerViewerTransmit);
// 
// 		if (effect == true)
// 		{
// 			ActivateEntity(entity[1]);
// 			AcceptEntityInput(entity[1], "Stop"); 
// 			m_hActive[client] = EntIndexToEntRef(entity[1]);
// 			
// 			ActivateEntity(entity[3]);
// 			AcceptEntityInput(entity[3], "Stop");
// 			m_hActive_vm[client] = EntIndexToEntRef(entity[3]);
// 		}
// 		else
// 		{
// 			ActivateEntity(entity[1]);
// 			AcceptEntityInput(entity[1], "Stop"); 
// 			m_hIdle[client] = EntIndexToEntRef(entity[1]);
// 			
// 			ActivateEntity(entity[3]);
// 			AcceptEntityInput(entity[3], "Stop");
// 			m_hIdle_vm[client] = EntIndexToEntRef(entity[3]);
// 		}
// 	}
// }