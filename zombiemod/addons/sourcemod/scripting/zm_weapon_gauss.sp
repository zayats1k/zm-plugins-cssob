#include <zombiemod>
#include <vphysics>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name = "[ZM] Weapon Gauss",
	author = "0kEmo",
	version = "1.0"
};

static const char g_model[][] = {
	"models/zschool/rustambadr/weapon/tau/v_gauss.dx80.vtx",
	"models/zschool/rustambadr/weapon/tau/v_gauss.dx90.vtx",
	"models/zschool/rustambadr/weapon/tau/v_gauss.mdl",
	"models/zschool/rustambadr/weapon/tau/v_gauss.sw.vtx",
	"models/zschool/rustambadr/weapon/tau/v_gauss.vvd",
	"models/zschool/rustambadr/weapon/tau/w_gauss.dx80.vtx",
	"models/zschool/rustambadr/weapon/tau/w_gauss.dx90.vtx",
	"models/zschool/rustambadr/weapon/tau/w_gauss.mdl",
	"models/zschool/rustambadr/weapon/tau/w_gauss.sw.vtx",
	"models/zschool/rustambadr/weapon/tau/w_gauss.vvd",
	"materials/models/zschool/rustambadr/weapons/v_gauss/back.vmt",
	"materials/models/zschool/rustambadr/weapons/v_gauss/back.vtf",
	"materials/models/zschool/rustambadr/weapons/v_gauss/capacitor.vmt",
	"materials/models/zschool/rustambadr/weapons/v_gauss/capacitor.vtf",
	"materials/models/zschool/rustambadr/weapons/v_gauss/coils.vmt",
	"materials/models/zschool/rustambadr/weapons/v_gauss/coils.vtf",
	"materials/models/zschool/rustambadr/weapons/v_gauss/details1.vmt",
	"materials/models/zschool/rustambadr/weapons/v_gauss/details1.vtf",
	"materials/models/zschool/rustambadr/weapons/v_gauss/fan.vmt",
	"materials/models/zschool/rustambadr/weapons/v_gauss/fan.vtf",
	"materials/models/zschool/rustambadr/weapons/v_gauss/fanback.vmt",
	"materials/models/zschool/rustambadr/weapons/v_gauss/fanback.vtf",
	"materials/models/zschool/rustambadr/weapons/v_gauss/generator.vmt",
	"materials/models/zschool/rustambadr/weapons/v_gauss/generator.vtf",
	"materials/models/zschool/rustambadr/weapons/v_gauss/glowchrome.vmt",
	"materials/models/zschool/rustambadr/weapons/v_gauss/glowchrome.vtf",
	"materials/models/zschool/rustambadr/weapons/v_gauss/glowtube.vmt",
	"materials/models/zschool/rustambadr/weapons/v_gauss/glowtube.vtf",
	"materials/models/zschool/rustambadr/weapons/v_gauss/hand.vmt",
	"materials/models/zschool/rustambadr/weapons/v_gauss/hand.vtf",
	"materials/models/zschool/rustambadr/weapons/v_gauss/spindle.vmt",
	"materials/models/zschool/rustambadr/weapons/v_gauss/spindle.vtf",
	"materials/models/zschool/rustambadr/weapons/v_gauss/stock.vmt",
	"materials/models/zschool/rustambadr/weapons/v_gauss/stock.vtf",
	"materials/models/zschool/rustambadr/weapons/v_gauss/supportarm.vmt",
	"materials/models/zschool/rustambadr/weapons/v_gauss/supportarm.vtf"
};


#define SOUND_WEAPON_PULSEMACHINE "weapons/gauss/chargeloop.wav" // "zombie-plague/weapons/tau/pulsemachine.wav"
#define SOUND_WEAPON_GAUSS2 "weapons/gauss/fire1.wav" // "zombie-plague/weapons/tau/gauss2.wav"
#define SOUND_WEAPON_ELECTRO4 "zombie-plague/weapons/tau/electro4.wav"
#define SOUND_WEAPON_ELECTRO5 "zombie-plague/weapons/tau/electro5.wav"
#define SOUND_WEAPON_ELECTRO6 "zombie-plague/weapons/tau/electro6.wav"

