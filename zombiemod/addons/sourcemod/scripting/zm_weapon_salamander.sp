#include <zombiemod>

#pragma semicolon 1
#pragma newdecls required

static const char g_model[][] = {
	"models/zschool/rustambadr/weapon/salamander/v_mach_m249para.dx80.vtx",
	"models/zschool/rustambadr/weapon/salamander/v_mach_m249para.dx90.vtx",
	"models/zschool/rustambadr/weapon/salamander/v_mach_m249para.mdl",
	"models/zschool/rustambadr/weapon/salamander/v_mach_m249para.sw.vtx",
	"models/zschool/rustambadr/weapon/salamander/v_mach_m249para.vvd",
	"models/zschool/rustambadr/weapon/salamander/v_mach_m249para.xbox.vtx",
	"models/zschool/rustambadr/weapon/salamander/w_mach_m249para.dx80.vtx",
	"models/zschool/rustambadr/weapon/salamander/w_mach_m249para.dx90.vtx",
	"models/zschool/rustambadr/weapon/salamander/w_mach_m249para.mdl",
	"models/zschool/rustambadr/weapon/salamander/w_mach_m249para.phy",
	"models/zschool/rustambadr/weapon/salamander/w_mach_m249para.sw.vtx",
	"models/zschool/rustambadr/weapon/salamander/w_mach_m249para.vvd",
	"models/zschool/rustambadr/weapon/salamander/w_mach_m249para.xbox.vtx",
	"materials/models/weapons/v_models/request cso/frame flame thrower d.vtf",
	"materials/models/weapons/v_models/request cso/frame flame thrower n.vtf",
	"materials/models/weapons/v_models/request cso/frame flame thrower.vmt",
	"materials/models/weapons/w_models/request cso/frame flame thrower.vmt"
};

#define SOUND_WEAPON_DEPLOY "zombie-plague/weapons/salamander/flame thrower deploy.wav"
#define SOUND_WEAPON_IN1 "zombie-plague/weapons/salamander/flame thrower in 1.wav"
#define SOUND_WEAPON_IN2 "zombie-plague/weapons/salamander/flame thrower in 2.wav"
#define SOUND_WEAPON_OUT1 "zombie-plague/weapons/salamander/flame thrower out 1.wav"
#define SOUND_WEAPON_OUT2 "zombie-plague/weapons/salamander/flame thrower out 2.wav"
#define SOUND_WEAPON_FLAMEGUN1 "zombie-plague/weapons/salamander/flamegun-1.wav"
#define SOUND_WEAPON_FLAMEGUN2 "zombie-plague/weapons/salamander/flamegun-2.wav"

int m_Weapon, m_Zombie;
float m_fNextShootTime[MAXPLAYERS+1];
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

	for (int i = 0; i < sizeof(g_model); i++) {
		AddFileToDownloadsTable(g_model[i]);
	}

	AddFileToDownloadsTable("sound/" ... SOUND_WEAPON_DEPLOY);
	PrecacheSound(SOUND_WEAPON_DEPLOY);
	AddFileToDownloadsTable("sound/" ... SOUND_WEAPON_IN1);
	PrecacheSound(SOUND_WEAPON_IN1);
	AddFileToDownloadsTable("sound/" ... SOUND_WEAPON_IN2);
	PrecacheSound(SOUND_WEAPON_IN2);
	AddFileToDownloadsTable("sound/" ... SOUND_WEAPON_OUT1);
	PrecacheSound(SOUND_WEAPON_OUT1);
	AddFileToDownloadsTable("sound/" ... SOUND_WEAPON_OUT2);
	PrecacheSound(SOUND_WEAPON_OUT2);
	AddFileToDownloadsTable("sound/" ... SOUND_WEAPON_FLAMEGUN1);
	PrecacheSound(SOUND_WEAPON_FLAMEGUN1);
	AddFileToDownloadsTable("sound/" ... SOUND_WEAPON_FLAMEGUN2);
	PrecacheSound(SOUND_WEAPON_FLAMEGUN2);
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
	m_Weapon = ZM_GetWeaponNameID("weapon_salamander");
	m_Zombie = ZM_GetClassNameID("zombie_tank");
}

