#include <zombiemod>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name = "[ZM] Weapon Dinfinity",
	author = "0kEmo",
	version = "1.0"
};

static const char g_model[][] = {
	"models/zschool/rustambadr/weapon/dinfinity/v_pist_elite.dx80.vtx",
	"models/zschool/rustambadr/weapon/dinfinity/v_pist_elite.dx90.vtx",
	"models/zschool/rustambadr/weapon/dinfinity/v_pist_elite.mdl",
	"models/zschool/rustambadr/weapon/dinfinity/v_pist_elite.sw.vtx",
	"models/zschool/rustambadr/weapon/dinfinity/v_pist_elite.vvd",
	"models/zschool/rustambadr/weapon/dinfinity/w_pist_elite.dx80.vtx",
	"models/zschool/rustambadr/weapon/dinfinity/w_pist_elite.dx90.vtx",
	"models/zschool/rustambadr/weapon/dinfinity/w_pist_elite.mdl",
	"models/zschool/rustambadr/weapon/dinfinity/w_pist_elite.phy",
	"models/zschool/rustambadr/weapon/dinfinity/w_pist_elite.sw.vtx",
	"models/zschool/rustambadr/weapon/dinfinity/w_pist_elite.vvd",
	"models/zschool/rustambadr/weapon/dinfinity/w_pist_elite_dropped.dx80.vtx",
	"models/zschool/rustambadr/weapon/dinfinity/w_pist_elite_dropped.dx90.vtx",
	"models/zschool/rustambadr/weapon/dinfinity/w_pist_elite_dropped.mdl",
	"models/zschool/rustambadr/weapon/dinfinity/w_pist_elite_dropped.phy",
	"models/zschool/rustambadr/weapon/dinfinity/w_pist_elite_dropped.sw.vtx",
	"models/zschool/rustambadr/weapon/dinfinity/w_pist_elite_dropped.vvd",
	"materials/models/weapons/v_models/pist_infinityex2/infinity_gold.vmt",
	"materials/models/weapons/v_models/pist_infinityex2/infinity_gold.vtf",
	"materials/models/weapons/v_models/pist_infinityex2/infinity_gold_flashlight.vmt",
	"materials/models/weapons/v_models/pist_infinityex2/infinity_gold_flashlight.vtf",
	"materials/models/weapons/v_models/pist_infinityex2/infinity_gold_flashlight_n.vtf",
	"materials/models/weapons/v_models/pist_infinityex2/infinity_gold_n.vtf",
	"materials/models/weapons/v_models/pist_infinityex2/infinity_red.vmt",
	"materials/models/weapons/v_models/pist_infinityex2/infinity_red.vtf",
	"materials/models/weapons/v_models/pist_infinityex2/infinity_red_flashlight.vmt",
	"materials/models/weapons/v_models/pist_infinityex2/infinity_red_flashlight.vtf",
	"materials/models/weapons/v_models/pist_infinityex2/infinity_red_flashlight_n.vtf",
	"materials/models/weapons/v_models/pist_infinityex2/infinity_red_n.vtf"
};

#define MODEL_WEAPON_DROP "models/zschool/rustambadr/weapon/dinfinity/w_pist_elite_dropped.mdl"
#define SOUND_WEAPON_SHOOT "zombie-plague/weapons/dinfinity/dinfinity-1.wav"
#define SOUND_WEAPON_DRAW "zombie-plague/weapons/dinfinity/infi_draw.wav"
#define SOUND_WEAPON_CLIPIN "zombie-plague/weapons/dinfinity/infi_clipin.wav"
#define SOUND_WEAPON_CLIPON "zombie-plague/weapons/dinfinity/infi_clipon.wav"
#define SOUND_WEAPON_CLIPOUT "zombie-plague/weapons/dinfinity/infi_clipout.wav"

int m_Weapon;
int m_WorldModelEntity[2048];
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
	
	PrecacheModel(MODEL_WEAPON_DROP, true);
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponEquipPost, Hook_WeaponEquipPost);
}

public void OnClientDisconnect_Post(int client)
{
	SDKUnhook(client, SDKHook_WeaponEquipPost, Hook_WeaponEquipPost);
}

