#include <clientprefs>
#include <zombiemod>

#pragma semicolon 1
#pragma newdecls required

#define MAX_MENUS 2
static const char cMenus[MAX_MENUS][2][] = {
	{"MENU_RESPAWN_ZOMBIE_CLASSMENU", "TOGGLE"}, // 0: ClassMenu
	{"MENU_SPAWN_PLAYER_GUNMENU", "TOGGLE"} // 1: GunMenu
};

/////////////////////////////////////////////////////////////
#define MAX_HUDS 5
static const char cMenuHuds[MAX_HUDS][2][] = {
	{"MENU_LS_INFO_HUD", "TOGGLE"}, // 0: level_system
	{"MENU_CLASS_HUD", "XXXXX"}, // 1: classes
	{"MENU_COUNTER_HUD", "TOGGLE"}, // 2: countdown
	{"MENU_GAMEMODES_HUD", "TOGGLE"}, // 3: gamemodes
	// {"MENU_SETTING_AMMOPACKS_HUD", "XXXXX"}, // 4: ammopacks - dead
	{"MENU_PROP_HEALTH_HUD", "TOGGLE"}, // 4: prop_health
};

/////////////////////////////////////////////////////////////
#define MAX_SOUNDS 4
#define MAX_MENU_SOUNDS 7

static const char cSounds[MAX_SOUNDS+MAX_MENU_SOUNDS][2][] =
{
	{"zombie-plague/announcer",				"0"},
	{"zombie-plague/zps",					"1"},
	{"zombie-plague/win_humans",			"2"}, {"zombie-plague/win_zombie", "2"},
	{"zombie-plague/zombie_ambience",		"3"}, {"zombiecity/nemesis/", "3"},
	{"zombie-plague/present_spawn",			"4"}, {"zombie-plague/zp_itempickup", "4"}, {"zombie-plague/zp_itemdrop", "4"},
	{"zombie-plague/human/",				"5"},
	{"zombie-plague/hero/",					"6"}
};

static const char cMenuSounds[MAX_MENU_SOUNDS][] =
{
	"MENU_COUNTER_SOUND",
	"MENU_ROUNDSTART_SOUND",
	"MENU_ROUNDEND_SOUND",
	"MENU_AMBIENCE_SOUND",
	"MENU_PRESENT_SOUND",
	"MENU_HUMAN_VOICE_SOUND",
	"MENU_ZOMBIE_VOICE_SOUND"
};

enum struct ServerData
{
	Cookie MenuCookie[MAX_MENUS];
	Cookie HudCookie[MAX_HUDS];
	Cookie SoundCookie[MAX_SOUNDS+MAX_MENU_SOUNDS];
	
	void Clear()
	{
		for (int i = 0; i < MAX_MENUS; i++)
		{
			delete this.MenuCookie[i];
		}
		
		for (int i = 0; i < MAX_HUDS; i++)
		{
			delete this.HudCookie[i];
		}
		
		for (int i = 0; i < sizeof(cMenuSounds); i++)
		{
			delete this.SoundCookie[i];
		}
	}
}
ServerData sServerData;

enum struct ClientData
{
	int MenuToggle[MAX_MENUS];
	int HudToggle[MAX_HUDS];
	bool SoundToggle[MAX_SOUNDS+MAX_MENU_SOUNDS];
	
	void Clear()
	{
		for (int i = 0; i < MAX_MENUS; i++)
		{
			this.MenuToggle[i] = 0;
		}
		
		for (int i = 0; i < MAX_HUDS; i++)
		{
			this.HudToggle[i] = 0;
		}
		
		for (int i = 0; i < sizeof(cMenuSounds); i++)
		{
			this.SoundToggle[i] = false;
		}
	}
}
ClientData sClientData[MAXPLAYERS+1];

GlobalForward hOnClientHudSettings;
int m_ModeNormal;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	hOnClientHudSettings = new GlobalForward("HS_OnClientHudSettings", ET_Ignore, Param_Cell, Param_Cell, Param_String);
	
	CreateNative("HS_GetClientCookie", Native_GetClientCookie);
	CreateNative("HS_SetClientCookie", Native_SetClientCookie);
	RegPluginLibrary("zm_settings");
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("zm_settings.phrases");
	LoadTranslations("zombiemod_market.phrases");
	
	for (int i = 0; i < sizeof(cMenus); i++)
	{
		sServerData.MenuCookie[i] = new Cookie(cMenus[i][0], "", CookieAccess_Private);
	}
	
	for (int i = 0; i < sizeof(cMenuHuds); i++)
	{
		sServerData.HudCookie[i] = new Cookie(cMenuHuds[i][0], "", CookieAccess_Private);
	}
	
	for (int i = 0; i < sizeof(cMenuSounds); i++)
	{
		sServerData.SoundCookie[i] = new Cookie(cMenuSounds[i], "", CookieAccess_Private);
	}
	
	SetCookieMenuItem(Settings_MenuHandler, 0, "");
	SetCookieMenuItem(SettingsHuds_MenuHandler, 0, "");
	SetCookieMenuItem(SettingsSounds_MenuHandler, 0, "");
	
	AddNormalSoundHook(Hook_NormalSound);
}

