#include <zombiemod>
#include <zm_settings>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name = "[ZM] Zombie Class: Invisible",
	author = "0kEmo",
	version = "1.0"
};

#define CLASS_INVISIBLE_COOLDOWN 4.0
#define CLASS_INVISIBLE_COOLDOWN_USESKILL 10.0

#define SOUND_INVISIBLE_ABILITY "zombie-plague/hero/fantom/fantom_ability.wav"
#define SOUND_INVISIBLE_UNABILITY "zombie-plague/hero/fantom/fantom_unability.wav"

static const char g_model[][] = {
	"models/zschool/rustambadr/normal_f/hand/hand_zombie_normal_f.dx80.vtx",
	"models/zschool/rustambadr/normal_f/hand/hand_zombie_normal_f.dx90.vtx",
	"models/zschool/rustambadr/normal_f/hand/hand_zombie_normal_f.mdl",
	"models/zschool/rustambadr/normal_f/hand/hand_zombie_normal_f.sw.vtx",
	"models/zschool/rustambadr/normal_f/hand/hand_zombie_normal_f.vvd",
	"models/zschool/rustambadr/normal_f/zombie_normal_f.dx80.vtx",
	"models/zschool/rustambadr/normal_f/zombie_normal_f.dx90.vtx",
	"models/zschool/rustambadr/normal_f/zombie_normal_f.mdl",
	"models/zschool/rustambadr/normal_f/zombie_normal_f.phy",
	"models/zschool/rustambadr/normal_f/zombie_normal_f.sw.vtx",
	"models/zschool/rustambadr/normal_f/zombie_normal_f.vvd",
	"materials/models/zschool/rustambadr/normal_f/hand/normal_f_hand.vmt",
	"materials/models/zschool/rustambadr/normal_f/normal_f_body.vmt",
	"materials/models/zschool/rustambadr/normal_f/normal_f_body.vtf",
	"materials/models/zschool/rustambadr/normal_f/normal_f_body_normal.vtf",
	"materials/models/zschool/rustambadr/normal_f/normal_f_hair.vmt",
	"materials/models/zschool/rustambadr/normal_f/normal_f_hair.vtf",
	"materials/models/zschool/rustambadr/normal_f/normal_f_hair_normal.vtf",
	"materials/models/zschool/rustambadr/normal_f/normal_f_hand.vmt",
	"materials/models/zschool/rustambadr/normal_f/normal_f_hand.vtf",
	"materials/models/zschool/rustambadr/normal_f/normal_f_hand_normal.vtf"
};

int m_Zombie;

enum struct ServerData
{
	int OwnerEntityOffset;
	int hActiveWeaponOffset;
	int flNextPrimaryAttack;
	int flNextSecondaryAttack;
	
	void Clear()
	{
		this.OwnerEntityOffset = -1;
		this.hActiveWeaponOffset = -1;
		this.flNextPrimaryAttack = -1;
		this.flNextSecondaryAttack = -1;
	}
}
ServerData sServerData;

enum struct ClientData
{
	bool ZombieClass;
	bool UseSkill;
	float Cooldown;
	float HudTimeLoad;
	float BotUse;
	
	void Clear()
	{
		this.ZombieClass = false;
		this.UseSkill = false;
		this.Cooldown = 0.0;
		this.HudTimeLoad = 0.0;
		this.BotUse = 0.0;
	}
}
ClientData sClientData[MAXPLAYERS+1];

public void OnPluginStart()
{
	LoadTranslations("zm_class.phrases");
	
	sServerData.OwnerEntityOffset = FindSendPropInfo("CBaseEntity", "m_hOwnerEntity");
	sServerData.hActiveWeaponOffset = FindSendPropInfo("CCSPlayer", "m_hActiveWeapon");
	sServerData.flNextPrimaryAttack = FindSendPropInfo("CBaseCombatWeapon", "m_flNextPrimaryAttack");
	sServerData.flNextSecondaryAttack = FindSendPropInfo("CBaseCombatWeapon", "m_flNextSecondaryAttack");
	
	HookEvent("player_death", Hook_PlayerDeath);
}

