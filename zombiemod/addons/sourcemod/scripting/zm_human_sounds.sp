#include <zombiemod>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name = "[ZM] Human Sounds",
	author = "0kEmo",
	version = "2.0"
};

static const char g_GrenadeSounds[5][2][] = {
	{"sound/zombie-plague/human/grenade01.wav", 			"0.2"},
	{"sound/zombie-plague/human/grenade02.wav", 			"0.2"},
	{"sound/zombie-plague/human/grenade08.wav", 			"0.2"},
	{"sound/zombie-plague/human/grenade09.wav", 			"0.2"},
	{"sound/zombie-plague/human/grenade10.wav", 			"0.2"}
};

static const char g_GrenadefSounds[3][2][] = {
	{"sound/zombie-plague/human/f/grenade01.wav",			"0.2"},
	{"sound/zombie-plague/human/f/grenade06.wav",			"0.2"},
	{"sound/zombie-plague/human/f/grenade07.wav",			"0.2"}
};
 
static const char g_ElisReloadSounds[5][2][] = {
	{"sound/zombie-plague/human/reloadintense01.wav",		"1.0"},
	{"sound/zombie-plague/human/reloadintense02.wav",		"1.0"},
	{"sound/zombie-plague/human/reloadintense03.wav",		"1.0"},
	{"sound/zombie-plague/human/reloadintense04.wav",		"1.0"},
	{"sound/zombie-plague/human/reloadintense05.wav",		"1.0"}
};

static const char g_RochelleReloadSounds[3][2][] = {
	{"sound/zombie-plague/human/f/reloadintense01.wav",		"1.0"},
	{"sound/zombie-plague/human/f/reloadintense02.wav",		"1.0"},
	{"sound/zombie-plague/human/f/reloadintense03.wav",		"1.0"}
};

static const char g_DeathFriendSounds[7][2][] = {
	{"sound/zombie-plague/human/no09.wav",					"1.0"},
	{"sound/zombie-plague/human/no10.wav",					"1.0"},
	{"sound/zombie-plague/human/boomerreaction01.wav",		"1.0"},
	{"sound/zombie-plague/human/boomerreaction05.wav",		"1.0"},
	{"sound/zombie-plague/human/reactionnegative02.wav",	"1.0"},
	{"sound/zombie-plague/human/reactionnegative03.wav",	"1.0"},
	{"sound/zombie-plague/human/reactionnegative09.wav",	"1.0"}
};

static const char g_DeathFriendfSounds[6][2][] = {
	{"sound/zombie-plague/human/f/no05.wav",				"1.0"},
	{"sound/zombie-plague/human/f/no09.wav",				"1.0"},
	{"sound/zombie-plague/human/f/boomerreaction02.wav",	"1.0"},
	{"sound/zombie-plague/human/f/boomerreaction03.wav",	"1.0"},
	{"sound/zombie-plague/human/f/boomerreaction04.wav",	"1.0"},
	{"sound/zombie-plague/human/f/boomerreaction05.wav",	"1.0"}
};

static const char g_SuicideSounds[6][2][] = {
	{"sound/zombie-plague/human/friendlyfire03.wav",				"1.0"},
	{"sound/zombie-plague/human/friendlyfire05.wav",				"1.0"},
	{"sound/zombie-plague/human/friendlyfire09.wav",				"1.0"},
	{"sound/zombie-plague/human/friendlyfire16.wav",				"1.0"},
	{"sound/zombie-plague/human/friendlyfire17.wav",				"1.0"},
	{"sound/zombie-plague/human/friendlyfire33.wav",				"1.0"}
};

static const char g_SuicidefSounds[6][2][] = {
	{"sound/zombie-plague/human/f/friendlyfire01.wav",			"1.0"},
	{"sound/zombie-plague/human/f/friendlyfire03.wav",			"1.0"},
	{"sound/zombie-plague/human/f/friendlyfire04.wav",			"1.0"},
	{"sound/zombie-plague/human/f/friendlyfire06.wav",			"1.0"},
	{"sound/zombie-plague/human/f/friendlyfire08.wav",			"1.0"},
	{"sound/zombie-plague/human/f/friendlyfire12.wav",			"1.0"}
};