public void OnPluginEnd()
{
	sServerData.Clear();
	RemoveNormalSoundHook(Hook_NormalSound);
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
}

public void OnClientPostAdminCheck(int client)
{
	if (IsValidClient(client) && !IsFakeClient(client) && AreClientCookiesCached(client))
	{
		OnClientCookiesCached(client);
	}
}

public void OnClientCookiesCached(int client)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		char buffer[2];
		for (int i = 0; i < MAX_MENUS; i++)
		{
			sServerData.MenuCookie[i].Get(client, buffer, sizeof(buffer));
			sClientData[client].MenuToggle[i] = StringToInt(buffer);
		}
		
		for (int i = 0; i < sizeof(cMenuSounds); i++)
		{
			sServerData.SoundCookie[i].Get(client, buffer, sizeof(buffer));
			sClientData[client].SoundToggle[i] = (buffer[0] != '\0' && StringToInt(buffer));
		}
		
		for (int i = 0; i < MAX_HUDS; i++)
		{
			sServerData.HudCookie[i].Get(client, buffer, sizeof(buffer));
			sClientData[client].HudToggle[i] = StringToInt(buffer);
			
			if (!buffer[0])
			{
				// MENU_SETTING_CLASS_HUD, MENU_SETTING_AMMOPACKS_HUD == || i == 4
				if (i == 1)
				{
					sClientData[client].HudToggle[i] = 2;
				}
			}
			
			CreateForward_OnClientHudSettings(client, i, buffer);
		}
	}
}

public void OnClientDisconnect_Post(int client)
{
	sClientData[client].Clear();
}

public void Settings_MenuHandler(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	if (action == CookieMenuAction_DisplayOption)
	{
		Format(buffer, maxlen, "%T", "MENU_SETTINGS_MENUS", client); 
	}
	else if (action == CookieMenuAction_SelectOption)
	{
		if (AreClientCookiesCached(client))
			DisplayMenuSettingsMenu(client);
		else ShowCookieMenu(client);
	}
}

public void SettingsHuds_MenuHandler(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	if (action == CookieMenuAction_DisplayOption)
	{
		Format(buffer, maxlen, "%T", "MENU_SETTINGS_HUDS", client); 
	}
	else if (action == CookieMenuAction_SelectOption)
	{
		if (AreClientCookiesCached(client))
			DisplayHudSettingsMenu(client);
		else ShowCookieMenu(client);
	}
}

public void SettingsSounds_MenuHandler(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	if (action == CookieMenuAction_DisplayOption)
	{
		Format(buffer, maxlen, "%T", "MENU_SETTINGS_SOUNDS", client); 
	}
	else if (action == CookieMenuAction_SelectOption)
	{
		if (AreClientCookiesCached(client))
			DisplaySoundSettingsMenu(client);
		else ShowCookieMenu(client);
	}
}

