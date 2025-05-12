#include <zombiemod>
#include <zm_player_animation>
#include <zm_settings>
#include <vphysics>
#include <shop_system>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name = "[ZM] Zombie Class: Hunter",
	author = "0kEmo",
	version = "1.0"
};

#define CLASS_HUNTER_COOLDOWN 0.3
#define CLASS_HUNTER_COOLDOWN_USESKILL 0.5

#define SOUND_SMOKER_POUNCEHIT "zombie-plague/hero/hunter/tackled_1.wav"

static const char g_model[][] = {
	"models/zschool/rustambadr/hunter/hunter.dx80.vtx",
	"models/zschool/rustambadr/hunter/hunter.dx90.vtx",
	"models/zschool/rustambadr/hunter/hunter.mdl",
	"models/zschool/rustambadr/hunter/hunter.phy",
	"models/zschool/rustambadr/hunter/hunter.sw.vtx",
	"models/zschool/rustambadr/hunter/hunter.vvd",
	"models/zschool/rustambadr/hunter/hand/v_claw_hunter.dx80.vtx",
	"models/zschool/rustambadr/hunter/hand/v_claw_hunter.dx90.vtx",
	"models/zschool/rustambadr/hunter/hand/v_claw_hunter.mdl",
	"models/zschool/rustambadr/hunter/hand/v_claw_hunter.sw.vtx",
	"models/zschool/rustambadr/hunter/hand/v_claw_hunter.vvd",
	"materials/models/zschool/rustambadr/hunter/hunter_01.vmt",
	"materials/models/zschool/rustambadr/hunter/hunter_01.vtf",
	"materials/models/zschool/rustambadr/hunter/hunter_01_detail.vtf",
	"materials/models/zschool/rustambadr/hunter/hunter_exponent.vtf",
	"materials/models/zschool/rustambadr/hunter/hunter_normal.vtf"
};

// static const char g_model[][] = {
// 	"models/zombiecity/zombies/hunter/hunter.dx80.vtx",
// 	"models/zombiecity/zombies/hunter/hunter.dx90.vtx",
// 	"models/zombiecity/zombies/hunter/hunter.mdl",
// 	"models/zombiecity/zombies/hunter/hunter.phy",
// 	"models/zombiecity/zombies/hunter/hunter.sw.vtx",
// 	"models/zombiecity/zombies/hunter/hunter.vvd",
// 	"models/zombiecity/zombies/hunter/hunter_claws.dx80.vtx",
// 	"models/zombiecity/zombies/hunter/hunter_claws.dx90.vtx",
// 	"models/zombiecity/zombies/hunter/hunter_claws.mdl",
// 	"models/zombiecity/zombies/hunter/hunter_claws.sw.vtx",
// 	"models/zombiecity/zombies/hunter/hunter_claws.vvd",
// 	"materials/zombiecity/zombies/hunter/hunter_01.vmt",
// 	"materials/zombiecity/zombies/hunter/hunter_01.vtf",
// 	"materials/zombiecity/zombies/hunter/hunter_exponent.vtf",
// 	"materials/zombiecity/zombies/hunter/hunter_normal.vtf"
// };

static const char g_WarnSounds[2][] =
{
	"sound/zombie-plague/hero/hunter/hunter_warn_1.wav",
	"sound/zombie-plague/hero/hunter/hunter_warn_2.wav"
};

static const char g_StalkSounds[3][] =
{
	"sound/zombie-plague/hero/hunter/hunter_stalk_01.wav",
	"sound/zombie-plague/hero/hunter/hunter_stalk_02.wav",
	"sound/zombie-plague/hero/hunter/hunter_stalk_03.wav"
};

static const char g_AttackmixSounds[3][] =
{
	"sound/zombie-plague/hero/hunter/hunter_attackmix_01.wav",
	"sound/zombie-plague/hero/hunter/hunter_attackmix_02.wav",
	"sound/zombie-plague/hero/hunter/hunter_attackmix_03.wav"
};

static const char g_AttackHitSounds[6][] =
{
	"sound/zombie-plague/hero/hunter/zombie_slice_1.wav",
	"sound/zombie-plague/hero/hunter/zombie_slice_2.wav",
	"sound/zombie-plague/hero/hunter/zombie_slice_3.wav",
	"sound/zombie-plague/hero/hunter/zombie_slice_4.wav",
	"sound/zombie-plague/hero/hunter/zombie_slice_5.wav",
	"sound/zombie-plague/hero/hunter/zombie_slice_6.wav"
};

