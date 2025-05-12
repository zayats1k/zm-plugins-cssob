enum struct CvarsList
{
	ConVar GAME_DESCIPTION;
	ConVar MAP_CONFIG_PATH;
	ConVar MAP_MANE;
	ConVar CHAT_PREFIX;
	ConVar CHAT_CONSOLE;

	ConVar NOBLOCK;
	ConVar REPEATKILL;

	ConVar MENU_COMMANDS;

	ConVar ACCOUNT_CASHFILL_VALUE;
	ConVar ACCOUNT_CASHDMG;
	
	ConVar MARKET_MENU_COMMANDS;
	ConVar MARKET_MENU;
	ConVar MARKET_FAVORITES;
	ConVar MARKET_BUYTIME;
	ConVar MARKET_HUMAN_OPEN_ALL;
	ConVar MARKET_OFF_WHEN_STARTED;
	
	ConVar CLASSES_MENU_COMMANDS_ZOMBIE;
	ConVar CLASSES_MENU_COMMANDS_HUMAN;
	ConVar CLASSES_RANDOM_ZOMBIE;
	ConVar CLASSES_RANDOM_HUMAN;
	ConVar CLASSES_OLD_SPEED;
	
	ConVar COSTUMES_MENU_COMMANDS;
	
	ConVar INFECTION_COUNTDOWN_TIME;
	ConVar INFECTION_COUNTDOWN_HUD;
	
	ConVar WEAPONS_REMOVE_DROPPED;
	
	ConVar SEFFECTS_ROUND_COUNT;
	ConVar SEFFECTS_ROUND_START_AMBIENT;
	
	ConVar VEFFECTS_RAGDOLL_REMOVE;
	ConVar VEFFECTS_RAGDOLL_DISSOLVE;
	ConVar VEFFECTS_RAGDOLL_DELAY;
	
	ConVar VEFFECTS_INFECT_FADE_COLOR;
	ConVar VEFFECTS_INFECT_FADE_DURATION;
	ConVar VEFFECTS_INFECT_FADE_TIME;
	ConVar VEFFECTS_HUMANIZE_FADE_COLOR;
	ConVar VEFFECTS_HUMANIZE_FADE_DURATION;
	ConVar VEFFECTS_HUMANIZE_FADE_TIME;
	
	ConVar VEFFECTS_INFECT_DURATION;
	ConVar VEFFECTS_INFECT_NAME;
	ConVar VEFFECTS_INFECT_ATTACH;
	
	ConVar VEFFECTS_GAME_START_FADE_COLOR;
	ConVar VEFFECTS_GAME_START_FADE_DURATION;
	ConVar VEFFECTS_GAME_START_FADE_TIME;
	ConVar VEFFECTS_ROUND_END_ZOMBIE_FADE_COLOR;
	ConVar VEFFECTS_ROUND_END_ZOMBIE_FADE_DURATION;
	ConVar VEFFECTS_ROUND_END_ZOMBIE_FADE_TIME;
	ConVar VEFFECTS_ROUND_END_HUMAN_FADE_COLOR;
	ConVar VEFFECTS_ROUND_END_HUMAN_FADE_DURATION;
	ConVar VEFFECTS_ROUND_END_HUMAN_FADE_TIME;
	ConVar VEFFECTS_ROUND_END_DRAW_FADE_COLOR;
	ConVar VEFFECTS_ROUND_END_DRAW_FADE_DURATION;
	ConVar VEFFECTS_ROUND_END_DRAW_FADE_TIME;
	
	ConVar VEFFECTS_LIGHTSTYLE;
	
	ConVar VEFFECTS_SUN_DISABLE;
	
	ConVar RESPAWN_HUD;
	ConVar RESPAWN_HUD_DEATH;
	ConVar RESPAWN_HUD_BUTTON;
	ConVar RESPAWN_HUD_STUCK;
	
	ConVar JUMPBOOST;
	ConVar JUMPBOOST_MULTIPLIER;
	ConVar JUMPBOOST_MAX;
	
	ConVar WARMUP_TIME;
	ConVar WARMUP_RATIO;
	ConVar WARMUP_TEAM;
	ConVar WARMUP_TIME_HUD;
	ConVar WARMUP_WAITING_HUD;
	
	ConVar TELEPORT_MENU_COMMANDS;
	ConVar TELEPORT_ESCAPE;
	ConVar TELEPORT_ZOMBIE;
	ConVar TELEPORT_HUMAN;
	ConVar TELEPORT_DELAY_ZOMBIE;
	ConVar TELEPORT_DELAY_HUMAN;
	ConVar TELEPORT_MAX_ZOMBIE;
	ConVar TELEPORT_MAX_HUMAN;
	ConVar TELEPORT_AUTOCANCEL;
	ConVar TELEPORT_AUTOCANCEL_DIST;
	ConVar TELEPORT_SPAWN_IOCATON;
	
	ConVar FREEZE_TIME;
	ConVar ROUND_TIME;
	ConVar ROUND_RESTART_DELAY;
	ConVar AUTO_TEAM_BALANCE;
	ConVar LIMIT_TEAMS;
	ConVar HUD_HINT_SOUND;
	ConVar IGNORE_ROUND_WIN_CONDITIONS;
	ConVar NOMVP;
	ConVar NOWINPANEL;
	
	ConVar FOOTSTEPS;
}
CvarsList sCvarList;

