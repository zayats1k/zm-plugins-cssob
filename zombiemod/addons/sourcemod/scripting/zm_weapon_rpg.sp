#include <zombiemod>

#pragma semicolon 1
#pragma newdecls required

#define RPG_ROCKET_RADIUS 500.0
#define RPG_ROCKET_DMG 800.0
#define RPG_ROCKET_SPEED 1500.0

#define RPG_DAMAGE_DISTANCE  500.0
#define RPG_DAMAGE_PRE_SEC  800.0

#define RPG_MISSILE "models/weapons/w_missile.mdl"
#define RPG_SOUND_ROCKET "weapons/rpg/rocket1.wav"
#define RPG_SOUND_ROCKETFIRE1 "weapons/rpg/rocketfire1.wav"
#define RPG_SOUND_EXPLODE "ambient/explosions/explode_4.wav"

#define RPG_LASER_SPRITE "sprites/redglow1.vmt"

static const char g_model[][] = {
	"models/zschool/rustambadr/weapon/rpg/v_rpg.dx80.vtx",
	"models/zschool/rustambadr/weapon/rpg/v_rpg.dx90.vtx",
	"models/zschool/rustambadr/weapon/rpg/v_rpg.mdl",
	"models/zschool/rustambadr/weapon/rpg/v_rpg.sw.vtx",
	"models/zschool/rustambadr/weapon/rpg/v_rpg.vvd"
};

static const char g_GrenadeLauncherSounds[5][] = {
	"sound/zombie-plague/human/grenadelauncher01.wav",
	"sound/zombie-plague/human/grenadelauncher02.wav",
	"sound/zombie-plague/human/grenadelauncher03.wav",
	"sound/zombie-plague/human/grenadelauncher04.wav",
	"sound/zombie-plague/human/grenadelauncher05.wav"
};

static const char g_GrenadeLauncherfSounds[6][] = {
	"sound/zombie-plague/human/f/grenadelauncher01.wav",
	"sound/zombie-plague/human/f/grenadelauncher02.wav",
	"sound/zombie-plague/human/f/grenadelauncher03.wav",
	"sound/zombie-plague/human/f/grenadelauncher04.wav",
	"sound/zombie-plague/human/f/grenadelauncher05.wav",
	"sound/zombie-plague/human/f/grenadelauncher06.wav"
};

int m_Weapon;
float m_fNextShootTime[MAXPLAYERS+1];
float m_fNextReloadTime[MAXPLAYERS+1];

int m_RpgSprite2[MAXPLAYERS+1];
int m_RpgSprite[MAXPLAYERS+1];
int m_RpgRocket[MAXPLAYERS+1];
int m_RpgEffect[MAXPLAYERS+1];

char m_VoioeSound[MAXPLAYERS+1][164];

public void OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath);
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

	PrecacheModel(RPG_MISSILE, true);
	PrecacheSound(RPG_SOUND_ROCKET, true);
	PrecacheSound(RPG_SOUND_ROCKETFIRE1, true);
	PrecacheSound(RPG_SOUND_EXPLODE, true);
	
	PrecacheModel("models/gibs/hgibs.mdl", true);
	PrecacheModel("models/gibs/hgibs_rib.mdl", true);
	PrecacheModel("models/gibs/hgibs_scapula.mdl", true);
	PrecacheModel("models/gibs/hgibs_spine.mdl", true);
	
	PrecacheSound("items/nvg_on.wav", true);
	PrecacheSound("items/nvg_off.wav", true);
	
	PrecacheModel(RPG_LASER_SPRITE, true);
	
	for (int i = 0; i < sizeof(g_GrenadeLauncherSounds); i++)
	{
		AddFileToDownloadsTable(g_GrenadeLauncherSounds[i]);
		PrecacheSound(g_GrenadeLauncherSounds[i][6]);
	}
	for (int i = 0; i < sizeof(g_GrenadeLauncherfSounds); i++)
	{
		AddFileToDownloadsTable(g_GrenadeLauncherfSounds[i]);
		PrecacheSound(g_GrenadeLauncherfSounds[i][6]);
	}
}