static const char g_KillZombieSounds[4][2][] = {
	{"sound/zombie-plague/human/killconfirmation01.wav",		"0.1"},
	{"sound/zombie-plague/human/killconfirmation03.wav",		"0.1"},
	{"sound/zombie-plague/human/killconfirmation06.wav",		"0.1"},
	{"sound/zombie-plague/human/killconfirmation07.wav",		"0.1"}
};

static const char g_KillZombiefSounds[5][2][] = {
	{"sound/zombie-plague/human/f/killconfirmation01.wav",		"0.1"},
	{"sound/zombie-plague/human/f/killconfirmation02.wav",		"0.1"},
	{"sound/zombie-plague/human/f/killconfirmation04.wav",		"0.1"},
	{"sound/zombie-plague/human/f/killconfirmation07.wav",		"0.1"},
	{"sound/zombie-plague/human/f/killconfirmation08.wav",		"0.1"},
};

static const char g_ZombieTankWarnSounds[2][] =
{
	"sound/zombie-plague/human/tankpound01.wav",
	"sound/zombie-plague/human/tankpound04.wav"
};
static const char g_ZombieTankWarnfSounds[1][] =
{
	"sound/zombie-plague/human/f/tankpound04.wav"
};

static const char g_ZombieHunterWarnSounds[1][] =
{
	"sound/zombie-plague/human/warnhunter03.wav"
};

static const char g_ZombieHunterWarnfSounds[1][] =
{
	"sound/zombie-plague/human/f/warnhunter02.wav"
};

#define SOUND_IGMAN "zombie-plague/igman.mp3"

Handle m_RoundTime_End;

enum struct ClientData
{
	float HGameTime;
	float ZGameTime;
	float HRestrictGameTime;
	char VoiceSound[164];
	
	void Clear(int client)
	{
		this.HGameTime = 0.0;
		this.ZGameTime = 0.0;
		this.HRestrictGameTime = 0.0;
		
		if (IsValidClient(client))
		{
			if (this.VoiceSound[0])
			{
				StopSound(client, SNDCHAN_AUTO, this.VoiceSound);
			}
		}
		
		this.VoiceSound = NULL_STRING;
	}
}
ClientData sClientData[MAXPLAYERS+1];

public void OnPluginStart()
{
	HookEvent("weapon_fire", Event_WeaponFire, EventHookMode_Pre);
	HookEvent("weapon_reload", Event_WeaponReload);
	HookEvent("player_death", Hook_PlayerDeath);
}

public void OnPluginEnd()
{
	UnhookEvent("weapon_fire", Event_WeaponFire, EventHookMode_Pre);
	UnhookEvent("weapon_reload", Event_WeaponReload);
	UnhookEvent("player_death", Hook_PlayerDeath);
}

