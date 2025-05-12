#include <zombiemod>
// #include <zm_settings>
#include <zm_vip_system>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name = "[ZM] Database",
	author = "0kEmo",
	version = "1.0"
};

int m_ModeNormal, m_ModeSwarm, m_ModeZE;
int m_HumanSniper, m_HumanSurvivor, m_ZombieMemesis;
bool m_IsMapZE;

#define LEVEL_CONFIG_PATH "addons/sourcemod/configs/zombiemod/levels.ini"
#define LEVEL_REWARD_CONFIG_PATH "addons/sourcemod/configs/zombiemod/level_reward.ini"

#include "zm_database/global.sp"
#include "zm_database/database.sp"

#include "zm_database/level.sp"
#include "zm_database/ammopacks.sp"
#include "zm_database/transfer.sp"

#include "zm_database/menu.sp"
#include "zm_database/api.sp"

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("zm_database.phrases");
	LoadTranslations("zombiemod_chat.phrases");
	LoadTranslations("zombiemod_shop.phrases");
	LoadTranslations("utils.phrases");
	
	sServerData.SyncHudAmmo = CreateHudSynchronizer();
	sServerData.ArrayLevels = new ArrayList();
	sServerData.ArrayReward = new ArrayList(sizeof(LevelData));
	
	RegConsoleCmd("top", Command_Top);
	RegConsoleCmd("ztop", Command_Top);
	RegConsoleCmd("rank", Command_Rank);
	RegAdminCmd("give_exp", Command_GiveExp, ADMFLAG_ROOT);
	RegAdminCmd("give_ap", Command_GiveAmmo, ADMFLAG_ROOT);
	RegAdminCmd("transfer", Command_Transfer, ADMFLAG_ROOT);
	
	AddCommandListener(DataBaseOnCommandListened, "exit");
	AddCommandListener(DataBaseOnCommandListened, "quit");
	AddCommandListener(DataBaseOnCommandListened, "restart");
	AddCommandListener(DataBaseOnCommandListened, "_restart");
	
	HookEvent("player_death", Event_PlayerDeath);
	
	if (SQL_CheckConfig("zm_core"))
	{
		Database.Connect(DBConnect, "zm_core");
	}
	else
	{
		char error[256];
		sServerData.Database = SQLite_UseDatabase("zm_core-sqlite", error, sizeof(error));
		DBConnect(sServerData.Database, error, 0);
	}
	
	File file = OpenFile(LEVEL_CONFIG_PATH, "r");
	if (file)
	{
		sServerData.ArrayLevels.Clear();
	
		static char buffer[66];
		while (file.ReadLine(buffer, sizeof(buffer)))
		{
			SplitString(buffer, "//", buffer, sizeof(buffer));
			TrimString(buffer);
			if (buffer[0])
			{
				sServerData.ArrayLevels.Push(StringToInt(buffer));
			}
		}
	}
	delete file;
	
	KeyValues kv = new KeyValues("Level Reward");
	if (kv.ImportFromFile(LEVEL_REWARD_CONFIG_PATH) && kv.GotoFirstSubKey())
	{
		char buffer[264]; LevelData cd;
		sServerData.ArrayReward.Clear();
		
		do
		{
			kv.GetSectionName(buffer, sizeof(buffer));
			cd.level = StringToInt(buffer);
			
			kv.GetString("params", buffer, sizeof(buffer), "");
			strcopy(cd.params, sizeof(cd.params), buffer);
			kv.GetString("chat_player", buffer, sizeof(buffer), "");
			strcopy(cd.chat_player, sizeof(cd.chat_player), buffer);
			kv.GetString("chat_all", buffer, sizeof(buffer), "");
			strcopy(cd.chat_all, sizeof(cd.chat_all), buffer);
			
			sServerData.ArrayReward.PushArray(cd, sizeof(cd));
		}
		while (kv.GotoNextKey());
	}
	delete kv;
}

public void OnPluginEnd()
{
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (IsClientInGame(i))
		{
			OnClientDisconnect(i);
		}
	}
	
	UnhookEvent("player_death", Event_PlayerDeath);
	
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
	m_ModeNormal = ZM_GetGameModeNameID("normal mode");
	m_ModeSwarm = ZM_GetGameModeNameID("swarm mode");
	m_ModeZE = ZM_GetGameModeNameID("escape mode");
	m_ZombieMemesis = ZM_GetClassNameID("zombie_nemesis");
	m_HumanSniper = ZM_GetClassNameID("human_sniper");
	m_HumanSurvivor = ZM_GetClassNameID("human_survivor");
}

