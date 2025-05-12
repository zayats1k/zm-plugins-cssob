#include <zombiemod>
#include <zm_player_animation>
#include <botattackcontrol>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name = "[ZM] Bot System",
	author = "0kEmo",
	version = "2.4"
};

// https://steamid.xyz/
int g_accountIDs[MAXPLAYERS+1] = {
	0,
	25341944,
	33063657,
	86114025,
	33139149,
	10019795,
	64136527,
	10014490,
	112064860,
	3312,
	3,
	136555,
	49797024,
	53988387,
	168894,
	29462734,
	20599720
};

// nicknames
#define MAX_BOTNAMES 64
char g_nameIDs[MAX_BOTNAMES+1][MAXPLAYERS+1] = {
	"",
	"Mr.Proper",
	"MaxWell",
	"Kentpro*A_D_I_N*37rus*",
	"♥˜”*°•П☈☉сTи ̴Ʒа βсЁ•°*”˜ ♥",
	"Spellsong",
	"Mr_KiLLaURa",
	"Iwannabeamonster",
	"Kandis",
	"Live-Evil",
	"yxoIop",
	"tango",
	"_от_А(да)_до_(ра)Я_­",
	"Durasell",
	"Я не идиальная зато реальна",
	"C.t.y.g.e.n.t.*.*.",
	"*(_So_SmisloM_)*",
	"Hugira",
	"Adrienrad",
	"Гамадрила",
	"Youdontknowwhoiam",
	"Dianann",
	"BJIacTeJIuH_KpeBeToK",
	"MegaCRAFT",
	"Под испанским нЁбом",
	"интимный прыщик",
	"rAndo0m4uk",
	"TeraMiraBili",
	"**(-_)KEKC161RUS",
	"AFTERLIFE",
	"me.wizzy",
	"4emodan",
	"llDLzll",
	"BTeMe|Dog:)",
	"jakonta",
	"StaRs",
	"Я вернулась из блока",
	"Luciferk@",
	"волшебная клизма",
	"Mann",
	"Jugami",
	"MecTHblu_XyJluraHuLLIka",
	"Anargas",
	"Miss_insta",
	"Torry",
	"CEKPET",
	"Nejas",
	"naemnik",
	"RostyslavK.",
	"Стон водопада",
	"Mightsong",
	"DJ_HEAD--",
	"Tolik",
	"killer",
	"Mazushicage",
	"AlaEva",
	"WOGY",
	"JlenecTok_JloToca",
	"Heino",
	"DONwerewolf",
	"☞0tsosi ne trЯsi",
	"Erkebulan",
	"★☆ВечНо_ПьянЫй☆★",
	"Beechum",
	"Nesquik*"
};

static const char g_GiveWeapon[][] = // https://wiki.alliedmods.net/Counter-Strike:_Source_Weapons
{	"weapon_m4a1", "weapon_ak47", "weapon_famas",
	"weapon_tmp", "weapon_sg552",
	"weapon_aug", "weapon_p90",
	"weapon_m3", "weapon_xm1014"
};

static const char g_GiveWeapon2[][] = 
{	"weapon_p228", "weapon_deagle",
	"weapon_elite", "weapon_fiveseven"
};

static const char g_GiveWeapon3[][] = 
{	"weapon_m249", "weapon_sg550",
	"weapon_m134", "weapon_dinfinity",
	"weapon_frostgun", "weapon_salamander",
	"weapon_mp5gitar", "weapon_m32",
	"weapon_awp_buff", "weapon_ethereal",
	"weapon_m3shark"
};

#define SOUND_ITEMICKUP "items/itempickup.wav"
#define SOUND_SMALLMEDKIT "items/smallmedkit1.wav"

#pragma semicolon 1
#pragma newdecls required