///////////////////////////////////////////////////////////
void DisplayMenuSettingsMenu(int client)
{
	char buffer[164], buffer2[32];
	Menu menu = new Menu(MenuHandler_MenuSettings);
	Format(buffer, sizeof(buffer), "%T:\n ", "MENU_SETTINGS_MENUS", client);
	menu.SetTitle(buffer);
	menu.ExitBackButton = true;
	
	for (int i = 0; i < sizeof(cMenus); i++)
	{
		Formatb(sClientData[client].MenuToggle[i], buffer2, sizeof(buffer2));
		Format(buffer, sizeof(buffer), "%T %T", cMenus[i][0], client, buffer2, client);
		menu.AddItem(cMenus[i][1], buffer);
	}
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_MenuSettings(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
		{
			ShowCookieMenu(param1);
		}
	}
	else if (action == MenuAction_Select)
	{
		char info[32]; menu.GetItem(param2, info, sizeof(info));
		
		if (strcmp(info, "XXXXX") == 0)
		{
			if (sClientData[param1].MenuToggle[param2] == 1)
			{
				sClientData[param1].MenuToggle[param2] = 2;
				sServerData.MenuCookie[param2].Set(param1, "2");
			}
			else if (sClientData[param1].MenuToggle[param2] == 2)
			{
				sClientData[param1].MenuToggle[param2] = 3;
				sServerData.MenuCookie[param2].Set(param1, "3");
			}
			else if (sClientData[param1].MenuToggle[param2] == 3)
			{
				sClientData[param1].MenuToggle[param2] = 1;
				sServerData.MenuCookie[param2].Set(param1, "1");
			}
		}
		else
		{
			if (sClientData[param1].MenuToggle[param2] != 0)
			{
				sClientData[param1].MenuToggle[param2] = 0;
				sServerData.MenuCookie[param2].Set(param1, "0");
			}
			else
			{
				sClientData[param1].MenuToggle[param2] = 1;
				sServerData.MenuCookie[param2].Set(param1, "1");
			}
		}
		
		DisplayMenuSettingsMenu(param1);
	}
	else if (action == MenuAction_End) delete menu;
	return 0;
}

///////////////////////////////////////////////
void DisplayHudSettingsMenu(int client)
{
	char buffer[164], buffer2[32];
	Menu menu = new Menu(MenuHandler_HudSettings);
	Format(buffer, sizeof(buffer), "%T:\n ", "MENU_SETTINGS_HUDS", client);
	menu.SetTitle(buffer);
	menu.ExitBackButton = true;
	
	for (int i = 0; i < sizeof(cMenuHuds); i++)
	{
		Formatb(sClientData[client].HudToggle[i], buffer2, sizeof(buffer2));
		Format(buffer, sizeof(buffer), "%T %T", cMenuHuds[i][0], client, buffer2, client);
		menu.AddItem(cMenuHuds[i][1], buffer);
	}
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_HudSettings(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
		{
			ShowCookieMenu(param1);
		}
	}
	else if (action == MenuAction_Select)
	{
		char info[32]; menu.GetItem(param2, info, sizeof(info));
		
		if (strcmp(info, "XXXXX") == 0)
		{
			if (sClientData[param1].HudToggle[param2] == 1)
			{
				sClientData[param1].HudToggle[param2] = 2;
				sServerData.HudCookie[param2].Set(param1, "2");
			}
			else if (sClientData[param1].HudToggle[param2] == 2)
			{
				sClientData[param1].HudToggle[param2] = 3;
				sServerData.HudCookie[param2].Set(param1, "3");
			}
			else if (sClientData[param1].HudToggle[param2] == 3)
			{
				sClientData[param1].HudToggle[param2] = 1;
				sServerData.HudCookie[param2].Set(param1, "1");
			}
		}
		else
		{
			if (sClientData[param1].HudToggle[param2] != 0)
			{
				sClientData[param1].HudToggle[param2] = 0;
				sServerData.HudCookie[param2].Set(param1, "0");
			}
			else
			{
				sClientData[param1].HudToggle[param2] = 1;
				sServerData.HudCookie[param2].Set(param1, "1");
			}
		}
		
		CreateForward_OnClientHudSettings(param1, param2, "1");
		DisplayHudSettingsMenu(param1);
	}
	else if (action == MenuAction_End) delete menu;
	return 0;
}

