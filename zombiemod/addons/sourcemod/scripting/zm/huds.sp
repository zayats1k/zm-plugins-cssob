enum
{
	HUDS_DATA_KEY,
	HUDS_DATA_NAME,
	HUDS_DATA_POSITION,
	HUDS_DATA_HOLDTIME,
	HUDS_DATA_COLOR1,
	HUDS_DATA_COLOR2,
	HUDS_DATA_EFFECT,
	HUDS_DATA_FXTIME,
	HUDS_DATA_FADEIN,
	HUDS_DATA_FADEOUT
};

enum struct HudData
{
	int Countdown;
	int Warmuptimer;
	int Warmupwaiting;
	int Respawn;
	int RespawnDeath;
	int RespawnButton;
	int RespawnStuck;
}
HudData sHudData;

void HudsOnOnLoad()
{
	static char buffer[SMALL_LINE_LENGTH];
	sCvarList.INFECTION_COUNTDOWN_HUD.GetString(buffer, sizeof(buffer));
	sHudData.Countdown = HudsKeyToIndex(buffer);
	sCvarList.WARMUP_TIME_HUD.GetString(buffer, sizeof(buffer));
	sHudData.Warmuptimer = HudsKeyToIndex(buffer);
	sCvarList.WARMUP_WAITING_HUD.GetString(buffer, sizeof(buffer));
	sHudData.Warmupwaiting = HudsKeyToIndex(buffer);
	sCvarList.RESPAWN_HUD.GetString(buffer, sizeof(buffer));
	sHudData.Respawn = HudsKeyToIndex(buffer);
	sCvarList.RESPAWN_HUD_DEATH.GetString(buffer, sizeof(buffer));
	sHudData.RespawnDeath = HudsKeyToIndex(buffer);
	sCvarList.RESPAWN_HUD_BUTTON.GetString(buffer, sizeof(buffer));
	sHudData.RespawnButton = HudsKeyToIndex(buffer);
	sCvarList.RESPAWN_HUD_STUCK.GetString(buffer, sizeof(buffer));
	sHudData.RespawnStuck = HudsKeyToIndex(buffer);
}

void HudsOnCvarInit()
{
	HookConVarChange(sCvarList.INFECTION_COUNTDOWN_HUD, Hook_OnCvarHuds);
	HookConVarChange(sCvarList.WARMUP_TIME_HUD, Hook_OnCvarHuds);
	HookConVarChange(sCvarList.WARMUP_WAITING_HUD, Hook_OnCvarHuds);
	HookConVarChange(sCvarList.RESPAWN_HUD, Hook_OnCvarHuds);
	HookConVarChange(sCvarList.RESPAWN_HUD_BUTTON, Hook_OnCvarHuds);
	HookConVarChange(sCvarList.RESPAWN_HUD_STUCK, Hook_OnCvarHuds);
}

public void Hook_OnCvarHuds(ConVar convar, const char[] oldValue, const char[] newValue)
{    
	if (strcmp(oldValue, newValue, false))
	{
		if (sServerData.MapLoaded)
		{
			HudsOnOnLoad();
		}
	}
}

void HudsOnLoad()
{
	ConfigRegisterConfig(File_Huds, Structure_KeyValue, CONFIG_FILE_ALIAS_HUDS);

	static char buffer[PLATFORM_LINE_LENGTH];
	if (!ConfigGetFullPath(CONFIG_FILE_ALIAS_HUDS, buffer, sizeof(buffer)))
	{
		LogError("[Huds] [Config Validation] Missing huds config file: \"%s\"", buffer);
		return;
	}

	ConfigSetConfigPath(File_Huds, buffer);
	if (!ConfigLoadConfig(File_Huds, sServerData.Huds, PLATFORM_LINE_LENGTH))
	{
		LogError("[Huds] [Config Validation] Unexpected error encountered loading: \"%s\"", buffer);
		return;
	}
	
	if (sServerData.Huds == null)
	{
		LogError("[Huds] [Config Validation] Invalid Handle 0 (error: 4)");
		LogError("[Huds] [Config Validation] server restart");
		return;
	}
	
	HudsOnCacheData();
	
	ConfigSetConfigLoaded(File_Huds, true);
	ConfigSetConfigReloadFunc(File_Huds, GetFunctionByName(GetMyHandle(), "HudsOnConfigReload"));
	ConfigSetConfigHandle(File_Huds, sServerData.Huds);
	
	HudsOnOnLoad();
}