public void ZM_OnClientUpdated(int client, int attacker)
{
	if (IsValidClient(client) && ZM_IsClientZombie(client))
	{
		SoundClientVoice(client);
	}
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	
	SoundClientVoice(client);
	SoundClientVoice(attacker);
	
	if (!IsValidClient(attacker) || attacker == client) return Plugin_Continue;
	
	if (IsValidClient(client))
	{
		if (ZM_IsClientZombie(client))
		{
			if (GetEntProp(client, Prop_Data, "m_bitsDamageType") != DMG_SONIC)
			{
				return Plugin_Continue;
			}
			
			float origin[3]; GetClientEyePosition(client, origin);
			static float vGib[3]; float vShoot[3];
			
			for (int x = 1; x <= 4; x++)
			{
				vShoot[1] += 60.0; vGib[0] = GetRandomFloat(0.0, 360.0); vGib[1] = GetRandomFloat(-15.0, 15.0); vGib[2] = GetRandomFloat(-15.0, 15.0); 
				switch (x)
				{
					case 1:
					{
						UTIL_CreateShooter(client, "models/gibs/hgibs.mdl", origin, vShoot, vGib, 1.0, 0.05, 200.0, 1.0, 10.0);
						origin[2] -= 25.0;
					}
					case 2 : UTIL_CreateShooter(client, "models/gibs/hgibs_rib.mdl", origin, vShoot, vGib, 1.0, 0.05, 200.0, 1.0, 10.0);
					case 3 : UTIL_CreateShooter(client, "models/gibs/hgibs_scapula.mdl", origin, vShoot, vGib, 1.0, 0.05, 200.0, 1.0, 10.0);
					case 4 : UTIL_CreateShooter(client, "models/gibs/hgibs_spine.mdl", origin, vShoot, vGib, 1.0, 0.05, 200.0, 1.0, 10.0);
				}
			}
			
			int ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
			if (ragdoll != -1)
			{
				static char classname[SMALL_LINE_LENGTH];
				GetEdictClassname(ragdoll, classname, sizeof(classname));
				if (!strcmp(classname, "cs_ragdoll", false)) {
					AcceptEntityInput(ragdoll, "Kill");
				}
			}
		}
	}
	return Plugin_Continue;
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
	m_Weapon = ZM_GetWeaponNameID("weapon_rpg");
}

public void OnClientDisconnect(int client)
{
	int entity = EntRefToEntIndex(m_RpgSprite[client]);
	if (IsValidEntityf(entity))
	{
		AcceptEntityInput(entity, "Kill");
		
		int beam = EntRefToEntIndex(m_RpgSprite2[client]);
		if (IsValidEntityf(beam))
		{
			AcceptEntityInput(beam, "Kill");
		}
		
		m_RpgSprite[client] = -1;
		m_RpgSprite2[client] = -1;
	}
	
	m_RpgRocket[client] = -1;
}