static const char g_StaticDischargeSounds[3][] = {
	SOUND_WEAPON_ELECTRO4, SOUND_WEAPON_ELECTRO5, SOUND_WEAPON_ELECTRO6
};

int m_Weapon;
float m_fNextShootTime[MAXPLAYERS+1];
float m_flStartCharge[MAXPLAYERS+1], m_flStartCharge2[MAXPLAYERS+1];
float m_flPlayAftershock[MAXPLAYERS+1];
bool m_FireRight[MAXPLAYERS+1], m_Bullet[MAXPLAYERS+1];
int m_SprayID;

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

	// AddFileToDownloadsTable("sound/" ... SOUND_WEAPON_PULSEMACHINE);
	PrecacheSound(SOUND_WEAPON_PULSEMACHINE);
	// AddFileToDownloadsTable("sound/" ... SOUND_WEAPON_GAUSS2);
	PrecacheSound(SOUND_WEAPON_GAUSS2);
	AddFileToDownloadsTable("sound/" ... SOUND_WEAPON_ELECTRO4);
	PrecacheSound(SOUND_WEAPON_ELECTRO4);
	AddFileToDownloadsTable("sound/" ... SOUND_WEAPON_ELECTRO5);
	PrecacheSound(SOUND_WEAPON_ELECTRO5);
	AddFileToDownloadsTable("sound/" ... SOUND_WEAPON_ELECTRO6);
	PrecacheSound(SOUND_WEAPON_ELECTRO6);
	
	m_SprayID = PrecacheDecal("decals/redglowfade.vmt");
}

public void OnClientConnected(int client)
{
	m_hIdle[client] = INVALID_ENT_REFERENCE;
	m_hIdle_vm[client] = INVALID_ENT_REFERENCE;
	m_hActive[client] = INVALID_ENT_REFERENCE;
	m_hActive_vm[client] = INVALID_ENT_REFERENCE;
}

public void OnClientPutInServer(int client)
{
	m_hIdle[client] = INVALID_ENT_REFERENCE;
	m_hIdle_vm[client] = INVALID_ENT_REFERENCE;
	m_hActive[client] = INVALID_ENT_REFERENCE;
	m_hActive_vm[client] = INVALID_ENT_REFERENCE;
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
	m_Weapon = ZM_GetWeaponNameID("weapon_gauss");
}

#define MAX_GAUSS_CHARGE_TIME 3.0
#define CHARGELOOP_PITCH_START 50
#define CHARGELOOP_PITCH_END 250

void OnPrimaryAttack2(int client, int weapon, int ammo, int mode, float time)
{
	if (ammo <= 0)
	{
		if (m_flStartCharge[client] <= time && mode == 1)
		{
			OnPrimaryAttack(client, weapon, ammo, mode, time);
		}
		return;
	}
	
	if (m_flStartCharge[client] <= time - 6.0 && mode == 1)
	{
		return;
	}

	float flChargeAmount = (time - m_flStartCharge[client] ) / MAX_GAUSS_CHARGE_TIME;
	if (flChargeAmount <= 1.0)
	{
		int newPitch = CHARGELOOP_PITCH_START + RoundToFloor((CHARGELOOP_PITCH_END - CHARGELOOP_PITCH_START) * flChargeAmount);
		EmitSoundToAll(SOUND_WEAPON_PULSEMACHINE, weapon, SNDCHAN_WEAPON, _, SND_CHANGEPITCH|SND_CHANGEVOL, _, newPitch);
	}

	if (m_fNextShootTime[client] > time)
	{
		return;
	}
	
	if (mode == 0)
	{
		OnCreateEffect1(client, weapon, "Stop");
		OnCreateEffect2(client, weapon, "Start");
	
		// EmitSoundToAll(SOUND_WEAPON_PULSEMACHINE, weapon, SNDCHAN_WEAPON);
		SetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoCount", 1);
		m_flStartCharge[client] = time;
		m_flStartCharge2[client] = time;
	}
	
	m_fNextShootTime[client] = time + 0.4;
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", time + 0.35);
	
	SetEntProp(client, Prop_Send, "m_iShotsFired", GetEntProp(client, Prop_Send, "m_iShotsFired") + 1);
	UTIL_SetReserveAmmo(client, weapon, ammo - 1);
	
	m_FireRight[client] = !m_FireRight[client];
	ZM_SetWeaponAnimation(client, m_FireRight[client] ? 3:4);
}

