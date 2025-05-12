#include <zombiemod>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo = {
	name = "[ZM] Weapon M32",
	author = "0kEmo",
	version = "1.0"
};

static const char g_model[][] = {
	"models/zombiecity/weapons/v_m32.dx80.vtx",
	"models/zombiecity/weapons/v_m32.dx90.vtx",
	"models/zombiecity/weapons/v_m32.mdl",
	"models/zombiecity/weapons/v_m32.sw.vtx",
	"models/zombiecity/weapons/v_m32.vvd",
	"models/zombiecity/weapons/w_m32.dx80.vtx",
	"models/zombiecity/weapons/w_m32.dx90.vtx",
	"models/zombiecity/weapons/w_m32.mdl",
	"models/zombiecity/weapons/w_m32.phy",
	"models/zombiecity/weapons/w_m32.sw.vtx",
	"models/zombiecity/weapons/w_m32.vvd",
	"models/zombiecity/weapons/w_m32_projectile.dx80.vtx",
	"models/zombiecity/weapons/w_m32_projectile.dx90.vtx",
	"models/zombiecity/weapons/w_m32_projectile.mdl",
	"models/zombiecity/weapons/w_m32_projectile.phy",
	"models/zombiecity/weapons/w_m32_projectile.sw.vtx",
	"models/zombiecity/weapons/w_m32_projectile.vvd",
	"materials/models/weapons/v_models/request cso/m32mgl-vari.vmt",
	"materials/models/weapons/v_models/request cso/m32mgl-vari.vtf",
	"materials/models/weapons/v_models/request cso/milkor m32 mgl d.vtf",
	"materials/models/weapons/v_models/request cso/milkor m32 mgl n.vtf",
	"materials/models/weapons/v_models/request cso/milkor m32 mgl.vmt",
	"materials/models/weapons/w_models/request cso/milkor m32 mgl.vmt"
};

#define SOUND_WEAPON_EXP "zombiecity/weapons/m32/exp1.wav"
#define SOUND_WEAPON_INSERT "zombiecity/weapons/m32/milkor m32 mgl insert.wav"
#define SOUND_WEAPON_AFER_RELOAD "zombiecity/weapons/m32/milkor m32 mgl after reload.wav"
#define SOUND_WEAPON_START_RELOAD "zombiecity/weapons/m32/milkor m32 mgl start reload.wav"
#define SOUND_WEAPON_DEPLOY "zombiecity/weapons/m32/milkor m32 mgl deploy.wav"
#define SOUND_WEAPON_FIRE "zombiecity/weapons/m32/milkor m32 mgl fire.wav"
#define WEAPON_ROCKET_MODEL "models/zombiecity/weapons/w_m32_projectile.mdl"

int m_Weapon;
int m_Trail;
bool m_FireRight[MAXPLAYERS+1];

float m_fNextShootTime[MAXPLAYERS+1];

public void OnLibraryAdded(const char[] sLibrary)
{
	if (!strcmp(sLibrary, "zombiemod", false))
	{
		if (ZM_IsMapLoaded())
		{
			ZM_OnEngineExecute();
		}
	}
}

public void ZM_OnEngineExecute()
{
	m_Weapon = ZM_GetWeaponNameID("weapon_m32");
}

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

	AddFileToDownloadsTable("sound/" ... SOUND_WEAPON_EXP);
	PrecacheSound(SOUND_WEAPON_EXP);
	AddFileToDownloadsTable("sound/" ... SOUND_WEAPON_INSERT);
	PrecacheSound(SOUND_WEAPON_INSERT);
	AddFileToDownloadsTable("sound/" ... SOUND_WEAPON_AFER_RELOAD);
	PrecacheSound(SOUND_WEAPON_AFER_RELOAD);
	AddFileToDownloadsTable("sound/" ... SOUND_WEAPON_START_RELOAD);
	PrecacheSound(SOUND_WEAPON_START_RELOAD);
	AddFileToDownloadsTable("sound/" ... SOUND_WEAPON_DEPLOY);
	PrecacheSound(SOUND_WEAPON_DEPLOY);
	AddFileToDownloadsTable("sound/" ... SOUND_WEAPON_FIRE);
	PrecacheSound(SOUND_WEAPON_FIRE);

	PrecacheModel(WEAPON_ROCKET_MODEL, true);

	m_Trail = PrecacheModel("materials/sprites/laserbeam.vmt", true);
	PrecacheModel("materials/sprites/xfireball3.vmt", true);
}