float m_fBotPingTimer;
int m_iPlayerManager = -1, m_iPing = -1;
int m_HumanSniper, m_HumanSurvivor;
int m_ModeNemesis, m_ModeNormal;
Handle m_Bot[MAXPLAYERS+1];
bool m_ZombieBotGive[MAXPLAYERS+1];
float m_fPingPingTimer[MAXPLAYERS+1];
bool m_TimeStart, m_IsMapZE;

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("zombiemod_shop.phrases");

	m_iPing	= FindSendPropInfo("CPlayerResource", "m_iPing");

	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_end", Event_RoundEnd);
	
	AddCommandListener(Command_Ping, "ping");
}

public void OnPluginEnd()
{
	UnhookEvent("player_death", Event_PlayerDeath);
	UnhookEvent("round_end", Event_RoundEnd);
}

public void OnMapStart()
{
	char mapname[PLATFORM_MAX_PATH];
	GetCurrentMap(mapname, sizeof(mapname));
	m_IsMapZE = strncmp(mapname, "ze_", 3, false) != 0;

	PrecacheSound(SOUND_ITEMICKUP, true);
	PrecacheSound(SOUND_SMALLMEDKIT, true);

	m_TimeStart = GetTimeStart(16, 17); // moscow time: "16:00 start" - "17:00 end" // moscow time: "17:00 start" - "20:00 end"

	if (m_IsMapZE != true)
	{
		ServerCommand("bot_kick");
	}
	else
	{
		ServerCommand("bot_quota %d", UTIL_GetRandomInt(2, 5));
	}

	m_iPlayerManager = FindEntityByClassname(MaxClients+1, "cs_player_manager");
	m_fBotPingTimer = 0.0;
}

public void OnMapEnd()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		m_Bot[i] = null;
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
	m_HumanSniper = ZM_GetClassNameID("human_sniper");
	m_HumanSurvivor = ZM_GetClassNameID("human_survivor");
	
	m_ModeNormal = ZM_GetGameModeNameID("normal mode");
	m_ModeNemesis = ZM_GetGameModeNameID("nemesis mode");
}

public void OnClientPutInServer(int client)
{
	if (IsValidClient(client) && IsFakeClient(client) && !IsClientSourceTV(client))
	{
		ChangeClientTeam(client, CS_TEAM_SPECTATOR);
		FakeClientCommand(client, "jointeam 1");
		
		m_Bot[client] = CreateTimer(float(UTIL_GetRandomInt(8, 18)), Timer_BotJoinTeam, GetClientUserId(client));
		CreateTimer(0.2, Timer_CreateFakeName, GetClientUserId(client));
	}
}

public Action Timer_CreateFakeName(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	
	if (IsValidClient(client) && IsFakeClient(client) && !IsClientSourceTV(client))
	{
		if (client <= MAX_BOTNAMES && g_nameIDs[client][0])
		{
			SetClientInfo(client, "name", g_nameIDs[client]);
			SetEntPropString(client, Prop_Data, "m_szNetname", g_nameIDs[client]);
		}
	}
	return Plugin_Stop;
}

public void OnClientPostAdminCheck(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
	m_fPingPingTimer[client] = 0.0;
	
	if (IsValidClient(client) && IsFakeClient(client))
	{
		delete m_Bot[client];
		m_ZombieBotGive[client] = false;
	}
}

public Action Timer_BotJoinTeam(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	m_Bot[client] = null;
	
	if (IsValidClient(client) && IsFakeClient(client) && !IsClientSourceTV(client))
	{
		FakeClientCommand(client, "jointeam 0");
		
		if (m_iPlayerManager != -1 && m_iPing != -1)
		{
			SetEntData(m_iPlayerManager, m_iPing + (client * 4), UTIL_GetRandomInt(35, 55));
		}
	}
	return Plugin_Stop;
}