// static const char g_ShredSounds[5][] =
// {
// 	"sound/zombie-plague/hero/hunter/hunter_shred_01.wav",
// 	"sound/zombie-plague/hero/hunter/hunter_shred_02.wav",
// 	"sound/zombie-plague/hero/hunter/hunter_shred_03.wav",
// 	"sound/zombie-plague/hero/hunter/hunter_shred_04.wav",
// 	"sound/zombie-plague/hero/hunter/hunter_shred_05.wav"
// };

static const char g_LungeSounds[4][] = 
{
	"sound/zombie-plague/hero/hunter/hunter_pounce_01.wav",
	"sound/zombie-plague/hero/hunter/hunter_pounce_02.wav",
	"sound/zombie-plague/hero/hunter/hunter_pounce_04.wav",
	"sound/zombie-plague/hero/hunter/hunter_pounce_05.wav"
};

static const char g_PounceSounds[11][] =
{
	"sound/zombie-plague/human/screamwhilepounced01.wav",
	"sound/zombie-plague/human/screamwhilepounced01a.wav",
	"sound/zombie-plague/human/screamwhilepounced02.wav",
	"sound/zombie-plague/human/screamwhilepounced03.wav",
	"sound/zombie-plague/human/screamwhilepounced03a.wav",
	"sound/zombie-plague/human/screamwhilepounced04a.wav",
	"sound/zombie-plague/human/screamwhilepounced05.wav",
	"sound/zombie-plague/human/screamwhilepounced06.wav",
	"sound/zombie-plague/human/screamwhilepounced07.wav",
	"sound/zombie-plague/human/screamwhilepounced07a.wav",
	"sound/zombie-plague/human/screamwhilepounced07b.wav"
};

static const char g_PouncefSounds[13][] =
{
	"sound/zombie-plague/human/f/screamwhilepounced01.wav",
	"sound/zombie-plague/human/f/screamwhilepounced01a.wav",
	"sound/zombie-plague/human/f/screamwhilepounced02.wav",
	"sound/zombie-plague/human/f/screamwhilepounced02a.wav",
	"sound/zombie-plague/human/f/screamwhilepounced02b.wav",
	"sound/zombie-plague/human/f/screamwhilepounced03.wav",
	"sound/zombie-plague/human/f/screamwhilepounced03a.wav",
	"sound/zombie-plague/human/f/screamwhilepounced03b.wav",
	"sound/zombie-plague/human/f/screamwhilepounced03c.wav",
	"sound/zombie-plague/human/f/screamwhilepounced04.wav",
	"sound/zombie-plague/human/f/screamwhilepounced04a.wav",
	"sound/zombie-plague/human/f/screamwhilepounced04b.wav",
	"sound/zombie-plague/human/f/screamwhilepounced05.wav"
};

enum struct ServerData
{
	int ViewModelOffset;
	int hActiveWeaponOffset;
	int OwnerEntityOffset;
	int m_vecVelocityOffset;
	int flNextPrimaryAttack;
	int flNextSecondaryAttack;
	
	void Clear()
	{
		this.ViewModelOffset = -1;
		this.hActiveWeaponOffset = -1;
		this.OwnerEntityOffset = -1;
		this.m_vecVelocityOffset = -1;
		this.flNextPrimaryAttack = -1;
		this.flNextSecondaryAttack = -1;
	}
}
ServerData sServerData;

enum struct ClientData
{
	Handle TimerStalk;
	
	bool InJump;
	bool ZombieClass;
	bool PlayerCanUse;
	bool Stalk;
	bool AttackHuman;
	bool Pounced;
	
	int Target[2];
	
	float Cooldown;
	float CooldownSkill;
	float fTimeLoad;
	float fLastWarn;
	float HudTimeLoad;
	float Pounce[3];
	float HumanScream;
	float LastPounce;
	
	void Clear()
	{
		this.InJump = false;
		this.ZombieClass = false;
		this.PlayerCanUse = false;
		this.Stalk = false;
		this.AttackHuman = false;
		this.Pounced = false;
		this.Target[0] = 0;
		this.Target[1] = 0;
		this.Cooldown = 0.0;
		this.CooldownSkill = 0.0;
		this.fTimeLoad = 0.0;
		this.HudTimeLoad = 0.0;
		this.fLastWarn = 0.0;
		this.HumanScream = 0.0;
		this.LastPounce = 0.0;
		this.Pounce = NULL_VECTOR;
		
		if (this.TimerStalk != null)
		{
			delete this.TimerStalk;
			this.TimerStalk = null;
		}
	}
}
ClientData sClientData[MAXPLAYERS+1];

