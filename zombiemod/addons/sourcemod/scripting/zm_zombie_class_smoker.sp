#include <zombiemod>
#include <zm_player_animation>
#include <zm_settings>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name = "[ZM] Zombie Class: Smoker",
	author = "0kEmo",
	version = "3.0"
};

#define CLASS_SMOKER_COOLDOWN 5.0

#define SOUND_SMOKER_HIT1 "zombie-plague/hero/smoker/tongue_hit_1.wav"

static const char g_model[][] = {
	"models/zschool/rustambadr/smoker/hand/v_claw_smoker_fix.dx80.vtx",
	"models/zschool/rustambadr/smoker/hand/v_claw_smoker_fix.dx90.vtx",
	"models/zschool/rustambadr/smoker/hand/v_claw_smoker_fix.mdl",
	"models/zschool/rustambadr/smoker/hand/v_claw_smoker_fix.sw.vtx",
	"models/zschool/rustambadr/smoker/hand/v_claw_smoker_fix.vvd",
	"models/zschool/rustambadr/smoker/smoker.dx80.vtx",
	"models/zschool/rustambadr/smoker/smoker.dx90.vtx",
	"models/zschool/rustambadr/smoker/smoker.mdl",
	"models/zschool/rustambadr/smoker/smoker.phy",
	"models/zschool/rustambadr/smoker/smoker.sw.vtx",
	"models/zschool/rustambadr/smoker/smoker.vvd",
	"models/zschool/rustambadr/smoker/smoker_tongue_attach.dx80.vtx",
	"models/zschool/rustambadr/smoker/smoker_tongue_attach.dx90.vtx",
	"models/zschool/rustambadr/smoker/smoker_tongue_attach.mdl",
	"models/zschool/rustambadr/smoker/smoker_tongue_attach.phy",
	"models/zschool/rustambadr/smoker/smoker_tongue_attach.sw.vtx",
	"models/zschool/rustambadr/smoker/smoker_tongue_attach.vvd",
	"materials/models/zschool/rustambadr/smoker/boomer_hair.vmt",
	"materials/models/zschool/rustambadr/smoker/smoker.vmt",
	"materials/models/zschool/rustambadr/smoker/smoker.vtf",
	"materials/models/zschool/rustambadr/smoker/smoker_normal.vtf",
	"materials/models/zschool/rustambadr/smoker/smoker_tongue.vmt",
	"materials/models/zschool/rustambadr/smoker/smoker_tongue.vtf",
	"materials/models/zschool/rustambadr/smoker/smoker_tongue_normal.vtf",
	"materials/models/zschool/rustambadr/smoker/smokerexponent.vtf",
};

static const char g_AlertSounds[3][] = {
	"sound/zombie-plague/hero/smoker/smoker_alert_03.wav",
	"sound/zombie-plague/hero/smoker/smoker_alert_01.wav",
	"sound/zombie-plague/hero/smoker/smoker_alert_02.wav"
};

static const char g_LaunchtongueSounds[3][] = {
	"sound/zombie-plague/hero/smoker/smoker_launchtongue_01.wav",
	"sound/zombie-plague/hero/smoker/smoker_launchtongue_02.wav",
	"sound/zombie-plague/hero/smoker/smoker_launchtongue_03.wav"
};

static const char g_ReeltongueinSounds[3][] = {
	"sound/zombie-plague/hero/smoker/smoker_reeltonguein_01.wav",
	"sound/zombie-plague/hero/smoker/smoker_reeltonguein_03.wav",
	"sound/zombie-plague/hero/smoker/smoker_reeltonguein_02.wav"
};

static const char g_TonguehitSounds[2][] = {
	"sound/zombie-plague/hero/smoker/smoker_tonguehit_01.wav",
	"sound/zombie-plague/hero/smoker/smoker_tonguehit_02.wav"
};

static const char g_IncapacitatedSounds[2][] = {
	"sound/zombie-plague/human/choke01.wav",
	"sound/zombie-plague/human/choke04.wav"
};