void OnThink(int client, int weapon, int clip, int ammo, int mode, float time)
{
	SetEntPropFloat(client, Prop_Send, "m_flNextAttack", 9999999.0);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", 9999999.0);
	
	if (clip == ZM_GetWeaponClip(m_Weapon) || ammo <= 0)
	{
		if (mode == 2)
		{
			OnReloadFinish(client, weapon, time);
			return;
		}
	}
	
	switch (mode)
	{
		case 1:
		{
			if (m_fNextShootTime[client] > time)
			{
				return;
			}
			
			m_FireRight[client] = !m_FireRight[client];
			
			// ZM_SendWeaponAnim(weapon, ACT_VM_RELOAD);
			ZM_SetWeaponAnimation(client, m_FireRight[client] ? 3:7);
			ZM_SetPlayerAnimation(client, 6);
			
			SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", time + 1.0);
			m_fNextShootTime[client] = time + 1.0;
			
			SetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoType", 2);
		}
		case 2:
		{
			SetEntProp(weapon, Prop_Send, "m_iClip1", clip + 1);
			UTIL_SetReserveAmmo(client, weapon, ammo - 1);
			
			SetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoType", 1);
		}
	}
}

void OnIdle(int client, int weapon, int clip, int ammo, int mode, float time)
{
	if (mode == 0)
	{
		if (clip <= 0)
		{
			if (ammo)
			{
				OnReload(client, weapon, clip, ammo, mode, time);
				return; /// Execute fake reload
			}
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
	if (ammo <= 0)
	{
		return;
	}
	
	if (clip >= ZM_GetWeaponClip(m_Weapon))
	{
		return;
	}
	
	if (m_fNextShootTime[client] > time)
	{
		return;
	}
	
	if (mode == 0)
	{
		ZM_SendWeaponAnim(weapon, ACT_SHOTGUN_RELOAD_START);
		// ZM_SetWeaponAnimation(client, 5); 
		
		EmitSoundToAll(SOUND_WEAPON_AFER_RELOAD, weapon, SNDCHAN_WEAPON);

		time += 0.7;
		SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", time);
		m_fNextShootTime[client] = time;
		
		SetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoType", 1);
		SetEntProp(client, Prop_Send, "m_iFOV", GetEntProp(client, Prop_Send, "m_iDefaultFOV"));
	}
}

void OnReloadFinish(int client, int weapon, float time)
{
	ZM_SendWeaponAnim(weapon, ACT_SHOTGUN_RELOAD_FINISH);
	// ZM_SetWeaponAnimation(client, 4);        
	ZM_SetPlayerAnimation(client, 7);
	
	EmitSoundToAll(SOUND_WEAPON_START_RELOAD, weapon, SNDCHAN_WEAPON);
	
	time += 0.63;
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", time);
	m_fNextShootTime[client] = time;

	SetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoType", 0);
	
	SetEntProp(client, Prop_Send, "m_iShotsFired", 0);
}

void OnDeploy(int client, int weapon, float time)
{
	// ZM_SetWeaponAnimation(client, 6);
	m_fNextShootTime[client] = time + 1.0;
	
	EmitSoundToAll(SOUND_WEAPON_DEPLOY, weapon, SNDCHAN_WEAPON);
	SetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoType", 0);
	SetEntProp(client, Prop_Send, "m_iShotsFired", 0);
	ZM_SendWeaponAnim(weapon, ACT_VM_DRAW);
	
	SetEntProp(client, Prop_Send, "m_iFOV", GetEntProp(client, Prop_Send, "m_iDefaultFOV"));
}

void OnPrimaryAttack(int client, int weapon, int clip, int mode, float time)
{
	if (mode > 0)
	{
		OnReloadFinish(client, weapon, time);
		return;
	}
	
	if (m_fNextShootTime[client] > time)
	{
		return;
	}
	
	if (clip <= 0)
	{
		// EmitSoundToClient(client, SOUND_CLIP_EMPTY, SOUND_FROM_PLAYER, SNDCHAN_ITEM);
		m_fNextShootTime[client] = time + 0.2;
		return;
	}
	
	m_fNextShootTime[client] = time + 0.6;

	SetEntProp(weapon, Prop_Send, "m_iClip1", clip - 1); 
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", time + 0.6);
	SetEntProp(client, Prop_Send, "m_iShotsFired", GetEntProp(client, Prop_Send, "m_iShotsFired") + 1);
	
	EmitSoundToAll(SOUND_WEAPON_FIRE, weapon, SNDCHAN_WEAPON);
	
	// m_FireRight[client] = !m_FireRight[client];
	// ZM_SetWeaponAnimation(client, m_FireRight[client] ? 1:2);
	ZM_SendWeaponAnim(weapon, ACT_VM_PRIMARYATTACK);
	ZM_SetPlayerAnimation(client, PLAYERANIMEVENT_FIRE_GUN_PRIMARY);
	
	OnCreateGrenade(client);

	static float vVelocity[3]; int iFlags = GetEntityFlags(client);
	float vKickback[] = { /*upBase = */4.5, /* lateralBase = */2.5, /* upMod = */0.125, /* lateralMod = */0.05, /* upMax = */7.5, /* lateralMax = */3.5, /* directionChange = */7.0 };

	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVelocity);

	if (GetVectorLength(vVelocity, true) <= 0.0){ }
	else if (!(iFlags & FL_ONGROUND)) for (int i = 0; i < sizeof(vKickback); i++) vKickback[i] *= 1.3;
	else if (iFlags & FL_DUCKING) for (int i = 0; i < sizeof(vKickback); i++) vKickback[i] *= 0.75;
	else for (int i = 0; i < sizeof(vKickback); i++) vKickback[i] *= 1.15;
	ZM_CreateWeaponKickBack(client, vKickback[0], vKickback[1], vKickback[2], vKickback[3], vKickback[4], vKickback[5], RoundFloat(vKickback[6]));
}

void OnSecondaryAttack(int client, int weapon, int mode, float time)
{
	if (mode > 0)
	{
		OnReloadFinish(client, weapon, time);
		return;
	}
	
	if (m_fNextShootTime[client] > time)
	{
		return;
	}
	
	m_fNextShootTime[client] = time + 0.3;
	int fov = GetEntProp(client, Prop_Send, "m_iDefaultFOV");
	SetEntProp(client, Prop_Send, "m_iFOV", GetEntProp(client, Prop_Send, "m_iFOV") == fov ? 44 : fov);
}

void OnCreateGrenade(int client)
{
	static float position[3], angle[3], vecVelocity[3], velocity[3];
	
	ZM_GetPlayerEyePosition(client, 30.0, ZM_GetFRightHand(client) ? -8.0:8.0, -6.0, position);
	GetClientEyeAngles(client, angle);
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vecVelocity);
	
	int entity = UTIL_CreateProjectile(position, angle, m_Weapon, WEAPON_ROCKET_MODEL);
	
	if (entity != -1)
	{
		GetAngleVectors(angle, velocity, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(velocity, velocity);
		ScaleVector(velocity, (GetEntProp(client, Prop_Data, "m_nWaterLevel") > 2) ? 500.0:2000.0);
		AddVectors(velocity, vecVelocity, velocity);
		TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, velocity);
		
		SetEntPropEnt(entity, Prop_Data, "m_pParent", client); 
		SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", client);
		SetEntPropEnt(entity, Prop_Data, "m_hThrower", client);
		SetEntPropFloat(entity, Prop_Data, "m_flGravity", 1.5); 
		
		SDKHook(entity, SDKHook_Touch, Hook_GrenadeTouch);
		
		TE_SetupBeamFollow(entity, m_Trail, 0, 0.25, 3.0, 3.0, 2, {230, 224, 212, 200});
		TE_SendToAll();
	}
}