void OnPrimaryAttack(int client, int weapon, int clip, float time)
{
	if (m_fNextShootTime[client] > time)
	{
		return;
	}
	
	if (clip <= 0)
	{
		m_fNextShootTime[client] = time + 0.2;
		return;
	}
	
	int rocket = EntRefToEntIndex(m_RpgRocket[client]);
	if (IsValidEntityf(rocket))
	{
		return;
	}
	
	m_fNextShootTime[client] = time + 0.8;
	SetEntProp(client, Prop_Send, "m_iShotsFired", GetEntProp(client, Prop_Send, "m_iShotsFired") + 1);
	SetEntProp(weapon, Prop_Send, "m_iClip1", clip - 1); 
	
	ZM_SendWeaponAnim(weapon, ACT_VM_PRIMARYATTACK);
	// ZM_SetWeaponAnimation(client, 2);
	// ZM_SetPlayerAnimation(client, 0); // 1 xd
	
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", time + 0.05);
	
	static float velocity[3]; int flags = GetEntityFlags(client); 
	float kickback[] = { /*upBase = */9.5, /* lateralBase = */6.45, /* upMod = */0.2, /* lateralMod = */0.05, /* upMax = */8.5, /* lateralMax = */6.5, /* directionChange = */6.0 };
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
	
	if (GetVectorLength(velocity, true) <= 0.0) { }
	else if (!(flags & FL_ONGROUND))
		for (int i = 0; i < sizeof(kickback); i++) kickback[i] *= 1.3;
	else if (flags & FL_DUCKING)
		for (int i = 0; i < sizeof(kickback); i++) kickback[i] *= 0.75;
	else for (int i = 0; i < sizeof(kickback); i++) kickback[i] *= 1.15;
	ZM_CreateWeaponKickBack(client, kickback[0], kickback[1], kickback[2], kickback[3], kickback[4], kickback[5], RoundFloat(kickback[6]));
	
	static float vPosition[3], vAngle[3], vVelocity[3], vEndVelocity[3];
	ZM_GetPlayerEyePosition(client, 30.0, 10.0, 0.0, vPosition);
	GetClientEyeAngles(client, vAngle);
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVelocity);
	
	int entity = UTIL_CreateProjectile(vPosition, vAngle, m_Weapon, RPG_MISSILE);
	
	if (entity != -1)
	{
		SetEntPropVector(entity, Prop_Send, "m_vecMins", view_as<float>({-4.0, -4.0, -4.0}));
		SetEntPropVector(entity, Prop_Send, "m_vecMaxs", view_as<float>({4.0, 4.0, 4.0}));
	
		GetAngleVectors(vAngle, vEndVelocity, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(vEndVelocity, vEndVelocity);
		ScaleVector(vEndVelocity, RPG_ROCKET_SPEED);
		AddVectors(vEndVelocity, vVelocity, vEndVelocity);
		TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vEndVelocity);
		
		SetEntProp(entity, Prop_Data, "m_iTeamNum", 0); // human - 0
		SetEntPropEnt(entity, Prop_Data, "m_pParent", client); 
		SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", client);
		SetEntPropEnt(entity, Prop_Data, "m_hThrower", client);
		SetEntPropFloat(entity, Prop_Data, "m_flGravity", 0.01); 
		// SetEntProp(entity, Prop_Send, "m_CollisionGroup", 11);
		// SetEntProp(entity, Prop_Send, "m_usSolidFlags", 8);
		
		SDKHook(entity, SDKHook_Touch, Hook_GrenadeTouch);
		
		RequestFrame(Frame_RpgEffect, EntIndexToEntRef(entity));
		
		UTIL_ScreenFade(client, 0.1, 0.0, FFADE_IN, {255, 225, 205, 64});
		
		if (IsValidEntityf(EntRefToEntIndex(m_RpgSprite[client])))
		{
			m_RpgRocket[client] = EntIndexToEntRef(entity);
		}
		
		EmitSoundToAll(RPG_SOUND_ROCKET, entity);
		EmitSoundToAll(RPG_SOUND_ROCKETFIRE1, client);
	}
}

