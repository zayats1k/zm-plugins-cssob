#include <zombiemod>
#include <zm_player_animation>
#include <zm_settings>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name = "[ZM] Zombie Class: Spitter",
	author = "0kEmo",
	version = "3.1"
};

#define CLASS_SPITTER_COOLDOWN 30.0 // 30

#define SOUND_SPITTER_SPIT1 "zombie-plague/hero/spitter/spitt/spitter_spit_01.wav"
#define SOUND_SPITTER_SPIT2 "zombie-plague/hero/spitter/spitt/spitter_spit_02.wav"
#define SOUND_SPITTER_MISS "zombie-plague/hero/spitter/spitter_miss_01.wav"

static const char g_model[][] = {
	"models/zschool/rustambadr/spitter/hand/v_spitter_arms.dx80.vtx",
	"models/zschool/rustambadr/spitter/hand/v_spitter_arms.dx90.vtx",
	"models/zschool/rustambadr/spitter/hand/v_spitter_arms.mdl",
	"models/zschool/rustambadr/spitter/hand/v_spitter_arms.sw.vtx",
	"models/zschool/rustambadr/spitter/hand/v_spitter_arms.vvd",
	"models/zschool/rustambadr/spitter/spitter.dx80.vtx",
	"models/zschool/rustambadr/spitter/spitter.dx90.vtx",
	"models/zschool/rustambadr/spitter/spitter.mdl",
	"models/zschool/rustambadr/spitter/spitter.phy",
	"models/zschool/rustambadr/spitter/spitter.sw.vtx",
	"models/zschool/rustambadr/spitter/spitter.vvd",
	"materials/models/zschool/rustambadr/spitter/spitter.vmt",
	"materials/models/zschool/rustambadr/spitter/spitter_color.vtf",
	"materials/models/zschool/rustambadr/spitter/spitter_exponent.vtf",
	"materials/models/zschool/rustambadr/spitter/spitter_normal.vtf",
	"materials/models/zschool/rustambadr/spitter/spitterenvmap.vmt"
};

static const char g_WarnSounds[3][] = {
	"sound/zombie-plague/hero/spitter/warn/spitter_warn_01.wav",
	"sound/zombie-plague/hero/spitter/warn/spitter_warn_02.wav",
	"sound/zombie-plague/hero/spitter/warn/spitter_warn_03.wav"	
};

static const char g_LoopSounds[2][] = {
	"sound/zombie-plague/hero/spitter/swarm/spitter_acid_loop_01.wav",
	"sound/zombie-plague/hero/spitter/swarm/spitter_acid_loop_02.wav"
};

static const char g_FadeoutSounds[2][] = {
	"sound/zombie-plague/hero/spitter/swarm/spitter_acid_fadeout.wav",
	"sound/zombie-plague/hero/spitter/swarm/spitter_acid_fadeout2.wav"
};

int m_Zombie;
Handle m_RemoveEntity[2048];

enum struct ServerData
{
	// int CollisionOffset;
	int clrRenderOffset;
	int OwnerEntityOffset;
	int bluelaser1;
	
	void Clear()
	{
		// this.CollisionOffset = -1;
		this.OwnerEntityOffset = -1;
	}
}
ServerData sServerData;

enum struct ClientData
{
	bool ZombieClass;
	bool PlayerCanUse;
	bool Timer1;
	
	float fLastTouch;
	float PlayerAngles[3];
	float Cooldown;
	float HudTimeLoad;
	float fLastWarn;
	
	int TrieParticle;
	