public void OnMapStart()
{
	for (int i = 0; i < sizeof(g_GrenadeSounds); i++)
	{
		AddFileToDownloadsTable(g_GrenadeSounds[i][0]);
		PrecacheSound(g_GrenadeSounds[i][0][6], true);
	}
	for (int i = 0; i < sizeof(g_GrenadefSounds); i++)
	{
		AddFileToDownloadsTable(g_GrenadefSounds[i][0]);
		PrecacheSound(g_GrenadefSounds[i][0][6], true);
	}
	for (int i = 0; i < sizeof(g_KillZombieSounds); i++)
	{
		AddFileToDownloadsTable(g_KillZombieSounds[i][0]);
		PrecacheSound(g_KillZombieSounds[i][0][6], true);
	}
	for (int i = 0; i < sizeof(g_KillZombiefSounds); i++)
	{
		AddFileToDownloadsTable(g_KillZombiefSounds[i][0]);
		PrecacheSound(g_KillZombiefSounds[i][0][6], true);
	}
	for (int i = 0; i < sizeof(g_ElisReloadSounds); i++)
	{
		AddFileToDownloadsTable(g_ElisReloadSounds[i][0]);
		PrecacheSound(g_ElisReloadSounds[i][0][6], true);
	}
	for (int i = 0; i < sizeof(g_RochelleReloadSounds); i++)
	{
		AddFileToDownloadsTable(g_RochelleReloadSounds[i][0]);
		PrecacheSound(g_RochelleReloadSounds[i][0][6], true);
	}
	for (int i = 0; i < sizeof(g_DeathFriendSounds); i++)
	{
		AddFileToDownloadsTable(g_DeathFriendSounds[i][0]);
		PrecacheSound(g_DeathFriendSounds[i][0][6], true);
	}
	for (int i = 0; i < sizeof(g_DeathFriendfSounds); i++)
	{
		AddFileToDownloadsTable(g_DeathFriendfSounds[i][0]);
		PrecacheSound(g_DeathFriendfSounds[i][0][6], true);
	}
	for (int i = 0; i < sizeof(g_SuicideSounds); i++)
	{
		AddFileToDownloadsTable(g_SuicideSounds[i][0]);
		PrecacheSound(g_SuicideSounds[i][0][6], true);
	}
	for (int i = 0; i < sizeof(g_SuicidefSounds); i++)
	{
		AddFileToDownloadsTable(g_SuicidefSounds[i][0]);
		PrecacheSound(g_SuicidefSounds[i][0][6], true);
	}
	for (int i = 0; i < sizeof(g_ZombieTankWarnSounds); i++)
	{
		AddFileToDownloadsTable(g_ZombieTankWarnSounds[i]);
		PrecacheSound(g_ZombieTankWarnSounds[i][6]);
	}
	for (int i = 0; i < sizeof(g_ZombieTankWarnfSounds); i++)
	{
		AddFileToDownloadsTable(g_ZombieTankWarnfSounds[i]);
		PrecacheSound(g_ZombieTankWarnfSounds[i][6]);
	}
	for (int i = 0; i < sizeof(g_ZombieHunterWarnSounds); i++)
	{
		AddFileToDownloadsTable(g_ZombieHunterWarnSounds[i]);
		PrecacheSound(g_ZombieHunterWarnSounds[i][6]);
	}
	for (int i = 0; i < sizeof(g_ZombieHunterWarnfSounds); i++)
	{
		AddFileToDownloadsTable(g_ZombieHunterWarnfSounds[i]);
		PrecacheSound(g_ZombieHunterWarnfSounds[i][6]);
	}

	AddFileToDownloadsTable("sound/" ... SOUND_IGMAN);
	PrecacheSound(SOUND_IGMAN);

	CreateTimer(1.0, Timer_OnPlayerSee, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public void OnMapEnd()
{
	m_RoundTime_End = null;
}

public void OnClientDisconnect(int client)
{
	sClientData[client].Clear(-1);
}

public void ZM_OnClientUpdated(int client, int attacker)
{
	if (IsValidClient(client))
	{
		sClientData[client].Clear(client);
	}
}

public Action CS_OnTerminateRound(float& delay, CSRoundEndReason& reason)
{
	delete m_RoundTime_End;
	
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (IsValidClient(i))
		{
			StopSound(i, SNDCHAN_AUTO, SOUND_IGMAN);
		}
	}
	return Plugin_Continue;
}

public void ZM_OnGameModeStart(int gamemode)
{
	float time = ZM_GetRoundTime();
	
	if (time > 1)
	{
		m_RoundTime_End = CreateTimer(time - 33.0, Timer_CheckRoundTime, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_CheckRoundTime(Handle timer)
{
	m_RoundTime_End = null;
	
	EmitSoundToAll(SOUND_IGMAN);
	return Plugin_Stop;
}

public Action Timer_OnPlayerSee(Handle timer)
{
	if (!ZM_IsStartedRound()) {
		return Plugin_Continue;
	}
	
	float time = GetGameTime();

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i))
		{
			OnPlayerSee(i, time);
		}
	}
	return Plugin_Continue;
}

void OnPlayerSee(int client, float time)
{
	if (!ZM_IsClientHuman(client))
	{
		return;
	}
	
	if (ZM_IsRespawn(client))
	{
		return;
	}
	
	if (sClientData[client].HRestrictGameTime > time)
	{
		return;
	}
	
	if (!Sound_GetEntitiesDistance(client, 260.0))
	{
		return;
	}
	
	if (sClientData[client].HGameTime > time)
	{
		return;
	}
	int zombie = GetZombies(client, time);
	
	if (zombie != 0 && IsValidClient(zombie) && IsPlayerAlive(zombie))
	{
		/*
		static float origin[3], origin1[3];
		GetClientAbsOrigin(human, origin);
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && IsPlayerAlive(i) && ZR_IsClientHuman(i))
			{
				GetClientAbsOrigin(i, origin1);
				if (GetVectorDistance(origin1, origin) <= 300)
				{
					sClientData[i].HGameTime = time + GetRandomFloat(10.0, 30.0);
				}
			}
		}*/
		
		char buffer[34];
		ZM_GetClassName(ZM_GetClientClass(zombie), buffer, sizeof(buffer));
		
		if (strcmp(buffer, "zombie_tank") == 0)
		{
			if (ZM_GetClassGetGender(ZM_GetClientClass(client)) || ZM_GetSkinsGender(ZM_GetClientSkin(client)))
			{
				int rand = GetRandomInt(0, sizeof(g_ZombieTankWarnfSounds)-1);
				EmitSoundToAll(g_ZombieTankWarnfSounds[rand][6], client);
				strcopy(sClientData[client].VoiceSound, 164, g_ZombieTankWarnfSounds[rand][6]);
			}
			else
			{
				int rand = GetRandomInt(0, sizeof(g_ZombieTankWarnSounds)-1);
				EmitSoundToAll(g_ZombieTankWarnSounds[rand][6], client);
				strcopy(sClientData[client].VoiceSound, 164, g_ZombieTankWarnSounds[rand][6]);
			}
			
			sClientData[zombie].ZGameTime = time + 1.0;
			sClientData[client].HGameTime = time + GetRandomFloat(15.0, 35.0);
			sClientData[client].HRestrictGameTime = time + 1.7;
		}
		else if (strcmp(buffer, "zombie_hunter") == 0)
		{
			if (ZM_GetClassGetGender(ZM_GetClientClass(client)) || ZM_GetSkinsGender(ZM_GetClientSkin(client)))
			{
				int rand = GetRandomInt(0, sizeof(g_ZombieHunterWarnfSounds)-1);
				EmitSoundToAll(g_ZombieHunterWarnfSounds[rand][6], client);
				strcopy(sClientData[client].VoiceSound, 164, g_ZombieHunterWarnfSounds[rand][6]);
			}
			else
			{
				int rand = GetRandomInt(0, sizeof(g_ZombieHunterWarnSounds)-1);
				EmitSoundToAll(g_ZombieHunterWarnSounds[rand][6], client);
				strcopy(sClientData[client].VoiceSound, 164, g_ZombieHunterWarnSounds[rand][6]);
			}
			
			sClientData[zombie].ZGameTime = time + 1.0;
			sClientData[client].HGameTime = time + GetRandomFloat(15.0, 35.0);
			sClientData[client].HRestrictGameTime = time + 1.7;
		}
	}
}

stock int GetZombies(int client, float time)
{
	static float origin[3];
	
	static int clients[MAXPLAYERS], total, i;
	for (i = 1, total = 0; i <= MaxClients; ++i)
	{
		if (IsValidClient(i) && IsPlayerAlive(i) && ZM_IsClientZombie(i))
		{
			if (sClientData[i].ZGameTime > time)
			{
				continue;
			}
			GetClientAbsOrigin(i, origin);
			
			if (!UTIL_IsAbleToSee2(origin, client, MASK_VISIBLE))
			{
				continue;
			}
			
			if (!UTIL_IsTargetInSightRange(origin, client, 110.0, 1300.0))
			{
				continue;
			}
			
			clients[++total] = i;
		}
	}
	return total ? clients[GetRandomInt(1, total)] : 0;
}

/////////////// 
public Action Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidClient(client) && ZM_IsClientHuman(client))
	{
		float time = GetGameTime();
		if (sClientData[client].HRestrictGameTime > time)
		{
			return Plugin_Continue;
		}
	
		char weapon[34]; event.GetString("weapon", weapon, sizeof(weapon));
		if (strcmp(weapon, "hegrenade", false) == 0)
		{
			if (ZM_GetClassGetGender(ZM_GetClientClass(client)) || ZM_GetSkinsGender(ZM_GetClientSkin(client)))
			{
				int rand = GetRandomInt(0, sizeof(g_GrenadefSounds)-1);
				EmitSoundToAll(g_GrenadefSounds[rand][0][6], client);
				strcopy(sClientData[client].VoiceSound, 164, g_GrenadefSounds[rand][0][6]);
				sClientData[client].HRestrictGameTime = time + StringToFloat(g_GrenadefSounds[rand][1]);
			}
			else
			{
				int rand = GetRandomInt(0, sizeof(g_GrenadeSounds)-1);
				EmitSoundToAll(g_GrenadeSounds[rand][0][6], client);
				strcopy(sClientData[client].VoiceSound, 164, g_GrenadeSounds[rand][0][6]);
				sClientData[client].HRestrictGameTime = time + StringToFloat(g_GrenadeSounds[rand][1]);
			}
		}
	}
	return Plugin_Continue;
}

