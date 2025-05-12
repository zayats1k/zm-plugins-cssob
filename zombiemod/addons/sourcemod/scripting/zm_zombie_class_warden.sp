#include <zombiemod>
#include <zm_player_animation>
#include <zm_settings>
#include <shop_system>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name = "[ZM] Zombie Class: Warden",
	author = "0kEmo",
	version = "1.0"
};

#define CLASS_WARDEN_COOLDOWN 30.0
#define SET_INTERVAL 1

int m_Zombie;

static const char g_model[][] = {
	"models/zschool/rustambadr/normalhost_f/zombie_normalhost_f.dx80.vtx",
	"models/zschool/rustambadr/normalhost_f/zombie_normalhost_f.dx90.vtx",
	"models/zschool/rustambadr/normalhost_f/zombie_normalhost_f.mdl",
	"models/zschool/rustambadr/normalhost_f/zombie_normalhost_f.phy",
	"models/zschool/rustambadr/normalhost_f/zombie_normalhost_f.sw.vtx",
	"models/zschool/rustambadr/normalhost_f/zombie_normalhost_f.vvd",
	"models/zschool/rustambadr/normalhost_f/hand/hand_zombie_normalhost_f.dx80.vtx",
	"models/zschool/rustambadr/normalhost_f/hand/hand_zombie_normalhost_f.dx90.vtx",
	"models/zschool/rustambadr/normalhost_f/hand/hand_zombie_normalhost_f.mdl",
	"models/zschool/rustambadr/normalhost_f/hand/hand_zombie_normalhost_f.sw.vtx",
	"models/zschool/rustambadr/normalhost_f/hand/hand_zombie_normalhost_f.vvd",
	"materials/models/zschool/rustambadr/normalhost_f/hand/normalhost_f_arm.vmt",
	"materials/models/zschool/rustambadr/normalhost_f/hand/normalhost_f_body.vmt",
	"materials/models/zschool/rustambadr/normalhost_f/normalhost_f_arm.vmt",
	"materials/models/zschool/rustambadr/normalhost_f/normalhost_f_arm.vtf",
	"materials/models/zschool/rustambadr/normalhost_f/normalhost_f_arm_normal.vtf",
	"materials/models/zschool/rustambadr/normalhost_f/normalhost_f_body.vmt",
	"materials/models/zschool/rustambadr/normalhost_f/normalhost_f_body.vtf",
	"materials/models/zschool/rustambadr/normalhost_f/normalhost_f_body_normal.vtf",
	"materials/models/zschool/rustambadr/normalhost_f/normalhost_f_face.vmt",
	"materials/models/zschool/rustambadr/normalhost_f/normalhost_f_face.vtf",
	"materials/models/zschool/rustambadr/normalhost_f/normalhost_f_face_normal.vtf",
	"materials/models/zschool/rustambadr/normalhost_f/normalhost_f_hat.vmt",
	"materials/models/zschool/rustambadr/normalhost_f/normalhost_f_hat.vtf",
	"materials/models/zschool/rustambadr/normalhost_f/normalhost_f_hat_normal.vtf"
};

enum struct ServerData
{
	int flProgressBarStartTimeOffset;
	int iProgressBarDurationOffset;
	int OwnerEntityOffset;
	// int CollisionOffset;
	
	void Clear()
	{
		this.flProgressBarStartTimeOffset = -1;
		this.iProgressBarDurationOffset = -1;
		this.OwnerEntityOffset = -1;
		// this.CollisionOffset = -1;
	}
}
ServerData sServerData;

enum struct ClientData
{
	bool ZombieClass;
	bool UseSkill;
	bool PlayerCanUse;
	float Cooldown;
	float HudTimeLoad;
	float AddTime;
	float fTimeEnd;
	float fTimeStart;
	float fLastDamage;
	int Target[2];
	int ScreamEffect;
	int ScreamEntity;
	
	Handle TimerUse;
	
	void Clear()
	{
		this.ZombieClass = false;
		this.UseSkill = false;
		this.PlayerCanUse = false;
		this.Cooldown = 0.0;
		this.HudTimeLoad = 0.0;
		this.AddTime = 0.0;
		this.fTimeEnd = 0.0;
		this.fTimeStart = 0.0;
		this.fLastDamage = 0.0;
		
		if (this.TimerUse != null)
		{
			KillTimer(this.TimerUse);
			this.TimerUse = null;
		}
	}
}
ClientData sClientData[MAXPLAYERS+1];

