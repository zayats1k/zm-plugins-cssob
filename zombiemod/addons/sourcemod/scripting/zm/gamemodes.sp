enum
{
	GAMEMODES_DATA_NAME,
	GAMEMODES_DATA_HUD_NAME,
	GAMEMODES_DATA_CHANCE,
	GAMEMODES_DATA_MINPLAYERS,
	GAMEMODES_DATA_RATIO,
	GAMEMODES_DATA_ROUNDTIME,
	GAMEMODES_DATA_HEALTH_HUMAN,
	GAMEMODES_DATA_HEALTH_ZOMBIE,
	GAMEMODES_DATA_TYPE_HUMAN,
	GAMEMODES_DATA_TYPE_ZOMBIE,
	GAMEMODES_DATA_DEATHMATCH,
	GAMEMODES_DATA_RESPAWN,
	GAMEMODES_DATA_AMOUNT,
	GAMEMODES_DATA_DELAY,
	GAMEMODES_DATA_ARMOR,
	GAMEMODES_DATA_ESCAPE,
	GAMEMODES_DATA_REGEN,
	GAMEMODES_DATA_KILLPROPS,
	GAMEMODES_DATA_INFECTION,
	
	// sounds and huds
	GAMEMODES_DATA_SOUND_START,
	GAMEMODES_DATA_HUD_START,
	GAMEMODES_DATA_SOUND_GAMESTART,
	GAMEMODES_DATA_HUD_GAMESTART,
	GAMEMODES_DATA_SOUND_ENDHUMAN,
	GAMEMODES_DATA_HUD_ENDHUMAN,
	GAMEMODES_DATA_SOUND_ENDZOMBIE,
	GAMEMODES_DATA_HUD_ENDZOMBIE,
	GAMEMODES_DATA_SOUND_ENDDRAW,
	GAMEMODES_DATA_HUD_ENDDRAW,
	
	// sounds
	GAMEMODES_DATA_SOUND_COMEBACK,
	GAMEMODES_DATA_SOUND_AMBIENT
};

void GameModesOnLoad()
{
	ConfigRegisterConfig(File_GameModes, Structure_KeyValue, CONFIG_FILE_ALIAS_GAMEMODES);

	static char buffer[PLATFORM_LINE_LENGTH];
	if (!ConfigGetFullPath(CONFIG_FILE_ALIAS_GAMEMODES, buffer, sizeof(buffer)))
	{
		LogError("[GameModes] [Config Validation] Missing gamemodes config file: \"%s\"", buffer);
		return;
	}
	
	ConfigSetConfigPath(File_GameModes, buffer);
	if (!ConfigLoadConfig(File_GameModes, sServerData.GameModes, PLATFORM_LINE_LENGTH))
	{
		LogError("[GameModes] [Config Validation] Unexpected error encountered loading: \"%s\"", buffer);
		return;
	}

	if (sServerData.GameModes == null)
	{
		LogError("[GameModes] [Config Validation] Invalid Handle 0 (error: 4)");
		LogError("[GameModes] [Config Validation] server restart");
		return;
	}

	GameModesOnCacheData();

	ConfigSetConfigLoaded(File_GameModes, true);
	ConfigSetConfigReloadFunc(File_GameModes, GetFunctionByName(GetMyHandle(), "GameModesOnConfigReload"));
	ConfigSetConfigHandle(File_GameModes, sServerData.GameModes);
}

