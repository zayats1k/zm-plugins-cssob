#include <zombiemod>
#include <zm_player_animation>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name = "[ZM] Weapon Thunderbolt",
	author = "0kEmo",
	version = "1.0"
};

static const char g_model[][] = {
	"models/zombiecity/weapons/v_thunderbolt.mdl",
	"models/zombiecity/weapons/v_thunderbolt.sw.vtx",
	"models/zombiecity/weapons/v_thunderbolt.vvd",
	"models/zombiecity/weapons/v_thunderbolt.dx80.vtx",
	"models/zombiecity/weapons/v_thunderbolt.dx90.vtx",
	"models/zombiecity/weapons/w_thunderbolt.dx90.vtx",
	"models/zombiecity/weapons/w_thunderbolt.mdl",
	"models/zombiecity/weapons/w_thunderbolt.phy",
	"models/zombiecity/weapons/w_thunderbolt.sw.vtx",
	"models/zombiecity/weapons/w_thunderbolt.vvd",
	"models/zombiecity/weapons/w_thunderbolt.dx80.vtx",
	"materials/models/weapons/tfa_cso/thunderbolt/sfsniper_v_n.vtf",
	"materials/models/weapons/tfa_cso/thunderbolt/sfsniper_v.vmt",
	"materials/models/weapons/tfa_cso/thunderbolt/sfsniper_v.vtf"
};

#define SOUND_WEAPON_IDLE "zombiecity/weapons/thunderbolt/idle.wav"
#define SOUND_WEAPON_FIRE "zombiecity/weapons/thunderbolt/fire.wav"
#define SOUND_WEAPON_DRAW "zombiecity/weapons/thunderbolt/draw.wav"

#define LASER_SPRITE "sprites/redglow1.vmt"

int m_Weapon;
float m_fLoopAnimation[MAXPLAYERS+1];
float m_fNextShootTime[MAXPLAYERS+1];
bool m_Bullet[MAXPLAYERS+1];
int m_fov[MAXPLAYERS+1];

int m_SeeSprite[MAXPLAYERS+1];

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

	AddFileToDownloadsTable("sound/" ... SOUND_WEAPON_IDLE);
	PrecacheSound(SOUND_WEAPON_IDLE);
	AddFileToDownloadsTable("sound/" ... SOUND_WEAPON_FIRE);
	PrecacheSound(SOUND_WEAPON_FIRE);
	AddFileToDownloadsTable("sound/" ... SOUND_WEAPON_DRAW);
	PrecacheSound(SOUND_WEAPON_DRAW);
	
	PrecacheModel(LASER_SPRITE, true);
	
	PrecacheModel("materials/sprites/laserbeam.vmt", true);
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
	m_Weapon = ZM_GetWeaponNameID("weapon_thunderbolt");
}

public void OnClientDisconnect(int client)
{
	int entity = EntRefToEntIndex(m_SeeSprite[client]);
	if (IsValidEntityf(entity))
	{
		AcceptEntityInput(entity, "Kill");
		m_SeeSprite[client] = -1;
	}
}

void OnPrimaryAttack(int client, int weapon, int ammo, float time)
{
	if (ammo <= 0)
	{
		return;
	}

	if (m_fNextShootTime[client] > time)
	{
		return;
	}
	
	m_Bullet[client] = false;
	m_fNextShootTime[client] = time + 2.5;
	SetEntProp(client, Prop_Send, "m_iShotsFired", GetEntProp(client, Prop_Send, "m_iShotsFired") + 1);
	UTIL_SetReserveAmmo(client, weapon, ammo - 1);
	
	ZM_SendWeaponAnim(weapon, ACT_VM_PRIMARYATTACK);
	ZM_SetPlayerAnimation(client, 1);
	
	StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_IDLE);
	EmitSoundToAll(SOUND_WEAPON_FIRE, weapon, SNDCHAN_WEAPON);
	
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", time + 2.5);
	
	static float velocity[3]; int flags = GetEntityFlags(client); 
	float kickback[] = {0.5, 0.15, 2.0, 1.0, 1.0, 1.0, 1.0};
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);

	if (GetVectorLength(velocity, true) <= 0.0) { }
	else if (!(flags & FL_ONGROUND))
		for (int i = 0; i < sizeof(kickback); i++) kickback[i] *= 1.3;
	else if (flags & FL_DUCKING)
		for (int i = 0; i < sizeof(kickback); i++) kickback[i] *= 0.75;
	else for (int i = 0; i < sizeof(kickback); i++) kickback[i] *= 1.15;
	ZM_CreateWeaponKickBack(client, kickback[0], kickback[1], kickback[2], kickback[3], kickback[4], kickback[5], RoundFloat(kickback[6]));
	
	// m_fov[client] = 0;
	SetEntProp(client, Prop_Send, "m_iFOV", GetEntProp(client, Prop_Send, "m_iDefaultFOV"));
	if (GetEntProp(client, Prop_Send, "m_bNightVisionOn") == 1) {
		SetEntProp(client, Prop_Send, "m_bNightVisionOn", 0, 4);
		SetEntProp(client, Prop_Send, "m_bHasNightVision", 0, 4);
	}
	
	int entity = EntRefToEntIndex(m_SeeSprite[client]);
	if (IsValidEntityf(entity))
	{
		AcceptEntityInput(entity, "HideSprite");
	}
	
	ZM_FireBullets(client, view_as<int>(CS_AliasToWeaponID("weapon_awp")), 0, GetURandomInt() & 255, _, 0.0, 0.0);
}