public Action Command_Ping(int client, const char[] command, int argc)
{
	if (IsValidClient(client))
	{
		float time = GetGameTime();
		
		if (m_fPingPingTimer[client] < time - 5.0)
		{
			m_fPingPingTimer[client] = time;
			
			char name[64]; 
			PrintToConsole(client, "Client ping times:");
			for (int i = 1; i <= MaxClients; i++) 
			{
				if (IsClientConnected(i) && IsClientInGame(i)) 
				{
					GetClientName(i, name, sizeof(name)); 
					
					if (!IsFakeClient(i)) 
					{
						PrintToConsole(client, " %d ms : %s", RoundToNearest(GetClientAvgLatency(i, NetFlow_Outgoing) * 1000), name); 
					}
					else
					{
						if (GetClientTeam(i) > CS_TEAM_SPECTATOR)
						{
							if (m_iPlayerManager != -1 && m_iPing != -1)
							{
								PrintToConsole(client, " %d ms : %s", GetEntData(m_iPlayerManager, m_iPing + (i * 4)), name);
							}
						}
					}
				}
			}
		}
	}
	return Plugin_Handled;
}

public void OnClientSettingsChanged(int client)
{
	if (IsFakeClient(client) && !IsClientSourceTV(client) && GetEntityFlags(client) != 65665 && g_accountIDs[client])
	{
		int tableIdx = FindStringTable("userinfo");
		if (tableIdx == INVALID_STRING_TABLE) {
			return;
		}
		
		char userInfo[132];
		if (GetStringTableData(tableIdx, client - 1, userInfo, 132))
		{
			int accountId = g_accountIDs[client];
			userInfo[72] = accountId;
			userInfo[72 + 1] = accountId >> 8;
			userInfo[72 + 2] = accountId >> 16;
			userInfo[72 + 3] = accountId >> 24;
			
			bool lockTable = LockStringTables(false);
			SetStringTableData(tableIdx, client - 1, userInfo, 132);
			LockStringTables(lockTable);
		}
	}
}

public void OnGameFrame()
{
	float time = GetGameTime();
	if (m_fBotPingTimer < time - 3.0)
	{
		m_fBotPingTimer = time;
		
		if (m_iPlayerManager == -1 || m_iPing == -1)
		{
			return;
		}
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsValidEdict(i) || !IsValidClient(i) || GetClientTeam(i) <= CS_TEAM_SPECTATOR || !IsFakeClient(i)) {
				continue;
			}
			
			SetEntData(m_iPlayerManager, m_iPing + (i * 4), UTIL_GetRandomInt(35, 55));
		}
	}
}

public Action Hook_OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	if (IsValidClient(victim) && IsPlayerAlive(victim) && IsFakeClient(victim) && ZM_IsClientZombie(victim) && m_ZombieBotGive[victim] != true)
	{
		if (m_Bot[victim] == null)
		{
			int rand = UTIL_GetRandomInt(0, 20);
			
			if (rand == 7)
			{
				m_Bot[victim] = CreateTimer(GetRandomFloat(5.0, 2.0), Timer_ZombieBotCmd, GetClientUserId(victim));
			}
			else
			{
				m_Bot[victim] = CreateTimer(GetRandomFloat(20.0, 2.0), Timer_ZombieBotGive, GetClientUserId(victim));
			}
		}
	}
	return Plugin_Continue;
}

public Action Timer_ZombieBotCmd(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	m_Bot[client] = null;
	
	if (IsValidClient(client) && IsFakeClient(client) && IsPlayerAlive(client) && ZM_IsClientZombie(client))
	{
		if (GetEntitySequence(client) != 0) {
			return Plugin_Stop;
		}
		
		if (ZM_GetCurrentGameMode() != m_ModeNormal) {
			return Plugin_Stop;
		}
		
		if (ZM_GetGameModeMatch(ZM_GetCurrentGameMode()) != 0) {
			return Plugin_Stop;
		}
		
		FakeClientCommand(client, "say !ztele");
	}
	return Plugin_Stop;
}