void GameModesOnCacheData()
{
	static char buffer[PLATFORM_LINE_LENGTH];
	ConfigGetConfigPath(File_GameModes, buffer, sizeof(buffer));

	KeyValues kv;
	if (!ConfigOpenConfigFile(File_GameModes, kv))
	{
		LogError("[GameModes] [Config Validation] Unexpected error caching data from gamemodes config file: \"%s\"", buffer);
		return;
	}

	int size = sServerData.GameModes.Length;
	if (!size)
	{
		LogError("[GameModes] [Config Validation] No usable data found in gamemodes config file: \"%s\"", buffer);
		return;
	}
	
	for (int i = 0; i < size; i++)
	{
		ModesGetName(i, buffer, sizeof(buffer)); // Index: 0
		kv.Rewind();
		if (!kv.JumpToKey(buffer))
		{
			SetFailState("[GameModes] [Config Validation] Couldn't cache gamemode data for: \"%s\" (check gamemodes config)", buffer);
			continue;
		}
		
		if (!TranslationIsPhraseExists(buffer))
		{
			SetFailState("[GameModes] [Config Validation] Couldn't cache gamemode name: \"%s\" (check translation file)", buffer);
			continue;
		}

		ArrayList array = sServerData.GameModes.Get(i);
		
		array.Push(HudsKeyToIndex(buffer)); // Index: 1
		
		array.Push(kv.GetNum("chance", 0)); // Index: 2
		array.Push(kv.GetNum("minplayer", 0)); // Index: 3
		array.Push(kv.GetFloat("ratio", 0.0)); // Index: 4
		array.Push(kv.GetNum("roundtime", 0)); // Index: 5
		
		array.Push(kv.GetNum("health_human", 0)); // Index: 6
		array.Push(kv.GetNum("health_zombie", 0)); // Index: 7
		
		kv.GetString("type_human", buffer, sizeof(buffer), "human");
		array.Push(sServerData.Types.FindString(buffer)); // Index: 8
		kv.GetString("type_zombie", buffer, sizeof(buffer), "zombie");
		array.Push(sServerData.Types.FindString(buffer)); // Index: 9
		
		array.Push(kv.GetNum("deathmatch", 0)); // Index: 10
		array.Push(kv.GetNum("respawn", 0)); // Index: 11
		array.Push(kv.GetNum("respawn_amount", 0)); // Index: 12
		array.Push(kv.GetNum("respawn_delay", 0)); // Index: 13
		
		array.Push(ConfigKvGetStringBool(kv, "heavyarmor", "on")); // Index: 14
		array.Push(ConfigKvGetStringBool(kv, "escape", "off")); // Index: 15
		array.Push(ConfigKvGetStringBool(kv, "regen", "on")); // Index: 16
		array.Push(ConfigKvGetStringBool(kv, "killprops", "off")); // Index: 17
		array.Push(kv.GetNum("infect", 0)); // Index: 18
		
		kv.GetString("start", buffer, sizeof(buffer), "");
		array.Push(SoundsKeyToIndex(buffer)); // Index: 19
		array.Push(HudsKeyToIndex(buffer)); // Index: 20
		kv.GetString("game_start", buffer, sizeof(buffer), "");
		array.Push(SoundsKeyToIndex(buffer)); // Index: 21
		array.Push(HudsKeyToIndex(buffer)); // Index: 22
		kv.GetString("round_end_human", buffer, sizeof(buffer), "");
		array.Push(SoundsKeyToIndex(buffer)); // Index: 23
		array.Push(HudsKeyToIndex(buffer)); // Index: 24
		kv.GetString("round_end_zombie", buffer, sizeof(buffer), "");
		array.Push(SoundsKeyToIndex(buffer)); // Index: 25
		array.Push(HudsKeyToIndex(buffer)); // Index: 26
		kv.GetString("round_end_draw", buffer, sizeof(buffer), "");
		array.Push(SoundsKeyToIndex(buffer)); // Index: 27
		array.Push(HudsKeyToIndex(buffer)); // Index: 28
		kv.GetString("comeback", buffer, sizeof(buffer), "");
		array.Push(SoundsKeyToIndex(buffer)); // Index: 29
		kv.GetString("ambient", buffer, sizeof(buffer), "");
		array.Push(SoundsKeyToIndex(buffer)); // Index: 30
	}
	delete kv;
}

public void GameModesOnConfigReload()
{
	GameModesOnLoad();
}