int m_Zombie;

public void OnPluginStart()
{
	LoadTranslations("zm_class.phrases");
	
	InitSendPropOffset(sServerData.hActiveWeaponOffset, "CCSPlayer", "m_hActiveWeapon");
	InitSendPropOffset(sServerData.OwnerEntityOffset, "CBaseEntity", "m_hOwnerEntity");
	InitSendPropOffset(sServerData.m_vecVelocityOffset, "CBasePlayer", "m_vecVelocity[0]");
	InitSendPropOffset(sServerData.flNextPrimaryAttack, "CBaseCombatWeapon", "m_flNextPrimaryAttack");
	InitSendPropOffset(sServerData.flNextSecondaryAttack, "CBaseCombatWeapon", "m_flNextSecondaryAttack");
	InitSendPropOffset(sServerData.ViewModelOffset, "CBasePlayer", "m_hViewModel");
	
	HookEvent("round_end", Hook_RoundEnd);
	HookEvent("player_death", Event_PlayerDeath);
}

public void OnPluginEnd()
{
	sServerData.Clear();
	
	UnhookEvent("round_end", Hook_RoundEnd);
	UnhookEvent("player_death", Event_PlayerDeath);
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

	AddFileToDownloadsTable("sound/" ... SOUND_SMOKER_POUNCEHIT);
	PrecacheSound(SOUND_SMOKER_POUNCEHIT);

	for (int i = 0; i < sizeof(g_WarnSounds); i++)
	{
		AddFileToDownloadsTable(g_WarnSounds[i]);
		PrecacheSound(g_WarnSounds[i][6]);
	}
	for (int i = 0; i < sizeof(g_StalkSounds); i++)
	{
		AddFileToDownloadsTable(g_StalkSounds[i]);
		PrecacheSound(g_StalkSounds[i][6]);
	}
	for (int i = 0; i < sizeof(g_AttackmixSounds); i++)
	{
		AddFileToDownloadsTable(g_AttackmixSounds[i]);
		PrecacheSound(g_AttackmixSounds[i][6]);
	}
	for (int i = 0; i < sizeof(g_AttackHitSounds); i++)
	{
		AddFileToDownloadsTable(g_AttackHitSounds[i]);
		PrecacheSound(g_AttackHitSounds[i][6]);
	}
	for (int i = 0; i < sizeof(g_PounceSounds); i++)
	{
		AddFileToDownloadsTable(g_PounceSounds[i]);
		PrecacheSound(g_PounceSounds[i][6]);
	}
	for (int i = 0; i < sizeof(g_PouncefSounds); i++)
	{
		AddFileToDownloadsTable(g_PouncefSounds[i]);
		PrecacheSound(g_PouncefSounds[i][6]);
	}
	// for (int i = 0; i < sizeof(g_ShredSounds); i++)
	// {
	// 	AddFileToDownloadsTable(g_ShredSounds[i]);
	// 	PrecacheSound(g_ShredSounds[i][6]);
	// }
	for (int i = 0; i < sizeof(g_LungeSounds); i++)
	{
		AddFileToDownloadsTable(g_LungeSounds[i]);
		PrecacheSound(g_LungeSounds[i][6]);
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
	m_Zombie = ZM_GetClassNameID("zombie_hunter");
}

public void OnClientDisconnect_Post(int client)
{
	sClientData[client].Clear();
	
	SDKUnhook(client, SDKHook_StartTouch, Hook_Touch);
	SDKUnhook(client, SDKHook_PostThinkPost, Hook_PostThinkPost);
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (IsValidClient(client) && sClientData[client].ZombieClass)
	{
		sClientData[client].HudTimeLoad = 0.0;
		sClientData[client].fTimeLoad = 0.0;
		sClientData[client].InJump = false;
		
		int target = GetClientFromSerial(sClientData[client].Target[1]);
		if (target != 0 && IsPlayerAlive(target) && ZM_IsClientHuman(target))
		{
			SetVictimState(target, 0);
			SetPlayerSequence(target, "NamVet_Pounced_end");
			
			if (sClientData[target].AttackHuman)
			{
				sClientData[target].AttackHuman = false;
				sClientData[target].Target[0] = 0;
			}
			
			sClientData[client].Pounced = false;
			sClientData[client].Target[1] = 0;
		}
		
		SDKUnhook(client, SDKHook_StartTouch, Hook_Touch);
	}
	return Plugin_Continue;
}

public void Hook_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && sClientData[i].ZombieClass)
		{
			sClientData[i].HudTimeLoad = 0.0;
			sClientData[i].fTimeLoad = 0.0;
			sClientData[i].InJump = false;
			
			SDKUnhook(i, SDKHook_StartTouch, Hook_Touch);
		}
	}
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3])
{
	if (IsValidClient(client) && IsPlayerAlive(client) && ZM_IsClientZombie(client)	&& sClientData[client].ZombieClass)
	{
		float time = GetGameTime();
	
		if (sClientData[client].InJump)
		{
			MoveType type = GetEntityMoveType(client);
			if (GetEntProp(client, Prop_Data, "m_nWaterLevel") || type == MOVETYPE_NOCLIP || type == MOVETYPE_LADDER)
			{
				sClientData[client].HudTimeLoad = 0.0;
				sClientData[client].fTimeLoad = 0.0;
				sClientData[client].InJump = false;
				
				SDKUnhook(client, SDKHook_StartTouch, Hook_Touch);
			}
		
			if (GetEntityFlags(client) & FL_ONGROUND && sClientData[client].fTimeLoad <= time)
			{
				Hook_Touch(client, 0);
				
				sClientData[client].HudTimeLoad = 0.0;
				sClientData[client].fTimeLoad = 0.0;
				sClientData[client].InJump = false;
			}
			
			float velocity[3];
			GetEntDataVector(client, sServerData.m_vecVelocityOffset, velocity);
			sClientData[client].Pounce = velocity;
		}
	
		if (sClientData[client].Cooldown <= 0.0)
		{
			static int RandomStalk;
			if (GetEntityFlags(client) & FL_ONGROUND && GetEntProp(client, Prop_Data, "m_nWaterLevel") < 2)
			{
				if (!sClientData[client].PlayerCanUse)
				{
					sClientData[client].PlayerCanUse = true;
					sClientData[client].HudTimeLoad = 0.0;
				}
				
				if (buttons & IN_DUCK)
				{
					if (!sClientData[client].Stalk)
					{
						sClientData[client].CooldownSkill = CLASS_HUNTER_COOLDOWN_USESKILL;
						
						sClientData[client].HudTimeLoad = 0.0;
						sClientData[client].Stalk = true;
					}
					
					if (sClientData[client].fLastWarn <= time)
					{
						RandomStalk = GetRandomInt(0, sizeof(g_StalkSounds)-1);
						EmitSoundToAll(g_StalkSounds[RandomStalk][6], client);
						
						sClientData[client].fLastWarn = time + GetRandomFloat(1.4, 2.5);
					}
				}
				else
				{
					if (sClientData[client].Stalk)
					{
						sClientData[client].Stalk = false;
						sClientData[client].HudTimeLoad = 0.0;
					}
				}
			}
			else
			{
				if (sClientData[client].PlayerCanUse)
				{
					if (sClientData[client].Stalk)
					{
						sClientData[client].Stalk = false;
					}
					
					sClientData[client].HudTimeLoad = 0.0;
					sClientData[client].PlayerCanUse = false;
				}
			}
			
			if (buttons & IN_DUCK && buttons & IN_ATTACK)
			{
				if (sClientData[client].CooldownSkill > 0.0)
				{
					return Plugin_Continue;
				}
			
				if (GetEntProp(client, Prop_Data, "m_nWaterLevel") > 1)
				{
					return Plugin_Continue;
				}
			
				if (sClientData[client].PlayerCanUse)
				{
					float pos[3], min[3], max[3], velocity[3], m_fT[3], m_fVector[3], ang_t[3], m_fForward[3];
					
					GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
					GetClientAbsOrigin(client, pos);
					GetClientMins(client, min);
					GetClientMaxs(client, max);
					
					if (angles[0] >= -5.0) angles[0] = -15.0;
					else angles[0] -= 10.0;
					if (angles[0] < -90.0) angles[0] = -80.0;
					ang_t[0] = 0.0; ang_t[1] = angles[1]; ang_t[2] = angles[2];
					
					GetAngleVectors(ang_t, m_fT, NULL_VECTOR, NULL_VECTOR);
					m_fForward[0] = pos[0] + m_fT[0] * 50.0;
					m_fForward[1] = pos[1] + m_fT[1] * 50.0;
					m_fForward[2] = pos[2] + m_fT[2] * 50.0;
					
					TR_TraceHullFilter(pos, m_fForward, min, max, MASK_PLAYERSOLID, TraceEntityFilter);
					
					if (TR_GetFraction() == 1.0 && !TR_StartSolid())
					{
						float fpos[3]; fpos[0] = m_fForward[0], fpos[1] = m_fForward[1], fpos[2] = m_fForward[2];
						fpos[2] -= 32.0;
						
						TR_TraceHullFilter(m_fForward, fpos, min, max, MASK_PLAYERSOLID, TraceEntityFilter);
						
						if (TR_GetFraction() == 1.0 && !TR_StartSolid())
						{
							SetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", m_fForward);
							float m_forward[3]; GetAimOrigin(client, m_forward);
							
							m_fVector[0] = m_forward[0] - m_fForward[0];
							m_fVector[1] = m_forward[1] - m_fForward[1];
							m_fVector[2] = m_forward[2] - m_fForward[2];
							
							GetVectorAngles(m_fVector, angles);
						}
					}

					GetAngleVectors(angles, m_fVector, NULL_VECTOR, NULL_VECTOR);
					
					m_fVector[0] *= 1000.0 + GetClientSkill(client, 0)+100.0;
					m_fVector[1] *= 1000.0 + GetClientSkill(client, 0)+100.0;
					m_fVector[2] *= 750.0 + GetClientSkill(client, 0);
					
					AddVectors(velocity, m_fVector, m_fVector);
					TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, m_fVector);
					SDKHook(client, SDKHook_StartTouch, Hook_Touch);
					
					StopSound(client, SNDCHAN_AUTO, g_StalkSounds[RandomStalk][6]);
					int rand = GetRandomInt(0, sizeof(g_AttackmixSounds)-1);
					EmitSoundToAll(g_AttackmixSounds[rand][6], client);
					
					if (sClientData[client].TimerStalk != null)
					{
						delete sClientData[client].TimerStalk;
						sClientData[client].TimerStalk = null;
					}
					
					int ClientWeapon = GetEntDataEnt2(client, sServerData.hActiveWeaponOffset);
					if (IsValidEdict(ClientWeapon))
					{
						ZM_SetWeaponAnimation(client, 6);
						SetWeaponNextAttack(ClientWeapon, 1.0);
					}
					
					sClientData[client].Stalk = false;
					sClientData[client].InJump = true;
					sClientData[client].HudTimeLoad = 0.0;
					sClientData[client].fTimeLoad = time + 0.7; // ...
					sClientData[client].Cooldown = CLASS_HUNTER_COOLDOWN;
					sClientData[client].CooldownSkill = 0.0;
					sClientData[client].Target[0] = 0;
				}
			}
		}
		else
		{
			static int iOldButton[MAXPLAYERS+1];
			if (buttons & IN_JUMP && !(iOldButton[client] & IN_JUMP))
			{
				if (sClientData[client].Pounced == true)
				{
					SetPlayerSequence(client, "Melee_pounce_Knockoff_Backward");
					sClientData[client].Pounced = false;
					
					int target = GetClientFromSerial(sClientData[client].Target[1]);
					if (target != 0)
					{
						SetVictimState(target, 0);
						SetPlayerSequence(target, "NamVet_Pounced_end");
						sClientData[target].AttackHuman = false;
						sClientData[client].Target[1] = 0;
					}
					return Plugin_Continue;
				}
			}
			iOldButton[client] = buttons;
		}
	}
	return Plugin_Continue;
}

