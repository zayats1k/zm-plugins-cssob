#include <zombiemod>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name = "[ZM] Player Animation",
	author = "0kEmo",
	version = "1.5"
};

#define DEBUG_MODE 0
#if DEBUG_MODE == 1
stock void Message(const char[] msg) {
	PrintToServer("%s", msg);
	PrintToChatAll("\x07FFFF00%s", msg);
}
#define DebugMessage(%1) Message(%1);
#else
#define DebugMessage(%1)
#endif

#define SOUND_BUTTON_BELL1 "buttons/bell1.wav"

GlobalForward hOnClientBreakSkill;
GlobalForward hOnPlayerSequence;
GlobalForward hOnPlayerSequencePre;
GlobalForward hOnResetPlayerSequencePre;
GlobalForward hOnResetPlayerSequence;
GlobalForward hOnAnimationDone;

int m_HandleAnimEventOffset = -1;

int m_hOwnerEntity;
int m_CollisionGroup;
int m_ZombieSmoker;

bool m_RoundEnd;

bool m_PlayerDock[MAXPLAYERS+1];
bool m_PlayerCanUse[MAXPLAYERS+1];
int m_AminEntity[MAXPLAYERS+1];
// int m_WeaponEntity[MAXPLAYERS+1];
float m_PlayerOrigin[MAXPLAYERS+1][3];
float m_PlayerAngles[MAXPLAYERS+1][3];

Handle m_SyncHud[2];
int m_iButtonActorDisable[MAXPLAYERS+1];
int m_iStateActorDisable[MAXPLAYERS+1];
int m_iMaxState[MAXPLAYERS+1];
float m_fLastPrint[MAXPLAYERS+1];
float m_fTimeResetActorDisable[MAXPLAYERS+1];
float m_fLastPrintMessage[MAXPLAYERS+1];
bool m_bActorDisable[MAXPLAYERS+1];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	hOnPlayerSequence = new GlobalForward("OnPlayerSequence", ET_Ignore, Param_Cell, Param_Cell);
	hOnPlayerSequencePre = new GlobalForward("OnPlayerSequencePre", ET_Ignore, Param_Cell, Param_Cell, Param_String);
	
	hOnResetPlayerSequencePre = new GlobalForward("OnResetPlayerSequencePre", ET_Ignore, Param_Cell, Param_Cell);
	hOnResetPlayerSequence = new GlobalForward("OnResetPlayerSequence", ET_Ignore, Param_Cell, Param_Cell);
	hOnAnimationDone = new GlobalForward("OnAnimationDone", ET_Hook, Param_Cell, Param_Cell);
	
	hOnClientBreakSkill = new GlobalForward("OnClientBreakSkill", ET_Ignore, Param_Cell, Param_Cell);
	
	CreateNative("SetVictimState", Native_SetVictimState);
	CreateNative("IsVictimState", Native_IsVictimState);
	
	CreateNative("GetHandleAnimEvent", Native_GetHandleAnimEvent);
	CreateNative("IsPlayerAnimation", Native_IsPlayerAnimation);
	CreateNative("GetEntitySequence", Native_GetEntitySequence);
	CreateNative("SetPlayerSequence", Native_SetPlayerSequence);
	CreateNative("GetClientAnimationAngles", Native_GetClientAnimationAngles);
	CreateNative("IsClientPlayerNone", Native_IsClientPlayerNone);
	
	RegPluginLibrary("zm_player_animation");
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("zm_player_animation.phrases");

	m_hOwnerEntity = FindSendPropInfo("CBaseEntity", "m_hOwnerEntity");
	m_CollisionGroup = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
	
	m_SyncHud[0] = CreateHudSynchronizer();
	m_SyncHud[1] = CreateHudSynchronizer();
	
	RegAdminCmd("sm_anim", Command_SetAnim, ADMFLAG_ROOT);
	RegAdminCmd("sm_anim_buttons", Command_SetAnimButtons, ADMFLAG_ROOT);
	
	HookConVarChange(FindConVar("mp_restartgame"), Hook_RestartGame);
	
	HookEvent("player_team", Hook_PlayerTeam);
	HookEvent("player_death", Hook_PlayerDeath, EventHookMode_Pre);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Hook_RoundEnd, EventHookMode_Pre);
	
	Handle hConf = LoadGameConfigFile("plugin.zombiemod");
	
	if (hConf == null)
	{
		SetFailState("plugin.zombiemod");
	}
	
	int offset = GameConfGetOffset(hConf, "HandleAnimEvent");
	if (offset == -1) LogError("[GameData] Failed to load SDK call \"HandleAnimEvent\". Update signature in \"plugin.zombiemod.games\"");
	m_HandleAnimEventOffset = offset;
	
	delete hConf;
}