	void ClearTimer()
	{
		this.ZombieClass = false;
		this.PlayerCanUse = false;
		this.Timer1 = false;
		this.fLastTouch = 0.0;
		this.PlayerAngles[0] = 0.0;
		this.PlayerAngles[1] = 0.0;
		this.PlayerAngles[2] = 0.0;
		this.Cooldown = 0.0;
		this.HudTimeLoad = 0.0;
		this.fLastWarn = 0.0;
	}
	void RemoveParticle()
	{
		if (IsValidEntityf(this.TrieParticle))
		{
			int entity = EntRefToEntIndex(this.TrieParticle);
			if (IsValidEntityf(entity))
			{
				SDKUnhook(entity, SDKHook_SetTransmit, Hook_SetTransmit);
				AcceptEntityInput(entity, "kill");
			}
		}
		
		this.TrieParticle = INVALID_ENT_REFERENCE;
	}
	void AddParticle(int client)
	{
		if (!IsValidEntityf(this.TrieParticle))
		{
			float origin[3]; GetClientAbsOrigin(client, origin);
			int entity = UTIL_CreateParticle(_, _, "spitter_mouth", origin);
			
			SetEntDataEnt2(entity, sServerData.OwnerEntityOffset, client);
			
			SetVariantString("!activator");
			AcceptEntityInput(entity, "SetParent", client, entity);
			SetVariantString("mouth");
			AcceptEntityInput(entity, "SetParentAttachment", client, entity);
			this.TrieParticle = EntIndexToEntRef(entity);
			
			UTIL_SetEdictFlagsAlways(entity);
			SDKHook(entity, SDKHook_SetTransmit, Hook_SetTransmit);
		}
	}
}
ClientData sClientData[MAXPLAYERS+1];

public void OnPluginStart()
{
	sServerData.OwnerEntityOffset = FindSendPropInfo("CBaseEntity", "m_hOwnerEntity");
	// sServerData.CollisionOffset = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
	
	LoadTranslations("zm_class.phrases");
}

public void OnPluginEnd()
{
	sServerData.Clear();
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
	m_Zombie = ZM_GetClassNameID("zombie_spitter");
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

	AddFileToDownloadsTable("sound/" ... SOUND_SPITTER_SPIT1);
	PrecacheSound(SOUND_SPITTER_SPIT1);
	AddFileToDownloadsTable("sound/" ... SOUND_SPITTER_SPIT2);
	PrecacheSound(SOUND_SPITTER_SPIT2);
	AddFileToDownloadsTable("sound/" ... SOUND_SPITTER_MISS);
	PrecacheSound(SOUND_SPITTER_MISS);
	
	for (int i = 0; i < sizeof(g_WarnSounds); i++)
	{
		AddFileToDownloadsTable(g_WarnSounds[i]);
		PrecacheSound(g_WarnSounds[i][6]);
	}
	for (int i = 0; i < sizeof(g_LoopSounds); i++)
	{
		AddFileToDownloadsTable(g_LoopSounds[i]);
		PrecacheSound(g_LoopSounds[i][6]);
	}
	for (int i = 0; i < sizeof(g_FadeoutSounds); i++)
	{
		AddFileToDownloadsTable(g_FadeoutSounds[i]);
		PrecacheSound(g_FadeoutSounds[i][6]);
	}
	
	sServerData.bluelaser1 = PrecacheModel("materials/sprites/bluelaser1.vmt", true);
	PrecacheModel("models/error.mdl", true);
}