public Action Hook_Touch(int client, int entity)
{
	if (IsValidClient(client) && GetEntProp(client, Prop_Send, "m_usSolidFlags", 2) != 8)
	{
		if (entity != 0 && client != entity && IsValidClient(entity) && IsPlayerAlive(entity) && ZM_IsClientHuman(entity) && GetEntityMoveType(entity) != MOVETYPE_NONE && !IsVictimState(entity))
		{
			if (GetEntityFlags(entity) & FL_ONGROUND)
			{
				sClientData[client].InJump = false;
				sClientData[client].HudTimeLoad = 0.0;
				
				if (IsPlayerAnimation(client, false) && IsPlayerAnimation(entity, false))
				{
					if (SetPlayerSequence(client, "Melee_Pounce")) // NamVet_Pounced_start
					{
						int knife = GetPlayerWeaponSlot(entity, 2);
						if (knife != -1)
						{
							char classname[NORMAL_LINE_LENGTH];
							GetEntityClassname(knife, classname, sizeof(classname));
							FakeClientCommand(entity, "use %s", classname);
						}
					
						SetPlayerSequence(entity, "NamVet_Pounced_loop");
						OnHandleAnimEvent(client, Hook_HandleAnimEvent);
						SetVictimState(entity, 3);
						
						sClientData[client].Pounced = true; 
						sClientData[entity].AttackHuman = true;
						sClientData[entity].Target[0] = GetClientSerial(client); // OwnerHuman
						sClientData[client].Target[1] = GetClientSerial(entity); // OwnerZombie
						
						float ang[3];
						GetVectorAngles(sClientData[client].Pounce, ang);
						
						ang[0] = 0.0; ang[2] = 0.0;
						TeleportEntity(GetEntitySequence(client), NULL_VECTOR, ang, NULL_VECTOR);
						ang[1] += 180.0;
						TeleportEntity(GetEntitySequence(entity), NULL_VECTOR, ang, NULL_VECTOR);
						
						CalcPosition(client, entity);
					}
				}
				
				SDKUnhook(client, SDKHook_StartTouch, Hook_Touch);
			}
			return Plugin_Continue;
		}
	
		if (IsValidEntity(entity) && Phys_IsPhysicsObject(entity) && GetEntityMoveType(entity) != MOVETYPE_NONE)
		{
			static char classname[NORMAL_LINE_LENGTH];
			GetEdictClassname(entity, classname, sizeof(classname));
			
			if (StrContains(classname, "prop_physics") > -1)
			{
				static float angles[3], velocity[3];
				GetClientAbsAngles(client, angles);
				GetAngleVectors(angles, velocity, NULL_VECTOR, NULL_VECTOR);
				NormalizeVector(velocity, velocity);
				ScaleVector(velocity, 7000.0 + (Phys_GetMass(entity) <= 350.0 ? Phys_GetMass(entity) * 60.0 : Phys_GetMass(entity) * 130.0));
				Phys_ApplyForceCenter(entity, velocity);
				
				sClientData[client].InJump = false;
				sClientData[client].HudTimeLoad = 0.0;
				RequestFrame(Frame_InJump, client);
				
				ZM_SetWeaponAnimation(client, 0);
				
				for (int i = 0; i < sizeof(g_AttackmixSounds); i++) {
					StopSound(client, SNDCHAN_AUTO, g_AttackmixSounds[i][6]);
				}
				EmitSoundToAll(SOUND_SMOKER_POUNCEHIT, client);
				SDKUnhook(client, SDKHook_StartTouch, Hook_Touch);

				return Plugin_Continue;
			}
		}
		
		if (GetEntityFlags(client) & FL_ONGROUND)
		{
			sClientData[client].InJump = false;
			sClientData[client].HudTimeLoad = 0.0;
			ZM_SetWeaponAnimation(client, 0);
			
			for (int i = 0; i < sizeof(g_AttackmixSounds); i++) {
				StopSound(client, SNDCHAN_AUTO, g_AttackmixSounds[i][6]);
			}
			EmitSoundToAll(SOUND_SMOKER_POUNCEHIT, client);
			
			RequestFrame(Frame_InJump, client);
			SDKUnhook(client, SDKHook_StartTouch, Hook_Touch);
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
			case 902:
			{
				SetPlayerSequence(client, "0");
			}
			case 804:
			{
				int target = GetClientFromSerial(sClientData[client].Target[1]);
				
				if (target == 0)
				{
					return MRES_Ignored;
				}
				
				// float origin[3];
				// GetClientEyePosition(target, origin);
				
				int rand = GetRandomInt(0, sizeof(g_AttackHitSounds)-1);
				EmitSoundToAll(g_AttackHitSounds[rand][6], target);
				
				// int effect = UTIL_CreateParticle(_, _, "blood_impact_red_01", origin);
				// SetVariantString("!activator");
				// AcceptEntityInput(effect, "SetParent", target, effect);
				// SetVariantString("forward");
				// AcceptEntityInput(effect, "SetParentAttachment", target, effect);
				// UTIL_RemoveEntity(effect, 0.3);
				
				// ZM_TakeDamage(target, client, client, GetRandomFloat(1.0, 5.0), DMG_BULLET);
				
				if (!UTIL_DamageArmor(target, GetRandomInt(1, 5)))
				{
					SDKHooks_TakeDamage(target, client, client, GetRandomFloat(1.0, 5.0), DMG_BULLET);
				}
			}
		}
	}
	return MRES_Ignored;
}