static const char g_IncapacitatedfSounds[2][] = {
	"sound/zombie-plague/human/f/choke04.wav",
	"sound/zombie-plague/human/f/choke06.wav"
};

static const char g_AttackHitSounds[6][] = {
	"sound/zombie-plague/hero/hunter/zombie_slice_1.wav",
	"sound/zombie-plague/hero/hunter/zombie_slice_2.wav",
	"sound/zombie-plague/hero/hunter/zombie_slice_3.wav",
	"sound/zombie-plague/hero/hunter/zombie_slice_4.wav",
	"sound/zombie-plague/hero/hunter/zombie_slice_5.wav",
	"sound/zombie-plague/hero/hunter/zombie_slice_6.wav"
};

int m_Zombie;

enum struct ServerData
{
	int OwnerEntityOffset;
	// int CollisionOffset;
	
	void Clear()
	{
		this.OwnerEntityOffset = -1;
		// this.CollisionOffset = -1;
	}
}
ServerData sServerData;

enum struct ClientData
{
	Handle TongueTimer;
	
	bool ZombieClass;
	bool PlayerCanUse;
	bool AttackHit;
	bool AttackHuman;
	
	int Target[2];
	
	int TongueEntity;
	int TongueEffect;
	
	float Cooldown;
	float fTimeLoad;
	float HudTimeLoad;
	float fLastWarn;
	
	void Clear()
	{
		this.ZombieClass = false;
		this.PlayerCanUse = false;
		this.AttackHit = false;
		this.AttackHuman = false;
		
		this.Cooldown = 0.0;
		
		// this.TongueEntity = 0;
		// this.TongueEffect = 0;
		this.HudTimeLoad = 0.0;
		this.fLastWarn = 0.0;
	}
}
ClientData sClientData[MAXPLAYERS+1];

public void OnPluginStart()
{
	LoadTranslations("zm_class.phrases");

	sServerData.OwnerEntityOffset = FindSendPropInfo("CBaseEntity", "m_hOwnerEntity");
	// sServerData.CollisionOffset = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
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
	m_Zombie = ZM_GetClassNameID("zombie_smoker");
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

	PrecacheModel("models/error.mdl", true);
	PrecacheModel("models/zschool/rustambadr/smoker/smoker_tongue_attach.mdl", true);
	
	AddFileToDownloadsTable("sound/" ... SOUND_SMOKER_HIT1);
	PrecacheSound(SOUND_SMOKER_HIT1);
	
	for (int i = 0; i < sizeof(g_AlertSounds); i++)
	{
		AddFileToDownloadsTable(g_AlertSounds[i]);
		PrecacheSound(g_AlertSounds[i][6]);
	}
	
	for (int i = 0; i < sizeof(g_LaunchtongueSounds); i++)
	{
		AddFileToDownloadsTable(g_LaunchtongueSounds[i]);
		PrecacheSound(g_LaunchtongueSounds[i][6]);
	}
	
	for (int i = 0; i < sizeof(g_ReeltongueinSounds); i++)
	{
		AddFileToDownloadsTable(g_ReeltongueinSounds[i]);
		PrecacheSound(g_ReeltongueinSounds[i][6]);
	}
	
	for (int i = 0; i < sizeof(g_TonguehitSounds); i++)
	{
		AddFileToDownloadsTable(g_TonguehitSounds[i]);
		PrecacheSound(g_TonguehitSounds[i][6]);
	}
	
	for (int i = 0; i < sizeof(g_IncapacitatedSounds); i++)
	{
		AddFileToDownloadsTable(g_IncapacitatedSounds[i]);
		PrecacheSound(g_IncapacitatedSounds[i][6]);
	}
	for (int i = 0; i < sizeof(g_IncapacitatedfSounds); i++)
	{
		AddFileToDownloadsTable(g_IncapacitatedfSounds[i]);
		PrecacheSound(g_IncapacitatedfSounds[i][6]);
	}
	
	for (int i = 0; i < sizeof(g_AttackHitSounds); i++)
	{
		AddFileToDownloadsTable(g_AttackHitSounds[i]);
		PrecacheSound(g_AttackHitSounds[i][6]);
	}
}