void CvarsOnInit()
{
	static char name[MAX_TARGET_LENGTH];
	sCvarList.GAME_DESCIPTION = CreateConVar("zm_game_desciption", "");
	sCvarList.GAME_DESCIPTION.AddChangeHook(Hook_GameDescription);
	sCvarList.GAME_DESCIPTION.GetString(name, sizeof(name));
	if (name[0]) {
		SteamWorks_SetGameDescription(name);
	}
	
	sCvarList.MAP_CONFIG_PATH = CreateConVar("zm_map_configs_path", "");
	sCvarList.MAP_MANE = CreateConVar("zm_map_name", "");
	sCvarList.MAP_MANE.AddChangeHook(Hook_MapName);
	
	sCvarList.CHAT_PREFIX = CreateConVar("zm_chat_prefix", "");
	sCvarList.CHAT_CONSOLE = CreateConVar("zm_chat_console", "");
	
	sCvarList.NOBLOCK = CreateConVar("zm_noblock", "0");
	sCvarList.REPEATKILL = CreateConVar("zm_repeatkill", "0.0");
	
	sCvarList.MENU_COMMANDS = CreateConVar("zm_menu_commands", "");

	sCvarList.ACCOUNT_CASHFILL_VALUE = CreateConVar("zm_account_cashfill", "0");
	sCvarList.ACCOUNT_CASHDMG = CreateConVar("zm_account_cashdmg", "0");

	sCvarList.MARKET_MENU_COMMANDS = CreateConVar("zm_market_menu_commands", "");
	sCvarList.MARKET_MENU = CreateConVar("zm_market_menu", "0");
	sCvarList.MARKET_FAVORITES = CreateConVar("zm_market_favorites", "0");
	sCvarList.MARKET_BUYTIME = CreateConVar("zm_market_buytime", "0");
	sCvarList.MARKET_HUMAN_OPEN_ALL = CreateConVar("zm_market_human_open_all_menu", "0");
	sCvarList.MARKET_OFF_WHEN_STARTED = CreateConVar("zm_market_off_menu_when_mode_started", "0");

	sCvarList.CLASSES_MENU_COMMANDS_ZOMBIE = CreateConVar("zm_classes_menu_commands_zombie", "");
	sCvarList.CLASSES_MENU_COMMANDS_HUMAN = CreateConVar("zm_classes_menu_commands_human", "");
	sCvarList.CLASSES_RANDOM_ZOMBIE = CreateConVar("zm_classes_random_zombie", "0");
	sCvarList.CLASSES_RANDOM_HUMAN = CreateConVar("zm_classes_random_human", "0");
	sCvarList.CLASSES_OLD_SPEED = CreateConVar("zm_classes_old_speed", "0");

	sCvarList.COSTUMES_MENU_COMMANDS = CreateConVar("zm_costumes_menu_commands", "");

	sCvarList.INFECTION_COUNTDOWN_TIME = CreateConVar("zm_infection_countdown_timer", "30");
	sCvarList.INFECTION_COUNTDOWN_HUD = CreateConVar("zm_infection_countdown_hud", "");
	
	sCvarList.WEAPONS_REMOVE_DROPPED = CreateConVar("zm_weapons_remove_dropped", "0.0");
	
	sCvarList.SEFFECTS_ROUND_COUNT = CreateConVar("zm_seffects_round_count", "");
	sCvarList.SEFFECTS_ROUND_START_AMBIENT = CreateConVar("zm_seffects_round_start_ambient", "");
	
	sCvarList.VEFFECTS_RAGDOLL_REMOVE = CreateConVar("zm_veffects_ragdoll_remove", "0");
	sCvarList.VEFFECTS_RAGDOLL_DISSOLVE = CreateConVar("zm_veffects_ragdoll_dissolve", "-1");
	sCvarList.VEFFECTS_RAGDOLL_DELAY = CreateConVar("zm_veffects_ragdoll_delay", "0.5");
	
	sCvarList.VEFFECTS_INFECT_FADE_COLOR = CreateConVar("zm_veffects_infect_fade_color", "0 0 0 0");
	sCvarList.VEFFECTS_INFECT_FADE_DURATION = CreateConVar("zm_veffects_infect_fade_duration", "1.0");
	sCvarList.VEFFECTS_INFECT_FADE_TIME = CreateConVar("zm_veffects_infect_fade_time", "1.0");
	sCvarList.VEFFECTS_HUMANIZE_FADE_COLOR = CreateConVar("zm_veffects_humanize_fade_color", "0 0 0 0");
	sCvarList.VEFFECTS_HUMANIZE_FADE_DURATION = CreateConVar("zm_veffects_humanize_fade_duration", "1.0");
	sCvarList.VEFFECTS_HUMANIZE_FADE_TIME = CreateConVar("zm_veffects_humanize_fade_time", "1.0");
	
	sCvarList.VEFFECTS_INFECT_DURATION = CreateConVar("zm_veffects_infect_duration", "0.0");
	sCvarList.VEFFECTS_INFECT_NAME = CreateConVar("zm_veffects_infect_name", "");
	sCvarList.VEFFECTS_INFECT_ATTACH = CreateConVar("zm_veffects_infect_attachment", "");

	sCvarList.VEFFECTS_GAME_START_FADE_COLOR = CreateConVar("zm_veffects_game_start_fade_color", "0 0 0 0");
	sCvarList.VEFFECTS_GAME_START_FADE_DURATION = CreateConVar("zm_veffects_game_start_fade_duration", "1.0");
	sCvarList.VEFFECTS_GAME_START_FADE_TIME = CreateConVar("zm_veffects_game_start_fade_time", "1.0");
	sCvarList.VEFFECTS_ROUND_END_ZOMBIE_FADE_COLOR = CreateConVar("zm_veffects_round_end_zombie_fade_color", "0 0 0 0");
	sCvarList.VEFFECTS_ROUND_END_ZOMBIE_FADE_DURATION = CreateConVar("zm_veffects_round_end_zombie_fade_duration", "1.0");
	sCvarList.VEFFECTS_ROUND_END_ZOMBIE_FADE_TIME = CreateConVar("zm_veffects_round_end_zombie_fade_time", "1.0");
	sCvarList.VEFFECTS_ROUND_END_HUMAN_FADE_COLOR = CreateConVar("zm_veffects_round_end_human_fade_color", "0 0 0 0");
	sCvarList.VEFFECTS_ROUND_END_HUMAN_FADE_DURATION = CreateConVar("zm_veffects_round_end_human_fade_duration", "1.0");
	sCvarList.VEFFECTS_ROUND_END_HUMAN_FADE_TIME = CreateConVar("zm_veffects_round_end_human_fade_time", "1.0");
	sCvarList.VEFFECTS_ROUND_END_DRAW_FADE_COLOR = CreateConVar("zm_veffects_round_end_draw_fade_color", "0 0 0 0");
	sCvarList.VEFFECTS_ROUND_END_DRAW_FADE_DURATION = CreateConVar("zm_veffects_round_end_draw_fade_duration", "1.0");
	sCvarList.VEFFECTS_ROUND_END_DRAW_FADE_TIME = CreateConVar("zm_veffects_round_end_draw_fade_time", "1.0");
	
	sCvarList.VEFFECTS_LIGHTSTYLE = CreateConVar("zm_veffects_lightstyle", "");
	sCvarList.VEFFECTS_SUN_DISABLE = CreateConVar("zm_veffects_sun_disable", "0");
	
	sCvarList.RESPAWN_HUD = CreateConVar("zm_respawn_hud", "");
	sCvarList.RESPAWN_HUD_DEATH = CreateConVar("zm_respawn_hud_death", "");
	sCvarList.RESPAWN_HUD_BUTTON = CreateConVar("zm_respawn_hud_button", "");
	sCvarList.RESPAWN_HUD_STUCK = CreateConVar("zm_respawn_hud_stuck", "");
	
	sCvarList.WARMUP_TIME = CreateConVar("zm_warmup_time", "0");
	sCvarList.WARMUP_RATIO = CreateConVar("zm_warmup_ratio", "0.0");
	sCvarList.WARMUP_TEAM = CreateConVar("zm_warmup_team", "0");
	sCvarList.WARMUP_TIME_HUD = CreateConVar("zm_warmup_time_hud", "");
	sCvarList.WARMUP_WAITING_HUD = CreateConVar("zm_warmup_waiting_hud", "");
	
	sCvarList.JUMPBOOST = CreateConVar("zm_jumpboost", "0");
	sCvarList.JUMPBOOST_MULTIPLIER = CreateConVar("zm_jumpboost_multiplier", "0.0");
	sCvarList.JUMPBOOST_MAX = CreateConVar("zm_jumpboost_max", "0.0");
	
	sCvarList.TELEPORT_MENU_COMMANDS = CreateConVar("zm_teleport_menu_commands", "");
	sCvarList.TELEPORT_ESCAPE = CreateConVar("zm_teleport_escape", "0");
	sCvarList.TELEPORT_ZOMBIE = CreateConVar("zm_teleport_zombie", "0");
	sCvarList.TELEPORT_HUMAN = CreateConVar("zm_teleport_human", "0");
	sCvarList.TELEPORT_DELAY_ZOMBIE = CreateConVar("zm_teleport_delay_zombie", "3.0");
	sCvarList.TELEPORT_DELAY_HUMAN = CreateConVar("zm_teleport_delay_human", "3.0");
	sCvarList.TELEPORT_MAX_ZOMBIE = CreateConVar("zm_teleport_max_zombie", "3");
	sCvarList.TELEPORT_MAX_HUMAN =  CreateConVar("zm_teleport_max_human", "1");
	sCvarList.TELEPORT_AUTOCANCEL = CreateConVar("zm_teleport_autocancel", "0");
	sCvarList.TELEPORT_AUTOCANCEL_DIST = CreateConVar("zm_teleport_autocancel_distance", "0.0");
	sCvarList.TELEPORT_SPAWN_IOCATON = CreateConVar("zm_teleport_spawn_location", "0");
	
	sCvarList.ROUND_TIME = FindConVar("mp_roundtime");
	sCvarList.ROUND_TIME.SetBounds(ConVarBound_Upper, true, 546.0);
	sCvarList.ROUND_TIME.AddChangeHook(Hook_RoundTime);
	
	sCvarList.ROUND_RESTART_DELAY = FindConVar("mp_round_restart_delay");
	FindConVar("mp_restartgame").AddChangeHook(Hook_RestartGame);
	
	sCvarList.FREEZE_TIME = FindConVar("mp_freezetime"); 
	sCvarList.FREEZE_TIME.AddChangeHook(Hook_Lock);
	sCvarList.FREEZE_TIME.IntValue = 0;
	
	sCvarList.AUTO_TEAM_BALANCE = FindConVar("mp_autoteambalance"); 
	sCvarList.AUTO_TEAM_BALANCE.AddChangeHook(Hook_Lock);
	sCvarList.AUTO_TEAM_BALANCE.IntValue = 0;
	
	sCvarList.LIMIT_TEAMS = FindConVar("mp_limitteams"); 
	sCvarList.LIMIT_TEAMS.AddChangeHook(Hook_Lock);
	sCvarList.LIMIT_TEAMS.IntValue = 0;
	
	sCvarList.HUD_HINT_SOUND = FindConVar("sv_hudhint_sound"); 
	sCvarList.HUD_HINT_SOUND.AddChangeHook(Hook_Lock);
	sCvarList.HUD_HINT_SOUND.IntValue = 0;
	
	sCvarList.IGNORE_ROUND_WIN_CONDITIONS = FindConVar("mp_ignore_round_win_conditions"); 
	sCvarList.IGNORE_ROUND_WIN_CONDITIONS.AddChangeHook(Hook_UnLock);
	sCvarList.IGNORE_ROUND_WIN_CONDITIONS.IntValue = 1;
	
	sCvarList.NOMVP = FindConVar("sv_nomvp"); 
	sCvarList.NOMVP.AddChangeHook(Hook_UnLock);
	sCvarList.NOMVP.IntValue = 1;
	
	sCvarList.NOWINPANEL = FindConVar("sv_nowinpanel"); 
	sCvarList.NOWINPANEL.AddChangeHook(Hook_UnLock);
	sCvarList.NOWINPANEL.IntValue = 1;
	
	sCvarList.FOOTSTEPS = FindConVar("sv_footsteps");
	sCvarList.FOOTSTEPS.Flags &= ~(FCVAR_NOTIFY|FCVAR_REPLICATED);
	
	VEffectsOnCvarInit();
}