public void OnClientDisconnect(int client)
{
	sClientData[client].RemoveParticle();
	sClientData[client].ClearTimer();
	SDKUnhook(client, SDKHook_PostThinkPost, Hook_PostThinkPost);
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3])
{
	if (IsValidClient(client) && IsPlayerAlive(client) && ZM_IsClientZombie(client)	&& sClientData[client].ZombieClass)
	{
		if (sClientData[client].Cooldown <= 0.0)
		{
			static int iOldButton[MAXPLAYERS+1];
			
			if (GetEntityFlags(client) & FL_ONGROUND && vel[0] == 0.0 && vel[1] == 0.0 && vel[2] == 0.0) // && IsPlayerAnimation(client)
			{
				if (!(buttons & IN_ATTACK2) && !sClientData[client].PlayerCanUse)
				{
					sClientData[client].Timer1 = false;
					sClientData[client].PlayerCanUse = true;
					sClientData[client].HudTimeLoad = 0.0;
				}
			}
			else
			{
				if (sClientData[client].PlayerCanUse)
				{
					sClientData[client].Timer1 = false;
					sClientData[client].PlayerCanUse = false;
					sClientData[client].HudTimeLoad = 0.0;
				}
			}
			
			if (buttons & IN_ATTACK2 && !(iOldButton[client] & IN_ATTACK2))
			{
				if (sClientData[client].Cooldown > 0.0)
				{
					return Plugin_Continue;
				}
			
				if (GetEntProp(client, Prop_Data, "m_nWaterLevel") > 1 || ZM_IsEndRound())
				{
					return Plugin_Continue;
				}
			
				if (sClientData[client].PlayerCanUse)
				{
					if (!SetPlayerSequence(client, IsPlayerAnimation(client, true) ? "spitter_spitting":"spitter_crouch_spitting_coop"))
					{
						return Plugin_Continue;
					}
					
					OnHandleAnimEvent(client, Hook_HandleAnimEvent);
					
					EmitSoundToAll(SOUND_SPITTER_SPIT1, client);
					
					float ang[3];
					GetClientAnimationAngles(client, ang);
					sClientData[client].PlayerAngles[0] = ang[0];
					sClientData[client].PlayerAngles[1] = ang[1];
					sClientData[client].PlayerAngles[2] = ang[2];
					
					sClientData[client].Cooldown = CLASS_SPITTER_COOLDOWN;
					sClientData[client].HudTimeLoad = 0.0;
					
					sClientData[client].RemoveParticle();
				}
			}
			
			iOldButton[client] = buttons;
		}
	}
	return Plugin_Continue;
}

public MRESReturn Hook_HandleAnimEvent(int pThis, Handle params)
{
	int client = GetEntDataEnt2(pThis, sServerData.OwnerEntityOffset);
	ChangeEdictState(pThis, sServerData.OwnerEntityOffset);
	
	if (IsValidClient(client) && sClientData[client].ZombieClass)
	{
		switch(DHookGetParamObjectPtrVar(params, 1, 0, ObjectValueType_Int))
		{
			case 900:
			{
				int entity = CreateEntityByName("hegrenade_projectile");
				if (entity != -1)
				{
					float ang[3], start[3], fwd[3];
					
					EmitSoundToAll(SOUND_SPITTER_SPIT2, client);
					
					GetClientAnimationAngles(client, ang);
					ZM_GetPlayerEyePosition(client, 15.0, 0.0, -10.0, start);
					
					DispatchKeyValue(entity, "Solid", "6"); 
					DispatchSpawn(entity);
					
					SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
					SetEntityRenderColor(entity, 255, 255, 255, 0);
					
					GetAngleVectors(ang, fwd, NULL_VECTOR, NULL_VECTOR);
					NormalizeVector(fwd, fwd);
					ScaleVector(fwd, 2048.0);
					TeleportEntity(entity, start, ang, fwd);
					
					SetEntPropEnt(entity, Prop_Data, "m_pParent", client); 
					SetEntPropEnt(entity, Prop_Data, "m_hThrower", client);
					SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 0.0001);
					// SetEntData(entity, sServerData.CollisionOffset, 11, 1, true);
					SetEntityCollisionGroup(entity, 11);
					
					int ent2 = UTIL_CreateParticle(_, _, "spitter_spitt", start);
					
					SetEntDataEnt2(entity, sServerData.OwnerEntityOffset, ent2);
					
					SetVariantString("!activator");
					AcceptEntityInput(ent2, "SetParent", entity, ent2);
					
					SDKHook(entity, SDKHook_StartTouchPost, OnStartTouchPost);
					
					delete m_RemoveEntity[entity];
					m_RemoveEntity[entity] = CreateTimer(10.0, Timer_RemoveEntity, EntIndexToEntRef(entity));
				}
			}
			case 901:
			{
				SetPlayerSequence(client, "0");
			}
		}
	}
	return MRES_Ignored;
}