public void OnClientDisconnect(int client)
{
	sClientData[client].Clear();
	RemoveTongue(client, true);
	
	SDKUnhook(client, SDKHook_PostThinkPost, Hook_PostThinkPost);
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3])
{
	if (IsValidClient(client) && IsPlayerAlive(client) && ZM_IsClientZombie(client)	&& sClientData[client].ZombieClass)
	{
		if (sClientData[client].Cooldown <= 0.0)
		{
			static int iOldButton[MAXPLAYERS+1];
			
			if (GetEntityFlags(client) & FL_ONGROUND && vel[0] == 0.0 && vel[1] == 0.0 && vel[2] == 0.0 && IsPlayerAnimation(client, false))
			{
				if (!(buttons & IN_ATTACK2) && !sClientData[client].PlayerCanUse)
				{
					sClientData[client].HudTimeLoad = 0.0;
					sClientData[client].PlayerCanUse = true;
				}
			}
			else
			{
				if (sClientData[client].PlayerCanUse)
				{
					sClientData[client].HudTimeLoad = 0.0;
					sClientData[client].PlayerCanUse = false;
					ClearSyncHud(client, ZM_GetHudSync());
				}
			}
			
			if (buttons & IN_ATTACK2 && !(iOldButton[client] & IN_ATTACK2))
			{
				if (sClientData[client].Cooldown == RoundToFloor(-10.0))
				{
					FallTongue(client, false);
					return Plugin_Continue;
				}
			
				if (GetEntProp(client, Prop_Data, "m_nWaterLevel") > 1 || ZM_IsEndRound())
				{
					return Plugin_Continue;
				}
			
				if (sClientData[client].PlayerCanUse)
				{
					if (!SetPlayerSequence(client, "tongue_attack_grab_survivor"))
					{
						return Plugin_Continue;
					}
					
					OnHandleAnimEvent(client, Hook_HandleAnimEvent);
					
					for (int i = 0; i < sizeof(g_AlertSounds); i++)
					{
						StopSound(client, SNDCHAN_AUTO, g_AlertSounds[i][6]);
					}
					
					int entity = CreateEntityByName("hegrenade_projectile");
					if (entity != -1)
					{
						float start[3], ang[3], fwd[3]; char buffer[34];
						
						int rand = GetRandomInt(0, sizeof(g_LaunchtongueSounds)-1);
						EmitSoundToAll(g_LaunchtongueSounds[rand][6], client);
						
						GetClientEyePosition(client, start);
						GetClientAnimationAngles(client, ang);
						
						Format(buffer, sizeof(buffer), "tongue_%d", entity); 
						DispatchKeyValue(entity, "targetname", buffer);     

						DispatchSpawn(entity);
						
						SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
						SetEntityRenderColor(entity, 255, 255, 255, 0);
						SetEntityMoveType(entity, MOVETYPE_FLY);
						
						GetAngleVectors(ang, fwd, NULL_VECTOR, NULL_VECTOR);
						NormalizeVector(fwd, fwd);
						ScaleVector(fwd, 2048.0);
						TeleportEntity(entity, start, ang, fwd);
						
						SDKHook(entity, SDKHook_Touch, Hook_Touch);
						
						SetEntProp(entity, Prop_Send, "m_usSolidFlags", FSOLID_TRIGGER|FSOLID_VOLUME_CONTENTS);
						SetEntProp(entity, Prop_Data, "m_nSolidType", SOLID_BBOX);
						SetEntPropEnt(entity, Prop_Data, "m_pParent", client); 
						SetEntPropEnt(entity, Prop_Data, "m_hThrower", client);
						SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 0.5);
						SetEntDataEnt2(entity, sServerData.OwnerEntityOffset, client);
						// SetEntData(entity, sServerData.CollisionOffset, 11, 1, true);
						SetEntityCollisionGroup(entity, 11);
						
						int effect = UTIL_CreateParticle(entity, "tongue_", "smoker_tongue_v2", start);
						int trigger = UTIL_CreateTrigger(GetEntitySequence(client), "models/error.mdl", start, view_as<float>({-15.0, -15.0, -15.0}), view_as<float>({15.0, 15.0, 15.0}));
						
						SetVariantString("!activator");
						AcceptEntityInput(effect, "SetParent", GetEntitySequence(client), effect);
						SetVariantString("smoker_mouth");
						AcceptEntityInput(effect, "SetParentAttachment", effect, effect);
						
						SetEntDataEnt2(trigger, sServerData.OwnerEntityOffset, client);
						// SetEntProp(trigger, Prop_Send, "m_usSolidFlags", 8);
						
						sClientData[client].TongueEntity = EntIndexToEntRef(entity);
						sClientData[client].TongueEffect = EntIndexToEntRef(effect);
						sClientData[client].TongueTimer = CreateTimer(0.4, Timer_StopTongue, GetClientUserId(client));
						sClientData[client].Cooldown = -1.0;
						sClientData[client].HudTimeLoad = 0.0;
						
						SDKHook(trigger, SDKHook_StartTouch, Hook_StartTouch); // ...
					}
				}
			}
			
			iOldButton[client] = buttons;
		}
	}
	return Plugin_Continue;
}