public void OnEntityDestroyed(int entity)
{
	if (entity > MaxClients && entity <= 2048)
    {
		if (m_WorldModelEntity[entity] != 0)
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
	m_Weapon = ZM_GetWeaponNameID("weapon_dinfinity");
}

public void Hook_WeaponEquipPost(int client, int weapon)
{
	if (weapon > MaxClients)
	{
		if (m_WorldModelEntity[weapon] != 0)
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
	EmitSoundToAll(SOUND_WEAPON_SHOOT, weapon, SNDCHAN_WEAPON);
	float kickback[] = { /*upBase = */20.5, /* lateralBase = */0.10, /* upMod = */5.1, /* lateralMod = */0.5, /* upMax = */1.5, /* lateralMax = */0.5, /* directionChange = */1.0 };
	
	m_bFireRight[client] = !m_bFireRight[client];
	if (GetClientButtons(client) & IN_ATTACK2)
	{
		for (int i = 0; i < sizeof(kickback); i++) kickback[i] *= 1.0;
	
		m_fNextShootTime[client] = time + 0.1;
		SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", time + 0.09);
		
		ZM_SetWeaponAnimation(client, m_bFireRight[client] ? 5:4);
	}
	else
	{
		for (int i = 0; i < sizeof(kickback); i++) kickback[i] *= 0.9;
		
		m_fNextShootTime[client] = time + 0.13;
		SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", time + 0.12);
		
		ZM_SetWeaponAnimation(client, m_bFireRight[client] ? 5:4);
	}
	
	ZM_SetPlayerAnimation(client, m_bFireRight[client] ? 1:2);
	
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

void OnDeploy(int client, int weapon, float time)
{
	m_fNextShootTime[client] = time + 1.2;
	m_bFireRight[client] = false;
	
	EmitSoundToAll(SOUND_WEAPON_DRAW, weapon, SNDCHAN_WEAPON);
	
	ZM_SendWeaponAnim(weapon, ACT_VM_DRAW);
	SetEntPropFloat(client, Prop_Send, "m_flNextAttack", 9999999.0);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", 9999999.0);
	SetEntProp(client, Prop_Send, "m_iShotsFired", 0);
	Hook_WeaponEquipPost(0, weapon);
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
	
	if (clip > 0)
	{
		ZM_EventWeaponReload(client);
	}
	
	ZM_SetWeaponAnimation(client, 8);
	ZM_SetPlayerAnimation(client, 4);
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", time);
	SetEntProp(client, Prop_Send, "m_iShotsFired", 0);
	
	time += 4.0;
	m_fNextShootTime[client] = time;
	
	time -= 0.5;
	m_fNextReloadTime[client] = time;
}

void OnEndAttack(int client, int weapon, float time)
{
	m_bFireRight[client] = false;
	
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
		if (sequence == 8)
		{
			if(ZM_InRangeSound(0.083333, fPrevCycle, fCycle))
				EmitSoundToAll(SOUND_WEAPON_CLIPOUT, weapon, SNDCHAN_WEAPON);
			else if(ZM_InRangeSound(0.375, fPrevCycle, fCycle))
				EmitSoundToAll(SOUND_WEAPON_CLIPIN, weapon, SNDCHAN_WEAPON);
			else if(ZM_InRangeSound(0.658333, fPrevCycle, fCycle))
				EmitSoundToAll(SOUND_WEAPON_CLIPIN, weapon, SNDCHAN_WEAPON);
			else if(ZM_InRangeSound(0.9, fPrevCycle, fCycle))
				EmitSoundToAll(SOUND_WEAPON_CLIPON, weapon, SNDCHAN_WEAPON);
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
		StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_SHOOT);
		StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_DRAW);
		StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_CLIPIN);
		StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_CLIPON);
		StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_CLIPOUT);
	
		m_fNextReloadTime[client] = 0.0;
		m_bFireRight[client] = false;
	}
}

public void ZM_OnWeaponDrop2(int weapon, int id)
{
	if (id == m_Weapon)
	{
		if (m_WorldModelEntity[weapon] != 0)
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
	
		static float flReloadTime;
		if ((flReloadTime = m_fNextReloadTime[client]) && flReloadTime <= time)
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
		
		if (buttons & IN_ATTACK && !(LastButtons & IN_ATTACK))
		{
			OnPrimaryAttack(client, weapon, clip, time);
			buttons &= (~IN_ATTACK);
			return Plugin_Changed;
		}
		
		if (buttons & IN_ATTACK2)
		{
			OnPrimaryAttack(client, weapon, clip, time);
			buttons &= (~IN_ATTACK2);
			return Plugin_Changed;
		}
		
		OnIdle(client, weapon, clip, ammo, time);
	}
	return Plugin_Continue;
}