public void ZM_OnWeaponAnimationEvent(int client, int weapon, int sequence, float fCycle, float fPrevCycle, int id)
{
	if (id == m_Weapon)
	{
		if (sequence == 3 || sequence == 7)
		{
			if (ZM_InRangeSound(0.151509, fPrevCycle, fCycle))
			{
				EmitSoundToAll(SOUND_WEAPON_INSERT, weapon, SNDCHAN_WEAPON);
			}
		}
	}
}

public void ZM_OnWeaponCreated(int weapon, int weaponID)
{
	if (weaponID == m_Weapon)
	{
		SetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoType", 0);
	}
}     

public void ZM_OnWeaponDeploy(int client, int weapon, int weaponID) 
{
	if (weaponID == m_Weapon)
	{
		OnDeploy(client, weapon, GetGameTime());
	}
}

public Action ZM_OnWeaponRunCmd(int client, int &buttons, int iLastButtons, int weapon, int weaponID)
{
	if (weaponID == m_Weapon)
	{
		float time = GetGameTime();
		int clip = GetEntProp(weapon, Prop_Send, "m_iClip1");
		int ammo = UTIL_GetReserveAmmo(client, weapon);
		int mode = GetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoType");
	
		OnThink(client, weapon, clip, ammo, mode, time);

		if (buttons & IN_RELOAD)
		{
			OnReload(client, weapon, clip, ammo, mode, time);
			buttons &= (~IN_RELOAD);
			return Plugin_Changed;
		}
		
		if (buttons & IN_ATTACK)
		{
			OnPrimaryAttack(client, weapon, clip, mode, time);
			buttons &= (~IN_ATTACK);
			return Plugin_Changed;
		}
		
		if (buttons & IN_ATTACK2)
		{
			OnSecondaryAttack(client, weapon, mode, time);
			buttons &= (~IN_ATTACK2);
			return Plugin_Changed;
		}
		
		OnIdle(client, weapon, clip, ammo, mode, time);
	}
	
	return Plugin_Continue;
}

public Action Hook_GrenadeTouch(int entity, int target)
{
	if (IsValidEdict(target))
	{
		int thrower = GetEntPropEnt(entity, Prop_Data, "m_hThrower");

		if (thrower == target)
		{
			return Plugin_Continue;
		}
		
		static char classname[32]; classname[0] = NULL_STRING[0];
		if (target != -1 && GetEntityClassname(target, classname, sizeof(classname)) && !strncmp(classname, "trigger", 7, false))
		{
			return Plugin_Continue;
		}
		
		static float vPosition[3];
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPosition);
		
		EmitSoundToAll(SOUND_WEAPON_EXP, entity, SNDCHAN_STATIC);
		
		UTIL_CreateExplosion(vPosition, CS_TEAM_CT, 64, _, 400.0, 300.0, thrower);
		AcceptEntityInput(entity, "Kill");
		SDKUnhook(entity, SDKHook_Touch, Hook_GrenadeTouch);
	}
	return Plugin_Continue;
}

public Action ZM_OnGrenadeSound(int grenade, int weaponID)
{
	if (weaponID == m_Weapon)
	{
		return Plugin_Stop; 
	}
	
	return Plugin_Continue;
}