void OnSecondaryAttack(int client, int clip, int ammo, float time)
{
	if (clip <= 0)
	{
		if (ammo <= 0)
		{
			return;
		}
	}

	if (m_fNextShootTime[client] > time)
	{
		return;
	}
	
	m_fNextShootTime[client] = time + 0.8;
	
	int entity = EntRefToEntIndex(m_RpgSprite[client]);
	
	if (IsValidEntityf(entity))
	{
		AcceptEntityInput(entity, "Kill");
		
		int beam = EntRefToEntIndex(m_RpgSprite2[client]);
		if (IsValidEntityf(beam))
		{
			AcceptEntityInput(beam, "Kill");
		}
		
		m_RpgSprite[client] = -1;
		m_RpgSprite2[client] = -1;
		
		EmitSoundToAll("items/nvg_off.wav", client);
	}
	else
	{
		int ent = CreateEntityByName("env_sprite");
		
		EmitSoundToAll("items/nvg_on.wav", client);
		
		if (ent != -1)
		{
			SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
			
			SetEntityModel(ent, RPG_LASER_SPRITE);
			DispatchKeyValue(ent, "rendercolor", "255 255 255");
			DispatchKeyValue(ent, "rendermode", "3");
			DispatchKeyValue(ent, "renderamt", "255"); 
			DispatchKeyValue(ent, "framerate", "20.0"); 
			DispatchKeyValue(ent, "scale", "0.1");
			
			DispatchSpawn(ent);
			
			AcceptEntityInput(ent, "ShowSprite");
			
			m_RpgSprite[client] = EntIndexToEntRef(ent);
		}
		
		int view = ZM_GetClientViewModel(client, false);
		if (view == -1) {    
			return;
		}
		
		int sprite = CreateEntityByName("env_sprite");
		
		if (sprite != -1)
		{
			SetEntPropEnt(sprite, Prop_Send, "m_hOwnerEntity", client);
			
			SetEntityModel(sprite, RPG_LASER_SPRITE);
			DispatchKeyValue(sprite, "rendercolor", "255 255 255");
			DispatchKeyValue(sprite, "rendermode", "3");
			DispatchKeyValue(sprite, "renderamt", "255"); 
			DispatchKeyValue(sprite, "framerate", "20.0"); 
			DispatchKeyValue(sprite, "scale", "0.4");
			
			DispatchSpawn(sprite);
			
			AcceptEntityInput(sprite, "ShowSprite");
			
			SetVariantString("!activator");
			AcceptEntityInput(sprite, "SetParent", view, sprite, 0);
			SetVariantString("laser"); // "forward"  // laser
			AcceptEntityInput(sprite, "SetParentAttachment", sprite, sprite, 0);
			
			SetEdictFlags(sprite, GetEdictFlags(sprite) & ~(FL_EDICT_ALWAYS|FL_EDICT_DONTSEND|FL_EDICT_PVSCHECK));
			SDKHook(sprite, SDKHook_SetTransmit, TracerClientTransmit);
			
			m_RpgSprite2[client] = EntIndexToEntRef(sprite);
		}
	}
}

////////////////////////////////////////////////////////////
public void OnGameFrame()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i) || !IsPlayerAlive(i) || !ZM_IsClientHuman(i))
		{
			continue;
		}
		
		int entity = EntRefToEntIndex(m_RpgSprite[i]);
		
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
				
				int rocket = EntRefToEntIndex(m_RpgRocket[i]);
				if (IsValidEntityf(rocket))
				{
					float entPosition[3], entAngle[3], vecangle[3];
					GetEntPropVector(rocket, Prop_Data, "m_vecAbsOrigin", entPosition);
					GetEntPropVector(rocket, Prop_Data, "m_angRotation", entAngle);
				
					MakeVectorFromPoints(entPosition, position, vecangle);
					NormalizeVector(vecangle, vecangle);
					GetVectorAngles(vecangle, entAngle);
					ScaleVector(vecangle, RPG_ROCKET_SPEED - 150.0);
					
					TeleportEntity(rocket, NULL_VECTOR, entAngle, vecangle);
				}
			}
			
			delete trace;
		}
	}
}