public void OnMapStart()
{
	char mapname[PLATFORM_MAX_PATH];
	GetCurrentMap(mapname, sizeof(mapname));

	CreateTimer(1.0, Timer_PlayTime, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(5.0, Timer_DBCheckCallbackCnt, _, TIMER_FLAG_NO_MAPCHANGE);
	
	sServerData.TimeStart = GetTimeStart(17, 20); // moscow time: "17:00 start" - "20:00 end"
	m_IsMapZE = strncmp(mapname, "ze_", 3, false) != 0;
}

public void OnClientConnected(int client)
{
	sClientData[client].Clear();
}

public void OnClientPostAdminCheck(int client)
{
	if (IsValidClient(client) && !IsClientSourceTV(client) && !IsFakeClient(client))
	{
		sClientData[client].AccountID = GetSteamAccountID(client);
		
		if (sClientData[client].AccountID)
		{
			char query[512];
			sServerData.Database.Format(query, sizeof(query), "SELECT * FROM `zm_core` WHERE `aid` = '%d'", sClientData[client].AccountID);
			sServerData.Database.Query(DB_SelectCallback, query, GetClientUserId(client), DBPrio_High);
		}
		else
		{
			LogError("Player: \"%L\" Error AccountId", client);
		}
	}
}

public void OnClientDisconnect(int client)
{
	if (!IsFakeClient(client) && sClientData[client].AccountID)
	{
		DB_ClientUpdate(client);
	}
	
	sClientData[client].Clear();
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (!IsValidClient(client) || attacker == client)
	{
		return Plugin_Continue;
	}
	
	if (IsValidClient(attacker))
	{
		int mode = ZM_GetCurrentGameMode();
		if (mode != m_ModeNormal && mode != m_ModeSwarm && mode != m_ModeZE)
		{
			if (!IsFakeClient(attacker))
			{
				int classid = ZM_GetClientClass(attacker);
				if (classid == m_HumanSniper || classid == m_HumanSurvivor || classid == m_ZombieMemesis)
				{
					SetClientAmmoPacks(attacker, UTIL_GetRandomInt(1, 3));
					SetClientExp(attacker, client, 3);
					
					sClientData[attacker].bosskills++;
				}
				else
				{
					SetClientAmmoPacks(attacker, 50);
					SetClientExp(attacker, -1, UTIL_GetRandomInt(30, 150));
					
					sClientData[attacker].boss++;
				}
			}
			return Plugin_Continue;
		}
		
		if (!IsFakeClient(attacker))
		{
			if (ZM_IsClientHuman(attacker))
			{
				if (!IsFakeClient(client))
				{
					if (m_IsMapZE != true)
					{
						if (DB_GetClientCount() >= 6)
						{
							SetClientExp(attacker, client, (sServerData.TimeStart == true) ? UTIL_GetRandomInt(10, 25):35);
							SetClientAmmoPacks(attacker, 3);
						}
					}
					else
					{
						SetClientExp(attacker, client, (sServerData.TimeStart == true) ? UTIL_GetRandomInt(10, 25):35);
						SetClientAmmoPacks(attacker, 3);
					}
				}
				else
				{
					SetClientExp(attacker, client, 1);
					SetClientAmmoPacks(attacker, 1);
				}
			}
			else
			{
				if (!IsFakeClient(client))
				{
					if (m_IsMapZE != true)
					{
						if (DB_GetClientCount() >= 6)
						{
							SetClientExp(attacker, client, (sServerData.TimeStart == true) ? UTIL_GetRandomInt(10, 25):35);
							SetClientAmmoPacks(attacker, 5);
						}
					}
					else
					{
						SetClientExp(attacker, client, (sServerData.TimeStart == true) ? UTIL_GetRandomInt(10, 25):35);
						SetClientAmmoPacks(attacker, 5);
					}
				}
				else
				{
					SetClientExp(attacker, client, 1);
					SetClientAmmoPacks(attacker, 1);
				}
			}
			
			sClientData[attacker].Kills++;
		}
		
		if (!IsFakeClient(client))
		{
			sClientData[client].DamageLost = 0.0;
			sClientData[client].Deaths++;
		}
	}
	return Plugin_Continue;
}

public void ZM_OnClientUpdated(int client, int attacker)
{
	if (IsValidClient(client) && IsValidClient(attacker) && ZM_IsClientZombie(attacker))
	{
		if (!IsFakeClient(attacker))
		{
			if (!IsFakeClient(client))
			{
				if (m_IsMapZE != true)
				{
					if (DB_GetClientCount() >= 6)
					{
						SetClientExp(attacker, client, (sServerData.TimeStart == true) ? UTIL_GetRandomInt(10, 25):35);
						SetClientAmmoPacks(attacker, 5);
					}
				}
				else
				{
					SetClientExp(attacker, client, (sServerData.TimeStart == true) ? UTIL_GetRandomInt(10, 25):35);
					SetClientAmmoPacks(attacker, 5);
				}
			}
			else
			{
				SetClientExp(attacker, client, 1);
				SetClientAmmoPacks(attacker, 1);
			}
			
			sClientData[attacker].Infects++;
		}
		
		if (!IsFakeClient(client))
		{
			sClientData[client].DamageLost = 0.0;
			sClientData[client].Infected++;
		}
	}
}

public void ZM_OnClientDamaged(int client, int attacker, int inflictor, float damage, int damagetype)
{
	if (!IsValidClient(client) || !IsPlayerAlive(client) || attacker == client) {
		return;
	}
	
	if (IsValidClient(attacker) && !IsFakeClient(attacker) && IsPlayerAlive(attacker) && ZM_IsClientHuman(attacker))
	{
		if (m_IsMapZE != true)
		{
			if (DB_GetClientCount() < 6)
			{
				return;
			}
		}
		
		damage *= (1.0 - (IsFakeClient(client) ? 0.7:0.000014 * sClientData[attacker].AmmoPacks));
		
		if (damage < 0) {
			return;
		}
		
		sClientData[attacker].DamageLost += damage;
		if (sClientData[attacker].DamageLost >= 800.0)
		{
			SetClientExp(attacker, client, RoundToZero(sClientData[attacker].DamageLost/800.0));
			SetClientAmmoPacks(attacker, RoundToZero(sClientData[attacker].DamageLost/800.0));
			sClientData[attacker].DamageLost -= UTIL_Clamp(damage, 0, sClientData[attacker].DamageLost);
		}
	}
}

public Action Timer_PlayTime(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++) 
	{
		if (IsValidClient(i) && sClientData[i].Loaded && GetClientTeam(i) > CS_TEAM_SPECTATOR)
		{
			CreateForward_OnClientPlayTime(i, sClientData[i].PlayTime++);
			
			// if (sClientData[i].PlayTime != 0)
			// {
			// 	if (sClientData[i].PlayTime == 18000*(sClientData[i].PlayTime/18000)) // 5 hours, 0 min 0 sec.
			// 	{
			// 		PrintToChat_Lang(i, "%t", "PLAYPIME_EXP");
			// 		SetClientExp(i, 80);
			// 	}
			// }
		}
	}
	return Plugin_Continue;
}