void OnSecondaryAttack(int client, float time)
{
	if (m_fNextShootTime[client] > time)
	{
		return;
	}
	
	m_fNextShootTime[client] = time + 0.3;
	
	m_fov[client]++;
	
	if (m_fov[client] == 1)
	{
		SetEntProp(client, Prop_Send, "m_iFOV", 44);
		SetEntProp(client, Prop_Send, "m_bNightVisionOn", 1, 4);
		SetEntProp(client, Prop_Send, "m_bHasNightVision", 1, 4);
		
		int ent = CreateEntityByName("env_sprite");
		
		EmitSoundToAll("items/nvg_on.wav", client);
		
		if (ent != -1)
		{
			SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
			
			SetEntityModel(ent, LASER_SPRITE);
			DispatchKeyValue(ent, "rendercolor", "255 255 255");
			DispatchKeyValue(ent, "rendermode", "3");
			DispatchKeyValue(ent, "renderamt", "190"); 
			DispatchKeyValue(ent, "framerate", "20.0"); 
			DispatchKeyValue(ent, "scale", "0.001");
			
			DispatchSpawn(ent);
			
			AcceptEntityInput(ent, "ShowSprite");
			
			m_SeeSprite[client] = EntIndexToEntRef(ent);
		}
	}
	else if (m_fov[client] == 2)
	{
		SetEntProp(client, Prop_Send, "m_iFOV", 10);
	}
	else if (m_fov[client] == 3)
	{
		SetEntProp(client, Prop_Send, "m_iFOV", GetEntProp(client, Prop_Send, "m_iDefaultFOV"));
		SetEntProp(client, Prop_Send, "m_bNightVisionOn", 0, 4);
		SetEntProp(client, Prop_Send, "m_bHasNightVision", 0, 4);
		m_fov[client] = 0;
		
		OnClientDisconnect(client);
	}
}

void OnDeploy(int client, int weapon, float time)
{
	StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_IDLE);
	StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_FIRE);
	EmitSoundToAll(SOUND_WEAPON_DRAW, weapon, SNDCHAN_WEAPON);
	
	m_fNextShootTime[client] = time + 2.5;
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", time + 1.2);
	
	ZM_SendWeaponAnim(weapon, ACT_VM_DRAW);
	SetEntPropFloat(client, Prop_Send, "m_flNextAttack", 9999999.0);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", 9999999.0);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", 9999999.0);
	SetEntProp(client, Prop_Send, "m_iShotsFired", 0);
	
	m_fov[client] = 0;
	SetEntProp(client, Prop_Send, "m_iFOV", GetEntProp(client, Prop_Send, "m_iDefaultFOV"));
	if (GetEntProp(client, Prop_Send, "m_bNightVisionOn") == 1) {
		SetEntProp(client, Prop_Send, "m_bNightVisionOn", 0, 4);
		SetEntProp(client, Prop_Send, "m_bHasNightVision", 0, 4);
	}
	
	OnClientDisconnect(client);
}

void OnIdle(int client, int weapon, float time)
{
	if (m_fov[client] != 0)
	{
		if (GetEntProp(client, Prop_Send, "m_iObserverMode") != 0)
		{
			m_fov[client] = 0;
			
			SetEntProp(client, Prop_Send, "m_iFOV", GetEntProp(client, Prop_Send, "m_iDefaultFOV"));
			if (GetEntProp(client, Prop_Send, "m_bNightVisionOn") == 1) {
				SetEntProp(client, Prop_Send, "m_bNightVisionOn", 0, 4);
				SetEntProp(client, Prop_Send, "m_bHasNightVision", 0, 4);
			}
			
			int entity = EntRefToEntIndex(m_SeeSprite[client]);
			if (IsValidEntityf(entity)) {
				AcceptEntityInput(entity, "HideSprite");
			}
			return;
		}
	}
	
	if (m_fNextShootTime[client] <= time)
	{
		if (m_fov[client] != 0 && GetEntProp(client, Prop_Send, "m_bNightVisionOn") == 0) 
		{
			if (m_fov[client] == 1)
			{
				SetEntProp(client, Prop_Send, "m_iFOV", 44);
				SetEntProp(client, Prop_Send, "m_bHasNightVision", 1, 4);
			}
			else if (m_fov[client] == 2)
			{
				SetEntProp(client, Prop_Send, "m_iFOV", 10);
				SetEntProp(client, Prop_Send, "m_bHasNightVision", 1, 4);
			}
			
			int entity = EntRefToEntIndex(m_SeeSprite[client]);
			if (IsValidEntityf(entity))
			{
				AcceptEntityInput(entity, "ShowSprite");
			}
			
			SetEntProp(client, Prop_Send, "m_bNightVisionOn", 1, 4);
		}
	}
	
	if (GetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle") > time)
	{
		return;
	}
	
	StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_IDLE);
	EmitSoundToAll(SOUND_WEAPON_IDLE, weapon, SNDCHAN_WEAPON);
	
	ZM_SetWeaponAnimation(client, 0);
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", time + 8.43);
}

