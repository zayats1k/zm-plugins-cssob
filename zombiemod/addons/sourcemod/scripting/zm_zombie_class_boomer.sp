#include <zombiemod>
#include <zm_player_animation>
#include <zm_settings>
#include <shop_system>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name = "[ZM] Zombie Class: Boomer",
	author = "0kEmo",
	version = "3.0"
};

#define CLASS_BOOMER_COOLDOWN 35.0

#define SOUND_BOOMER_BV1 "zombie-plague/hero/boomer/bv1.wav"

static const char g_model[][] = {
	"models/zschool/rustambadr/boomer/hand/v_claw_boomer_fix.dx80.vtx",
	"models/zschool/rustambadr/boomer/hand/v_claw_boomer_fix.dx90.vtx",
	"models/zschool/rustambadr/boomer/hand/v_claw_boomer_fix.mdl",
	"models/zschool/rustambadr/boomer/hand/v_claw_boomer_fix.sw.vtx",
	"models/zschool/rustambadr/boomer/hand/v_claw_boomer_fix.vvd",
	"models/zschool/rustambadr/boomer/boomer.dx80.vtx",
	"models/zschool/rustambadr/boomer/boomer.dx90.vtx",
	"models/zschool/rustambadr/boomer/boomer.mdl",
	"models/zschool/rustambadr/boomer/boomer.phy",
	"models/zschool/rustambadr/boomer/boomer.sw.vtx",
	"models/zschool/rustambadr/boomer/boomer.vvd",
	"materials/models/zschool/rustambadr/boomer/hand/v_boomer_hands.vmt",
	"materials/models/zschool/rustambadr/boomer/hand/v_boomer_hands.vtf",
	"materials/models/zschool/rustambadr/boomer/hand/v_boomer_hands_normal.vtf",
	"materials/models/zschool/rustambadr/boomer/boomer.vmt",
	"materials/models/zschool/rustambadr/boomer/boomer.vtf",
	"materials/models/zschool/rustambadr/boomer/boomer_color.vtf",
	"materials/models/zschool/rustambadr/boomer/boomer_hair.vmt",
	"materials/models/zschool/rustambadr/boomer/boomer_hair.vtf",
	"materials/models/zschool/rustambadr/boomer/boomer_normal.vtf"
};

static const char g_AlertSounds[5][] = {
	"sound/zombie-plague/hero/boomer/male_boomer_alert_07.wav",
	"sound/zombie-plague/hero/boomer/male_boomer_alert_10.wav",
	"sound/zombie-plague/hero/boomer/male_boomer_alert_11.wav",
	"sound/zombie-plague/hero/boomer/male_boomer_alert_12.wav",
	"sound/zombie-plague/hero/boomer/male_boomer_alert_13.wav"
};

static const char g_ReactionBoomerSounds[2][] = {
	"sound/zombie-plague/human/boomerreaction01.wav",
	"sound/zombie-plague/human/boomerreaction05.wav"
};

static const char g_ReactionBoomerfSounds[4][] = {
	"sound/zombie-plague/human/f/boomerreaction02.wav",
	"sound/zombie-plague/human/f/boomerreaction03.wav",
	"sound/zombie-plague/human/f/boomerreaction04.wav",
	"sound/zombie-plague/human/f/boomerreaction05.wav"
};

int m_Zombie;

enum struct ServerData
{
	int OwnerEntityOffset;
	
	void Clear()
	{
		this.OwnerEntityOffset = -1;
	}
}
ServerData sServerData;

enum struct ClientData
{
	bool ZombieClass;
	bool PlayerCanUse;
	bool UseSkill;
	
	float Cooldown;
	float HudTimeLoad;
	float fLastWarn;
	float NextFlame;
	float DamageVomit;
	float BotUse;
	
	void Clear()
	{
		this.ZombieClass = false;
		this.PlayerCanUse = false;
		this.UseSkill = false;
		this.Cooldown = 0.0;
		this.HudTimeLoad = 0.0;
		this.fLastWarn = 0.0;
		this.NextFlame = 0.0;
		this.DamageVomit = 0.0;
		this.BotUse = 0.0;
	}
}
ClientData sClientData[MAXPLAYERS+1];