stock int GetPlayerOnline(int AccountID)
{
	int target = 0;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && !IsFakeClient(i))
		{
			if (AccountID == sClientData[i].AccountID)
			{
				target = i;
			}
		}
	}
	return target;
}

stock int DB_GetClientCount()
{
    int count = 0;
	
    for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsValidClient(i) && IsPlayerAlive(i) && !IsFakeClient(i))
		{
			count++;
		}
	}
    return count;
}

stock void PrintToChat_Lang(int client, const char[] format, any ...)
{
	static char buffer[264];
	VFormat(buffer, sizeof(buffer), format, 3);
	ReplaceString(buffer, sizeof(buffer), "\\n", "\n");
	ReplaceString(buffer, sizeof(buffer), "#", "\x07");
	ReplaceString(buffer, sizeof(buffer), "{default}", "\x01");
	PrintToChat(client, "%s", buffer);
}

stock void SecondsToTime(int time, char[] buffer, int maxLen, int client = LANG_SERVER)
{
	char gtime[64]; int len = 0;
	if (time >= 86400) len += FormatEx(gtime[len], sizeof(gtime)-len, "%2d%T", time/86400, "days", client);
	if (time >= 3600) len += FormatEx(gtime[len], sizeof(gtime)-len, "%2d%T", time/3600%24,"hours", client);
	if (time >= 60) len += FormatEx(gtime[len], sizeof(gtime)-len, "%02d%T", time/60%60, "mines", client);
	if (time < 86400) len += FormatEx(gtime[len], sizeof(gtime)-len, "%2d%T", time%60, "sec", client);
	FormatEx(buffer, maxLen, "%s", gtime);
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