public void OnPluginStart()
{
	LoadTranslations("zm_class.phrases");
	
	sServerData.flProgressBarStartTimeOffset = FindSendPropInfo("CCSPlayer", "m_flProgressBarStartTime");
	sServerData.iProgressBarDurationOffset = FindSendPropInfo("CCSPlayer", "m_iProgressBarDuration");
	sServerData.OwnerEntityOffset = FindSendPropInfo("CBaseEntity", "m_hOwnerEntity");
	// sServerData.CollisionOffset = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
	
	HookEvent("player_death", Hook_PlayerDeath);
}

public void OnPluginEnd()
{
	sServerData.Clear();

	UnhookEvent("player_death", Hook_PlayerDeath);
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

	AddFileToDownloadsTable("sound/zombie-plague/hero/lifedrain_cast.wav");
	PrecacheSound("zombie-plague/hero/lifedrain_cast.wav");
	AddFileToDownloadsTable("sound/zombie-plague/hero/lifedrain_loop.wav");
	PrecacheSound("zombie-plague/hero/lifedrain_loop.wav");
}

public void OnClientDisconnect(int client)
{
	if (IsValidClient(client))
	{
		int zombie = GetClientFromSerial(sClientData[client].Target[1]);
		if (zombie != 0)
		{
			StopSkill(zombie, 0.0);
			sClientData[client].Target[1] = 0;
		}
		
		StopSkill(client, 0.0);
		SetProgressBar(client, 0.0, 0, 1);
	}

	sClientData[client].Clear();
	SDKUnhook(client, SDKHook_PostThinkPost, Hook_PostThinkPost);
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
	m_Zombie = ZM_GetClassNameID("zombie_warden");
}