public void OnPlayerSequencePre(int client, int entity, const char[] anim)
{
	if (IsValidClient(client))
	{
		if (m_fov[client] != 0)
		{
			m_fov[client] = 0;
			if (GetEntProp(client, Prop_Send, "m_bNightVisionOn") == 1) {
				SetEntProp(client, Prop_Send, "m_bNightVisionOn", 0, 4);
				SetEntProp(client, Prop_Send, "m_bHasNightVision", 0, 4);
			}
			
			OnClientDisconnect(client);
		}
	}
}

public void OnGameFrame()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i) || !IsPlayerAlive(i) || !ZM_IsClientHuman(i))
		{
			continue;
		}
		
		int entity = EntRefToEntIndex(m_SeeSprite[i]);
		
		if (IsValidEntityf(entity))
		{
			float pos[3], angle[3], position[3];
			
			GetClientEyePosition(i, pos);
			GetClientEyeAngles(i, angle);
			
			Handle trace = TR_TraceRayFilterEx(pos, angle, MASK_SOLID, RayType_Infinite, TraceEntityFilter, i);
		
			if (TR_DidHit(trace) == true)
			{
				TR_GetEndPosition(position, trace);
				TeleportEntity(entity, position, NULL_VECTOR, NULL_VECTOR);
			}
			delete trace;
		}
	}
}

public void ZM_OnWeaponBullet(int client, int weapon, const float bullet[3], int id)
{	
	if (id == m_Weapon)
	{
		if (m_Bullet[client] == false)
		{
			static float position[3];
			ZM_GetPlayerEyePosition(client, 30.0, ZM_GetFRightHand(client) ? -10.0:10.0, -5.0, position);
			
			int entity = UTIL_CreateBeam(position, bullet, _, _, "3.0", _, _, _, _, _, _, "materials/sprites/laserbeam.vmt", _, _, BEAM_STARTSPARKS | BEAM_ENDSPARKS, _, _, _, "0 69 255", 0.0, 1.5, "sflaser");
			
			if (entity != -1)
			{
				CreateTimer(0.1, Timer_BeamEffect, EntIndexToEntRef(entity), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
			}
		
			m_Bullet[client] = true;
		}
	}
}

public Action Timer_BeamEffect(Handle hTimer, int ref)
{
	int entity = EntRefToEntIndex(ref);

	if (entity != -1)
	{
		int iNewAlpha = RoundToNearest((240.0 / 5) / 10.0);
		int iAlpha = UTIL_GetRenderColor(entity, 3);
		
		if (iAlpha < iNewAlpha || iAlpha > 255)
		{
			AcceptEntityInput(entity, "Kill");
			return Plugin_Stop;
		}
		
		UTIL_SetRenderColor(entity, 3, iAlpha - iNewAlpha);
	}
	else return Plugin_Stop;
	return Plugin_Continue;
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
		StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_IDLE);
		StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_FIRE);
		StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_DRAW);
		
		m_fov[client] = 0;
		if (GetEntProp(client, Prop_Send, "m_bNightVisionOn") == 1) {
			SetEntProp(client, Prop_Send, "m_bNightVisionOn", 0, 4);
			SetEntProp(client, Prop_Send, "m_bHasNightVision", 0, 4);
		}
		
		OnClientDisconnect(client);
		
		m_Bullet[client] = false;
		m_fLoopAnimation[client] = 0.0;
	}
}

public void ZM_OnWeaponDrop(int client, int weapon, int id)
{
	if (id == m_Weapon)
	{
		StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_IDLE);
		StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_FIRE);
		StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_DRAW);
		
		m_fov[client] = 0;
		if (GetEntProp(client, Prop_Send, "m_bNightVisionOn") == 1) {
			SetEntProp(client, Prop_Send, "m_bNightVisionOn", 0, 4);
			SetEntProp(client, Prop_Send, "m_bHasNightVision", 0, 4);
		}
		
		OnClientDisconnect(client);
	}
}

public Action ZM_OnWeaponRunCmd(int client, int& buttons, int LastButtons, int weapon, int id)
{
	if (id == m_Weapon)
	{
		float time = GetGameTime();
		
		OnIdle(client, weapon, time);
		
		if (buttons & IN_ATTACK)
		{
			OnPrimaryAttack(client, weapon, UTIL_GetReserveAmmo(client, weapon), time);
			buttons &= (~IN_ATTACK);
			return Plugin_Changed;
		}
		
		if (buttons & IN_ATTACK2)
		{
			OnSecondaryAttack(client, time);
			buttons &= (~IN_ATTACK2);
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

public bool TraceEntityFilter(int entity, int mask, any data)
{
	if (entity != data && GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") != data)
		return true;
	else return false;
}