public Action Timer_StopTongue(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	
	if (IsValidClient(client))
	{
		int target = GetClientFromSerial(sClientData[client].Target[0]);
		if (target == 0)
		{
			FallTongue(client, false);
		}
	}
	sClientData[client].TongueTimer = null;
	return Plugin_Stop;
}

public Action Hook_Touch(int entity, int other)
{
	if (IsValidEntityf(entity) && entity != other)
	{
		int owner = GetEntDataEnt2(entity, sServerData.OwnerEntityOffset);
		ChangeEdictState(entity, sServerData.OwnerEntityOffset);
		
		if (owner == other)
		{
			return Plugin_Continue;
		}
		
		if (other != -1 && IsValidClient(other))
		{
			Hook_StartTouch(entity, other);
			SDKUnhook(entity, SDKHook_Touch, Hook_Touch);
			return Plugin_Continue;
		}
		
		FallTongue(owner, true);
		SDKUnhook(entity, SDKHook_Touch, Hook_Touch);
	}
	return Plugin_Continue;
}

public Action Hook_StartTouch(int entity, int other)
{
	if (IsValidEntityf(entity) && entity != other)
	{
		int owner = GetEntDataEnt2(entity, sServerData.OwnerEntityOffset);
		ChangeEdictState(entity, sServerData.OwnerEntityOffset);
		
		if (owner == other)
		{
			return Plugin_Continue;
		}
		
		if (!IsValidEntityf(other) && other == EntRefToEntIndex(sClientData[owner].TongueEntity))
		{
			return Plugin_Continue;
		}
		
		if (IsValidClient(other) && IsPlayerAlive(other) && ZM_IsClientHuman(other) && !IsVictimState(other)) // && GetEntityMoveType(other) != MOVETYPE_NONE
		{
			SetPlayerSequence(other, "0");
		
			if (sClientData[owner].TongueEntity != 0)
			{
				int entity2 = EntRefToEntIndex(sClientData[owner].TongueEntity);
				if (IsValidEntityf(entity2))
				{
					int rand = GetRandomInt(0, sizeof(g_TonguehitSounds)-1);
					EmitSoundToAll(g_TonguehitSounds[rand][6], entity2);
				}
			}
			
			if (ZM_GetClassGetGender(ZM_GetClientClass(other)) || ZM_GetSkinsGender(ZM_GetClientSkin(other)))
			{
				int rand = GetRandomInt(0, sizeof(g_IncapacitatedfSounds)-1);
				EmitSoundToAll(g_IncapacitatedfSounds[rand][6], other);
			}
			else
			{
				int rand = GetRandomInt(0, sizeof(g_IncapacitatedSounds)-1);
				EmitSoundToAll(g_IncapacitatedSounds[rand][6], other);
			}
			
			RemoveTongue(owner, false);
			SetPlayerSequence(owner, "tongue_attack_drag_survivor_idle");
			
			float origin[3];
			GetClientEyePosition(owner, origin);
			
			char buffer[64];
			
			int entity2 = CreateEntityByName("prop_dynamic_ornament");
			DispatchKeyValue(entity2, "model", "models/zschool/rustambadr/smoker/smoker_tongue_attach.mdl");   
			DispatchKeyValue(entity2, "DefaultAnim", "NamVet_Idle_Tongued_Dragging_Ground");		
			
			Format(buffer, sizeof(buffer), "tongue_%d", entity2);
			DispatchKeyValue(entity2, "targetname", buffer);
			
			DispatchSpawn(entity2);
			ActivateEntity(entity2);
			
			SetVariantString("!activator");
			AcceptEntityInput(entity2, "DisableMotion", other);
			SetVariantString("!activator");
			AcceptEntityInput(entity2, "SetAttached", other);
			
			int effect = UTIL_CreateParticle(entity2, "tongue_", "smoker_tongue_v2", origin);
			
			SetVariantString("!activator");
			AcceptEntityInput(effect, "SetParent", GetEntitySequence(owner), effect);
			SetVariantString("smoker_mouth");
			AcceptEntityInput(effect, "SetParentAttachment", effect, effect);
			
			SetEntProp(other, Prop_Send, "m_bIsDefusing", 1); // STOP PLAYER
			sClientData[other].Target[1] = GetClientSerial(owner); // OwnerHuman
			SetVictimState(other, 3);
			UTIL_SetClientCam(other, true);
			
			sClientData[owner].TongueEntity = EntIndexToEntRef(entity2);
			sClientData[owner].TongueEffect = EntIndexToEntRef(effect);
			sClientData[owner].Target[0] = GetClientSerial(other); // OwnerZombie
			sClientData[owner].Cooldown = -10.0;
			sClientData[owner].AttackHit = false;
			
			SDKHook(owner, SDKHook_PostThink, Hook_PostThink);
			
			SDKUnhook(entity, SDKHook_Touch, Hook_Touch);
			SDKUnhook(entity, SDKHook_StartTouch, Hook_StartTouch);
			return Plugin_Continue;
		}
		
		FallTongue(owner, true);
		SDKUnhook(entity, SDKHook_StartTouch, Hook_StartTouch);
	}
	return Plugin_Continue;
}