public Action Timer_ZombieBotGive(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	m_Bot[client] = null;
	
	if (IsValidClient(client) && IsFakeClient(client) && IsPlayerAlive(client) && ZM_IsClientZombie(client))
	{
		if (GetEntitySequence(client) != 0) {
			return Plugin_Stop;
		}
		
		m_ZombieBotGive[client] = true;
		
		if (ZM_GetCurrentGameMode() != m_ModeNormal) {
			return Plugin_Stop;
		}
		if (ZM_GetGameModeMatch(ZM_GetCurrentGameMode()) != 0) {
			return Plugin_Stop;
		}
		
		int rand = UTIL_GetRandomInt(0, 6);
		
		if (rand == 0) FakeClientCommand(client, "say !zshop");
		else if (rand == 1) FakeClientCommand(client, "say !shop");
		else if (rand == 2) FakeClientCommand(client, "say !zmenu");
		else return Plugin_Stop;
		
		m_Bot[client] = CreateTimer(GetRandomFloat(1.5, 0.5), Timer_ZombieBotGive2, GetClientUserId(client));
	}
	return Plugin_Stop;
}

public Action Timer_ZombieBotGive2(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	m_Bot[client] = null;
	
	if (IsValidClient(client) && IsFakeClient(client) && IsPlayerAlive(client) && ZM_IsClientZombie(client))
	{
		if (GetEntitySequence(client) != 0) {
			return Plugin_Stop;
		}
		if (ZM_GetCurrentGameMode() != m_ModeNormal) {
			return Plugin_Stop;
		}
		if (ZM_GetGameModeMatch(ZM_GetCurrentGameMode()) != 0) {
			return Plugin_Stop;
		}
		
		if (UTIL_GetRandomInt(0, 5) == 3)
		{
			if (!(GetZombies() > 5)){
				return Plugin_Stop;
			}
			
			ZM_ChangeClient(client, _, -3);
			EmitSoundToAll(SOUND_SMALLMEDKIT, client);
			
			float origin[3]; GetClientAbsOrigin(client, origin);
			UTIL_CreateParticle(-2, "nw_player_", "player_humn_1", origin, true);
				
			origin[2] -= 5.0;
			TE_DynamicLight(origin, 0, 0, 255, 2, 1000.0, 1.0, 1000.0);
			TE_SendToAll();
			
			char temp[164];
			Format(temp, sizeof(temp), "%T", "HUD_ANTIDOTE", client, client); // cl_showpluginmessages 1
			KeyValues kv = new KeyValues("Stuff", "title");
			kv.SetColor("color", 0, 255, 255, 255);
			kv.SetNum("level", 1);
			kv.SetNum("time", 1);
			
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsValidClient(i) && !IsFakeClient(i))
				{
					Format(temp, sizeof(temp), "%T", "HUD_ANTIDOTE", i, client);
					kv.SetString("title", temp);
					
					CreateDialog(i, kv, DialogType_Msg);
				}
			}
			delete kv;
		}
	}
	return Plugin_Stop;
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (IsValidClient(client) && IsFakeClient(client))
	{
		if (m_Bot[client] != null) {
			KillTimer(m_Bot[client]);
			m_Bot[client] = null;
		}
	}
}

public void ZM_OnClientUpdated(int client, int attacker)
{
	if (IsValidClient(client) && IsFakeClient(client))
	{
		if (m_Bot[client] != null) {
			KillTimer(m_Bot[client]);
			m_Bot[client] = null;
		}
		
		if (ZM_IsClientHuman(client))
		{
			m_Bot[client] = CreateTimer(GetRandomFloat(5.0, 1.5), Timer_BotGiveWeapon, GetClientUserId(client));
		}
	}
}