void CvarsOnClientPutInServer(int client)
{
	if (!IsFakeClient(client))
	{
		sCvarList.FOOTSTEPS.ReplicateToClient(client, "0");
	}
}

public void Hook_GameDescription(ConVar cvar, char[] oldValue, char[] newValue)
{
	static char name[MAX_TARGET_LENGTH];
	cvar.GetString(name, sizeof(name));
	
	if (name[0])
	{
		SteamWorks_SetGameDescription(name);
	}
}

public void OnGameFrame()
{
	Hook_MapName(sCvarList.MAP_MANE, "", ""); // idk
}

public void Hook_MapName(ConVar cvar, char[] oldValue, char[] newValue)
{
	if (cvar == null) {
		return;
	}

	static char name[MAX_TARGET_LENGTH];
	cvar.GetString(name, sizeof(name));
	
	if (name[0])
	{
		SteamWorks_SetMapName(name);
	}
}

public void Hook_RestartGame(ConVar cvar, char[] oldValue, char[] newValue)
{
	cvar.IntValue = 0;
	int delay = StringToInt(newValue);
	if (delay <= 0) {
		return;
	}
	
	ZombieModOnGameStart();
}

public void Hook_RoundTime(ConVar cvar, char[] oldValue, char[] newValue)
{
	int roundtime = StringToInt(newValue);
	
	if (roundtime == 1) {
		return;
	}
	
	delete sServerData.RoundTime;
	ToolsSetRoundTime(roundtime * 60.0);
	sServerData.RoundTime = CreateTimer((roundtime * 60.0), Timer_CheckRoundTimeExpired, _, TIMER_FLAG_NO_MAPCHANGE);
}

public void Hook_Lock(ConVar cvar, char[] oldValue, char[] newValue)
{
	cvar.IntValue = 0;
}

public void Hook_UnLock(ConVar cvar, char[] oldValue, char[] newValue)
{
	cvar.IntValue = 1;
}