public void Hook_PostThink(int client)
{
	if (IsValidClient(client) && sClientData[client].ZombieClass)
	{
		int target = GetClientFromSerial(sClientData[client].Target[0]);
		
		if (target == 0 || ZM_IsEndRound())
		{
			FallTongue(client, false);
			SDKUnhook(client, SDKHook_PostThink, Hook_PostThink);
			return;
		}
		float origin2[3], origin1[3], origin3[3];
		GetClientEyePosition(client, origin1);
		GetClientEyePosition(target, origin2); origin2[2] -= 30.0;
		GetClientEyePosition(target, origin3);
		
		if (!IsPlayerAlive(target) || !ZM_IsClientHuman(target) || UTIL_IsAbleToSee(origin1, origin2) &&  UTIL_IsAbleToSee(origin1, origin3))
		{
			FallTongue(client, false);
			SDKUnhook(client, SDKHook_PostThink, Hook_PostThink);
			return;
		}
		
		if (!IsPlayerAlive(client) || !ZM_IsClientZombie(client))
		{
			RemoveTongue(client, true);
			SDKUnhook(client, SDKHook_PostThink, Hook_PostThink);
			return;
		}
		
		float time = GetGameTime();
		if (GetVectorDistance(origin1, origin3) < 45.0)
		{
			if (!sClientData[client].AttackHit)
			{
				sClientData[client].fTimeLoad = 0.0;
				sClientData[client].fTimeLoad = time + 0.5;
				SetPlayerSequence(client, "tongue_attack_incap_survivor_idle");
				sClientData[client].AttackHit = true;
				sClientData[target].AttackHuman = true;
			}
		}
		else
		{
			float velocity[3];
		
			if (sClientData[client].AttackHit)
			{
				SetEntityMoveType(target, MOVETYPE_WALK);
				SetPlayerSequence(client, "tongue_attack_grab_survivor");
				sClientData[client].AttackHit = false;
			}
			
			if (sClientData[client].fTimeLoad <= time)
			{
				if (!UTIL_DamageArmor(target, GetRandomInt(1, 10)))
				{
					SDKHooks_TakeDamage(target, client, client, GetRandomFloat(1.0, 10.0), DMG_BULLET);
				}
				
				sClientData[client].fTimeLoad = time + GetRandomFloat(0.5, 1.5);
			}
			
			MakeVectorFromPoints(origin2, origin1, velocity);
			NormalizeVector(velocity, velocity);
			ScaleVector(velocity, 250.0);
			
			TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, velocity);
		}
	}
}