public void OnPluginEnd()
{
	StopPlayerSequences();
	
	UnhookEvent("player_team", Hook_PlayerTeam);
	UnhookEvent("player_death", Hook_PlayerDeath, EventHookMode_Pre);
	UnhookEvent("round_start", Event_RoundStart);
	UnhookEvent("round_end", Hook_RoundEnd, EventHookMode_Pre);
}

public void OnMapStart()
{
	PrecacheSound(SOUND_BUTTON_BELL1, true);
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
	m_ZombieSmoker = ZM_GetClassNameID("zombie_smoker");
}

public void OnClientPutInServer(int client)
{
	// m_WeaponEntity[client] = INVALID_ENT_REFERENCE;
	if (IsValidClient(client))
	{
		ResetPlayerSequence(client, false);
	}
}

public void OnClientDisconnect(int client)
{
	if (IsValidClient(client))
	{
		ResetPlayerSequence(client, false);
	}
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3])
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		OnRandomButtonRunCmd(client, buttons);
	
		if (GetEntityFlags(client) & FL_ONGROUND && vel[0] == 0.0 && vel[1] == 0.0 && vel[2] == 0.0) // && IsPlayerAnimation(client)
		{
			if (!m_PlayerCanUse[client])
			{
				m_PlayerCanUse[client] = true;
			}
		}
		else
		{
			if (m_PlayerCanUse[client])
			{
				m_PlayerCanUse[client] = false;
			}
		}
	
		if (m_AminEntity[client] != 0)
		{
			vel[0] = 0.0, vel[1] = 0.0, vel[2] = 0.0; impulse = 0;
			// buttons &= ~IN_USE;
			
			if ((GetEntityFlags(client) & FL_DUCKING) != 0)
			{
				if (m_PlayerDock[client] == true)
				{
					SetEntProp(client, Prop_Send, "m_bDucked", 0);
					buttons |= IN_DUCK;
				}
				else if (!IsClientDuck(client, false))
				{
					buttons &= ~IN_DUCK;
				}
			}
			else buttons &= ~IN_DUCK;
			
			if (IsPlayerAnimation(client) || !IsClientDown(client))
			{
				DebugMessage("OnPlayerRunCmd() == " ... "nove|...")
				ResetPlayerSequence(client, true);
			}
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

public void Hook_RestartGame(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) > 0)
	{
		StopPlayerSequences();
	}
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	StopPlayerSequences();
	
	m_RoundEnd = false;
}

public void Hook_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	StopPlayerSequences();
	
	m_RoundEnd = true;
}

public void Hook_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (IsValidClient(client) && event.GetInt("team") <= CS_TEAM_SPECTATOR)
	{
		ResetPlayerSequence(client, true);
	}
}

public void Hook_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (IsValidClient(client))
	{
		ResetPlayerSequence(client, true);
	}
}

public Action ZM_OnClientModel(int client, const char[] model)
{
	if (IsValidClient(client) && m_AminEntity[client] != 0)
	{
		DebugMessage("Timer_EventPlayerSpawnPost()" ... "\nZR_OnClientInfected()" ... "\nZR_OnClientHumanPost()")
		// m_WeaponEntity[client] = INVALID_ENT_REFERENCE;
		
		ResetPlayerSequence(client, true);
	}
	return Plugin_Continue;
}

