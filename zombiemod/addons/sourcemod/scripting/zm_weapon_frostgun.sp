#include <zombiemod>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name = "[ZM] Weapon Frostgun",
	author = "0kEmo",
	version = "1.0"
};

static const char g_model[][] = {
	"models/zschool/rustambadr/weapon/frostgun/v_smg_p90.dx80.vtx",
	"models/zschool/rustambadr/weapon/frostgun/v_smg_p90.dx90.vtx",
	"models/zschool/rustambadr/weapon/frostgun/v_smg_p90.mdl",
	"models/zschool/rustambadr/weapon/frostgun/v_smg_p90.sw.mdl",
	"models/zschool/rustambadr/weapon/frostgun/v_smg_p90.vvd",
	"models/zschool/rustambadr/weapon/frostgun/v_smg_p90.xbox.vtx",
	"models/zschool/rustambadr/weapon/frostgun/w_smg_p90.dx80.vtx",
	"models/zschool/rustambadr/weapon/frostgun/w_smg_p90.dx90.vtx",
	"models/zschool/rustambadr/weapon/frostgun/w_smg_p90.mdl",
	"models/zschool/rustambadr/weapon/frostgun/w_smg_p90.phy",
	"models/zschool/rustambadr/weapon/frostgun/w_smg_p90.sw.vtx",
	"models/zschool/rustambadr/weapon/frostgun/w_smg_p90.vvd",
	"models/zschool/rustambadr/weapon/frostgun/w_smg_p90.xbox.vtx",
	"materials/models/weapons/v_models/request cso/frame water rifle back d.vtf",
	"materials/models/weapons/v_models/request cso/frame water rifle back n.vtf",
	"materials/models/weapons/v_models/request cso/frame water rifle back.vmt",
	"materials/models/weapons/v_models/request cso/frame water rifle body d.vtf",
	"materials/models/weapons/v_models/request cso/frame water rifle body n.vtf",
	"materials/models/weapons/v_models/request cso/frame water rifle body.vmt",
	"materials/models/weapons/w_models/request cso/frame water rifle back.vmt",
	"materials/models/weapons/w_models/request cso/frame water rifle body.vmt"
};

#define SOUND_WEAPON_SHOOT "zombie-plague/weapons/frostgun/water-1.wav"
#define SOUND_WEAPON_DRAW "zombie-plague/weapons/frostgun/water rifle draw.wav"
#define SOUND_WEAPON_IN "zombie-plague/weapons/frostgun/water rifle in.wav"
#define SOUND_WEAPON_OUT "zombie-plague/weapons/frostgun/water rifle out.wav"
#define SOUND_WEAPON_PUMP "zombie-plague/weapons/frostgun/water rifle pump.wav"

int m_Weapon;
Handle m_ZombieIce[MAXPLAYERS+1] = { null, ... }; 
int m_iCurShot[MAXPLAYERS+1]; 
float m_fLastTouch[MAXPLAYERS+1];
float m_EntityOrigin[MAXPLAYERS+1][3];
float m_fNextShootTime[MAXPLAYERS+1];
float m_fNextReloadTime[MAXPLAYERS+1];

public void OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_hurt", Event_PlayerHurt);
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

	AddFileToDownloadsTable("sound/" ... SOUND_WEAPON_SHOOT);
	PrecacheSound(SOUND_WEAPON_SHOOT);
	AddFileToDownloadsTable("sound/" ... SOUND_WEAPON_DRAW);
	PrecacheSound(SOUND_WEAPON_DRAW);
	AddFileToDownloadsTable("sound/" ... SOUND_WEAPON_IN);
	PrecacheSound(SOUND_WEAPON_IN);
	AddFileToDownloadsTable("sound/" ... SOUND_WEAPON_OUT);
	PrecacheSound(SOUND_WEAPON_OUT);
	AddFileToDownloadsTable("sound/" ... SOUND_WEAPON_PUMP);
	PrecacheSound(SOUND_WEAPON_PUMP);
	
	PrecacheModel("models/error.mdl", true);
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
	m_Weapon = ZM_GetWeaponNameID("weapon_frostgun");
}

public void OnMapEnd()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		m_ZombieIce[i] = null;
		m_iCurShot[i] = 0;
		m_EntityOrigin[i] = NULL_VECTOR;
	}
}