public void OnClientConnected(int client)
{
	m_hIdle[client] = INVALID_ENT_REFERENCE;
	m_hActive[client] = INVALID_ENT_REFERENCE;
	m_hIdle_vm[client] = INVALID_ENT_REFERENCE;
	m_hActive_vm[client] = INVALID_ENT_REFERENCE;
}

public void OnClientPutInServer(int client)
{
	m_hIdle[client] = INVALID_ENT_REFERENCE;
	m_hActive[client] = INVALID_ENT_REFERENCE;
	m_hIdle_vm[client] = INVALID_ENT_REFERENCE;
	m_hActive_vm[client] = INVALID_ENT_REFERENCE;
}

void OnPrimaryAttack(int client, int weapon, int clip, float time)
{
	if (clip <= 0)
	{
		OnEndAttack(client, weapon, clip, time);
		return;
	}

	if (m_fNextShootTime[client] > time)
	{
		return;
	}
	
	m_fNextShootTime[client] = time + 0.3;
	SetEntProp(weapon, Prop_Send, "m_iClip1", clip - 1);
	EmitSoundToAll(SOUND_WEAPON_FLAMEGUN1, weapon, SNDCHAN_WEAPON);
	ZM_SetWeaponAnimation(client, ANIM_SHOOT1);
	// ZM_SetPlayerAnimation(ACT_VM_PRIMARYATTACK);
	
	SetEntProp(client, Prop_Send, "m_iShotsFired", GetEntProp(client, Prop_Send, "m_iShotsFired") + 1);
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", time + 0.3);
	
	float origin[3], originx[3];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i) && ZM_IsClientZombie(i))
		{
			GetClientAbsOrigin(i, originx); originx[2] -= 17.0;
			GetClientAbsOrigin(i, origin); origin[2] -= 35.0;
			if (!IsTargetInSightRange(origin, client, 34.0, 400.0) && !IsTargetInSightRange(originx, client, 34.0, 400.0))
			{
				continue;
			}
			
			if (ZM_GetClientClass(i) != m_Zombie)
			{
				IgniteEntity(i, 1.5, _, 1.0);
			}
			
			ZM_TakeDamage(i, client, client, 1.0, DMG_BURN);
			// PrintToChatAll("%N", i);
		}
	}
	
	OnCreateEffect1(client, weapon, "Start");
	OnCreateEffect2(client, weapon, "Stop");
	
	// PrintToChatAll("STATE_ATTACK(%d, %d, %d, %d, %.1f)", client, weapon, clip, mode, time);
}