public void OnPluginStart()
{
	LoadTranslations("zm_class.phrases");
	
	sServerData.OwnerEntityOffset = FindSendPropInfo("CBaseEntity", "m_hOwnerEntity");
	
	HookEvent("player_death", Event_PlayerDeath);
}

public void OnPluginEnd()
{
	sServerData.Clear();
	UnhookEvent("player_death", Event_PlayerDeath);
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
	m_Zombie = ZM_GetClassNameID("zombie_boomer");
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

	PrecacheScriptSound("explode_5");
	
	AddFileToDownloadsTable("sound/" ... SOUND_BOOMER_BV1);
	PrecacheSound(SOUND_BOOMER_BV1);
	
	PrecacheModel("models/gibs/hgibs.mdl", true);
	PrecacheModel("models/gibs/hgibs_rib.mdl", true);
	PrecacheModel("models/gibs/hgibs_scapula.mdl", true);
	PrecacheModel("models/gibs/hgibs_spine.mdl", true);
	
	for (int i = 0; i < sizeof(g_AlertSounds); i++)
	{
		AddFileToDownloadsTable(g_AlertSounds[i]);
		PrecacheSound(g_AlertSounds[i][6]);
	}
	
	for (int i = 0; i < sizeof(g_ReactionBoomerSounds); i++)
	{
		AddFileToDownloadsTable(g_ReactionBoomerSounds[i]);
		PrecacheSound(g_ReactionBoomerSounds[i][6]);
	}
	
	for (int i = 0; i < sizeof(g_ReactionBoomerfSounds); i++)
	{
		AddFileToDownloadsTable(g_ReactionBoomerfSounds[i]);
		PrecacheSound(g_ReactionBoomerfSounds[i][6]);
	}
}

