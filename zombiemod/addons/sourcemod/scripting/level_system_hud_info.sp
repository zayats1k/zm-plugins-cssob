#include <zombiemod>
#include <zm_database> // level_system
#include <zm_settings>
#include <utils>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name = "[LevelSystem] hud info",
	author = "0kEmo",
	version = "1.1"
};

#define CONFIG_PATH "addons/sourcemod/configs/zombiemod/level_hud_info.ini"

enum struct ConfigData
{
	char keyname[34];
	char text[164];
	int colors[3];
	float position[2];
}

enum struct ServerData
{
	ArrayList ArrayHud;
	Handle SyncHud;
	
	void Clear()
	{
		delete this.ArrayHud;
		delete this.SyncHud;
	}
}
ServerData sServerData;

enum struct ClientData
{
	Handle TimerHud;
	
	void Clear()
	{
		delete this.TimerHud;
	}
}
ClientData sClientData[MAXPLAYERS+1];

public void OnPluginStart()
{
	LoadTranslations("level_system_hud_info.phrases");
	// LoadTranslations("zm_chatcolor.phrases");
	// LoadTranslations("zombiemod_classes.phrases");

	sServerData.ArrayHud = new ArrayList(sizeof(ConfigData));
	sServerData.SyncHud = CreateHudSynchronizer();
	
	HookEvent("player_death", Event_PlayerDeath);
}

public void OnPluginEnd()
{
	sServerData.Clear();
	
	UnhookEvent("player_death", Event_PlayerDeath);
}

public void OnConfigsExecuted()
{
	sServerData.ArrayHud.Clear();
	
	KeyValues kv = new KeyValues("hud info");
	if (kv.ImportFromFile(CONFIG_PATH) && kv.GotoFirstSubKey())
	{
		ConfigData cd; char buffers[3][6], buffer[MAX_NAME_LENGTH];
		
		do
		{
			kv.GetSectionName(buffer, sizeof(buffer));
			strcopy(cd.keyname, sizeof(cd.keyname), buffer);
			
			kv.GetString("text", buffer, sizeof(buffer), "");
			strcopy(cd.text, sizeof(cd.text), buffer);
			
			kv.GetString("color", buffer, sizeof(buffer), "255 255 255");
			ExplodeString(buffer, " ", buffers, sizeof(buffers), sizeof(buffers[]));
			for (int i = 0; i < 3; i++) cd.colors[i] = StringToInt(buffers[i]);
			
			kv.GetString("position", buffer, sizeof(buffer), "0.01 0.01");
			ExplodeString(buffer, " ", buffers, sizeof(buffers), sizeof(buffers[]));
			cd.position[0] = StringToFloat(buffers[0]);
			cd.position[1] = StringToFloat(buffers[1]);
			
			sServerData.ArrayHud.PushArray(cd, sizeof(cd));
		}
		while (kv.GotoNextKey());
	}
	delete kv;
}

public void HS_OnClientHudSettings(int client, int id, const char[] name)
{
	if (id != 0) return;
	if (IsValidClient(client))
	{
		if (HS_GetClientCookie(client, id) == 0)
		{
			if (sClientData[client].TimerHud == null)
			{
				sClientData[client].TimerHud = CreateTimer(1.0, Timer_HudUpdate, GetClientUserId(client), TIMER_REPEAT);
				TriggerTimer(sClientData[client].TimerHud);
			}
		}
		else
		{
			if (sClientData[client].TimerHud != null)
			{
				ClearSyncHud(client, sServerData.SyncHud);
				delete sClientData[client].TimerHud;
			}
		}
	}
}

public void OnClientDisconnect_Post(int client)
{
	sClientData[client].Clear();
}