public void Event_WeaponReload(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (IsValidClient(client) && ZM_IsClientHuman(client))
	{
		if (ZM_IsRespawn(client))
		{
			return;
		}
	
		float time = GetGameTime();
		if (sClientData[client].HRestrictGameTime > time)
		{
			return;
		}
		
		char weapon[32]; GetClientWeapon(client, weapon, sizeof(weapon));
		if (strcmp(weapon[7], "m3") == 0 || strcmp(weapon[7], "xm1014") == 0)
		{
			return;
		}
		
		if (!Sound_GetEntitiesDistance(client, 230.0))
		{
			return;
		}
		
		if (!Sound_GetSeeZombies(client))
		{
			return;
		}
		
		if (ZM_GetClassGetGender(ZM_GetClientClass(client)) || ZM_GetSkinsGender(ZM_GetClientSkin(client)))
		{
			int rand = GetRandomInt(0, sizeof(g_RochelleReloadSounds)-1);
			EmitSoundToAll(g_RochelleReloadSounds[rand][0][6], client);
			strcopy(sClientData[client].VoiceSound, 164, g_RochelleReloadSounds[rand][0][6]);
			sClientData[client].HRestrictGameTime = time + StringToFloat(g_RochelleReloadSounds[rand][1]);
		}
		else
		{
			int rand = GetRandomInt(0, sizeof(g_ElisReloadSounds)-1);
			EmitSoundToAll(g_ElisReloadSounds[rand][0][6], client);
			strcopy(sClientData[client].VoiceSound, 164, g_ElisReloadSounds[rand][0][6]);
			sClientData[client].HRestrictGameTime = time + StringToFloat(g_ElisReloadSounds[rand][1]);
		}
	}
}