public void OnResetPlayerSequence(int client, bool player)
{
	if (player == true)
	{
		if (IsValidClient(client))
		{
			if (sClientData[client].ZombieClass)
			{
				RemoveTongue(client, true);
				sClientData[client].HudTimeLoad = 0.0;
			}
			
			if (sClientData[client].AttackHuman)
			{
				sClientData[client].AttackHuman = false;
			}
		}
	}
}

public void OnClientBreakSkill(int client)
{
	int target = GetClientFromSerial(sClientData[client].Target[1]);
	
	if (target != 0)
	{
		RemoveTongue(target, true);
		
		// FallTongue(target, false);
		SetPlayerSequence(target, "tongue_attack_grab_survivor_stop");
		sClientData[client].Target[1] = 0;
	}
}

public MRESReturn Hook_HandleAnimEvent(int pThis, Handle params)
{
	int client = GetEntDataEnt2(pThis, sServerData.OwnerEntityOffset);
	ChangeEdictState(pThis, sServerData.OwnerEntityOffset);
	
	if (IsValidClient(client) && sClientData[client].ZombieClass)
	{
		switch(DHookGetParamObjectPtrVar(params, 1, 0, ObjectValueType_Int))
		{
			case 804:
			{
				int target = GetClientFromSerial(sClientData[client].Target[0]);
				
				if (target == 0)
				{
					return MRES_Ignored;
				}
				
				float origin[3];
				GetClientEyePosition(target, origin);
				
				int rand = GetRandomInt(0, sizeof(g_AttackHitSounds)-1);
				EmitSoundToAll(g_AttackHitSounds[rand][6], target);
				
				int effect = UTIL_CreateParticle(_, _, "blood_impact_red_01", origin);
				SetVariantString("!activator");
				AcceptEntityInput(effect, "SetParent", target, effect);
				SetVariantString("forward");
				AcceptEntityInput(effect, "SetParentAttachment", target, effect);
				UTIL_RemoveEntity(effect, 0.3);
				
				if (!UTIL_DamageArmor(target, GetRandomInt(4, 10)))
				{
					SDKHooks_TakeDamage(target, client, client, GetRandomFloat(4.0, 10.0), DMG_BULLET);
				}
			}
		}
	}
	return MRES_Ignored;
}