public bool TraceEntityFilter(int entity, int mask, any data)
{
	if (entity != data && GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") != data)
		return true;
	return false;
}

///////////////////////////////////////////////////////////////
public void Frame_RpgEffect(int entref)
{
	if (IsValidEntityf(entref))
	{
		int entity = EntRefToEntIndex(entref);
		
		if (IsValidEntityf(entity))
		{
			float vPosition[3];
			GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPosition);
		
			int effect = UTIL_CreateParticle(_, "rpg_effect_", "rpg_trail", vPosition);
			// UTIL_RemoveEntity(effect, 30.0);
			
			int thrower = GetEntPropEnt(entity, Prop_Data, "m_hThrower");
			
			if (IsValidClient(thrower))
			{
				m_RpgEffect[thrower] = EntIndexToEntRef(effect);
			}
			
			SetVariantString("!activator");
			AcceptEntityInput(effect, "SetParent", entity, effect);
			SetVariantString("0");
			AcceptEntityInput(effect, "SetParentAttachment", effect, effect);
		}
	}
}

void OnDeploy(int client, int weapon, float time)
{
	m_fNextShootTime[client] = time + 1.2;
	
	ZM_SendWeaponAnim(weapon, ACT_VM_DRAW);
	// ZM_SetWeaponAnimation(client, 1);
	// ZM_SetPlayerAnimation(client, 0); // 1 xd
	
	OnClientDisconnect(client);
	
	SetEntPropFloat(client, Prop_Send, "m_flNextAttack", 9999999.0);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", 9999999.0);
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", time + 1.2);
	SetEntProp(client, Prop_Send, "m_iShotsFired", 0);
}

void OnReloadFinish(int client, int weapon, int clip, int ammo)
{
	int amount = UTIL_Clamp(ZM_GetWeaponClip(m_Weapon) - clip, 0, ammo);

	int entity = EntRefToEntIndex(m_RpgSprite[client]);
	if (IsValidEntityf(entity))
	{
		AcceptEntityInput(entity, "ShowSprite");
		
		int beam = EntRefToEntIndex(m_RpgSprite2[client]);
		if (IsValidEntityf(beam))
		{
			AcceptEntityInput(beam, "ShowSprite");
		}
	}

	m_fNextReloadTime[client] = 0.0;
	SetEntProp(weapon, Prop_Send, "m_iClip1", clip + amount);
	UTIL_SetReserveAmmo(client, weapon, ammo - amount);
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
	
	if (clip <= 0)
	{
		if (ammo <= 0)
		{
			if (GetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle") > time)
			{
				return;
			}
			
			int rocket = EntRefToEntIndex(m_RpgRocket[client]);
			if (IsValidEntityf(rocket))
			{
				return;
			}
			
			OnClientDisconnect(client);
			
			ZM_SetWeaponAnimation(client, 4);
			SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", time + 9999999.0);
		}
	}
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
	
	int rocket = EntRefToEntIndex(m_RpgRocket[client]);
	if (IsValidEntityf(rocket))
	{
		return;
	}
	
	int entity = EntRefToEntIndex(m_RpgSprite[client]);
	if (IsValidEntityf(entity))
	{
		AcceptEntityInput(entity, "HideSprite");
		
		int beam = EntRefToEntIndex(m_RpgSprite2[client]);
		if (IsValidEntityf(beam))
		{
			AcceptEntityInput(beam, "HideSprite");
		}
	}
	
	time += 2.0;
	m_fNextShootTime[client] = time;
	m_fNextReloadTime[client] = time - 0.5;
	
	ZM_SendWeaponAnim(weapon, ACT_VM_RELOAD);
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", time);
	SetEntProp(client, Prop_Send, "m_iShotsFired", 0);
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
		
		StopSound(entity, SNDCHAN_AUTO, RPG_SOUND_ROCKET);
		
		static float m_EntityOrigin[3];
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", m_EntityOrigin);
		EmitSoundToAll(RPG_SOUND_EXPLODE, entity);
		// UTIL_CreatePhysExplosion(m_EntityOrigin, RPG_DAMAGE_DISTANCE, RPG_DAMAGE_DISTANCE);
		UTIL_ScreenShake(m_EntityOrigin, 70.0, 0.1, 0.25, 900.0, 0, true);
		
		int effect = UTIL_CreateParticle(-2, "rpg_explode_", "rpg_explode", m_EntityOrigin, true);
		UTIL_RemoveEntity(effect, 0.2);
		
		int effect2 = EntRefToEntIndex(m_RpgEffect[thrower]);
		if (IsValidEntityf(effect2))
		{
			AcceptEntityInput(effect2, "Kill");
		}
		
		float m_PlayerOrigin[3];
		m_RpgRocket[thrower] = -1;
		m_RpgEffect[thrower] = -1;
		
		float flDist = 0.0, flPercent = 0.0;
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && IsPlayerAlive(i) && ZM_IsClientZombie(i))
			{
				GetClientEyePosition(i, m_PlayerOrigin);
				
				flDist = GetVectorDistance(m_EntityOrigin, m_PlayerOrigin);
				if (flDist > RPG_DAMAGE_DISTANCE)
				{
					continue;
				}
				
				flPercent = 1.0 - flDist/RPG_DAMAGE_DISTANCE;
				if (flPercent < 0.1) {
					flPercent = 0.1;
				}
				
				TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, view_as<float>({0.0, 0.0, 0.0}));
				ZM_TakeDamage(i, thrower, thrower, flPercent*RPG_DAMAGE_PRE_SEC, DMG_SONIC);
			}
		}
		
		// UTIL_CreateExplosion(vPosition, CS_TEAM_CT, 4|64|512, _, RPG_ROCKET_DMG, RPG_ROCKET_RADIUS, thrower);
		
		AcceptEntityInput(entity, "Kill");
		SDKUnhook(entity, SDKHook_Touch, Hook_GrenadeTouch);
	}
	return Plugin_Continue;
}