public Action Timer_BotGiveWeapon(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	m_Bot[client] = null;
	
	if (IsValidClient(client) && IsFakeClient(client) && IsPlayerAlive(client) && ZM_IsClientHuman(client))
	{
		int classid = ZM_GetClientClass(client);
		if (classid == m_HumanSniper || classid == m_HumanSurvivor) {
			return Plugin_Stop;
		}
		
		if (GetEntitySequence(client) != 0) {
			return Plugin_Stop;
		}
	
		int rand2 = UTIL_GetRandomInt(0, 10);
		
		if (rand2 == 5)
		{
			FakeClientCommand(client, "say !guns");
		
			m_Bot[client] = CreateTimer(GetRandomFloat(3.0, 1.0), Timer_BotGiveWeapon0, GetClientUserId(client));
			return Plugin_Stop;
		}
	
		int rand = UTIL_GetRandomInt(0, sizeof(g_GiveWeapon)-1);
		int index = GivePlayerItem(client, g_GiveWeapon[rand]);
		EquipPlayerWeapon(client, index);

		CSWeaponID id = CS_AliasToWeaponID(g_GiveWeapon[rand]);
		UTIL_SetReserveAmmo(client, index, CS_WeaponMaxAmmo[id]*2); // ammo x2

		EmitSoundToAll(SOUND_ITEMICKUP, client);
		
		m_Bot[client] = CreateTimer(GetRandomFloat(1.0, 0.5), Timer_BotGiveWeapon2, GetClientUserId(client));
	}
	return Plugin_Stop;
}

public Action Timer_BotGiveWeapon0(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	m_Bot[client] = null;
	
	if (IsValidClient(client) && IsFakeClient(client) && IsPlayerAlive(client) && ZM_IsClientHuman(client))
	{
		int classid = ZM_GetClientClass(client);
		if (classid == m_HumanSniper || classid == m_HumanSurvivor) {
			return Plugin_Stop;
		}
		
		if (GetEntitySequence(client) != 0) {
			return Plugin_Stop;
		}
	
		int rand = UTIL_GetRandomInt(0, sizeof(g_GiveWeapon)-1);
		int index = GivePlayerItem(client, g_GiveWeapon[rand]);
		EquipPlayerWeapon(client, index);

		CSWeaponID id = CS_AliasToWeaponID(g_GiveWeapon[rand]);
		UTIL_SetReserveAmmo(client, index, CS_WeaponMaxAmmo[id]*2); // ammo x2

		EmitSoundToAll(SOUND_ITEMICKUP, client);
		
		m_Bot[client] = CreateTimer(GetRandomFloat(1.0, 0.5), Timer_BotGiveWeapon2, GetClientUserId(client));
	}
	return Plugin_Stop;
}

public Action Timer_BotGiveWeapon2(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	m_Bot[client] = null;
	
	if (IsValidClient(client) && IsFakeClient(client) && IsPlayerAlive(client) && ZM_IsClientHuman(client))
	{
		int classid = ZM_GetClientClass(client);
		if (classid == m_HumanSniper || classid == m_HumanSurvivor) {
			return Plugin_Stop;
		}
		
		if (GetEntitySequence(client) != 0) {
			return Plugin_Stop;
		}
	
		int rand = UTIL_GetRandomInt(0, sizeof(g_GiveWeapon2)-1);
		int index = GivePlayerItem(client, g_GiveWeapon2[rand]);
		EquipPlayerWeapon(client, index);
		GivePlayerItem(client, "weapon_hegrenade");
		
		CSWeaponID id = CS_AliasToWeaponID(g_GiveWeapon2[rand]);
		UTIL_SetReserveAmmo(client, index, CS_WeaponMaxAmmo[id]*2); // ammo x2
		
		m_Bot[client] = CreateTimer((ZM_GetCurrentGameMode() == m_ModeNemesis) ? GetRandomFloat(3.0, 10.0):GetRandomFloat(15.0, 100.0), Timer_BotShopWeapon, GetClientUserId(client));
		
		EmitSoundToAll(SOUND_ITEMICKUP, client);
	}
	return Plugin_Stop;
}