void FallTongue(int client, bool hit)
{
	if (IsValidClient(client))
	{
		if (hit == true)
		{
			if (sClientData[client].TongueEntity != 0)
			{
				int entity = EntRefToEntIndex(sClientData[client].TongueEntity);
				if (IsValidEntityf(entity))
				{
					EmitSoundToAll(SOUND_SMOKER_HIT1, entity);
				}
			}
		}
		
		SetPlayerSequence(client, "tongue_attack_grab_survivor_stop");
		
		int rand = GetRandomInt(0, sizeof(g_ReeltongueinSounds)-1);
		EmitSoundToAll(g_ReeltongueinSounds[rand][6], client);
		
		RemoveTongue(client, true);
	}
}

void RemoveTongue(int client, bool tonguefall)
{
	if (sClientData[client].TongueEntity != 0)
	{
		int entity = EntRefToEntIndex(sClientData[client].TongueEntity);
		if (IsValidEntityf(entity))
		{
			if (tonguefall == true)
			{
				float origin[3];
				int target = GetClientFromSerial(sClientData[client].Target[0]);
				if (target != 0)
				{
					SetEntityMoveType(target, MOVETYPE_WALK);
					SetEntProp(target, Prop_Send, "m_bIsDefusing", 0);
					
					GetClientEyePosition(target, origin);
					origin[2] -= 25.0;
					
					if (IsValidClient(target))
					{
						if (IsPlayerAlive(target))
							UTIL_SetClientCam(target, false);
						else SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
					}
					
					SetVictimState(target, 0);
					sClientData[target].AttackHuman = false;
					sClientData[target].Target[1] = 0;
				}
				else GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
				
				if (IsValidClient(client))
				{
					int entity2 = CreateEntityByName("hegrenade_projectile");
					if (entity2 != -1)
					{
						char buffer[64]; Format(buffer, sizeof(buffer), "tonguefall_%d", entity2); 
						DispatchKeyValue(entity2, "targetname", buffer);     
						
						DispatchSpawn(entity2);
						
						SetEntityRenderMode(entity2, RENDER_TRANSCOLOR);
						SetEntityRenderColor(entity2, 255, 255, 255, 0);
					
						TeleportEntity(entity2, origin, NULL_VECTOR, NULL_VECTOR);
						
						SetEntPropEnt(entity2, Prop_Data, "m_pParent", client); 
						SetEntPropEnt(entity2, Prop_Data, "m_hThrower", client);
						SetEntPropFloat(entity2, Prop_Send, "m_flModelScale", 0.0001);
						// SetEntData(entity2, sServerData.CollisionOffset, 2, 1, true);
						SetEntityCollisionGroup(entity2, 2);
						
						int fall_effect = UTIL_CreateParticle(entity2, "tonguefall_", "smoker_tongue_fall", origin);
						
						int fall_entity = GetEntitySequence(client);
						SetVariantString("!activator");
						AcceptEntityInput(fall_effect, "SetParent", fall_entity?fall_entity:client, fall_effect);
						SetVariantString("smoker_mouth");
						AcceptEntityInput(fall_effect, "SetParentAttachment", fall_effect, fall_effect);
						
						UTIL_RemoveEntity(entity2, 0.3);
						UTIL_RemoveEntity(fall_effect, 0.3);
					}
				}
				
				SDKUnhook(client, SDKHook_PostThink, Hook_PostThink);
			}
			
			SetVariantString("");
			AcceptEntityInput(entity, "ClearParent");
			
			TeleportEntity(entity, view_as<float>({-5000.0, -5000.0, -5000.0}), NULL_VECTOR, NULL_VECTOR);
			
			UTIL_RemoveEntity(entity, 0.3);
		}
		
		if (sClientData[client].TongueEffect != 0)
		{
			int effect = EntRefToEntIndex(sClientData[client].TongueEffect);
			if (IsValidEntityf(effect))
			{
				SetVariantString("");
				AcceptEntityInput(effect, "ClearParent");
				
				if (IsValidEntityf(entity))
				{
					SetVariantString("!activator");
					AcceptEntityInput(effect, "SetParent", entity, effect);
				}
				
				TeleportEntity(effect, view_as<float>({-5000.0, -5000.0, -5000.0}), NULL_VECTOR, NULL_VECTOR);
				UTIL_RemoveEntity(effect, 0.3);
			}
		}
		
		sClientData[client].Cooldown = CLASS_SMOKER_COOLDOWN;
		sClientData[client].TongueEntity = 0;
		sClientData[client].TongueEffect = 0;
		sClientData[client].Target[0] = 0;
		sClientData[client].fTimeLoad = 0.0;
	}
	
	if (sClientData[client].TongueTimer != null)
	{
		KillTimer(sClientData[client].TongueTimer);
		sClientData[client].TongueTimer = null;
	}
}