public Action ZM_OnPlayFootStep(int client, const char[] sound, int channel, int level, int flags, float volume, int pitch)
{
	if (IsValidClient(client) && m_AminEntity[client] != 0)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

bool SetPlayerSequence(int client, const char[] anim, const char[] anim2 = "")
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		if (m_RoundEnd == true)
		{
			DebugMessage("SetPlayerSequence() == " ... "RoundEnd")
			ResetPlayerSequence(client, true);
			return false;
		}
	
		if (!anim[0] || StrEqual(anim, "0"))
		{
			DebugMessage("SetPlayerSequence() == " ... "\"\"")
			ResetPlayerSequence(client, true);
			return false;
		}
		
		if (m_AminEntity[client] != 0)
		{
			int entity = EntRefToEntIndex(m_AminEntity[client]);
			if (IsValidEntityf(entity))
			{
				SetVariantString(anim);
				AcceptEntityInput(entity, "SetAnimation");
				HookSingleEntityOutput(entity, "OnAnimationDone", Hook_OnAnimationDone, true);
				
				DebugMessage("SetPlayerSequence() == " ... "anim2")
				return true;
			}
			
			DebugMessage("SetPlayerSequence() == " ... "entity")
			return false;
		}
		
		if (!IsPlayerAnimation(client))
		{
			DebugMessage("SetPlayerSequence() == " ... "nove|...")
			ResetPlayerSequence(client, true);
			return false;
		}
		
		if (!IsClientDown(client))
		{
			DebugMessage("SetPlayerSequence() == " ... "Down")
			ResetPlayerSequence(client, true);
			return false;
		}
		
		int entity = CreateEntityByName("prop_dynamic_override");
		if (entity != -1)
		{
			CreateForward_OnPlayerSequencePre(client, entity, anim);
		
			SDKHook(client, SDKHook_WeaponSwitch, Hook_WeaponCanUseSwitch);
			SDKHook(client, SDKHook_WeaponCanUse, Hook_WeaponCanUseSwitch);
			SDKHook(client, SDKHook_PostThinkPost, Hook_PostThinkPost);
			SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit_invis);
			
			int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if (weapon != -1)
			{
				// m_WeaponEntity[client] = EntIndexToEntRef(weapon);
				// SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", -1);
				
				SetEntPropFloat(client, Prop_Send, "m_flNextAttack", 9999999.0);
				SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", 9999999.0);
				SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", 9999999.0);
				SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
				SetEntityRenderColor(weapon, 255, 255, 255, 0);
			}
		
			char targetname[20], model[64];
			float origin[3], angles[3];
			
			GetClientAbsOrigin(client, origin);
			GetClientEyeAngles(client, angles);
			GetClientModel(client, model, sizeof(model));
			
			m_PlayerOrigin[client] = origin;
			m_PlayerAngles[client] = angles;
			
			FormatEx(targetname, sizeof(targetname), "playeranim_%d", entity);
			DispatchKeyValue(entity, "targetname", targetname);
			DispatchKeyValue(entity, "model", model);
			DispatchKeyValue(entity, "solid", "0");
			DispatchKeyValue(entity, "spawnflags", "320");
			
			ActivateEntity(entity);
			DispatchSpawn(entity);
			
			angles[0] = 0.0; angles[2] = 0.0;
			TeleportEntity(entity, origin, angles, NULL_VECTOR);
			
			CreateForward_OnPlayerSequence(client, entity);
			
			SetEntityRenderMode(client, RENDER_TRANSCOLOR);
			SetEntityRenderColor(client, 255, 255, 255, 0);
			
			SetVariantString(targetname);
			AcceptEntityInput(entity, "SetParent", client, entity);
			
			// SetEntProp(entity, Prop_Send, "m_CollisionGroup", 17);
			SetEntityCollisionGroup(entity, 17);
			SetEntityMoveType(client, MOVETYPE_NONE);
			SetEntProp(client, Prop_Send, "m_fEffects", EF_BONEMERGE|EF_NOSHADOW|EF_NORECEIVESHADOW|EF_BONEMERGE_FASTCULL|EF_PARENT_ANIMATES);
			SetEntPropFloat(entity, Prop_Send, "m_flPlaybackRate", 0.85);
			SetEntDataEnt2(entity, m_hOwnerEntity, client);
			
			if (anim2[0])
			{
				SetVariantString(anim2);
				AcceptEntityInput(entity, "SetDefaultAnimation");
			}
			else
			{
				HookSingleEntityOutput(entity, "OnAnimationDone", Hook_OnAnimationDone, true);
			}
			
			SetVariantString(anim);
			AcceptEntityInput(entity, "SetAnimation");
			
			m_AminEntity[client] = EntIndexToEntRef(entity);
			UTIL_SetClientCam(client, true);
			ZM_WeaponAttachRemoveAddons(client);
			
			DebugMessage("SetPlayerSequence() == " ... "anim1")
			return true;
		}
	}
	
	DebugMessage("SetPlayerSequence() == " ... "0")
	return false;
}