stock bool IsTargetInSightRange(float origin[3], int client, float angle = 90.0, float distance = 0.0)
{
	if (angle > 360.0)
	{
		angle = 360.0;
	}
	if (angle < 0.0)
	{
		return false;
	}
	
	float clientpos[3], anglevector[3], targetvector[3];
	float resultdistance;
	
	GetClientAbsOrigin(client, clientpos);
	GetClientEyeAngles(client, anglevector);
	
	// anglevector[0] = anglevector[2] = 0.0;
	GetAngleVectors(anglevector, anglevector, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(anglevector, anglevector);
	
	resultdistance = GetVectorDistance(clientpos, origin);
	
	// clientpos[2] = origin[2] = 0.0;
	MakeVectorFromPoints(clientpos, origin, targetvector);
	NormalizeVector(targetvector, targetvector);
	
	origin[2] += 30.0;
	if (!UTIL_IsAbleToSee2(origin, client, MASK_SOLID))
	{
		return false;
	}
	
	if (RadToDeg(ArcCosine(GetVectorDotProduct(targetvector, anglevector))) <= angle / 2)
	{
		if (distance > 0)
		{
			if (distance >= resultdistance)
			{
				return true;
			}
			else
			{
				return false;
			}
		}
		else
		{
			return true;
		}
	}
	return false;
}

void OnDeploy(int client, int weapon, int clip, float time)
{

	m_fNextShootTime[client] = time + 1.23;
	
	EmitSoundToAll(SOUND_WEAPON_DEPLOY, weapon, SNDCHAN_WEAPON);
	
	ZM_SetWeaponAnimation(client, ANIM_DRAW);
	SetEntPropFloat(client, Prop_Send, "m_flNextAttack", 9999999.0);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", 9999999.0);
	SetEntProp(client, Prop_Send, "m_iShotsFired", 0);
	
	OnCreateEffect1(client, weapon);
	OnCreateEffect2(client, weapon);
	
	if (clip <= 0)
	{
		OnCreateEffect2(client, weapon, "Stop");
	}
}

void OnReloadFinish(int client, int weapon, int clip, int ammo, float time)
{
	int amount = UTIL_Clamp(ZM_GetWeaponClip(m_Weapon) - clip, 0, ammo);

	m_fNextReloadTime[client] = 0.0;
	SetEntProp(weapon, Prop_Send, "m_iClip1", clip + amount);
	UTIL_SetReserveAmmo(client, weapon, ammo - amount);
	
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", time);
	
	OnCreateEffect1(client, weapon, "Stop");
	OnCreateEffect2(client, weapon, "Start");
}

void OnReload(int client, int weapon, int clip, int ammo, float time)
{
	if (UTIL_Clamp(ZM_GetWeaponClip(m_Weapon) - clip, 0, ammo) <= 0)
	{
		return;
	}
	
	OnCreateEffect1(client, weapon, "Stop"); // ...
	
	if (m_fNextShootTime[client] > time)
	{
		return;
	}
	
	time += 5.5;
	m_fNextShootTime[client] = time;
	// m_fNextReloadTime[client] = time;
	m_fNextReloadTime[client] = time - 1.0;
	
	ZM_SetWeaponAnimation(client, ANIM_RELOAD); 
	ZM_SetPlayerAnimation(client, 4);
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", time);
	SetEntProp(client, Prop_Send, "m_iShotsFired", 0);
	
	OnCreateEffect2(client, weapon, "Stop");
}

void OnEndAttack(int client, int weapon, int clip, float time)
{
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", time + 1.0);
	
	if (m_fNextReloadTime[client] > time)
	{
		return;
	}
	
	OnCreateEffect1(client, weapon, "Stop");
	
	if (clip <= 0)
	{
		OnCreateEffect2(client, weapon, "Stop");
		return;
	}
	
	OnCreateEffect2(client, weapon, "Start");
}

void OnCreateEffect1(int client, int weapon, const char[] input = "")
{
	if (!hasLength(input))
	{
		if (IsValidEntity(m_hActive[client]) && m_hActive[client] != INVALID_ENT_REFERENCE)
		{
			return;
		}
		
		ZM_CreateWeaponTracer2(client, weapon, "flame", "luffaren_flamet_fire_v", "luffaren_flamet_fire", true);
	}
	else
	{
		if (IsValidEntity(m_hActive[client]) && m_hActive[client] != INVALID_ENT_REFERENCE)
		{
			if (input[3] == 'o')
			{
				EmitSoundToAll(SOUND_WEAPON_FLAMEGUN2, weapon, SNDCHAN_WEAPON);
			}
		
			AcceptEntityInput(m_hActive[client], input); 
		}
		
		if (IsValidEntity(m_hActive_vm[client]) && m_hActive_vm[client] != INVALID_ENT_REFERENCE)
		{
			AcceptEntityInput(m_hActive_vm[client], input); 
		}
	}
}

void OnCreateEffect2(int client, int weapon, const char[] input = "")
{
	if (!hasLength(input))
	{
		if (IsValidEntity(m_hIdle[client]) && m_hIdle[client] != INVALID_ENT_REFERENCE)
		{
			return;
		}
		
		ZM_CreateWeaponTracer2(client, weapon, "flame", "luffaren_flamet_idle_v", "luffaren_flamet_idle", false);
	}
	else
	{
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

stock void ZM_CreateWeaponTracer2(int client, int weapon, const char[] sAttach1, const char[] sEffect1, const char[] sEffect2, bool effect)
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
		// GetClientEyeAngles(client, angles);
		
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
		SetVariantString(sAttach1);
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
			
			ActivateEntity(entity[1]);
			AcceptEntityInput(entity[1], "Stop");
			m_hActive_vm[client] = EntIndexToEntRef(entity[1]);
		}
		else
		{
			ActivateEntity(entity[0]);
			AcceptEntityInput(entity[0], "Start"); 
			m_hIdle[client] = EntIndexToEntRef(entity[0]);
			
			ActivateEntity(entity[1]);
			AcceptEntityInput(entity[1], "Start");
			m_hIdle_vm[client] = EntIndexToEntRef(entity[1]);
		}
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
	
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", time + 2.0);
}

///////////////
public void ZM_OnWeaponAnimationEvent(int client, int weapon, int sequence, float fCycle, float fPrevCycle, int id)
{
	if (id == m_Weapon)
	{
		if (sequence == 3)
		{
			if(ZM_InRangeSound(0.006622, fPrevCycle, fCycle))
				EmitSoundToAll(SOUND_WEAPON_OUT1, weapon, SNDCHAN_WEAPON);
			else if(ZM_InRangeSound(0.203913, fPrevCycle, fCycle))
				EmitSoundToAll(SOUND_WEAPON_OUT2, weapon, SNDCHAN_WEAPON);
			else if(ZM_InRangeSound(0.514364, fPrevCycle, fCycle))
				EmitSoundToAll(SOUND_WEAPON_IN1, weapon, SNDCHAN_WEAPON);
			else if(ZM_InRangeSound(0.702209, fPrevCycle, fCycle))
				EmitSoundToAll(SOUND_WEAPON_IN2, weapon, SNDCHAN_WEAPON);
		}
	}
}

public void ZM_OnWeaponDeploy(int client, int weapon, int id)
{
	if (id == m_Weapon)
	{
		OnDeploy(client, weapon, GetEntProp(weapon, Prop_Send, "m_iClip1"), GetGameTime());
	}
}

public void ZM_OnWeaponHolster(int client, int weapon, int id)
{
	if (id == m_Weapon)
	{
		m_fNextReloadTime[client] = 0.0;
		
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
		m_fNextReloadTime[client] = 0.0;
	
		OnCreateEffect1(client, weapon, "Kill");
		OnCreateEffect2(client, weapon, "Kill");
		
		m_hIdle[client] = INVALID_ENT_REFERENCE;
		m_hActive[client] = INVALID_ENT_REFERENCE;
		m_hIdle_vm[client] = INVALID_ENT_REFERENCE;
		m_hActive_vm[client] = INVALID_ENT_REFERENCE;
	}
}

public Action ZM_OnWeaponRunCmd(int client, int& buttons, int LastButtons, int weapon, int id)
{
	if (id == m_Weapon)
	{
		static float flReloadTime;
		float time = GetGameTime();
		int clip = GetEntProp(weapon, Prop_Send, "m_iClip1");
		int ammo = UTIL_GetReserveAmmo(client, weapon);
		
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
		
		if (buttons & IN_ATTACK)
		{
			if (GetEntProp(client, Prop_Data, "m_nWaterLevel") > 2)
			{
				OnEndAttack(client, weapon, clip, time);
				return Plugin_Continue;
			}
			
			OnPrimaryAttack(client, weapon, clip, time);
			buttons &= (~IN_ATTACK);
			return Plugin_Changed;
		}
		else if (LastButtons & IN_ATTACK)
		{
			OnEndAttack(client, weapon, clip, time);
		}
		
		OnIdle(client, weapon, clip, ammo, time);
	}
	return Plugin_Continue;
}