public Action Hook_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	float time = GetGameTime();
	int client = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	bool bSuicide = (client == attacker || attacker == 0);
	int random = GetRandomInt(1, 3);
	
	if (IsValidClient(client) && ZM_IsClientZombie(client) && IsValidClient(attacker) && ZM_IsClientHuman(attacker) && !bSuicide)
	{
		if (ZM_IsRespawn(attacker))
		{
			return Plugin_Continue;
		}
	
		if (random == 1)
		{
			return Plugin_Continue;
		}
		
		if (sClientData[attacker].HRestrictGameTime > time)
		{
			return Plugin_Continue;
		}
		
		if (ZM_GetClassGetGender(ZM_GetClientClass(attacker)) || ZM_GetSkinsGender(ZM_GetClientSkin(attacker)))
		{
			int rand = GetRandomInt(0, sizeof(g_KillZombiefSounds)-1);
			EmitSoundToAll(g_KillZombiefSounds[rand][0][6], attacker);
			strcopy(sClientData[attacker].VoiceSound, 164, g_KillZombiefSounds[rand][0][6]);
			sClientData[attacker].HRestrictGameTime = time + StringToFloat(g_KillZombiefSounds[rand][1]);
		}
		else
		{
			int rand = GetRandomInt(0, sizeof(g_KillZombieSounds)-1);
			EmitSoundToAll(g_KillZombieSounds[rand][0][6], attacker);
			strcopy(sClientData[attacker].VoiceSound, 164, g_KillZombieSounds[rand][0][6]);
			sClientData[attacker].HRestrictGameTime = time + StringToFloat(g_KillZombieSounds[rand][1]);
		}
		
		return Plugin_Continue;
	}
	
	if (IsValidClient(client))
	{
		sClientData[client].Clear(client);
		
		if (ZM_IsClientHuman(client))
		{
			int countVoice = GetRandomInt(1, 3);
			
			static float origin[3];
			GetClientEyePosition(client, origin);
			
			for (int i = 1; i <= MaxClients; ++i)
			{
				if (IsValidClient(i) && IsPlayerAlive(i) && ZM_IsClientHuman(i) && client != i)
				{
					if (ZM_IsRespawn(i))
					{
						continue;
					}
				
					if (random == 1 || countVoice <= 0)
					{
						continue;
					}
					
					if (sClientData[i].HRestrictGameTime > time)
					{
						continue;
					}
					
					if (!UTIL_IsAbleToSee2(origin, i, MASK_VISIBLE))
					{
						continue;
					}
					
					if (!UTIL_IsTargetInSightRange(origin, i, 110.0, 1000.0))
					{
						continue;
					}
					
					if (bSuicide) // Suicide
					{
						if (ZM_GetClassGetGender(ZM_GetClientClass(i)) || ZM_GetSkinsGender(ZM_GetClientSkin(i)))
						{
							int rand = GetRandomInt(0, sizeof(g_SuicidefSounds)-1);
							EmitSoundToAll(g_SuicidefSounds[rand][0][6], i);
							strcopy(sClientData[i].VoiceSound, 164, g_SuicidefSounds[rand][0][6]);
							sClientData[i].HRestrictGameTime = time + StringToFloat(g_SuicidefSounds[rand][1]);
						}
						else
						{
							int rand = GetRandomInt(0, sizeof(g_SuicideSounds)-1);
							EmitSoundToAll(g_SuicideSounds[rand][0][6], i);
							strcopy(sClientData[i].VoiceSound, 164, g_SuicideSounds[rand][0][6]);
							sClientData[i].HRestrictGameTime = time + StringToFloat(g_SuicideSounds[rand][1]);
						}
					}
					else // Dead
					{
						if (ZM_GetClassGetGender(ZM_GetClientClass(i)) || ZM_GetSkinsGender(ZM_GetClientSkin(i)))
						{
							int rand = GetRandomInt(0, sizeof(g_DeathFriendfSounds)-1);
							EmitSoundToAll(g_DeathFriendfSounds[rand][0][6], i);
							strcopy(sClientData[i].VoiceSound, 164, g_DeathFriendfSounds[rand][0][6]);
							sClientData[i].HRestrictGameTime = time + StringToFloat(g_DeathFriendfSounds[rand][1]);
						}
						else
						{
							int rand = GetRandomInt(0, sizeof(g_DeathFriendSounds)-1);
							EmitSoundToAll(g_DeathFriendSounds[rand][0][6], i);
							strcopy(sClientData[i].VoiceSound, 164, g_DeathFriendSounds[rand][0][6]);
							sClientData[i].HRestrictGameTime = time + StringToFloat(g_DeathFriendSounds[rand][1]);
						}
					}
					
					countVoice--;
				}
			}
		}
	}
	return Plugin_Continue;
}