public void Hook_OnAnimationDone(const char[] output, int caller, int activator, float delay)
{
	if (caller > 0 && IsValidEdict(caller) && IsValidEntity(caller))
	{
		UnhookSingleEntityOutput(caller, "OnAnimationDone", Hook_OnAnimationDone);
		
		int client = GetEntDataEnt2(caller, m_hOwnerEntity);
		ChangeEdictState(caller, m_hOwnerEntity);
		
		if (IsValidClient(client) && m_AminEntity[client] != 0)
		{
			if (IsPlayerAnimation(client))
			{
				DebugMessage("OnAnimationDone() == " ... "nove|...")
				ResetPlayerSequence(client, true);
				return;
			}
			
			switch(CreateForward_OnAnimationDone(client, caller))
			{
				case Plugin_Continue:
				{
					DebugMessage("OnAnimationDone() == " ... "Plugin_Continue")
					return;
				}
				case Plugin_Stop, Plugin_Handled:
				{
					DebugMessage("OnAnimationDone() == " ... "Plugin_Stop|Plugin_Handled")
					ResetPlayerSequence(client, true);
				}
			}
		}
	}
}

void StopPlayerSequences()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			ResetPlayerSequence(i, true);
		}
	}
}

bool ResetPlayerSequence(int client, bool player = true)
{
	ResetRandomButton(client);

	if (m_AminEntity[client] != 0)
	{
		CreateForward_OnResetPlayerSequencePre(client, player);
	
		SDKUnhook(client, SDKHook_WeaponSwitch, Hook_WeaponCanUseSwitch);
		SDKUnhook(client, SDKHook_WeaponCanUse, Hook_WeaponCanUseSwitch);
		SDKUnhook(client, SDKHook_PostThinkPost, Hook_PostThinkPost);
		SDKUnhook(client, SDKHook_SetTransmit, Hook_SetTransmit_invis);
		
		int entity = EntRefToEntIndex(m_AminEntity[client]);
		if (IsValidEntityf(entity))
		{
			UnhookSingleEntityOutput(entity, "OnAnimationDone", Hook_OnAnimationDone);
		
			char targetname[16];
			GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));
			SetVariantString(targetname);
			AcceptEntityInput(client, "ClearParent", entity, entity);
			
			if (ZM_GetClientClass(client) == m_ZombieSmoker)
			{
				UTIL_RemoveEntity(entity, 0.1);
			}
			else
			{
				AcceptEntityInput(entity, "kill");
			}
		}
		
		if (IsPlayerAlive(client))
		{
			if (player == true)
			{
				// if (m_WeaponEntity[client] != INVALID_ENT_REFERENCE)
				// {
				// 	int weapon = EntRefToEntIndex(m_WeaponEntity[client]);
				// 	if (weapon != INVALID_ENT_REFERENCE)
				// 	{
				// 		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
				// 	}
				// }
				
				int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				if (weapon != -1)
				{
					SetEntPropFloat(client, Prop_Send, "m_flNextAttack", 0.0);
					SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", 0.0);
					SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", 0.0);
					
					if (ZM_IsClientHuman(client))
					{
						SetEntityRenderMode(weapon, RENDER_NORMAL);
						SetEntityRenderColor(weapon, 255, 255, 255, 255);
					}
					else
					{
						int knife = GetPlayerWeaponSlot(client, 2);
						if (knife != -1) 
						{
							UTIL_SetRenderColor(knife, 3, 1);
							UTIL_AddEffect(knife, EF_NODRAW);
						}
					}
				}
				
				TeleportEntity(client, m_PlayerOrigin[client], m_PlayerAngles[client], NULL_VECTOR);
				
				if (GetEntityMoveType(client) == MOVETYPE_NONE)
				{
					SetEntityMoveType(client, MOVETYPE_WALK);
				}
			}
			
			UTIL_SetClientCam(client, false);
		}
		else
		{
			if (player == true)
			{
				SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
			}
		}
		
		SetEntityRenderMode(client, RENDER_NORMAL);
		SetEntityRenderColor(client, 255, 255, 255, 255);
		
		CreateForward_OnResetPlayerSequence(client, player);
		
		m_PlayerDock[client] = false;
		m_AminEntity[client] = 0;
		// m_WeaponEntity[client] = INVALID_ENT_REFERENCE;
		DebugMessage("ResetPlayerSequence()")
		return true;
	}
	return false;
}