public void OnClientDisconnect(int client)
{
	delete m_ZombieIce[client];
	m_iCurShot[client] = 0;
	m_fLastTouch[client] = 0.0;
	m_EntityOrigin[client] = NULL_VECTOR;
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
	
	m_fNextShootTime[client] = time + 0.08;
	
	SetEntProp(client, Prop_Send, "m_iShotsFired", GetEntProp(client, Prop_Send, "m_iShotsFired") + 1);
	SetEntProp(weapon, Prop_Send, "m_iClip1", clip - 1); 
	
	EmitSoundToAll(SOUND_WEAPON_SHOOT, weapon, SNDCHAN_WEAPON);
	ZM_SetWeaponAnimation(client, 3);
	ZM_CreateParticle(ZM_GetClientViewModel(client, true), _, _, "flash", "water_impact_v2", 0.1);
	
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", time + 0.05);
	
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
	
	ZM_FireBullets(client, view_as<int>(CS_AliasToWeaponID("weapon_p90")), 0, GetURandomInt() & 255, _, 0.01, 0.02);
	// PrintToChatAll("STATE_ATTACK(%d, %d, %d, %d, %.1f)", client, weapon, clip, mode, time);
}

void OnDeploy(int client, int weapon, float time)
{
	m_fNextShootTime[client] = time + 0.9;
	
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
	
	time += 3.5;
	m_fNextShootTime[client] = time;
	m_fNextReloadTime[client] = time - 0.5;
	
	ZM_SetWeaponAnimation(client, 1); 
	ZM_SetPlayerAnimation(client, 4);
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", time);
	SetEntProp(client, Prop_Send, "m_iShotsFired", 0);
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

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (IsValidClient(client) && m_ZombieIce[client] != null)
	{
		SetEntityRenderColor(client, 255, 255, 255, 255);
		
		m_iCurShot[client] = 0;
		m_fLastTouch[client] = 0.0;
		delete m_ZombieIce[client];
	}
	return Plugin_Continue;
}

public Action Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	
	if (IsValidClient(attacker) && IsPlayerAlive(attacker) && ZM_IsClientHuman(attacker))
	{
		int weapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
		
		if (weapon == -1)
		{
			return Plugin_Continue;
		}
	
		char classname[64];
		GetEntityClassname(weapon, classname, sizeof(classname));
		
		if (strcmp(classname, "weapon_frostgun") == 0)
		{
			if (IsValidClient(client) && IsPlayerAlive(client) && ZM_IsClientZombie(client))
			{
				if (m_iCurShot[client] >= 6)
				{
					SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 200.0 / 300.0);
					UTIL_ScreenFade(client, 2.0, 0.1, FFADE_IN, {30, 144, 255, 50});
					
					delete m_ZombieIce[client];
					m_ZombieIce[client] = CreateTimer(4.0, Timer_RemoveIce, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
				}
				
				m_iCurShot[client]++;
			}
		}
	}
	
	if (IsValidClient(client) && IsPlayerAlive(client) && ZM_IsClientZombie(client) && m_ZombieIce[client] != null)
	{
		if (UTIL_GetRenderColor(client, 3) >= 3)
		{
			SetEntityRenderColor(client, 0, 128, 255, 255);
		}
	}
	return Plugin_Continue;
}

public void ZM_OnClientUpdated(int client, int attacker)
{
	if (IsValidClient(client) && IsPlayerAlive(client) && m_ZombieIce[client] != null)
	{
		SetEntityRenderColor(client, 255, 255, 255, 255);
		delete m_ZombieIce[client];
		m_iCurShot[client] = 0;
	}
}

public Action TouchSlime(int entity, int other)
{
	if (IsValidClient(other) && IsPlayerAlive(other) && ZM_IsClientZombie(other))
	{
		float time = GetGameTime();
	
		if (m_fLastTouch[other] > time)
		{
			return Plugin_Continue;
		}
		
		if (UTIL_GetRenderColor(other, 3) >= 3)
		{
			SetEntityRenderColor(other, 0, 128, 255, 255);
		}
		
		SetEntPropFloat(other, Prop_Data, "m_flLaggedMovementValue", 200.0 / 300.0);
		UTIL_ScreenFade(other, 2.0, 0.1, FFADE_IN, {30, 144, 255, 50});
		m_iCurShot[other] = 10;
		
		delete m_ZombieIce[other];
		m_ZombieIce[other] = CreateTimer(4.0, Timer_RemoveIce, GetClientUserId(other), TIMER_FLAG_NO_MAPCHANGE);
		
		m_fLastTouch[other] = time + 1.0;
	}
	return Plugin_Continue;
}