//////////////////////////////////////////////////////////////////////////////////////
stock bool Sound_GetEntitiesDistance(int client, float distance)
{
	static float origin[3]; bool count = false;
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (IsValidClient(i) && IsPlayerAlive(i) && ZM_IsClientHuman(i) && client != i)
		{
			GetClientEyePosition(i, origin);
			
			if (!UTIL_IsAbleToSee2(origin, client, MASK_VISIBLE))
			{
				continue;
			}
			
			if (GetEntitiesDistance(origin, client) > distance)
			{
				continue;
			}
			
			count = true;
		}
	}
	return count;
}

stock int Sound_GetSeeZombies(int client)
{
	static float origin[3]; bool count = false;
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (IsValidClient(i) && IsPlayerAlive(i) && ZM_IsClientZombie(i))
		{
			GetClientAbsOrigin(i, origin);
			
			if (!UTIL_IsAbleToSee2(origin, client, MASK_VISIBLE))
			{
				continue;
			}
			
			if (!UTIL_IsTargetInSightRange(origin, client, 110.0, 1300.0))
			{
				continue;
			}
			
			count = true;
		}
	}
	return count;
}

stock float GetEntitiesDistance(const float origin[3], int client)
{
	static float origin1[3];
	
	GetClientEyePosition(client, origin1);
	return GetVectorDistance(origin, origin1);
}