void OnRandomButtonRunCmd(int client, int buttons)
{
	if (m_bActorDisable[client] == true)
	{
		float time = GetGameTime();
		
		if (IsFakeClient(client))
		{
			if (m_fTimeResetActorDisable[client] - time < 0.0)
			{
				Call_StartForward(hOnClientBreakSkill);
				Call_PushCell(client);
				Call_Finish();
				
				m_bActorDisable[client] = false;
				m_iStateActorDisable[client] = 1;
			}
			return;
		}
		
		if (m_fTimeResetActorDisable[client] < time)
		{
			// GetRandomButton(client);
			// UTIL_ScreenFade(client, 1.0, 0.1, FFADE_IN, {128, 0, 0, 128});
			m_iStateActorDisable[client] = 1;
			m_fTimeResetActorDisable[client] = time + 3.0;
		}
		
		if (buttons != 0)
		{
			if (buttons & m_iButtonActorDisable[client])
			{
				m_iButtonActorDisable[client] &= ~buttons;
		
				if (m_iButtonActorDisable[client] == 0)
				{
					m_iStateActorDisable[client]++;
		
					if (m_iStateActorDisable[client] == m_iMaxState[client])
					{
						Call_StartForward(hOnClientBreakSkill);
						Call_PushCell(client);
						Call_Finish();
						
						UTIL_ScreenFade(client, 1.0, 0.1, FFADE_IN, {0, 128, 0, 128});
						m_bActorDisable[client] = false;
						m_iStateActorDisable[client] = 1;
						return;
					}
					
					UTIL_ScreenFade(client, 1.0, 0.1, FFADE_IN, {0, 0, 128, 128});
					if (time > m_fTimeResetActorDisable[client])
						m_fTimeResetActorDisable[client] = time + 3.0;
					else m_fTimeResetActorDisable[client] += 3.0;
					
					GetRandomButton(client);
					EmitSoundToClient(client, SOUND_BUTTON_BELL1);  
				}
			}
		}
		
		if (m_fLastPrintMessage[client] < time)
		{
			m_fLastPrintMessage[client] = time + 0.75;
			
			SetHudTextParams( -1.0, -1.0, 0.76, 255, 255, 255, 255);
			ShowSyncHudText(client, m_SyncHud[1], "%t", "HUD_PLAYER_BUTTONS", m_iStateActorDisable[client], m_iMaxState[client]-1, (m_fTimeResetActorDisable[client]-time));
		}
		
		if (m_fLastPrint[client] < time)
		{
			m_fLastPrint[client] = time + 0.15;
			SetHudTextParams(-1.0, 0.46, 0.16, 255, 0, 0, 255);
			
			static char buffer[32]; GetButtonsName(client, buffer, sizeof(buffer));
			ShowSyncHudText(client, m_SyncHud[0], "\n\n[ %s]", buffer);
		}
	}
}

void ResetRandomButton(int client)
{
	if (m_bActorDisable[client] == true)
	{
		m_bActorDisable[client] = false;
		m_iStateActorDisable[client] = 1;
		m_fLastPrintMessage[client] = 0.0;
		m_fTimeResetActorDisable[client] = 0.0;
		m_fLastPrint[client] = 0.0;
	}
}

void SetVictimState(int client, int maxstate)
{
	m_bActorDisable[client] = maxstate ? true:false;
	m_iStateActorDisable[client] = 1;
	m_iMaxState[client] = maxstate;
	
	m_fLastPrintMessage[client] = 0.0;
	m_fLastPrint[client] = 0.0;
	m_fTimeResetActorDisable[client] = (IsFakeClient(client) ? GetGameTime()+GetRandomFloat(2.0, 5.0):0.0);
	
	GetRandomButton(client);
}