public Action Timer_BotShopWeapon(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	m_Bot[client] = null;
	
	if (IsValidClient(client) && IsFakeClient(client) && IsPlayerAlive(client) && ZM_IsClientHuman(client))
	{
		int classid = ZM_GetClientClass(client);
		if (classid == m_HumanSniper || classid == m_HumanSurvivor) {
			return Plugin_Stop;
		}
		if (GetEntitySequence(client) != 0) {
			return Plugin_Stop;
		}
	
		int rand = UTIL_GetRandomInt(0, 5);
		
		if (rand == 0) FakeClientCommand(client, "say !zshop");
		else if (rand == 1) FakeClientCommand(client, "say !shop");
		else if (rand == 2) FakeClientCommand(client, "say !zmenu");
		else return Plugin_Stop;
		
		m_Bot[client] = CreateTimer(GetRandomFloat(3.0, 1.5), Timer_BotShopWeapon2, GetClientUserId(client));
	}
	return Plugin_Stop;
}

public Action Timer_BotShopWeapon2(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	m_Bot[client] = null;
	
	if (IsValidClient(client) && IsFakeClient(client) && IsPlayerAlive(client) && ZM_IsClientHuman(client))
	{
		int classid = ZM_GetClientClass(client);
		if (classid == m_HumanSniper || classid == m_HumanSurvivor) {
			return Plugin_Stop;
		}
		if (GetEntitySequence(client) != 0) {
			return Plugin_Stop;
		}
	
		float origin[3], angles[3];
		GetClientEyePosition(client, origin);
		GetClientEyeAngles(client, angles);
	
		int rand = UTIL_GetRandomInt(0, sizeof(g_GiveWeapon3)-1);
		
		int index = ZM_SpawnWeapon(g_GiveWeapon3[rand], "", origin, angles);
		EquipPlayerWeapon(client, index);
	}
	return Plugin_Stop;
}

public void ZM_OnClientValidateDamage(int client, int& attacker, int& inflicter, float& damage, int& damagetype)
{
	if (m_TimeStart == true)
	{
		if (IsValidClient(client) && IsFakeClient(client) && IsPlayerAlive(client) && ZM_IsClientZombie(client) && IsValidClient(attacker) && IsPlayerAlive(attacker) && ZM_IsClientHuman(attacker))
		{
			damage *= 2.0;
		}
	}
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i) && IsFakeClient(i))
		{
			if (m_Bot[i] != null) {
				KillTimer(m_Bot[i]);
				m_Bot[i] = null;
			}
			
			m_ZombieBotGive[i] = false;
		}
	}
}

public Action OnShouldBotAttackPlayer(int bot, int player, bool &result)
{
	if (!IsValidClient(player) || !IsPlayerAlive(player) || !IsValidClient(bot) || !IsPlayerAlive(bot))
	{
		return Plugin_Continue;
	}
	
	if (UTIL_GetRenderColor(player, 3) <= 10 || UTIL_GetRenderColor(bot, 3) <= 10)
	{
		result = false;
		return Plugin_Changed;
	}
	
	result = (ZM_IsClientHuman(player) && ZM_IsClientHuman(bot) || ZM_IsClientZombie(player) && ZM_IsClientZombie(bot)) ? false : true;
	return Plugin_Changed;
}

public void ZM_OnGameModeStart(int gamemode)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			m_ZombieBotGive[i] = false;
		}
	}
}

stock int GetZombies()
{
	int count;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i) && ZM_IsClientZombie(i))
		{  
			count++;
		}
	}
	return count;
}

stock bool GetTimeStart(int TimeStart, int TimeStop)
{
	char mTime[4];
	FormatTime(mTime, sizeof mTime, "%H", GetTime());
	int time = StringToInt(mTime);
	
	if (time >= TimeStart && time < TimeStop)
	{
		return true;
	}
	return false;
}