public Action Hook_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (IsValidClient(client))
	{
		if (ZM_IsClientZombie(client) && sClientData[client].ZombieClass)
		{
			ClearSyncHud(client, ZM_GetHudSync());
			OnClientDisconnect(client);
		}
		else
		{
			int zombie = GetClientFromSerial(sClientData[client].Target[1]);
			
			if (zombie != 0)
			{
				StopSkill(zombie, 0.0);
				sClientData[client].Target[1] = 0;
			}
		}
	}
	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3])
{
	if (IsValidClient(client) && IsPlayerAlive(client) && ZM_IsClientZombie(client) && sClientData[client].ZombieClass)
	{
		if (sClientData[client].Cooldown <= 0.0)
		{
			static int iOldButton[MAXPLAYERS+1];
			
			if (GetEntityFlags(client) & FL_ONGROUND && vel[0] == 0.0 && vel[1] == 0.0 && vel[2] == 0.0 && IsPlayerAnimation(client, false))
			{
				if (!sClientData[client].PlayerCanUse)
				{
					sClientData[client].HudTimeLoad = 0.0;
					sClientData[client].PlayerCanUse = true;
				}
			}
			else
			{
				if (sClientData[client].PlayerCanUse)
				{
					StopSkill(client, 0.0);
					sClientData[client].HudTimeLoad = 0.0;
					sClientData[client].PlayerCanUse = false;
					ClearSyncHud(client, ZM_GetHudSync());
				}
			}
			
			if (buttons & IN_RELOAD && sClientData[client].TimerUse == null)
			{
				if (sClientData[client].UseSkill == true)
				{
					StopSkill(client, 0.0);
					return Plugin_Continue;
				}
				if (sClientData[client].PlayerCanUse == false)
				{
					StopSkill(client, 0.0);
					return Plugin_Continue;
				}
				
				if (GetEntProp(client, Prop_Data, "m_nWaterLevel") > 1 || ZM_IsEndRound())
				{
					return Plugin_Continue;
				}
				
				sClientData[client].TimerUse = CreateTimer(float(SET_INTERVAL), Timer_Scream, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				
				SetProgressBar(client, GetGameTime(), SET_INTERVAL, 4);
				ClearSyncHud(client, ZM_GetHudSync());
			}
			
			if (!(buttons & IN_RELOAD) && iOldButton[client] & IN_RELOAD)
			{
				StopSkill(client, 0.0);
			}
			
			iOldButton[client] = buttons;
		}
		else if (sClientData[client].UseSkill == true)
		{
			float time = GetGameTime();
		
			if ((time - sClientData[client].fTimeStart) > 1.0 && buttons & IN_ATTACK)
			{
				StopSkill(client, 5.0);
				return Plugin_Continue;
			}
		
			if (sClientData[client].fTimeEnd < time)
			{
				StopSkill(client, 0.0);
				return Plugin_Continue;
			}
		
			int entity = GetEntitySequence(client);
			
			if (IsValidEntityf(entity))
			{
				if (sClientData[client].fLastDamage < time)
				{
					sClientData[client].fLastDamage = time + GetRandomFloat(0.5, 1.5);
					
					int health = GetClientHealth(client);
					int maxhealth = GetEntProp(client, Prop_Data, "m_iMaxHealth");
					
					if (health < maxhealth)
					{
						health += RoundToCeil(35.0 * GetClientSkill(client, 1));
						SetEntityHealth(client, UTIL_Clamp(health, 0, maxhealth));
					}
					
					int target = GetClientFromSerial(sClientData[client].Target[0]);
					if (target != 0 && IsValidClient(target))
					{
						if (!UTIL_DamageArmor(target, RoundToCeil(8.0 + GetClientSkill(client, 0))))
						{
							SDKHooks_TakeDamage(target, client, client, 8.0 + GetClientSkill(client, 0), DMG_ENERGYBEAM);
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action Timer_Scream(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	
	if (IsValidClient(client))
	{
		float angle[3], origin[3], m_TargetOrigin[3];
		
		GetClientEyePosition(client, origin);
		GetClientEyeAngles(client, angle);
		
		Handle trace = TR_TraceRayFilterEx(origin, angle, MASK_VISIBLE, RayType_Infinite, TraceEntityFilter, client);
		
		if (TR_DidHit(trace))
		{
			TR_GetEndPosition(m_TargetOrigin, trace);
			int target = TR_GetEntityIndex(trace);
			
			if (GetVectorDistance(origin, m_TargetOrigin) <= 550.0)
			{
				if (IsValidClient(target) && IsPlayerAlive(target) && ZM_IsClientHuman(target) && !IsVictimState(target)) // && GetEntityMoveType(target) != MOVETYPE_NONE)
				{
					SetPlayerSequence(target, "0");
				
					float time = GetGameTime();
				
					if (!SetPlayerSequence(client, "scream"))
					{
						delete trace;
						sClientData[client].TimerUse = null;
						return Plugin_Stop;
					}
					
					int entity = CreateEntityByName("hegrenade_projectile");
					if (entity != -1)
					{
						float ang[3];
						char buffer[34], buffer2[34];
						
						GetClientAnimationAngles(client, ang);
						
						Format(buffer, sizeof(buffer), "beam_%d", entity); 
						DispatchKeyValue(entity, "targetname", buffer);

						DispatchSpawn(entity);
						
						SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
						SetEntityRenderColor(entity, 255, 255, 255, 0);
						SetEntityMoveType(entity, MOVETYPE_FLY);
						
						TeleportEntity(entity, m_TargetOrigin, NULL_VECTOR, NULL_VECTOR);
						
						SetVariantString("!activator");
						AcceptEntityInput(entity, "SetParent", GetEntitySequence(client), entity);
						SetVariantString("sucklife");
						AcceptEntityInput(entity, "SetParentAttachment", entity, entity);
						
						SetEntProp(entity, Prop_Data, "m_nNextThinkTick", -1);
						SetEntProp(entity, Prop_Data, "m_takedamage", 0);
						SetEntPropEnt(entity, Prop_Data, "m_pParent", client); 
						SetEntPropEnt(entity, Prop_Data, "m_hThrower", client);
						SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 0.0001);
						SetEntDataEnt2(entity, sServerData.OwnerEntityOffset, client);
						// SetEntData(entity, sServerData.CollisionOffset, 5, 1, true);
						SetEntityCollisionGroup(entity, 2);
						
						int effect = CreateEntityByName("info_particle_system");
						if (effect != -1)
						{
							Format(buffer2, sizeof(buffer2), "suck_beam_%d", effect); 
							DispatchKeyValue(effect, "targetname", buffer2);
						
							DispatchKeyValueVector(effect, "origin", m_TargetOrigin);
							
							if (GetClientSkill(client, 0) > 0.1)
							{
								DispatchKeyValue(effect, "effect_name", "sz_life_drain_give_damage");
							}
							else if (GetClientSkill(client, 1) > 0.1) 
							{
								DispatchKeyValue(effect, "effect_name", "sz_life_drain_give_heal");
							}
							else DispatchKeyValue(effect, "effect_name", "sz_life_drain_give");
							
							DispatchKeyValue(effect, "start_active", "1");
							
							DispatchKeyValue(effect, "cpoint1", buffer);
							DispatchKeyValue(effect, "cpoint2", buffer2);
							
							DispatchSpawn(effect);
							ActivateEntity(effect);
							
							if (ZM_LookupAttachment(target, "forward") != 0)
							{
								SetVariantString("!activator");
								AcceptEntityInput(effect, "SetParent", target, effect);
								SetVariantString("forward");
								AcceptEntityInput(effect, "SetParentAttachment", effect, effect);
							}
							
							EmitSoundToAll("zombie-plague/hero/lifedrain_cast.wav", target);
							EmitSoundToAll("zombie-plague/hero/lifedrain_loop.wav", target);
							EmitSoundToAll("zombie-plague/hero/lifedrain_cast.wav", client);
							EmitSoundToAll("zombie-plague/hero/lifedrain_loop.wav", client);
							
							sClientData[client].ScreamEffect = EntIndexToEntRef(effect);
						}
						
						sClientData[client].ScreamEntity = EntIndexToEntRef(entity);
					}
					
					UTIL_SetClientCam(target, true);
					SetVictimState(target, 3);
					sClientData[client].Target[0] = GetClientSerial(target); // OwnerZombie
					sClientData[target].Target[1] = GetClientSerial(client); // OwnerHuman
					SetEntityMoveType(target, MOVETYPE_NONE);
					
					sClientData[client].fTimeStart = time;
					sClientData[client].fTimeEnd = time + 10.0;
					sClientData[client].PlayerCanUse = false;
					sClientData[client].UseSkill = true;
					sClientData[client].Cooldown = CLASS_WARDEN_COOLDOWN;
					sClientData[client].HudTimeLoad = 0.0;
					SetProgressBar(client, 0.0, 0, 1);
					
					delete trace;
					sClientData[client].TimerUse = null;
					return Plugin_Stop;
				}
			}
		}
		delete trace;
		
		SetProgressBar(client, GetGameTime(), SET_INTERVAL, 4);
		return Plugin_Continue;
	}
	
	sClientData[client].TimerUse = null;
	return Plugin_Stop;
}

public void OnClientBreakSkill(int client)
{
	int zombie = GetClientFromSerial(sClientData[client].Target[1]);
	
	if (zombie != 0)
	{
		StopSkill(zombie, 5.0);
		sClientData[client].Target[1] = 0;
	}
}

public Action OnAnimationDone(int client, int entity)
{
	if (IsValidClient(client) && sClientData[client].ZombieClass)
	{
		SetPlayerSequence(client, "Idle_lower");
		return Plugin_Continue;
	}
	return Plugin_Handled;
}

public void OnResetPlayerSequence(int client, bool player)
{
	if (IsValidClient(client) && sClientData[client].ZombieClass)
	{
		StopSkill(client, 0.0, false);
	}
}

public void ZM_OnClientDamaged(int client, int attacker, int inflictor, float damage, int damagetype)
{
	if (IsValidClient(client) && IsPlayerAlive(client) && ZM_IsClientZombie(client) && sClientData[client].ZombieClass)
	{
		if (sClientData[client].TimerUse != null)
		{
			SetProgressBar(client, 0.0, 0, 1);
			sClientData[client].AddTime = 0.0;
			
			KillTimer(sClientData[client].TimerUse);
			sClientData[client].TimerUse = null;
		}
	}
}

void StopSkill(int client, float addTime, bool anim = true)
{
	if (sClientData[client].TimerUse != null)
	{
		SetProgressBar(client, 0.0, 0, 1);
		sClientData[client].AddTime = 0.0;
		
		KillTimer(sClientData[client].TimerUse);
		sClientData[client].TimerUse = null;
	}

	if (sClientData[client].UseSkill == true)
	{
		if (anim == true)
		{
			SetPlayerSequence(client, "0");
		}
	
		int target = GetClientFromSerial(sClientData[client].Target[0]);
		if (target != 0)
		{
			SetEntityMoveType(target, MOVETYPE_WALK);
			
			if (IsValidClient(target))
			{
				if (IsPlayerAlive(target))
					UTIL_SetClientCam(target, false);
				else SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
			}
			
			StopSound(target, SNDCHAN_AUTO, "zombie-plague/hero/lifedrain_cast.wav");
			StopSound(target, SNDCHAN_AUTO, "zombie-plague/hero/lifedrain_loop.wav");
			CreateTimer(0.5, Timer_StopSound, GetClientUserId(target));
			
			SetVictimState(target, 0);
			sClientData[target].Target[1] = 0;
		}
		
		StopSound(client, SNDCHAN_AUTO, "zombie-plague/hero/lifedrain_cast.wav");
		StopSound(client, SNDCHAN_AUTO, "zombie-plague/hero/lifedrain_loop.wav");
		CreateTimer(0.5, Timer_StopSound, GetClientUserId(client));
		
		if (sClientData[client].ScreamEffect != 0)
		{
			int entity = EntRefToEntIndex(sClientData[client].ScreamEffect);
			if (IsValidEntityf(entity))
			{
				AcceptEntityInput(entity, "Kill");
			}
		}
		if (sClientData[client].ScreamEntity != 0)
		{
			int entity = EntRefToEntIndex(sClientData[client].ScreamEntity);
			if (IsValidEntityf(entity))
			{
				AcceptEntityInput(entity, "Kill");
			}
		}
		
		sClientData[client].Cooldown = CLASS_WARDEN_COOLDOWN + addTime;
		sClientData[client].AddTime = addTime;
		sClientData[client].HudTimeLoad = 0.0;
		sClientData[client].UseSkill = false;
		sClientData[client].Target[0] = 0;
		
		sClientData[client].ScreamEffect = 0;
		sClientData[client].ScreamEntity = 0;
	}
}

public Action Timer_StopSound(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	
	if (IsValidClient(client))
	{
		StopSound(client, SNDCHAN_AUTO, "zombie-plague/hero/lifedrain_cast.wav");
		StopSound(client, SNDCHAN_AUTO, "zombie-plague/hero/lifedrain_loop.wav");
	}
	return Plugin_Stop;
}

public void ZM_OnClientUpdated(int client, int attacker)
{
	if (IsValidClient(client))
	{
		if (ZM_IsClientZombie(client))
		{
			int zombie = GetClientFromSerial(sClientData[client].Target[1]);
			
			if (zombie != 0)
			{
				StopSkill(zombie, 0.0);
				sClientData[client].Target[1] = 0;
			}
		}
	
		if (sClientData[client].ZombieClass)
		{
			ClearSyncHud(client, ZM_GetHudSync());
			OnClientDisconnect(client);
		}
	
		if (ZM_GetClientClass(client) == m_Zombie)
		{
			sClientData[client].ZombieClass = true;
			sClientData[client].Cooldown = CLASS_WARDEN_COOLDOWN;
			
			SDKHook(client, SDKHook_PostThinkPost, Hook_PostThinkPost);
		}
	}
}

public void Hook_PostThinkPost(int client)
{
	if (IsValidClient(client) && sClientData[client].ZombieClass)
	{
		if (!IsPlayerAlive(client) || !ZM_IsClientZombie(client) || ZM_IsEndRound())
		{
			sClientData[client].UseSkill = false;
			SDKUnhook(client, SDKHook_PostThinkPost, Hook_PostThinkPost);
			return;
		}
		
		float time = GetGameTime();
		if (sClientData[client].HudTimeLoad <= time)
		{
			if (sClientData[client].TimerUse != null) {
				return;
			}
		
			if (sClientData[client].UseSkill == true)
			{
				sClientData[client].HudTimeLoad = time + 1.0;
				SetHudTextParams(-1.0, -0.20, 1.1, 	255, 255, 255, 255, 0, 1.0, 0.05, 0.5);
				PrintText(client, 1, ZM_GetHudSync(), "%T", "ZOMBIE_CLASS_WARDEN_HUD_BUTTON_STOP", client);
				return;
			}
		
			if (sClientData[client].Cooldown <= 0.0)
			{
				sClientData[client].HudTimeLoad = time + 1.0;
				
				if (GetEntProp(client, Prop_Data, "m_nWaterLevel") > 1)
				{
					return;
				}
				
				SetHudTextParams(-1.0, -0.20, 1.1, 	255, 255, 255, 255, 0, 1.0, 0.05, 0.5);
				
				if (sClientData[client].PlayerCanUse)
				{
					PrintText(client, 1, ZM_GetHudSync(), "%T", "ZOMBIE_CLASS_WARDEN_HUD_BUTTON", client);
				}
				else
				{
					PrintText(client, 1, ZM_GetHudSync(), "%T", "ZOMBIE_CLASS_WARDEN_HUD_NONE", client);
				}
				return;
			}
			
			sClientData[client].HudTimeLoad = time + 0.2;
			int r = RoundToCeil((255.0/CLASS_WARDEN_COOLDOWN) + sClientData[client].AddTime * sClientData[client].Cooldown);
			SetHudTextParams(-1.0, -0.20, 0.3, r, 255-r, 255, 255, 0, 1.0, 0.05, 0.5);
			PrintText(client, 1, ZM_GetHudSync(), "%T", "ZOMBIE_CLASS_WARDEN_HUD_COOLDOWN", client, sClientData[client].Cooldown);
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

stock void SetProgressBar(int client, float time, int interval, int size)
{
	SetEntDataFloat(client, sServerData.flProgressBarStartTimeOffset, time, true);
	SetEntData(client, sServerData.iProgressBarDurationOffset, interval, size, true);
}

public bool TraceEntityFilter(int entity, int mask, any data)
{
	return (data != entity);
}