public void OnPluginEnd()
{
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

	PrecacheModel("materials/models/zschool/rustambadr/other/inv_event.vmt", true);
	
	AddFileToDownloadsTable("sound/" ... SOUND_INVISIBLE_ABILITY);
	PrecacheSound(SOUND_INVISIBLE_ABILITY);
	AddFileToDownloadsTable("sound/" ... SOUND_INVISIBLE_UNABILITY);
	PrecacheSound(SOUND_INVISIBLE_UNABILITY);
}

public void OnClientDisconnect_Post(int client)
{
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
	m_Zombie = ZM_GetClassNameID("zombie_invisible");
}

public Action Hook_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (IsValidClient(client) && ZM_IsClientZombie(client) && sClientData[client].ZombieClass)
	{
		ClientCommand(client, "r_screenoverlay \"\"");
		ClearSyncHud(client, ZM_GetHudSync());
		OnClientDisconnect_Post(client);
		ZM_SetPlayerSpotted(client, true);
		
		SetPlayerColor(client, 255);
	}
	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3])
{
	if (IsValidClient(client) && IsPlayerAlive(client) && ZM_IsClientZombie(client) && sClientData[client].ZombieClass)
	{
		if (sClientData[client].UseSkill == true)
		{
			if (sClientData[client].Cooldown <= 0.0 || buttons & (IN_ATTACK|IN_ATTACK2))
			{
				SetPlayerColor(client, 255);
				ZM_SetPlayerSpotted(client, true);
				
				float origin[3]; GetClientEyePosition(client, origin);
				int effect = UTIL_CreateParticle(_, _, "fantom_unability", origin);
				SetVariantString("!activator");
				AcceptEntityInput(effect, "SetParent", client, effect);
				UTIL_RemoveEntity(effect, 0.3);
				
				ClientCommand(client, "r_screenoverlay \"\"");
				EmitSoundToAll(SOUND_INVISIBLE_UNABILITY, client);
				
				sClientData[client].UseSkill = false;
				sClientData[client].Cooldown = CLASS_INVISIBLE_COOLDOWN;
				sClientData[client].HudTimeLoad = 0.0;
				return Plugin_Continue;
			}
			
			float vel2[3]; GetEntPropVector(client, Prop_Data, "m_vecVelocity", vel2);
			int speed = RoundFloat(UTIL_VectorNormalize(vel2) * 0.19);
			if (speed > 200) speed = 140;
			else if (speed < 1) speed = 1;
			SetPlayerColor(client, speed);
			return Plugin_Continue;
		}
	
		if (sClientData[client].Cooldown <= 0.0)
		{
			static int iOldButton[MAXPLAYERS+1];
			
			if (IsFakeClient(client))
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
							
							if (IsTargetInSightRange(origin, client, 64.0, 700.0))
							{
								use = true;
							}
						}
					}
					
					if (use == true)
					{
						buttons |= IN_RELOAD;
					}
				}
			}
			
			if (buttons & IN_RELOAD && !(iOldButton[client] & IN_RELOAD))
			{
				if (sClientData[client].UseSkill == true)
				{
					return Plugin_Continue;
				}
				
				if (ZM_IsEndRound())
				{
					return Plugin_Continue;
				}
				
				SetPlayerColor(client, 1);
				ZM_SetPlayerSpotted(client, false);
				
				float origin[3]; GetClientEyePosition(client, origin);
				int effect = UTIL_CreateParticle(_, _, "fantom_ability", origin); // fantom_ability
				
				SetEntDataEnt2(effect, sServerData.OwnerEntityOffset, client);
				
				SetVariantString("!activator");
				AcceptEntityInput(effect, "SetParent", client, effect);
				UTIL_RemoveEntity(effect, 1.0);
				
				ClientCommand(client, "r_screenoverlay \"models/zschool/rustambadr/other/inv_event.vmt\"");
				EmitSoundToAll(SOUND_INVISIBLE_ABILITY, client);
				
				int ClientWeapon = GetEntDataEnt2(client, sServerData.hActiveWeaponOffset);
				if (IsValidEdict(ClientWeapon)) {
					ZM_SendWeaponAnim(ClientWeapon, ACT_VM_DRAW);
				}
				
				sClientData[client].UseSkill = true;
				sClientData[client].Cooldown = CLASS_INVISIBLE_COOLDOWN_USESKILL;
				sClientData[client].HudTimeLoad = 0.0;
			}
			
			iOldButton[client] = buttons;
		}
	}
	return Plugin_Continue;
}