public Action Timer_RemoveIce(Handle hTimer, int userid)
{
	int client = GetClientOfUserId(userid);
	m_ZombieIce[client] = null;
	m_iCurShot[client] = 0;
	
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
	return Plugin_Stop;
}

public void ZM_OnWeaponAnimationEvent(int client, int weapon, int sequence, float fCycle, float fPrevCycle, int id)
{
	if (id == m_Weapon)
	{
		if (sequence == 1)
		{
			if (ZM_InRangeSound(0.141509, fPrevCycle, fCycle))
				EmitSoundToAll(SOUND_WEAPON_OUT, weapon, SNDCHAN_WEAPON);
			else if (ZM_InRangeSound(0.377358, fPrevCycle, fCycle))
				EmitSoundToAll(SOUND_WEAPON_IN, weapon, SNDCHAN_WEAPON);
			else if (ZM_InRangeSound(0.613207, fPrevCycle, fCycle))
				EmitSoundToAll(SOUND_WEAPON_PUMP, weapon, SNDCHAN_WEAPON);
		}
	}
}

public void ZM_OnWeaponBullet(int client, int weapon, const float bullet[3], int id)
{	
	if (id == m_Weapon)
	{
		ZM_CreateWeaponTracer(client, weapon, "flash", "flash", "water_beam_mian", bullet, 0.15);
		
		if (m_iCurShot[client] == 1)
		{
			m_EntityOrigin[client][0] = bullet[0];
			m_EntityOrigin[client][1] = bullet[1];
			m_EntityOrigin[client][2] = bullet[2] + 6.0;
		}
		
		if (GetVectorDistance(bullet, m_EntityOrigin[client]) <= 64.0)
		{
			if (m_iCurShot[client] >= 7)
			{
				m_iCurShot[client] = 0;
				
				float angle[3] = {0.0, 0.0, 0.0}, fwd[3], pos[3];
				for (int m_iSize = 0; m_iSize < 4; m_iSize++)
				{
					switch(m_iSize)
					{
						case 0: angle[1] += 90.0;
						case 1: angle[1] += 180.0;
						case 2: angle[1] += 270.0;
						case 3: angle[1] += 360.0;
					}
					GetAngleVectors(angle, fwd, NULL_VECTOR, NULL_VECTOR);
					
					pos[0] = m_EntityOrigin[client][0] + fwd[0] * 32.0;
					pos[1] = m_EntityOrigin[client][1] + fwd[1] * 32.0;
					pos[2] = m_EntityOrigin[client][2] + fwd[2] * 32.0;
					
					if (UTIL_IsAbleToSee(m_EntityOrigin[client], pos) || !IsEntityDown(pos))
					{
						continue;
					}
					
					int ent = UTIL_CreateParticle(_, _, "water_icewall", pos);
					
					UTIL_RemoveEntity(ent, 6.5);
					
					int trigger = UTIL_CreateTrigger(ent, "models/error.mdl", pos, view_as<float>({-32.0, -32.0, 0.0}), view_as<float>({32.0, 32.0, 5.0}));
					SDKHook(trigger, SDKHook_Touch, TouchSlime);
				}
			}
		}
		else
		{
			if (m_iCurShot[client] >= 7)
			{
				m_iCurShot[client] = 0;
			}
		}
		
		m_iCurShot[client]++;
	}
}

public void ZM_OnWeaponHolster(int client, int weapon, int id)
{
	if (id == m_Weapon)
	{
		StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_SHOOT);
		StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_DRAW);
		StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_IN);
		StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_OUT);
		StopSound(weapon, SNDCHAN_WEAPON, SOUND_WEAPON_PUMP);
	
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

stock bool IsEntityDown(float origin[3])
{
	float firstHit[3];
	Handle trace = TR_TraceRayFilterEx(origin, view_as<float>({89.0, 0.0, 0.0}), MASK_SOLID, RayType_Infinite, TraceRayDontHitEntity);
	
	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(firstHit, trace);
		
		if (firstHit[2] > origin[2]-10.0) // -30.0
		{
			delete trace;
			return true;
		}
	}
	delete trace;
	return false;
}

public bool TraceRayDontHitEntity(int entity, int mask)
{
	return (entity && entity > MaxClients);
}