public void OnEntityDestroyed(int entity)
{
	if (MaxClients < entity < 2048)
	{
		if (IsValidEntityf(entity))
		{
			if (m_RemoveEntity[entity] != null)
			{
				KillTimer(m_RemoveEntity[entity]);
				m_RemoveEntity[entity] = null;
			}
		}
	}
}

public Action OnStartTouchPost(int entity, int target)
{
	if (IsValidEdict(target))
	{
		static float origin[3]; static bool bSpeed[MAXPLAYERS+1];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
		int thrower = GetEntPropEnt(entity, Prop_Data, "m_hThrower");
		
		if (UTIL_IsEntityOnground2(entity) || thrower == target)
		{
			if (!bSpeed[thrower])
			{
				static float position[3], speed[3], velocity[3];
				
				GetClientEyePosition(thrower, position);
				GetEntPropVector(thrower, Prop_Data, "m_vecVelocity", velocity);
				
				GetAngleVectors(sClientData[thrower].PlayerAngles, speed, NULL_VECTOR, NULL_VECTOR);
				NormalizeVector(speed, speed);
				ScaleVector(speed, 300.0);
				AddVectors(speed, velocity, speed);
				
				TeleportEntity(entity, origin, NULL_VECTOR, speed);
			}
			else
			{
				float speed[3];
				origin[0] += GetRandomFloat(-100.0, 100.0);
				origin[1] += GetRandomFloat(-30.0, 30.0);
				GetAngleVectors(origin, speed, NULL_VECTOR, NULL_VECTOR);
				NormalizeVector(speed, speed);
				ScaleVector(speed, 100.0);
				TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, speed);
			}
			
			EmitSoundToAll(SOUND_SPITTER_MISS, entity);
			
			delete m_RemoveEntity[entity];
			m_RemoveEntity[entity] = CreateTimer(7.5, Timer_RemoveEntity, EntIndexToEntRef(entity));
			
			bSpeed[thrower] = true;
			return Plugin_Continue;
		}
		SetEntityMoveType(entity, MOVETYPE_NONE);
		
		float angle[3] = {0.0, 0.0, 0.0}, fwd[3], pos[3];
		for (int m_iSize = 0; m_iSize < 8; m_iSize++)
		{
			switch(m_iSize)
			{
				case 0: angle[1] += 45.0;
				case 1: angle[1] += 90.0;
				case 2: angle[1] += 135.0;
				case 3: angle[1] += 180.0;
				case 4: angle[1] += 225.0;
				case 5: angle[1] += 270.0;
				case 6: angle[1] += 315.0;
				case 7: angle[1] += 360.0;
			}
			GetAngleVectors(angle, fwd, NULL_VECTOR, NULL_VECTOR);
			
			pos[0] = origin[0] + fwd[0] * 65.0;
			pos[1] = origin[1] + fwd[1] * 65.0;
			pos[2] = origin[2] + fwd[2] * 65.0;
			
			if (UTIL_IsAbleToSee(origin, pos) || !IsEntityDown(pos))
			{
				continue;
			}
			
			int ent = UTIL_CreateParticle(_, _, "spitter_slime", pos);
			
			SetVariantString("!activator");
			AcceptEntityInput(ent, "SetParent", entity, ent);
			
			UTIL_RemoveEntity(ent, 7.5);
			
			int trigger = UTIL_CreateTrigger(ent, "models/error.mdl", pos, view_as<float>({-32.0, -32.0, 0.0}), view_as<float>({32.0, 32.0, 5.0}));
			SetEntDataEnt2(trigger, sServerData.OwnerEntityOffset, thrower);
			
			SDKHook(trigger, SDKHook_Touch, TouchSlime);
		}
		
		int rand = GetRandomInt(0, sizeof(g_LoopSounds)-1);
		EmitSoundToAll(g_LoopSounds[rand][6], entity);
		
		bSpeed[thrower] = false;
		
		delete m_RemoveEntity[entity];
		m_RemoveEntity[entity] = CreateTimer(7.5, Timer_RemoveEntity, EntIndexToEntRef(entity));
		SDKUnhook(entity, SDKHook_StartTouchPost, OnStartTouchPost);
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
		
		if (firstHit[2] > origin[2]-30.0)
		{
			delete trace;
			return true;
		}
	}
	delete trace;
	return false;
}