void OnPrimaryAttack(int client, int weapon, int ammo, int mode, float time)
{
	if (mode == 0)
	{
		if (ammo <= 0)
		{
			if (ammo <= -1)
			{
				OnCreateEffect1(client, weapon, "Start");
				OnCreateEffect2(client, weapon, "Stop");
			
				UTIL_SetReserveAmmo(client, weapon, 0);
				
				m_flStartCharge[client] = 0.0;
				m_flPlayAftershock[client] = 0.0;
				SetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoCount", 0);
			}
			return;
		}
	}
	
	if (mode == 1)
	{
		if (m_flStartCharge[client] > time - 6.0)
		{
			OnCreateEffect1(client, weapon, "Start");
			OnCreateEffect2(client, weapon, "Stop");
		
			float flDamage = ((time - m_flStartCharge[client]) * 100.0);
			flDamage = GetRandomFloat(180.0, 380.0);
			
			if (flDamage > 1000.0) flDamage = 1000.0;
			else flDamage = 500 * ((time - m_flStartCharge[client]) / 4.0);
			
			float ang[3], vec[3], velocity[3];
			GetClientEyeAngles(client, ang);
			GetAngleVectors(ang, vec, NULL_VECTOR, NULL_VECTOR);
			
			GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", velocity);
			velocity[0] = velocity[0] - vec[0] * flDamage;
			velocity[1] = velocity[1] - vec[1] * flDamage;
			velocity[2] = velocity[2] - vec[2] * flDamage;
			SetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", velocity);
			
			m_fNextShootTime[client] = 0.0;
			m_flStartCharge[client] = 0.0;
		}
		else
		{
			OnCreateEffect1(client, weapon, "Start");
			OnCreateEffect2(client, weapon, "Stop");
			
			EmitSoundToAll(SOUND_WEAPON_ELECTRO4, weapon);
			EmitSoundToAll(SOUND_WEAPON_ELECTRO6, weapon, SNDCHAN_WEAPON);
			
			SetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoCount", 0);
			m_fNextShootTime[client] = time + 1.0;
		}
	}

	if (m_fNextShootTime[client] > time)
	{
		return;
	}
	
	m_Bullet[client] = false;
	m_fNextShootTime[client] = time + 0.5;
	m_flPlayAftershock[client] = time + GetRandomFloat(0.3, 0.8);
	
	SetEntProp(client, Prop_Send, "m_iShotsFired", GetEntProp(client, Prop_Send, "m_iShotsFired") + 2);
	
	UTIL_SetReserveAmmo(client, weapon, UTIL_Clamp(ammo - 2, 0, ammo));
		
	m_FireRight[client] = !m_FireRight[client];
	ZM_SetWeaponAnimation(client, m_FireRight[client] ? 5:6);
	
	EmitSoundToAll(SOUND_WEAPON_GAUSS2, weapon, SNDCHAN_WEAPON);
	
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", time + 1.0);
	
	static float velocity[3]; int flags = GetEntityFlags(client); 
	float kickback[] = {0.5, 0.15, 3.1, 1.0, 5.0, 1.0, 1.0};
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
	
	if (GetVectorLength(velocity, true) <= 0.0) { }
	else if (!(flags & FL_ONGROUND))
		for (int i = 0; i < sizeof(kickback); i++) kickback[i] *= 1.3;
	else if (flags & FL_DUCKING)
		for (int i = 0; i < sizeof(kickback); i++) kickback[i] *= 0.75;
	else for (int i = 0; i < sizeof(kickback); i++) kickback[i] *= 1.15;
	ZM_CreateWeaponKickBack(client, kickback[0], kickback[1], kickback[2], kickback[3], kickback[4], kickback[5], RoundFloat(kickback[6]));
	
	ZM_FireBullets(client, view_as<int>(CS_AliasToWeaponID("weapon_m249")), 0, GetURandomInt() & 255, _, 0.0, 0.0);
	
	SetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoCount", 0);
	
	if (GetEntProp(client, Prop_Data, "m_nWaterLevel") > 2)
	{
		SDKHooks_TakeDamage(client, 0, 0, 3.0, DMG_BULLET);
	}
}