void HudsOnCacheData()
{
	static char buffer[PLATFORM_LINE_LENGTH], buffers[3][6];
	ConfigGetConfigPath(File_Huds, buffer, sizeof(buffer));
	
	KeyValues kv;
	if (!ConfigOpenConfigFile(File_Huds, kv))
	{
		LogError("[Huds] [Config Validation] Unexpected error caching data from huds config file: \"%s\"", buffer);
		return;
	}
	
	int size = sServerData.Huds.Length;
	if (!size)
	{
		LogError("[Huds] [Config Validation] No usable data found in huds config file: \"%s\"", buffer);
		return;
	}
	
	for (int i = 0; i < size; i++)
	{
		HudsGetKey(i, buffer, sizeof(buffer)); // Index: 0
		kv.Rewind();
		if (!kv.JumpToKey(buffer))
		{
			SetFailState("[Huds] [Config Validation] Couldn't cache hud data for: \"%s\" (check huds config)", buffer);
			continue;
		}
		
		ArrayList array = sServerData.Huds.Get(i);
		
		if (kv.GotoFirstSubKey())
		{
			do
			{
				kv.GetSectionName(buffer, sizeof(buffer));
				
				if (hasLength(buffer) && !TranslationIsPhraseExists(buffer))
				{
					LogError("[Huds] [Config Validation] Couldn't cache hud name: \"%s\" (check translation file)", buffer);
					continue;
				}
				
				array.PushString(buffer); // Index: i + 0
				
				float position[2]; kv.GetString("position", buffer, sizeof(buffer), "0.01 0.01");
				ExplodeString(buffer, " ", buffers, sizeof(buffers), sizeof(buffers[]));
				position[0] = StringToFloat(buffers[0]);
				position[1] = StringToFloat(buffers[1]);
				array.PushArray(position, sizeof(position)); // Index: i + 1
				
				array.Push(kv.GetFloat("holdTime", 0.0)); // Index: i + 2
				
				int color1[4]; kv.GetColor4("color1", color1);
				array.PushArray(color1, sizeof(color1)); // Index: i + 3
				int color2[4]; kv.GetColor4("color2", color2);
				array.PushArray(color2, sizeof(color2)); // Index: i + 4
				
				array.Push(kv.GetNum("effect", 0)); // Index: i + 5
				array.Push(kv.GetFloat("fxTime", 6.0)); // Index: i + 6
				array.Push(kv.GetFloat("fadeIn", 0.1)); // Index: i + 7
				array.Push(kv.GetFloat("fadeOut", 0.2)); // Index: i + 8
			}
			while (kv.GotoNextKey());
		}
	}
	delete kv;
}

public void HudsOnConfigReload()
{
	HudsOnLoad();
}

bool HudsPrintHudText(Handle Sync, int client, int key, int num = 0, any value = 0)
{
	static char name[PLATFORM_LINE_LENGTH];
	float position[2], holdTime, fxTime, fadeIn, fadeOut;
	int color1[4], color2[4], effect;
	
	if (HudsGetHud(key, num, name, position, holdTime, color1, color2, effect, fxTime, fadeIn, fadeOut))
	{
		TranslationPrintHudText(Sync, client, position, holdTime, color1, color2, effect, fxTime, fadeIn, fadeOut, name, name, value);
		return true;
	}
	return false;
}

bool HudsPrintHudTextAll(Handle Sync, int key, int num = 0, any value = 0)
{
	static char name[PLATFORM_LINE_LENGTH];
	float position[2], holdTime, fxTime, fadeIn, fadeOut;
	int color1[4], color2[4], effect;
	
	if (HudsGetHud(key, num, name, position, holdTime, color1, color2, effect, fxTime, fadeIn, fadeOut))
	{
		TranslationPrintHudTextAll(Sync, position, holdTime, color1, color2, effect, fxTime, fadeIn, fadeOut, name, name, value);
		return true;
	}
	return false;
}

void HudsGetKey(int id, char[] key, int maxLen)
{
	ArrayList array = sServerData.Huds.Get(id);
	array.GetString(HUDS_DATA_KEY, key, maxLen);
}

bool HudsGetHud(int key, int num = 0, char name[PLATFORM_LINE_LENGTH], float position[2], float& holdTime, int color1[4], int color2[4], int& effect, float& fxTime, float& fadeIn, float& fadeOut)
{
	if (key == -1) {
		return false;
	}

	ArrayList array = sServerData.Huds.Get(key);

	int size = (array.Length - 1) / HUDS_DATA_FADEOUT;
	if (num <= size)
	{
		int id = ((num ? num : UTIL_GetRandomInt(1, size)) - 1) * HUDS_DATA_FADEOUT;
		
		array.GetString(id + HUDS_DATA_NAME, name, sizeof(name));
		array.GetArray(id + HUDS_DATA_POSITION, position, sizeof(position));
		holdTime = array.Get(id + HUDS_DATA_HOLDTIME);
		array.GetArray(id + HUDS_DATA_COLOR1, color1, sizeof(color1));
		array.GetArray(id + HUDS_DATA_COLOR2, color2, sizeof(color2));
		effect = array.Get(id + HUDS_DATA_EFFECT);
		fxTime = array.Get(id + HUDS_DATA_FXTIME);
		fadeIn = array.Get(id + HUDS_DATA_FADEIN);
		fadeOut = array.Get(id + HUDS_DATA_FADEOUT);
		return true;
	}
	return false;
}

int HudsKeyToIndex(const char[] key)
{
	static char name[SMALL_LINE_LENGTH];
	for (int i = 0; i < sServerData.Huds.Length; i++)
	{
		HudsGetKey(i, name, sizeof(name));
		if (!strcmp(key, name, false))
		{
			return i;
		}
	}
	return -1;
}