public void OnClientDisconnect_Post(int client)
{
	sClientData[client].Clear();
	
	SDKUnhook(client, SDKHook_PostThink, Hook_PostThink);
	SDKUnhook(client, SDKHook_PostThinkPost, Hook_PostThinkPost);
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (!ZM_IsEndRound())
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
		
		if (IsValidClient(client) && sClientData[client].ZombieClass)
		{
			if (sClientData[client].UseSkill)
			{
				float origin[3], Origin2[3];
				GetClientAbsOrigin(client, origin); origin[2] -= 5.0;
				
				TE_DynamicLight(origin, 255, 0, 0, 2, 700.0, 0.55, 768.0);
				TE_SendToAll();
				
				UTIL_CreateParticle(-2, "nw_boomer_", "boomer_explode", origin, true);
				UTIL_ScreenShake(origin, 200.0, 1.5, 1.0, 250.0, 0, false);
				UTIL_CreatePhysExplosion(origin, 180.0, 180.0);
				
				EmitGameSoundToAll("explode_5", client);
				
				float origin2[3];
				GetClientEyePosition(client, origin2);
				
				if (GetEntProp(client, Prop_Data, "m_bitsDamageType") != DMG_SONIC)
				{
					static float vGib[3]; float vShoot[3]; 
					for (int x = 1; x <= 4; x++)
					{
						vShoot[1] += 60.0; vGib[0] = GetRandomFloat(0.0, 360.0); vGib[1] = GetRandomFloat(-15.0, 15.0); vGib[2] = GetRandomFloat(-15.0, 15.0); 
						switch (x)
						{
							case 1 : UTIL_CreateShooter(client, "models/gibs/hgibs.mdl", origin2, vShoot, vGib, 1.0, 0.05, 500.0, 1.0, 10.0);
							case 2 : UTIL_CreateShooter(client, "models/gibs/hgibs_rib.mdl", origin2, vShoot, vGib, 1.0, 0.05, 500.0, 1.0, 10.0);
							case 3 : UTIL_CreateShooter(client, "models/gibs/hgibs_scapula.mdl", origin2, vShoot, vGib, 1.0, 0.05, 500.0, 1.0, 10.0);
							case 4 : UTIL_CreateShooter(client, "models/gibs/hgibs_spine.mdl", origin2, vShoot, vGib, 1.0, 0.05, 500.0, 1.0, 10.0);
						}
					}
				}
				
				for (int i = 1; i <= MaxClients; i++)
				{
					if (IsValidClient(i) && IsPlayerAlive(i))
					{
						GetClientEyePosition(i, Origin2); Origin2[2] -= 18.0;
						if (GetVectorDistance(origin, Origin2) <= 160)
						{
							if (ZM_IsClientHuman(i))
							{
								if (!UTIL_IsAbleToSee2(Origin2, client, MASK_SOLID))
								{
									continue;
								}
								
								if (!UTIL_DamageArmor(i, RoundToCeil(GetRandomFloat(15.0, 30.0) * (GetClientSkill(client, 1) + 1.0))))
								{
									SDKHooks_TakeDamage(i, client, client, GetRandomFloat(15.0, 30.0) * (GetClientSkill(client, 1) + 1.0), DMG_BULLET);
								}
								
								UTIL_ScreenFade(i, 5.0, 0.1, FFADE_IN, {150, 150, 80, 200});
							}
						}
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
			
			ClearSyncHud(client, ZM_GetHudSync());
			OnClientDisconnect_Post(client);
		}
	}
	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3])
{
	if (IsValidClient(client) && IsPlayerAlive(client) && ZM_IsClientZombie(client)	&& sClientData[client].ZombieClass)
	{
		if (sClientData[client].Cooldown <= 0.0)
		{
			static int iOldButton[MAXPLAYERS+1];
			
			if (GetEntityFlags(client) & FL_ONGROUND && vel[0] == 0.0 && vel[1] == 0.0 && vel[2] == 0.0)
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
					sClientData[client].HudTimeLoad = 0.0;
					sClientData[client].PlayerCanUse = false;
				}
			}
			
			if (IsFakeClient(client))
			{
				if (GetEntityFlags(client) & FL_ONGROUND)
				{
					float time = GetGameTime();
					
					if (sClientData[client].BotUse < time)
					{
						sClientData[client].BotUse = time + GetRandomFloat(2.0, 1.0);
						
						float origin[3]; bool use = false;
						for (int i = 1; i <= MaxClients; i++)
						{
							if (IsValidClient(i) && IsPlayerAlive(i) && ZM_IsClientHuman(i))
							{
								GetClientAbsOrigin(i, origin);
								
								if (!UTIL_IsAbleToSee2(origin, client, MASK_SOLID))
								{
									continue;
								}
								
								if (IsTargetInSightRange(origin, client, 25.0, 200.0))
								{
									use = true;
								}
							}
						}
						
						if (use == true)
						{
							buttons |= IN_ATTACK2;
						}
					}
				}
			}
			
			if (buttons & IN_ATTACK2 && !(iOldButton[client] & IN_ATTACK2))
			{
				if (sClientData[client].Cooldown == RoundToFloor(-1.0))
				{
					return Plugin_Continue;
				}
				
				if (GetEntProp(client, Prop_Data, "m_nWaterLevel") > 1 || ZM_IsEndRound())
				{
					return Plugin_Continue;
				}
				
				if (IsFakeClient(client))
				{
					if (!SetPlayerSequence(client, IsPlayerAnimation(client, true) ? "Idle_STAND_VOMIT":"Idle_CROUSH_VOMIT"))
					{
						return Plugin_Continue;
					}
					
					for (int i = 0; i < sizeof(g_AlertSounds); i++)
					{
						StopSound(client, SNDCHAN_AUTO, g_AlertSounds[i][6]);
					}
					
					EmitSoundToAll(SOUND_BOOMER_BV1, client);
					
					OnHandleAnimEvent(client, Hook_HandleAnimEvent);
					
					SDKHook(client, SDKHook_PostThink, Hook_PostThink);
					
					sClientData[client].UseSkill = false;
					sClientData[client].Cooldown = -1.0;
					return Plugin_Continue;
				}
				
				if (sClientData[client].PlayerCanUse)
				{
					if (!SetPlayerSequence(client, IsPlayerAnimation(client, true) ? "Idle_STAND_VOMIT":"Idle_CROUSH_VOMIT"))
					{
						return Plugin_Continue;
					}
					
					for (int i = 0; i < sizeof(g_AlertSounds); i++)
					{
						StopSound(client, SNDCHAN_AUTO, g_AlertSounds[i][6]);
					}
					
					EmitSoundToAll(SOUND_BOOMER_BV1, client);
					
					OnHandleAnimEvent(client, Hook_HandleAnimEvent);
					
					SDKHook(client, SDKHook_PostThink, Hook_PostThink);
					
					sClientData[client].UseSkill = false;
					sClientData[client].Cooldown = -1.0;
					sClientData[client].HudTimeLoad = 0.0;
				}
			}
			
			iOldButton[client] = buttons;
		}
	}
	return Plugin_Continue;
}