public Action Timer_HudUpdate(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	
	if (!IsFakeClient(client) && IsValidClient(client))
	{
		if (ZM_IsRespawn(client, 0))
		{
			return Plugin_Continue;
		}
	
		char buffer[164] = "";
		if (!IsPlayerAlive(client))
		{
			if (IsClientObserver(client) && !(GetEntProp(client, Prop_Send, "m_iObserverMode") & 2))
			{
				int target = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
				if (target != -1)
				{
					if (!IsFakeClient(target)) strcopy(buffer, sizeof(buffer), "HUD_TARGET_ALIVE");
					else strcopy(buffer, sizeof(buffer), "HUD_TARGET_BOT");
				}
				else strcopy(buffer, sizeof(buffer), "HUD_PLAYER_ALIVE");
			}
			else strcopy(buffer, sizeof(buffer), "HUD_PLAYER_ALIVE");
		}
		else
		{
			if (HS_GetClientCookie(client, 4) == 3)
			{
				if (ZM_IsClientHuman(client))
					strcopy(buffer, sizeof(buffer), "HUD_PLAYER_HUMAN_2");
				else strcopy(buffer, sizeof(buffer), "HUD_PLAYER_ZOMBIE_2");
			}
			else
			{
				if (ZM_IsClientHuman(client))
					strcopy(buffer, sizeof(buffer), "HUD_PLAYER_HUMAN");
				else strcopy(buffer, sizeof(buffer), "HUD_PLAYER_ZOMBIE");
			}
		}
	
		int index = sServerData.ArrayHud.FindString(buffer);
		if (index != -1)
		{
			ConfigData cd; sServerData.ArrayHud.GetArray(index, cd, sizeof(cd));
			
			if (cd.text[0])
			{
				SetGlobalTransTarget(client);
				Format(buffer, sizeof(buffer), IsTranslatedForLanguage(cd.text, GetServerLanguage()) ? "%t":"%s", cd.text);
				int mode = GetEntProp(client, Prop_Send, "m_iObserverMode");
				
				if (!IsPlayerAlive(client) && IsClientObserver(client) && !(mode & 2))
				{
					int target = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
					if (target != -1)
					{
						OnReplaceString(target, client, buffer, sizeof(buffer));
					}
					else 
					{
						OnReplaceString(client, client, buffer, sizeof(buffer));
					}
				}
				else
				{
					OnReplaceString(client, client, buffer, sizeof(buffer));
				}
				
				SetHudTextParams(cd.position[0], cd.position[1], 1.1, cd.colors[0], cd.colors[1], cd.colors[2], 255, 1, 0.0, 0.2, 0.2);
				ShowSyncHudText(client, sServerData.SyncHud, buffer);
			}
		}
		return Plugin_Continue;
	}
	
	sClientData[client].TimerHud = null;
	return Plugin_Stop;
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	OnClientExp_Post(GetClientOfUserId(event.GetInt("userid")));
}

public void ZM_OnClientUpdated(int client, int attacker)
{
	OnClientExp_Post(client);
}

public void OnClientExp_Post(int client)
{
	if (IsValidClient(client) && !IsFakeClient(client) && sClientData[client].TimerHud != null)
	{
		TriggerTimer(sClientData[client].TimerHud);
	}
}

stock void OnReplaceString(int client, int target, char[] text, int maxlength)
{
	ReplaceString(text, maxlength, "\\n", "\n");
	
	char buffer[36];
	if (StrContains(text, "{LVL}") != -1)
	{
		IntToString(GetClientLevel(client), buffer, sizeof(buffer));
		ReplaceString(text, maxlength, "{LVL}", buffer);
    }
	if (StrContains(text, "{EXP}") != -1)
	{
		IntToString(GetClientExp(client), buffer, sizeof(buffer));
		ReplaceString(text, maxlength, "{EXP}", buffer);
    }
	if (StrContains(text, "{EXPD}") != -1)
	{
		IntToString(GetClientExp2(client), buffer, sizeof(buffer));
		ReplaceString(text, maxlength, "{EXPD}", buffer);
    }
	if (StrContains(text, "{AP}") != -1)
	{
		if (GetFeatureStatus(FeatureType_Native, "GetClientAmmoPacks") == FeatureStatus_Available)
		{
			IntToString(GetClientAmmoPacks(client), buffer, sizeof(buffer));
			ReplaceString(text, maxlength, "{AP}", buffer);
		}
    }
	if (StrContains(text, "{CLASS}") != -1)
	{
		char buffer2[34];
		ZM_GetClassName(ZM_GetClientClass(client), buffer2, sizeof(buffer2));
		
		SetGlobalTransTarget(target);
		Format(buffer, sizeof(buffer), IsTranslatedForLanguage(buffer2, GetServerLanguage()) ? "%t":"%s", buffer2);
		
		ReplaceString(text, maxlength, "{CLASS}", buffer);
    }
}