public Action Hook_SetTransmit_invis(int entity, int client) 
{
	if (IsValidClient(entity))
	{
		if (entity == client) {
			return Plugin_Continue;
		}
		
		if (!IsPlayerAlive(entity)) {
			SDKUnhook(entity, SDKHook_SetTransmit, Hook_SetTransmit_invis);
			return Plugin_Continue;
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Hook_WeaponCanUseSwitch(int client, int weapon)
{
	return Plugin_Stop;
}

public void Hook_PostThinkPost(int client)
{
	SetEntProp(client, Prop_Send, "m_iAddonBits", 0);
}

bool IsPlayerAnimation(int client)
{
	if (GetEntityMoveType(client) == MOVETYPE_NONE)
	{
		if (GetEntPropEnt(client, Prop_Data, "m_hObserverTarget") != 0)
		{
			return true;
		}
		return false;
	}
	return true;
}

bool IsClientDuck(int client, bool duck)
{
	float origin[3], min[3], max[3];
	GetClientAbsOrigin(client, origin);
	GetClientMins(client, min);
	GetClientMaxs(client, max);
	
	max[2] += 20.0;
	TR_TraceHullFilter(origin, origin, min, max, MASK_PLAYERSOLID, TraceEntityFilter, client);

	if (duck == true)
	{
		if (view_as<bool>(GetEntityFlags(client) & FL_DUCKING))
		{
			if (!TR_DidHit())
			{
				m_PlayerDock[client] = true;
			}
			return true;
		}
		return false;
	}
	
	if (GetEntProp(client, Prop_Send, "m_bDucked") == 1)
	{
		return TR_DidHit();
	}
	return false;
}

public bool TraceEntityFilter(int entity, int contentsMask, int client)
{
	if (entity > 0 && client != entity)
	{
		int cg = GetEntData(entity, m_CollisionGroup);
		if (IS_COLLISION(cg))
		{
			return true;
		}
	}
	return false;
}

bool IsClientDown(int client)
{
	if (ZM_IsClientHuman(client))
	{
		float origin[3], min[3], max[3];
		GetClientAbsOrigin(client, origin);
		GetClientMins(client, min);
		GetClientMaxs(client, max); min[2] -= 20.0;
		TR_TraceHullFilter(origin, origin, min, max, MASK_PLAYERSOLID, TraceEntityFilter2, client);
		return TR_DidHit();
	}
	return true;
}

public bool TraceEntityFilter2(int entity, int contentsMask, int client)
{
	if (entity > 0 && client != entity)
	{
		if (IsValidClient(client) && IsValidClient(entity))
		{
			return false;
		}
	
		int cg = GetEntData(entity, m_CollisionGroup);
		if (IS_COLLISION(cg))
		{
			return true;
		}
	}
	return false;
}

void GetRandomButton(int client)
{
	int max_button = 4; // Максимальное колличество кнопок для нажатия человеком (ZMBreak).
	int buttons = 1; int cmd_button = 0;
	
	if (max_button != buttons && GetRandomInt(1, 2) == 1) {
		cmd_button |= IN_FORWARD;
		buttons++;
	}
	
	if (max_button != buttons && GetRandomInt(1, 2) == 1) {
		cmd_button |= IN_BACK;
		buttons++;
	}
	
	if (max_button != buttons && GetRandomInt(1, 2) == 1) {
		cmd_button |= IN_MOVELEFT;
		buttons++;
	}
	
	if (max_button != buttons && GetRandomInt(1, 2) == 1) {
		cmd_button |= IN_MOVERIGHT;
		buttons++;
	}
	
	if (max_button != buttons && GetRandomInt(1, 2) == 1) {
		cmd_button |= IN_RELOAD;
		buttons++;
	}
	
	if ((max_button != buttons && GetRandomInt(1, 2) == 1) || buttons <= 2) {
		cmd_button |= IN_USE;
		buttons++;
	}
	
	m_iButtonActorDisable[client] = cmd_button;
}

void GetButtonsName(int client, char[] buffer, int maxlength)
{
	Format(buffer, maxlength, "");
	if (m_iButtonActorDisable[client] & IN_FORWARD) Format(buffer, maxlength, "%sW ", buffer);
	if (m_iButtonActorDisable[client] & IN_BACK) Format(buffer, maxlength, "%sS ", buffer);
	if (m_iButtonActorDisable[client] & IN_MOVELEFT) Format(buffer, maxlength, "%sA ", buffer);
	if (m_iButtonActorDisable[client] & IN_MOVERIGHT) Format(buffer, maxlength, "%sD ", buffer);
	if (m_iButtonActorDisable[client] & IN_RELOAD) Format(buffer, maxlength, "%sR ", buffer);
	if (m_iButtonActorDisable[client] & IN_USE) Format(buffer, maxlength, "%sE ", buffer);
}

// cmd
public Action Command_SetAnim(int client, int args)
{
	if (IsValidClient(client))
	{
		char arg[10], animname[64], target_name[MAX_TARGET_LENGTH];
		int target_list[MAXPLAYERS], target_count; bool tn_is_ml;
		GetCmdArg(1, arg, sizeof(arg));
		GetCmdArg(2, animname, sizeof(animname));
		
		if ((target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		
		for (int i = 0; i < target_count; i++)
		{
			int target = target_list[i];
			
			if (SetPlayerSequence(target, animname))
			{
				continue;
			}
			
			ResetPlayerSequence(target, true);
		}
		
		PrintToChat(client, "\x07FFFF00Sequence name: \"%s\"", animname);
	}
	return Plugin_Handled;
}

public Action Command_SetAnimButtons(int client, int args)
{
	if (IsValidClient(client))
	{
		char arg[10], animname[64], target_name[MAX_TARGET_LENGTH];
		int target_list[MAXPLAYERS], target_count; bool tn_is_ml;
		GetCmdArg(1, arg, sizeof(arg));
		GetCmdArg(2, animname, sizeof(animname));
		
		if ((target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		
		for (int i = 0; i < target_count; i++)
		{
			int target = target_list[i];
			
			if (SetPlayerSequence(target, animname))
			{
				continue;
			}
			
			ResetPlayerSequence(target, true);
		}
		
		SetVictimState(client, 5);
		
		PrintToChat(client, "\x07FFFF00Sequence name: \"%s\"", animname);
	}
	return Plugin_Handled;
}

// api
public int Native_SetVictimState(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int maxstate = GetNativeCell(2);
	SetVictimState(client, maxstate);
	return 0;
}

public int Native_IsVictimState(Handle plugin, int numParams)
{
	return m_bActorDisable[GetNativeCell(1)];
}

public int Native_GetHandleAnimEvent(Handle plugin, int numParams)
{
	return m_HandleAnimEventOffset;
}

public int Native_IsClientPlayerNone(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return m_PlayerCanUse[client];
}

public int Native_IsPlayerAnimation(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);

	if (IsPlayerAnimation(client) && !IsClientDuck(client, GetNativeCell(2)))
	{
		return true;
	}
	return false;
}

public int Native_GetClientAnimationAngles(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);

	if (m_AminEntity[client] != 0)
	{
		SetNativeArray(2, m_PlayerAngles[client], 3);
	}
	return 0;
}

public int Native_GetEntitySequence(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);

	if (m_AminEntity[client] != 0)
	{
		return EntRefToEntIndex(m_AminEntity[client]);
	}
	return 0;
}

public int Native_SetPlayerSequence(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	static char animname[64], animname2[64];
	GetNativeString(2, animname, sizeof(animname));
	GetNativeString(3, animname2, sizeof(animname2));
	
	return SetPlayerSequence(client, animname, animname2);
}

void CreateForward_OnPlayerSequence(int client, int entity)
{
	Call_StartForward(hOnPlayerSequence);
	Call_PushCell(client);
	Call_PushCell(entity);
	Call_Finish();
}

void CreateForward_OnPlayerSequencePre(int client, int entity, const char[] anim)
{
	Call_StartForward(hOnPlayerSequencePre);
	Call_PushCell(client);
	Call_PushCell(entity);
	Call_PushString(anim);
	Call_Finish();
}

void CreateForward_OnResetPlayerSequencePre(int client, int player)
{
	Call_StartForward(hOnResetPlayerSequencePre);
	Call_PushCell(client);
	Call_PushCell(player);
	Call_Finish();
}

void CreateForward_OnResetPlayerSequence(int client, bool player)
{
	Call_StartForward(hOnResetPlayerSequence);
	Call_PushCell(client);
	Call_PushCell(player);
	Call_Finish();
}

Action CreateForward_OnAnimationDone(int client, int entity)
{
	Action result = Plugin_Handled;
	Call_StartForward(hOnAnimationDone);
	Call_PushCell(client);
	Call_PushCell(entity);
	Call_Finish(result);
	
	return result;
}