public Action ZM_OnHudText(int client, const char[] name) // test
{
	if (IsValidClient(client))
	{
		if (strcmp(name, "countdown timer") == 0)
		{
			if (sClientData[client].HudToggle[2] == 1)
			{
				return Plugin_Handled;
			}
		}
		else if (strcmp(name, "start normal mode") == 0 || strcmp(name, "start swarm mode") == 0 || strcmp(name, "start nemesis mode") == 0 || strcmp(name, "start survivor mode") == 0)
		{
			if (sClientData[client].HudToggle[3] == 1)
			{
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

public int Native_GetClientCookie(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int id = GetNativeCell(2);
	return sClientData[client].HudToggle[id];
}

public int Native_SetClientCookie(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int id = GetNativeCell(2);
	sClientData[client].HudToggle[id] = GetNativeCell(3);
	return 0;
}

void CreateForward_OnClientHudSettings(int client, int id, const char[] name)
{
	Call_StartForward(hOnClientHudSettings);
	Call_PushCell(client);
	Call_PushCell(id);
	Call_PushString(name);
	Call_Finish();
}

///////////////////////////////////////////////////////////////////////////////////////////////////
void DisplaySoundSettingsMenu(int client)
{
	char buffer[164];
	Menu menu = new Menu(MenuHandler_SoundSettings);
	Format(buffer, sizeof(buffer), "%T:\n ", "MENU_SETTINGS_SOUNDS", client);
	menu.SetTitle(buffer);
	menu.ExitBackButton = true;
	
	for (int i = 0; i < sizeof(cMenuSounds); i++)
	{
		Format(buffer, sizeof(buffer), "%T %T", cMenuSounds[i], client, sClientData[client].SoundToggle[i] ? "DISABLE":"ENABLE", client);
		menu.AddItem("", buffer);
	}
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_SoundSettings(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
		{
			ShowCookieMenu(param1);
		}
	}
	else if (action == MenuAction_Select)
	{
		if (sClientData[param1].SoundToggle[param2])
		{
			sClientData[param1].SoundToggle[param2] = false;
			sServerData.SoundCookie[param2].Set(param1, "0");
		}
		else
		{
			sClientData[param1].SoundToggle[param2] = true;
			sServerData.SoundCookie[param2].Set(param1, "1");
		}
		
		DisplaySoundSettingsMenu(param1);
	}
	else if (action == MenuAction_End) delete menu;
	return 0;
}

public Action Hook_NormalSound(int clients[64], int& numClients, char sample[PLATFORM_MAX_PATH], int& entity, int& channel, float& volume, int& level, int& pitch, int& flags)
{
	int index = GetSoundIndex(sample);
	
	if (index != -1)
	{
		int i, j;
		for (i = 0; i < numClients; i++)
		{
			if (sClientData[clients[i]].SoundToggle[index])
			{
				for (j = i; j < numClients-1; j++) clients[j] = clients[j+1];
				numClients--; i--;
			}
		}
		return (numClients > 0) ? Plugin_Changed:Plugin_Stop;
	}
	return Plugin_Continue;
}

stock int GetSoundIndex(const char[] sample)
{
	for (int i = 0; i < sizeof(cSounds); i++)
	{
		if (StrContains(sample, cSounds[i][0], false) != -1)
		{
			return StringToInt(cSounds[i][1]);
		}
	}
	return -1;
}

///////////////////////////////////////////////
public void ZM_OnClientUpdated(int client, int attacker)
{
	if (IsValidClient(client) && !IsFakeClient(client) && sClientData[client].MenuToggle[1] == 0 && ZM_IsClientHuman(client))
	{
		CreateTimer(0.5, Timer_GunMenu, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_GunMenu(Handle timer, int userid) {
	int client = GetClientOfUserId(userid);
	if (IsValidClient(client) && IsPlayerAlive(client) && ZM_IsClientHuman(client))
	{
		if (ZM_GetSvaeDefaultCart(client) > 1)
		{
			ZM_PrintToChat(client, _, "%T", "market favorite start", client);
		
			if (ZM_IsStartedRound() && ZM_GetCurrentGameMode() != m_ModeNormal)
			{
				return Plugin_Stop;
			}
		
			if (sClientData[client].MenuToggle[0] == 0)
			{
				ClientCommand(client, "zclass");
			}
			return Plugin_Stop;
		}
		
		ClientCommand(client, "guns");
	}
	return Plugin_Stop;
}

public void ZM_OnClientRespawn(int client, int respawn_timer)
{
	if (IsValidClient(client) && sClientData[client].MenuToggle[0] == 0) //  && !IsPlayerAlive(client) && GetClientTeam(client) > CS_TEAM_SPECTATOR
	{
		if (respawn_timer >= 5)
		{
			CreateTimer(0.5, Timer_RespawnDeath, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action Timer_RespawnDeath(Handle timer, int userid) {
	int client = GetClientOfUserId(userid);
	if (IsValidClient(client) && !IsPlayerAlive(client) && GetClientTeam(client) > CS_TEAM_SPECTATOR)
	{
		ClientCommand(client, "zclass");
	}
	return Plugin_Stop;
}

////////////////////////////////////////////////////////////////////////////
void Formatb(int toggle, char[] buffer, int maxlength)
{
	if (toggle == 0)
	{
		Format(buffer, maxlength, "ENABLE");
	}
	else if (toggle == 1)
	{
		Format(buffer, maxlength, "DISABLE");
	}
	else if (toggle == 2)
	{
		Format(buffer, maxlength, "NEW");
	}
	else if (toggle == 3)
	{
		Format(buffer, maxlength, "OLD");
	}
}