public void ZM_OnWeaponCreated(int client, int weapon, int id)
{
	if (id == m_Weapon)
	{
		SoundClientVoice(client);
	
		if (IsValidClient(client))
		{
			if (ZM_GetClassGetGender(ZM_GetClientClass(client)) || ZM_GetSkinsGender(ZM_GetClientSkin(client)))
			{
				int rand = GetRandomInt(0, sizeof(g_GrenadeLauncherfSounds)-1);
				EmitSoundToAll(g_GrenadeLauncherfSounds[rand][6], client);
				strcopy(m_VoioeSound[client], 164, g_GrenadeLauncherfSounds[rand][6]);
			}
			else
			{
				int rand = GetRandomInt(0, sizeof(g_GrenadeLauncherSounds)-1);
				EmitSoundToAll(g_GrenadeLauncherSounds[rand][6], client);
				strcopy(m_VoioeSound[client], 164, g_GrenadeLauncherSounds[rand][6]);
			}
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

public void ZM_OnWeaponHolster(int client, int weapon, int id)
{
	if (id == m_Weapon)
	{
		m_fNextReloadTime[client] = 0.0;
		
		OnClientDisconnect(client);
	}
}

public void ZM_OnWeaponDrop(int client, int weapon, int id)
{
	if (id == m_Weapon)
	{
		m_fNextReloadTime[client] = 0.0;
		
		OnClientDisconnect(client);
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
			OnReloadFinish(client, weapon, clip, ammo);
		}
		
		if (buttons & IN_ATTACK)
		{
			OnPrimaryAttack(client, weapon, clip, time);
			buttons &= (~IN_ATTACK);
			return Plugin_Changed;
		}
		
		if (buttons & IN_ATTACK2 && !(LastButtons & IN_ATTACK2))
		{
			OnSecondaryAttack(client, clip, ammo, time);
			buttons &= (~IN_ATTACK2);
			return Plugin_Changed;
		}
		
		OnIdle(client, weapon, clip, ammo, time);
	}
	return Plugin_Continue;
}

void SoundClientVoice(int client)
{
	if (IsValidClient(client))
	{
		if (m_VoioeSound[client][0])
		{
			StopSound(client, SNDCHAN_AUTO, m_VoioeSound[client]);
		}
		
		m_VoioeSound[client] = NULL_STRING;
	}
}