public void OnClientBreakSkill(int client)
{
	int target = GetClientFromSerial(sClientData[client].Target[0]);
	
	if (target != 0)
	{
		SetPlayerSequence(target, "0");
		SetPlayerSequence(client, "NamVet_Pounced_end");
		sClientData[client].Target[0] = 0;
	}
}

void CalcPosition(int client, int client2)
{
	float m_fPos[3], fwd[3], right[3], ang[3];
	
	GetVectorAngles(sClientData[client].Pounce, ang);
	GetAngleVectors(ang, fwd, right, m_fPos);
	
	GetClientAbsOrigin(client2, m_fPos);
	
	m_fPos[0] = m_fPos[0] + fwd[0] * 15.0 + right[0] * -12.0;
	m_fPos[1] = m_fPos[1] + fwd[1] * 15.0 + right[1] * -12.0;
	m_fPos[2] = m_fPos[2] + fwd[2] * 15.0 + right[2] * -12.0;
	
	TeleportEntity(GetEntitySequence(client), m_fPos, NULL_VECTOR, NULL_VECTOR);// skin
	// TeleportEntity(client, m_fPos, NULL_VECTOR, NULL_VECTOR);// skin
}

public void OnResetPlayerSequence(int client, bool player)
{
	if (IsValidClient(client))
	{
		if (sClientData[client].ZombieClass)
		{
			sClientData[client].Pounced = false;
			sClientData[client].HudTimeLoad = 0.0;
			
			int target = GetClientFromSerial(sClientData[client].Target[1]);
			if (target != 0 && IsPlayerAlive(target) && ZM_IsClientHuman(target))
			{
				SetVictimState(target, 0);
				SetPlayerSequence(target, "NamVet_Pounced_end");
				sClientData[client].Target[1] = 0;
			}
		}
		
		if (sClientData[client].AttackHuman)
		{
			int target = GetClientFromSerial(sClientData[client].Target[0]);
			if (target != 0 && ZM_IsClientZombie(target))
			{
				SetPlayerSequence(target, "Melee_pounce_Knockoff_Backward");
				sClientData[target].Pounced = false;
				sClientData[client].Target[0] = 0;
			}
			
			sClientData[client].AttackHuman = false;
		}
	}
}