public bool TraceRayDontHitEntity(int entity, int mask, any data)
{
	return (entity != data);
}

public Action Timer_RemoveEntity(Handle timer, int ent)
{
	int entity = EntRefToEntIndex(ent);
	if (IsValidEntityf(entity))
	{
		for (int i = 0; i < sizeof(g_LoopSounds); i++) {
			StopSound(entity, SNDCHAN_AUTO, g_LoopSounds[i][6]);
		}
		
		int rand = GetRandomInt(0, sizeof(g_FadeoutSounds)-1);
		EmitSoundToAll(g_FadeoutSounds[rand][6], entity);
		
		int oEnt = GetEntDataEnt2(entity, sServerData.OwnerEntityOffset);
		ChangeEdictState(entity, sServerData.OwnerEntityOffset);
		AcceptEntityInput(oEnt, "kill");
		
		UTIL_RemoveEntity(entity, 1.0);
	}
	
	m_RemoveEntity[entity] = null;
	return Plugin_Stop;
}

public Action TouchSlime(int entity, int other)
{
	if (IsValidClient(other) && IsPlayerAlive(other) && ZM_IsClientHuman(other) && !ZM_IsEndRound())
	{
		float time = GetGameTime();
	
		if (sClientData[other].fLastTouch > time)
		{
			return Plugin_Continue;
		}
		int OwnerEntity = GetEntDataEnt2(entity, sServerData.OwnerEntityOffset);
		
		UTIL_ScreenFade(other, 0.5, 0.1, FFADE_IN, {200, 0, 0, 50});
		
		if (!UTIL_DamageArmor(other, GetRandomInt(1, 3)))
		{
			SDKHooks_TakeDamage(other, OwnerEntity, OwnerEntity, GetRandomFloat(1.0, 3.0), DMG_BULLET);
		}
		
		sClientData[other].fLastTouch = time + GetRandomFloat(0.2, 0.35);
	}
	return Plugin_Continue;
}

public void ZM_OnClientUpdated(int client, int attacker)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		if (sClientData[client].ZombieClass)
		{
			ClearSyncHud(client, ZM_GetHudSync());
			OnClientDisconnect(client);
		}
	
		if (ZM_GetClientClass(client) == m_Zombie)
		{
			sClientData[client].Cooldown = CLASS_SPITTER_COOLDOWN;
			sClientData[client].ZombieClass = true;
			
			// int rand = GetRandomInt(0, sizeof(g_WarnSounds)-1);
			// EmitSoundToAll(g_WarnSounds[rand][6], client);
			
			ZM_SetWeaponAnimation(client, 2);
			
			SDKHook(client, SDKHook_PostThinkPost, Hook_PostThinkPost);
		}
	}
}