public void Hook_PostThink(int client)
{
	if (IsValidClient(client) && sClientData[client].ZombieClass)
	{
		if (ZM_IsEndRound() || !IsPlayerAlive(client) || !ZM_IsClientZombie(client))
		{
			SDKUnhook(client, SDKHook_PostThink, Hook_PostThink);
			return;
		}
		
		if (!sClientData[client].UseSkill)
		{
			return;
		}
		
		float time = GetGameTime();
		if (sClientData[client].NextFlame < time)
		{
			sClientData[client].NextFlame = time + 0.15;
			
			float origin[3];
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsValidClient(i) && IsPlayerAlive(i) && ZM_IsClientHuman(i))
				{
					GetClientAbsOrigin(i, origin);
					
					if (!UTIL_IsAbleToSee2(origin, client, MASK_SOLID))
					{
						continue;
					}
					
					if (IsTargetInSightRange(origin, GetEntitySequence(client), 60.0, 350.0))
					{
						if (sClientData[i].DamageVomit < time)
						{
							// int effect = UTIL_CreateParticle(_, _, "blood_antlionguard_injured_heavy", origin);
							// SetVariantString("!activator");
							// AcceptEntityInput(effect, "SetParent", i, effect);
						
							sClientData[i].DamageVomit = time + 5.0;
							
							if (ZM_GetClassGetGender(ZM_GetClientClass(i)) || ZM_GetSkinsGender(ZM_GetClientSkin(i)))
							{
								int rand = GetRandomInt(0, sizeof(g_ReactionBoomerfSounds)-1);
								EmitSoundToAll(g_ReactionBoomerfSounds[rand][6], i);
							}
							else
							{
								int rand = GetRandomInt(0, sizeof(g_ReactionBoomerSounds)-1);
								EmitSoundToAll(g_ReactionBoomerSounds[rand][6], i);
							}
						}
						
						if (!UTIL_DamageArmor(i, RoundToCeil(GetRandomFloat(1.0, 2.0) * (GetClientSkill(client, 1) + 1.5))))
						{
							SDKHooks_TakeDamage(i, client, client, GetRandomFloat(1.0, 2.0) * (GetClientSkill(client, 0) + 1.5), DMG_BULLET);
						}
						
						UTIL_ScreenFade(i, 2.0, 0.1, FFADE_IN, {150, 150, 80, 200});
					}
				}
			}
		}
	}
}

public void OnResetPlayerSequence(int client, bool player)
{
	if (player == true)
	{
		if (IsValidClient(client) && sClientData[client].ZombieClass)
		{
			SDKUnhook(client, SDKHook_PostThink, Hook_PostThink);
			sClientData[client].Cooldown = CLASS_BOOMER_COOLDOWN;
			sClientData[client].HudTimeLoad = 0.0;
		}
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
			case 901:
			{
				sClientData[client].UseSkill = true;
				float origin[3];
				GetEntPropVector(GetEntitySequence(client), Prop_Send, "m_vecOrigin", origin);
				int effect = UTIL_CreateParticle(_, _, "boomer_mouth", origin);
				
				SetVariantString("!activator");
				AcceptEntityInput(effect, "SetParent", GetEntitySequence(client), effect);
				SetVariantString("mouth");
				AcceptEntityInput(effect, "SetParentAttachment", effect, effect);
			}
			// case 902:
			// {
			// 	sClientData[client].UseSkill = false;
			// 	SDKUnhook(client, SDKHook_PostThink, Hook_PostThink);
			// }
			default:
			{
				if (sClientData[client].UseSkill == true)
				{
					SDKUnhook(client, SDKHook_PostThink, Hook_PostThink);
					sClientData[client].UseSkill = false;
					sClientData[client].HudTimeLoad = 0.0;
				}
			}
		}
	}
	return MRES_Ignored;
}