public Action ZM_OnPlayFootStep(int client, const char[] sound, int channel, int level, int flags, float volume, int pitch)
{
	if (IsValidClient(client) && sClientData[client].ZombieClass && sClientData[client].UseSkill == true)
	{
		if (GetEntityFlags(client) & FL_ONGROUND)
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public void ZM_OnClientUpdated(int client, int attacker)
{
	if (IsValidClient(client))
	{
		if (sClientData[client].ZombieClass)
		{
			ClientCommand(client, "r_screenoverlay \"\"");
			ClearSyncHud(client, ZM_GetHudSync());
			OnClientDisconnect_Post(client);
			
			SetPlayerColor(client, 255);
		}
	
		if (ZM_GetClientClass(client) == m_Zombie)
		{
			sClientData[client].ZombieClass = true;
			sClientData[client].Cooldown = CLASS_INVISIBLE_COOLDOWN;
			
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
			if (sClientData[client].Cooldown <= 0.0)
			{
				sClientData[client].HudTimeLoad = time + 1.0;
				SetHudTextParams(-1.0, -0.20, 1.1, 	255, 255, 255, 255, 0, 1.0, 0.05, 0.5);
				PrintText(client, 1, ZM_GetHudSync(), "%T", "ZOMBIE_CLASS_INVISIBLE_HUD_BUTTON", client); // ShowSyncHudText(client, ZM_GetHudSync(), "%t", "ZOMBIE_CLASS_INVISIBLE_HUD_BUTTON");
				return;
			}
			
			sClientData[client].HudTimeLoad = time + 0.2;
			if (sClientData[client].UseSkill != true)
			{
				int r = RoundToCeil((255.0/CLASS_INVISIBLE_COOLDOWN) * sClientData[client].Cooldown);
				SetHudTextParams(-1.0, -0.20, 0.3, r, 255-r, 255, 255, 0, 1.0, 0.05, 0.5);
				PrintText(client, 1, ZM_GetHudSync(), "%T", "ZOMBIE_CLASS_INVISIBLE_HUD_COOLDOWN", client, sClientData[client].Cooldown); // ShowSyncHudText(client, ZM_GetHudSync(), "%t", "ZOMBIE_CLASS_INVISIBLE_HUD_COOLDOWN", sClientData[client].Cooldown);
			}
			else
			{
				int r = RoundToCeil((255.0/CLASS_INVISIBLE_COOLDOWN_USESKILL) * sClientData[client].Cooldown);
				SetHudTextParams(-1.0, -0.20, 0.3, r, 255-r, 255, 255, 0, 1.0, 0.05, 0.5);
				PrintText(client, 1, ZM_GetHudSync(), "%T", "ZOMBIE_CLASS_INVISIBLE_HUD_COOLDOWN_USESKILL", client, sClientData[client].Cooldown); // ShowSyncHudText(client, ZM_GetHudSync(), "%t", "ZOMBIE_CLASS_INVISIBLE_HUD_COOLDOWN_USESKILL", sClientData[client].Cooldown);
			}
			
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

void SetPlayerColor(int client, const int color)
{
    SetEntityRenderMode(client, (color == 255) ? RENDER_NORMAL:RENDER_TRANSCOLOR);
    SetEntityRenderColor(client, 255, 255, 255, color);
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
	if (!UTIL_IsAbleToSee2(origin, client, MASK_VISIBLE))
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