public void Frame_InJump(int client)
{
	if (IsValidClient(client))
	{
		static float velocity[3];
		GetEntDataVector(client, sServerData.m_vecVelocityOffset, velocity);
		
		int rand = GetRandomInt(0, sizeof(g_LungeSounds)-1);
		EmitSoundToAll(g_LungeSounds[rand][6], client);
			
		velocity[0] = 0.0, velocity[1] = 0.0, velocity[2] = 0.0;
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
		SetEntDataVector(client, sServerData.m_vecVelocityOffset, velocity);
	}
}

void GetAimOrigin(int client, float origin[3])
{
	float pos[3], ang[3];
	GetClientEyePosition(client, pos);
	GetClientEyeAngles(client, ang);

	Handle trace = TR_TraceRayFilterEx(pos, ang, MASK_SHOT, RayType_Infinite, TraceEntityFilter);
	if (TR_DidHit(trace)) TR_GetEndPosition(origin, trace);
	delete trace;
}

public bool TraceEntityFilter(int entity, int contentsMask) 
{
    return (entity == 0 || entity > MaxClients);
}

public void ZM_OnClientUpdated(int client, int attacker)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		if (sClientData[client].ZombieClass)
		{
			ClearSyncHud(client, ZM_GetHudSync());
			OnClientDisconnect_Post(client);
		}
	
		if (ZM_GetClientClass(client) == m_Zombie)
		{
			sClientData[client].Cooldown = CLASS_HUNTER_COOLDOWN;
			sClientData[client].ZombieClass = true;
			
			int rand = GetRandomInt(0, sizeof(g_WarnSounds)-1);
			EmitSoundToAll(g_WarnSounds[rand][6], client);
			
			SDKHook(client, SDKHook_PostThinkPost, Hook_PostThinkPost);
		}
	}
}