public void ZM_OnClientUpdated(int client, int attacker)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		if (sClientData[client].ZombieClass)
		{
			ClearSyncHud(client, ZM_GetHudSync());
			
			sClientData[client].Clear();
			SDKUnhook(client, SDKHook_PostThinkPost, Hook_PostThinkPost);
			// OnClientDisconnect_Post(client);
		}
	
		if (ZM_GetClientClass(client) == m_Zombie)
		{
			sClientData[client].Cooldown = CLASS_SMOKER_COOLDOWN;
			sClientData[client].ZombieClass = true;
			
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
			SDKUnhook(client, SDKHook_PostThinkPost, Hook_PostThinkPost);
			return;
		}
		
		float time = GetGameTime();
		if (sClientData[client].HudTimeLoad <= time)
		{
			if (sClientData[client].Cooldown == -1.0)
			{
				// sClientData[client].HudTimeLoad = time + 1.0;
				return;
			}
		
			if (sClientData[client].Cooldown == RoundToFloor(-10.0))
			{
				sClientData[client].HudTimeLoad = time + 1.0;
				SetHudTextParams(-1.0, -0.20, 1.1, 	255, 255, 255, 255, 0, 1.0, 0.05, 0.5);
				PrintText(client, 1, ZM_GetHudSync(), "%T", "ZOMBIE_CLASS_SMOKER_HUD_BUTTON_STOP", client); // ShowSyncHudText(client, ZM_GetHudSync(), "%t", "ZOMBIE_CLASS_SMOKER_HUD_BUTTON_STOP");
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
					if (sClientData[client].fLastWarn <= time)
					{
						int rand = GetRandomInt(0, sizeof(g_AlertSounds)-1);
						EmitSoundToAll(g_AlertSounds[rand][6], client);
						
						sClientData[client].fLastWarn = time + GetRandomFloat(2.0, 3.5);
					}
				
					PrintText(client, 1, ZM_GetHudSync(), "%T", "ZOMBIE_CLASS_SMOKER_HUD_BUTTON", client); // ShowSyncHudText(client, ZM_GetHudSync(), "%t", "ZOMBIE_CLASS_SMOKER_HUD_BUTTON");
				}
				else
				{
					PrintText(client, 1, ZM_GetHudSync(), "%T", "ZOMBIE_CLASS_SMOKER_HUD_NONE", client); // ShowSyncHudText(client, ZM_GetHudSync(), "%t", "ZOMBIE_CLASS_SMOKER_HUD_NONE");
				}
				return;
			}
			
			sClientData[client].HudTimeLoad = time + 0.2;
			int r = RoundToCeil((255.0/CLASS_SMOKER_COOLDOWN) * sClientData[client].Cooldown);
			SetHudTextParams(-1.0, -0.20, 0.3, r, 255-r, 255, 255, 0, 1.0, 0.05, 0.5);
			PrintText(client, 1, ZM_GetHudSync(), "%T", "ZOMBIE_CLASS_SMOKER_HUD_COOLDOWN", client, sClientData[client].Cooldown); // ShowSyncHudText(client, ZM_GetHudSync(), "%t", "ZOMBIE_CLASS_SMOKER_HUD_COOLDOWN", sClientData[client].Cooldown);
			
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