public void ZM_OnClientUpdated(int client, int attacker)
{
	if (IsValidClient(client))
	{
		if (sClientData[client].ZombieClass)
		{
			ClearSyncHud(client, ZM_GetHudSync());
			OnClientDisconnect_Post(client);
		}
	
		if (ZM_GetClientClass(client) == m_Zombie)
		{
			sClientData[client].UseSkill = false;
			sClientData[client].ZombieClass = true;
			sClientData[client].Cooldown = CLASS_BOOMER_COOLDOWN;
			
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
			if (sClientData[client].UseSkill)
			{
				sClientData[client].HudTimeLoad = time + 1.0;
				SetHudTextParams(-1.0, -0.20, 1.1, 	255, 255, 255, 255, 0, 1.0, 0.05, 0.5);
				PrintText(client, 1, ZM_GetHudSync(), "%T", "ZOMBIE_CLASS_BOOMER_HUD_USESKILL", client); // ShowSyncHudText(client, ZM_GetHudSync(), "%t", "ZOMBIE_CLASS_BOOMER_HUD_USESKILL");
				return;
			}
		
			if (sClientData[client].Cooldown == -1.0)
			{
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
				
				if (sClientData[client].fLastWarn <= time)
				{
					sClientData[client].fLastWarn = time + GetRandomFloat(2.0, 3.5);
					int rand = GetRandomInt(0, sizeof(g_AlertSounds)-1);
					EmitSoundToAll(g_AlertSounds[rand][6], client);
				}
				
				if (sClientData[client].PlayerCanUse)
				{
					PrintText(client, 1, ZM_GetHudSync(), "%T", "ZOMBIE_CLASS_BOOMER_HUD_BUTTON", client); // ShowSyncHudText(client, ZM_GetHudSync(), "%t", "ZOMBIE_CLASS_BOOMER_HUD_BUTTON");
				}
				else
				{
					PrintText(client, 1, ZM_GetHudSync(), "%T", "ZOMBIE_CLASS_BOOMER_HUD_NONE", client); // ShowSyncHudText(client, ZM_GetHudSync(), "%t", "ZOMBIE_CLASS_BOOMER_HUD_NONE");
				}
				return;
			}
			
			sClientData[client].HudTimeLoad = time + 0.2;
			int r = RoundToCeil((255.0/CLASS_BOOMER_COOLDOWN) * sClientData[client].Cooldown);
			SetHudTextParams(-1.0, -0.20, 0.3, r, 255-r, 255, 255, 0, 1.0, 0.05, 0.5);
			PrintText(client, 1, ZM_GetHudSync(), "%T", "ZOMBIE_CLASS_BOOMER_HUD_COOLDOWN", client, sClientData[client].Cooldown); // ShowSyncHudText(client, ZM_GetHudSync(), "%t", "ZOMBIE_CLASS_BOOMER_HUD_COOLDOWN", sClientData[client].Cooldown);
			
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

stock bool IsTargetInSightRange(float origin[3], int ent, float angle = 90.0, float distance = 0.0)
{
	if (angle > 360.0) angle = 360.0;
	if (angle < 0.0) return false;
	
	float pos[3], anglevector[3], targetvector[3];
	float resultdistance;
	
	GetEntPropVector(ent, Prop_Data, "m_vecAbsOrigin", pos);
	GetEntPropVector(ent, Prop_Data, "m_angRotation", anglevector);
	
	// anglevector[0] = anglevector[2] = 0.0;
	GetAngleVectors(anglevector, anglevector, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(anglevector, anglevector);
	
	resultdistance = GetVectorDistance(pos, origin);
	
	pos[2] = origin[2] = 0.0;
	MakeVectorFromPoints(pos, origin, targetvector);
	NormalizeVector(targetvector, targetvector);
	
	if (RadToDeg(ArcCosine(GetVectorDotProduct(targetvector, anglevector))) <= angle / 2)
	{
		if (distance > 0)
		{
			if (distance >= resultdistance) return true;
			else return false;
		}
		else return true;
	}
	return false;
}