public void Hook_PostThinkPost(int client)
{
	if (IsValidClient(client) && sClientData[client].ZombieClass)
	{
		if (!IsPlayerAlive(client) || !ZM_IsClientZombie(client))
		{
			SDKUnhook(client, SDKHook_PostThinkPost, Hook_PostThinkPost);
			return;
		}
		
		float time = GetGameTime();
		if (sClientData[client].HudTimeLoad <= time)
		{
			if (sClientData[client].Pounced == true)
			{
				int target = GetClientFromSerial(sClientData[client].Target[1]);
				if (target != 0 && IsValidClient(target))
				{
					if (sClientData[target].HumanScream <= time)
					{
						sClientData[target].HumanScream = time + GetRandomFloat(0.8, 1.6);
						
						if (ZM_GetClassGetGender(ZM_GetClientClass(target)) || ZM_GetSkinsGender(ZM_GetClientSkin(target)))
						{
							int rand = GetRandomInt(0, sizeof(g_PouncefSounds)-1);
							EmitSoundToAll(g_PouncefSounds[rand][6], target);
						}
						else
						{
							int rand = GetRandomInt(0, sizeof(g_PounceSounds)-1);
							EmitSoundToAll(g_PounceSounds[rand][6], target);
						}
					}
				}
				
				// if (sClientData[client].LastPounce <= time)
				// {
				// 	sClientData[client].LastPounce = time + GetRandomFloat(0.15, 0.35);
				// 	int rand = GetRandomInt(0, sizeof(g_ShredSounds)-1);
				// 	EmitSoundToAll(g_ShredSounds[rand][6], client);
				// }
				return;
			}
		
			if (sClientData[client].InJump == true)
			{
				sClientData[client].HudTimeLoad = time + 1.0;
				SetHudTextParams(-1.0, -0.20, 1.1, 	255, 255, 255, 255, 0, 1.0, 0.05, 0.5);
				PrintText(client, 1, ZM_GetHudSync(), "%T", "ZOMBIE_CLASS_HUNTER_HUD_INJUMP", client);
				return;
			}
		
			if (sClientData[client].Stalk == true)
			{
				if (sClientData[client].CooldownSkill <= 0.0)
				{
					sClientData[client].HudTimeLoad = time + 1.0;
					SetHudTextParams(-1.0, -0.20, 1.1, 	255, 255, 255, 255, 0, 1.0, 0.05, 0.5);
				
					if (sClientData[client].PlayerCanUse == true)
						PrintText(client, 1, ZM_GetHudSync(), "%T", "ZOMBIE_CLASS_HUNTER_HUD_BUTTON2", client); // ShowSyncHudText(client, ZM_GetHudSync(), "%t", "ZOMBIE_CLASS_HUNTER_HUD_BUTTON2");
					else PrintText(client, 1, ZM_GetHudSync(), "%T", "ZOMBIE_CLASS_HUNTER_HUD_NONE", client); // ShowSyncHudText(client, ZM_GetHudSync(), "%t", "ZOMBIE_CLASS_HUNTER_HUD_NONE");
					return;
				}
			
				sClientData[client].HudTimeLoad = time + 0.2;
				int r = RoundToCeil((255.0/CLASS_HUNTER_COOLDOWN_USESKILL) * sClientData[client].CooldownSkill);
				SetHudTextParams(-1.0, -0.20, 0.3, r, 255-r, 255, 255, 0, 1.0, 0.05, 0.5);
				PrintText(client, 1, ZM_GetHudSync(), "%T", "ZOMBIE_CLASS_HUNTER_HUD_COOLDOWN_USESKILL", client, sClientData[client].CooldownSkill);
				
				sClientData[client].CooldownSkill -= 0.1;
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
			
				if (sClientData[client].PlayerCanUse == true)
					PrintText(client, 1, ZM_GetHudSync(), "%T", "ZOMBIE_CLASS_HUNTER_HUD_BUTTON1", client); // ShowSyncHudText(client, ZM_GetHudSync(), "%t", "ZOMBIE_CLASS_HUNTER_HUD_BUTTON1");
				else PrintText(client, 1, ZM_GetHudSync(), "%T", "ZOMBIE_CLASS_HUNTER_HUD_NONE", client); // ShowSyncHudText(client, ZM_GetHudSync(), "%t", "ZOMBIE_CLASS_HUNTER_HUD_NONE");
				return;
			}
			
			sClientData[client].HudTimeLoad = time + 0.2;
			int r = RoundToCeil((255.0/CLASS_HUNTER_COOLDOWN) * sClientData[client].Cooldown);
			SetHudTextParams(-1.0, -0.20, 0.3, r, 255-r, 255, 255, 0, 1.0, 0.05, 0.5);
			PrintText(client, 1, ZM_GetHudSync(), "%T", "ZOMBIE_CLASS_HUNTER_HUD_COOLDOWN", client, sClientData[client].Cooldown);
			
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

stock void SetWeaponNextAttack(int weapon, float t = 0.0)
{
	if (IsValidEntity(weapon))
	{
		float time = GetGameTime() + t;
		SetEntDataFloat(weapon, sServerData.flNextPrimaryAttack, time);
		SetEntDataFloat(weapon, sServerData.flNextSecondaryAttack, time);
		ChangeEdictState(weapon);
	}
}

void InitSendPropOffset(int &offsetDest, const char[] serverClass, const char[] propName)
{
	if ((offsetDest = FindSendPropInfo(serverClass, propName)) == -1)
	{
		SetFailState("Failed to find offset: \"%s\"!", propName);
	}
}