public Action Hook_SetTransmit(int entity, int client)
{
	UTIL_SetEdictFlagsAlways(entity);
	
	int OwnerEntity = GetEntDataEnt2(entity, sServerData.OwnerEntityOffset);
	
	if (GetEntProp(client, Prop_Send, "m_iObserverMode") == 4)
	{
		if (GetEntPropEnt(client, Prop_Send, "m_hObserverTarget") == OwnerEntity)
		{
			return Plugin_Handled;
		}
	}
	
	if (GetEntProp(OwnerEntity, Prop_Send, "m_iObserverMode") == 0)
	{
		if (OwnerEntity == client)
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public void Hook_PostThinkPost(int client)
{
	if (IsValidClient(client) && sClientData[client].ZombieClass)
	{
		if (!IsPlayerAlive(client) || !ZM_IsClientZombie(client) || ZM_IsEndRound())
		{
			sClientData[client].RemoveParticle();
			SDKUnhook(client, SDKHook_PostThinkPost, Hook_PostThinkPost);
			return;
		}
		
		float time = GetGameTime();
		if (sClientData[client].HudTimeLoad <= time)
		{
			if (sClientData[client].Cooldown <= 0.0)
			{
				sClientData[client].HudTimeLoad = time + 1.0;
				
				if (GetEntProp(client, Prop_Data, "m_nWaterLevel") > 1)
				{
					sClientData[client].RemoveParticle();
					return;
				}
				
				sClientData[client].AddParticle(client);
				SetHudTextParams(-1.0, -0.20, 1.1, 	255, 255, 255, 255, 0, 1.0, 0.05, 0.5);
				
				if (sClientData[client].PlayerCanUse)
				{
					if (IsValidEntityf(sClientData[client].TrieParticle))
					{
						float vel[3]; GetEntPropVector(client, Prop_Data, "m_vecVelocity", vel);
						if (sClientData[client].Timer1 && !GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") && vel[0] == 0.0 && vel[1] == 0.0 && vel[2] == 0.0)
						{
							float origin[3]; GetClientAbsOrigin(client, origin);
							int ent = UTIL_CreateParticle(_, _, "spitter_footstep", origin);
							
							SetVariantString("!activator");
							AcceptEntityInput(ent, "SetParent", client, ent);
							
							SetVariantString("rfoot");
							AcceptEntityInput(ent, "SetParentAttachment", client, ent);
							
							if (GetClientButtons(client) & IN_DUCK)
							{
								TeleportEntity(ent, view_as<float>({6.0, -17.0, 20.0}), NULL_VECTOR, NULL_VECTOR); 
							}
							else TeleportEntity(ent, view_as<float>({15.0, -25.0, 10.0}), NULL_VECTOR, NULL_VECTOR); 
							
							UTIL_RemoveEntity(ent, 1.0);
						}
						sClientData[client].Timer1 = true;
						
						if (sClientData[client].fLastWarn <= time)
						{
							int rand = GetRandomInt(0, sizeof(g_WarnSounds)-1);
							EmitSoundToAll(g_WarnSounds[rand][6], client);
							
							sClientData[client].fLastWarn = time + GetRandomFloat(1.7, 3.5);
						}
					}
				
					PrintText(client, 1, ZM_GetHudSync(), "%T", "ZOMBIE_CLASS_SPITTER_HUD_BUTTON", client); // ShowSyncHudText(client, ZM_GetHudSync(), "%t", "ZOMBIE_CLASS_SPITTER_HUD_BUTTON");
				}
				else
				{
					PrintText(client, 1, ZM_GetHudSync(), "%T", "ZOMBIE_CLASS_SPITTER_HUD_NONE", client); // ShowSyncHudText(client, ZM_GetHudSync(), "%t", "ZOMBIE_CLASS_SPITTER_HUD_NONE");
				}
				return;
			}
			
			sClientData[client].HudTimeLoad = time + 0.2;
			int r = RoundToCeil((255.0/CLASS_SPITTER_COOLDOWN) * sClientData[client].Cooldown);
			SetHudTextParams(-1.0, -0.20, 0.3, r, 255-r, 255, 255, 0, 1.0, 0.05, 0.5);
			PrintText(client, 1, ZM_GetHudSync(), "%T", "ZOMBIE_CLASS_SPITTER_HUD_COOLDOWN", client, sClientData[client].Cooldown); // ShowSyncHudText(client, ZM_GetHudSync(), "%t", "ZOMBIE_CLASS_SPITTER_HUD_COOLDOWN", sClientData[client].Cooldown);
			
			sClientData[client].Cooldown -= 0.2;
		}
	}
}

public void HS_OnClientHudSettings(int client, int id, const char[] name)
{
	if (id != 1) return;
	if (IsValidClient(client) && sClientData[client].ZombieClass)
	{
		ClearSyncHud(client, ZM_GetHudSync());
		PrintHintText(client, "");
		
		sClientData[client].HudTimeLoad = 0.0;
	}
}