void GameModeHudsStart()
{
	if (HudsPrintHudTextAll(sServerData.SyncHud, ModesGetHudNameID(sServerData.RoundMode)))
	{
		CreateTimer(1.0, Timer_GameModeHudRepeat, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_GameModeHudRepeat(Handle timer)
{
	if (!sServerData.RoundEnd)
	{
		if (HudsPrintHudTextAll(sServerData.SyncHud, ModesGetHudNameID(sServerData.RoundMode)))
		{
			CreateTimer(1.0, Timer_GameModeHudRepeat, _, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	return Plugin_Stop;
}

void ModesGetName(int id, char[] name, int maxLen)
{
	if (id == -1) {
		strcopy(name, maxLen, "");
		return;
	}
	
	ArrayList array = sServerData.GameModes.Get(id);
	array.GetString(GAMEMODES_DATA_NAME, name, maxLen);
}

int ModesGetHudNameID(int id)
{
	if (id == -1) {
		return -1;
	}
	
	ArrayList array = sServerData.GameModes.Get(id);
	return array.Get(GAMEMODES_DATA_HUD_NAME);
}

int ModesGetChance(int id)
{
	if (id == -1) {
		return 0;
	}
	
	ArrayList array = sServerData.GameModes.Get(id);
	return array.Get(GAMEMODES_DATA_CHANCE);
}

int ModesGetMinPlayers(int id)
{
	if (id == -1) {
		return 0;
	}
	
	ArrayList array = sServerData.GameModes.Get(id);
	return array.Get(GAMEMODES_DATA_MINPLAYERS);
}

float ModesGetRatio(int id)
{
	if (id == -1) {
		return 0.0;
	}
	
	ArrayList array = sServerData.GameModes.Get(id);
	return array.Get(GAMEMODES_DATA_RATIO);
}

int ModesGetRoundTime(int id)
{
	if (id == -1) {
		return 0;
	}
	
	ArrayList array = sServerData.GameModes.Get(id);
	return array.Get(GAMEMODES_DATA_ROUNDTIME);
}

int ModesGetHealthHuman(int id)
{
	if (id == -1) {
		return 0;
	}
	
	ArrayList array = sServerData.GameModes.Get(id);
	return array.Get(GAMEMODES_DATA_HEALTH_HUMAN);
}

int ModesGetHealthZombie(int id)
{
	if (id == -1) {
		return 0;
	}
	
	ArrayList array = sServerData.GameModes.Get(id);
	return array.Get(GAMEMODES_DATA_HEALTH_ZOMBIE);
}

int ModesGetTypeHuman(int id)
{
	if (id == -1) {
		return sServerData.Human;
	}
	
	ArrayList array = sServerData.GameModes.Get(id);
	return array.Get(GAMEMODES_DATA_TYPE_HUMAN);
}

int ModesGetTypeZombie(int id)
{
	if (id == -1) {
		return sServerData.Zombie;
	}
	
	ArrayList array = sServerData.GameModes.Get(id);
	return array.Get(GAMEMODES_DATA_TYPE_ZOMBIE);
}

int ModesGetMatch(int id)
{
	if (id == -1) {
		return 1;
	}
	
	ArrayList array = sServerData.GameModes.Get(id);
	return array.Get(GAMEMODES_DATA_DEATHMATCH);
}

int ModesGetRespawn(int id)
{
	if (id == -1) {
		return 0;
	}
	
	ArrayList array = sServerData.GameModes.Get(id);
	return array.Get(GAMEMODES_DATA_RESPAWN);
}

int ModesGetAmount(int id)
{
	if (id == -1) {
		return 0;
	}
	
	ArrayList array = sServerData.GameModes.Get(id);
	return array.Get(GAMEMODES_DATA_AMOUNT);
}

int ModesGetDelay(int id)
{
	if (id == -1) {
		return 0;
	}
	
	ArrayList array = sServerData.GameModes.Get(id);
	return array.Get(GAMEMODES_DATA_DELAY);
}

bool ModesIsArmor(int id)
{
	if (id == -1) {
		return false;
	}
	
	ArrayList array = sServerData.GameModes.Get(id);
	return array.Get(GAMEMODES_DATA_ARMOR);
}

bool ModesIsEscape(int id)
{
	if (id == -1) {
		return false;
	}
	
	ArrayList array = sServerData.GameModes.Get(id);
	return array.Get(GAMEMODES_DATA_ESCAPE);
}

bool ModesIsRegen(int id)
{
	if (id == -1) {
		return false;
	}
	
	ArrayList array = sServerData.GameModes.Get(id);
	return array.Get(GAMEMODES_DATA_REGEN);
}

bool ModesKillProps(int id)
{
	if (id == -1) {
		return false;
	}
	
	ArrayList array = sServerData.GameModes.Get(id);
	return array.Get(GAMEMODES_DATA_KILLPROPS);
}

int ModesIsInfection(int id)
{
	if (id == -1) {
		return 0;
	}
	
	ArrayList array = sServerData.GameModes.Get(id);
	return array.Get(GAMEMODES_DATA_INFECTION);
}

int ModesGetHudStartID(int id)
{
	if (id == -1) {
		return -1;
	}
	
	ArrayList array = sServerData.GameModes.Get(id);
	return array.Get(GAMEMODES_DATA_HUD_START);
}

int ModesGetHudGameStartID(int id)
{
	if (id == -1) {
		return -1;
	}
	
	ArrayList array = sServerData.GameModes.Get(id);
	return array.Get(GAMEMODES_DATA_HUD_GAMESTART);
}

int ModesGetHudEndHumanID(int id)
{
	if (id == -1) {
		return -1;
	}
	
	ArrayList array = sServerData.GameModes.Get(id);
	return array.Get(GAMEMODES_DATA_HUD_ENDHUMAN);
}

int ModesGetHudEndZombieID(int id)
{
	if (id == -1) {
		return -1;
	}
	
	ArrayList array = sServerData.GameModes.Get(id);
	return array.Get(GAMEMODES_DATA_HUD_ENDZOMBIE);
}

int ModesGetHudEndDrawID(int id)
{
	if (id == -1) {
		return -1;
	}
	
	ArrayList array = sServerData.GameModes.Get(id);
	return array.Get(GAMEMODES_DATA_HUD_ENDDRAW);
}

int ModesGetSoundStartID(int id)
{
	if (id == -1) {
		return -1;
	}
	
	ArrayList array = sServerData.GameModes.Get(id);
	return array.Get(GAMEMODES_DATA_SOUND_START);
}

int ModesGetSoundGameStartID(int id)
{
	if (id == -1) {
		return -1;
	}
	
	ArrayList array = sServerData.GameModes.Get(id);
	return array.Get(GAMEMODES_DATA_SOUND_GAMESTART);
}

int ModesGetSoundEndHumanID(int id)
{
	if (id == -1) {
		return -1;
	}
	
	ArrayList array = sServerData.GameModes.Get(id);
	return array.Get(GAMEMODES_DATA_SOUND_ENDHUMAN);
}

int ModesGetSoundEndZombieID(int id)
{
	if (id == -1) {
		return -1;
	}
	
	ArrayList array = sServerData.GameModes.Get(id);
	return array.Get(GAMEMODES_DATA_SOUND_ENDZOMBIE);
}

int ModesGetSoundEndDrawID(int id)
{
	if (id == -1) {
		return -1;
	}
	
	ArrayList array = sServerData.GameModes.Get(id);
	return array.Get(GAMEMODES_DATA_SOUND_ENDDRAW);
}

int ModesGetSoundComebackID(int id)
{
	if (id == -1) {
		return -1;
	}
	
	ArrayList array = sServerData.GameModes.Get(id);
	return array.Get(GAMEMODES_DATA_SOUND_COMEBACK);
}

int ModesGetSoundAmbientID(int id)
{
	if (id == -1) {
		return -1;
	}
	
	ArrayList array = sServerData.GameModes.Get(id);
	return array.Get(GAMEMODES_DATA_SOUND_AMBIENT);
}

int ModesNameToIndex(const char[] name)
{
	static char modename[SMALL_LINE_LENGTH];
	for (int i = 0; i < sServerData.GameModes.Length; i++)
	{
		ModesGetName(i, modename, sizeof(modename));
		if (!strcmp(modename, name, false))
		{
			return i;
		}
	}
	return -1;
}


void GameModesOnNativeInit() 
{
	CreateNative("ZM_GetCurrentGameMode", Native_GetCurrentGameMode);
	CreateNative("ZM_GetGameModeNameID", Native_GetGameModeNameID);
	CreateNative("ZM_GetGameModeName", Native_GetGameModeName);
	CreateNative("ZM_IsGameModeInfect", Native_IsGameModeInfect);
	CreateNative("ZM_GetGameModeTypeHuman", Native_GetGameModeTypeHuman);
	CreateNative("ZM_GetGameModeTypeZombie", Native_GetGameModeTypeZombie);
	CreateNative("ZM_GetGameModeMatch", Native_GetGameModeMatch);
	CreateNative("ZM_GetNumberGameMode", Native_GetNumberGameMode);
	CreateNative("ZM_GetGameModeMinPlayers", Native_GetGameModeMinPlayers);
	CreateNative("ZM_SetGameMode", Native_SetGameMode);
}

public int Native_GetCurrentGameMode(Handle plugin, int numParams)
{
	return sServerData.RoundMode;
}

public int Native_GetGameModeNameID(Handle plugin, int numParams)
{
	int maxLen;
	GetNativeStringLength(1, maxLen);

	if (!maxLen) {
		LogError("[GameModes] [Native Validation] Can't find mode with an empty name");
		return -1;
	}
	
	static char name[SMALL_LINE_LENGTH];
	GetNativeString(1, name, sizeof(name));
	return ModesNameToIndex(name);  
}

public int Native_GetGameModeName(Handle plugin, int numParams)
{
	int id = GetNativeCell(1);

	if (id == -1) {
		return id;
	}
	
	if (id >= sServerData.GameModes.Length) {
		LogError("[GameModes] [Native Validation] Invalid the mode index (%d)", id);
		return -1;
	}
	
	int maxLen = GetNativeCell(3);

	if (!maxLen) {
		LogError("[GameModes] [Native Validation] No buffer size");
		return -1;
	}
	
	static char name[SMALL_LINE_LENGTH];
	ModesGetName(id, name, sizeof(name));
	return SetNativeString(2, name, maxLen);
}

public int Native_IsGameModeInfect(Handle plugin, int numParams)
{
	int id = GetNativeCell(1);
	
	if (id == -1) {
		return false;
	}
	
	if (id >= sServerData.GameModes.Length) {
		LogError("[GameModes] [Native Validation] Invalid the mode index (%d)", id);
		return -1;
	}
	return ModesIsInfection(id);
}

public int Native_GetGameModeTypeHuman(Handle plugin, int numParams)
{
	int id = GetNativeCell(1);
	
	if (id == -1) {
		return false;
	}
	
	if (id >= sServerData.GameModes.Length) {
		LogError("[GameModes] [Native Validation] Invalid the mode index (%d)", id);
		return -1;
	}
	return ModesGetTypeHuman(id);
}

public int Native_GetGameModeTypeZombie(Handle plugin, int numParams)
{
	int id = GetNativeCell(1);
	
	if (id == -1) {
		return false;
	}
	
	if (id >= sServerData.GameModes.Length) {
		LogError("[GameModes] [Native Validation] Invalid the mode index (%d)", id);
		return -1;
	}
	return ModesGetTypeZombie(id);
}

public int Native_GetGameModeMatch(Handle plugin, int numParams)
{
	int id = GetNativeCell(1);

	if (id == -1) {
		return id;
	}
	
	if (id >= sServerData.GameModes.Length) {
		LogError("[GameModes] [Native Validation] Invalid the mode index (%d)", id);
		return -1;
	}
	return ModesGetMatch(id);
}

public int Native_GetGameModeMinPlayers(Handle plugin, int numParams)
{
	int id = GetNativeCell(1);

	if (id == -1) {
		return id;
	}
	
	if (id >= sServerData.GameModes.Length) {
		LogError("[GameModes] [Native Validation] Invalid the mode index (%d)", id);
		return -1;
	}
	return ModesGetMinPlayers(id);
}

public int Native_SetGameMode(Handle plugin, int numParams)
{
	int id = GetNativeCell(1);

	if (id == -1) {
		return false;
	}
	
	if (id >= sServerData.GameModes.Length) {
		LogError("[GameModes] [Native Validation] Invalid the mode index (%d)", id);
		return false;
	}
	
	ZombieModOnBegin(id, GetNativeCell(2));
	return true;
}

public int Native_GetNumberGameMode(Handle plugin, int numParams)
{
	return sServerData.GameModes.Length;
}