void OnDeploy(int client, int weapon, float time)
{
	m_fNextShootTime[client] = time + 0.6;
	m_Bullet[client] = false;
	m_flStartCharge[client] = 0.0;
	m_flStartCharge2[client] = 0.0;
	m_flPlayAftershock[client] = 0.0;
	
	OnCreateEffect1(client, weapon);
	OnCreateEffect2(client, weapon);
	
	ZM_SendWeaponAnim(weapon, ACT_VM_DRAW);
	SetEntPropFloat(client, Prop_Send, "m_flNextAttack", 9999999.0);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", 9999999.0);
	SetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoCount", 0);
	SetEntProp(client, Prop_Send, "m_iShotsFired", 0);
}

void OnIdle(int client, int weapon, float time)
{
	if (GetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle") > time)
	{
		return;
	}
	
	if (m_flPlayAftershock[client] && m_flPlayAftershock[client] < time)
	{
		EmitSoundToAll(g_StaticDischargeSounds[GetRandomInt(0, sizeof(g_StaticDischargeSounds)-1)], weapon, SNDCHAN_WEAPON);
		m_flPlayAftershock[client] = 0.0;
	}
	
	ZM_SetWeaponAnimation(client, 0);
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", time + 1.0);
}

void OnCreateEffect1(int client, int weapon, const char[] input = "")
{
	if (!hasLength(input))
	{
		if (IsValidEntity(m_hIdle[client]) && m_hIdle[client] != INVALID_ENT_REFERENCE)
		{
			return;
		}
		
		ZM_CreateWeaponTracer2(client, weapon, "0", "gaus_fade_idle_v", "gaus_fade_idle", false);
	}
	else
	{
		if (IsValidEntity(m_hIdle[client]) && m_hIdle[client] != INVALID_ENT_REFERENCE)
		{
			if (input[1] == 'k')
			{
				int effect = EntRefToEntIndex(m_hIdle[client]);
				if (IsValidEntityf(effect))
				{
					TeleportEntity(effect, view_as<float>({-5000.0, -5000.0, -5000.0}), NULL_VECTOR, NULL_VECTOR);
				}
			}
		
			AcceptEntityInput(m_hIdle[client], input); 
		}
		
		if (IsValidEntity(m_hIdle_vm[client]) && m_hIdle_vm[client] != INVALID_ENT_REFERENCE)
		{
			if (input[1] == 'k')
			{
				int effect = EntRefToEntIndex(m_hIdle_vm[client]);
				if (IsValidEntityf(effect))
				{
					TeleportEntity(effect, view_as<float>({-5000.0, -5000.0, -5000.0}), NULL_VECTOR, NULL_VECTOR);
				}
			}
		
			AcceptEntityInput(m_hIdle_vm[client], input); 
		}
	}
}

void OnCreateEffect2(int client, int weapon, const char[] input = "")
{
	if (!hasLength(input))
	{
		if (IsValidEntity(m_hActive[client]) && m_hActive[client] != INVALID_ENT_REFERENCE)
		{
			return;
		}
		
		ZM_CreateWeaponTracer2(client, weapon, "0", "gaus_fade_active_v", "gaus_fade_active", true);
	}
	else
	{
		if (IsValidEntity(m_hActive[client]) && m_hActive[client] != INVALID_ENT_REFERENCE)
		{
			if (input[1] == 'k')
			{
				int effect = EntRefToEntIndex(m_hActive[client]);
				if (IsValidEntityf(effect))
				{
					TeleportEntity(effect, view_as<float>({-5000.0, -5000.0, -5000.0}), NULL_VECTOR, NULL_VECTOR);
				}
			}
		
			AcceptEntityInput(m_hActive[client], input); 
		}
		
		if (IsValidEntity(m_hActive_vm[client]) && m_hActive_vm[client] != INVALID_ENT_REFERENCE)
		{
			if (input[1] == 'k')
			{
				int effect = EntRefToEntIndex(m_hActive_vm[client]);
				if (IsValidEntityf(effect))
				{
					TeleportEntity(effect, view_as<float>({-5000.0, -5000.0, -5000.0}), NULL_VECTOR, NULL_VECTOR);
				}
			}
		
			AcceptEntityInput(m_hActive_vm[client], input); 
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
		// float angles[3];
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

public void ZM_OnWeaponBullet(int client, int weapon, const float bullet[3], int id)
{	
	if (id == m_Weapon)
	{
		if (m_Bullet[client] == false)
		{
			float time = GetGameTime();
		
			WeaponKnock(client, time);
		
			if (m_flStartCharge2[client] > time - 6.0)
			{
				float flDamage = ((time - m_flStartCharge2[client]) * 100.0);
				
				if(flDamage < 250.0) ZM_CreateWeaponTracer(client, weapon, "0", "0", "gaus_beam_low", bullet, 0.15);
				else if(flDamage < 350.0) ZM_CreateWeaponTracer(client, weapon, "0", "0", "gaus_beam_high", bullet, 0.15);
				else if(flDamage > 350.0) ZM_CreateWeaponTracer(client, weapon, "0", "0", "gaus_beam_monster", bullet, 0.15);
			}
			else ZM_CreateWeaponTracer(client, weapon, "0", "0", "gaus_beam_low", bullet, 0.15);
			
			TE_SetupWorldDecal(bullet, m_SprayID);
			TE_SendToAll();
			
			m_Bullet[client] = true;
			
			RequestFrame(Frame_WeaponBullet, GetClientUserId(client));
		}
		
		TE_SetupSparks(bullet, NULL_VECTOR, 1, 2);
		TE_SendToAll();
	}
}

public void Frame_WeaponBullet(int userid)
{
	int client = GetClientOfUserId(userid);
	
	if (client && IsClientInGame(client) && IsPlayerAlive(client) && !IsClientObserver(client))
	{
		m_flStartCharge2[client] = 0.0;
	}
}

void WeaponKnock(int client, float time)
{
	static float angles[3], pos[3], velocity[3];
	
	GetClientEyePosition(client, pos);
	GetClientEyeAngles(client, angles);

	Handle trace = TR_TraceRayFilterEx(pos, angles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPhysics);
	
	if (TR_DidHit(trace))
	{
		int entity = TR_GetEntityIndex(trace);
	
		if (IsValidEntity(entity) && Phys_IsPhysicsObject(entity) && GetEntityMoveType(entity) != MOVETYPE_NONE)
		{
			static char classname[NORMAL_LINE_LENGTH];
			GetEdictClassname(entity, classname, sizeof(classname));
			
			if (StrContains(classname, "prop_physics") > -1)
			{
				GetAngleVectors(angles, velocity, NULL_VECTOR, NULL_VECTOR);
				NormalizeVector(velocity, velocity);
				
				float speed = (Phys_GetMass(entity) <= 350.0 ? Phys_GetMass(entity) * 700.0 : Phys_GetMass(entity) * 300.0);
				
				if (m_flStartCharge2[client] > time - 6.0)
				{
					ScaleVector(velocity, 10000.0 + ((time - m_flStartCharge2[client]) * 10000.0) + speed);
				}
				else ScaleVector(velocity, 10000.0 + speed);
				
				Phys_ApplyForceCenter(entity, velocity);
				
				// PrintToChatAll("Phys_IsPhysicsObject: %s, %d, %d, %d, %d", classname, GetEntityMoveType(entity), GetEntProp(entity, Prop_Data, "m_takedamage"), GetEntProp(entity, Prop_Data, "m_iHealth"), GetEntProp(entity, Prop_Data, "m_iMaxHealth"));
			}
		}
	}
	
	delete trace;
}

public bool TraceEntityFilterPhysics(int entity, int contentsMask)
{
    return ((entity > MaxClients) && Phys_IsPhysicsObject(entity));
}

public void ZM_OnClientValidateDamage(int client, int& attacker, int& inflicter, float& damage, int& damagetype)
{
	if (IsValidClient(attacker) && IsPlayerAlive(attacker) && ZM_IsClientHuman(attacker))
	{
		int weapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
		if (weapon != -1 && GetEntProp(weapon, Prop_Data, "m_iMaxHealth") == m_Weapon)
		{
			if (IsValidClient(client) && IsPlayerAlive(client) && ZM_IsClientZombie(client))
			{
				float time = GetGameTime();
				
				if (m_flStartCharge2[attacker] > time - 6.0)
				{
					damage += ((time - m_flStartCharge2[attacker]) * 25.0) + 25;
				}
			}
		}
	}
}

public void ZM_OnWeaponDrop(int client, int weapon, int id)
{
	if (id == m_Weapon)
	{
		m_flStartCharge[client] = 0.0;
		m_flStartCharge2[client] = 0.0;
		m_flPlayAftershock[client] = 0.0;
	
		StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_PULSEMACHINE);
		SetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoCount", 0);
		
		OnCreateEffect1(client, weapon, "Kill");
		OnCreateEffect2(client, weapon, "Kill");
		
		m_hIdle[client] = INVALID_ENT_REFERENCE;
		m_hIdle_vm[client] = INVALID_ENT_REFERENCE;
		m_hActive[client] = INVALID_ENT_REFERENCE;
		m_hActive_vm[client] = INVALID_ENT_REFERENCE;
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
		m_flStartCharge[client] = 0.0;
		m_flStartCharge2[client] = 0.0;
		m_flPlayAftershock[client] = 0.0;
		
		StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_PULSEMACHINE);
		SetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoCount", 0);
		
		OnCreateEffect1(client, weapon, "Kill");
		OnCreateEffect2(client, weapon, "Kill");
		
		m_hIdle[client] = INVALID_ENT_REFERENCE;
		m_hIdle_vm[client] = INVALID_ENT_REFERENCE;
		m_hActive[client] = INVALID_ENT_REFERENCE;
		m_hActive_vm[client] = INVALID_ENT_REFERENCE;
	}
}

public Action ZM_OnWeaponRunCmd(int client, int& buttons, int LastButtons, int weapon, int id)
{
	if (id == m_Weapon)
	{
		float time = GetGameTime();
	
		if (m_flStartCharge[client] <= time - 6.0 && GetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoCount") == 1)
		{
			OnCreateEffect1(client, weapon, "Start");
			OnCreateEffect2(client, weapon, "Stop");
		
			UTIL_ScreenFade(client, 2.0, 0.5, FFADE_IN, {255,128,0,128});
			ZM_SetWeaponAnimation(client, 0);
			
			SDKHooks_TakeDamage(client, 0, 0, GetRandomFloat(50.0, 100.0), DMG_BULLET);
			
			EmitSoundToAll(SOUND_WEAPON_ELECTRO4, weapon);
			EmitSoundToAll(SOUND_WEAPON_ELECTRO6, weapon, SNDCHAN_WEAPON);
			
			SetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoCount", 0);
			m_fNextShootTime[client] = time + 1.0;
			return Plugin_Continue;
		}
		
		int ammo = UTIL_GetReserveAmmo(client, weapon);
		int mode = GetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoCount");
	
		if (buttons & IN_ATTACK2)
		{
			OnPrimaryAttack2(client, weapon, ammo, mode, time);
			buttons &= (~IN_ATTACK2);
			return Plugin_Changed;
		}
	
		if (LastButtons & IN_ATTACK2)
		{
			OnPrimaryAttack(client, weapon, ammo, mode, time);
			buttons &= (~IN_ATTACK2);
			return Plugin_Changed;
		}
	
		if (buttons & IN_ATTACK)
		{
			OnPrimaryAttack(client, weapon, ammo, mode, time);
			buttons &= (~IN_ATTACK);
			return Plugin_Changed;
		}
		
		OnIdle(client, weapon, time);
	}
	return Plugin_Continue;
}