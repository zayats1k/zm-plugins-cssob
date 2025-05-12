enum
{
	SOUNDS_DATA_KEY,
	SOUNDS_DATA_PATH,
	SOUNDS_DATA_VOLUME,
	SOUNDS_DATA_LEVEL,
	SOUNDS_DATA_FLAGS,
	SOUNDS_DATA_PITCH,
	SOUNDS_DATA_DURATION
};

void SoundsOnLoad()
{
	ConfigRegisterConfig(File_Sounds, Structure_KeyValue, CONFIG_FILE_ALIAS_SOUNDS);

	static char buffer[PLATFORM_LINE_LENGTH];
	if (!ConfigGetFullPath(CONFIG_FILE_ALIAS_SOUNDS, buffer, sizeof(buffer)))
	{
		LogError("[Sounds] [Config Validation] Missing sounds config file: \"%s\"", buffer);
		return;
	}

	ConfigSetConfigPath(File_Sounds, buffer);
	if (!ConfigLoadConfig(File_Sounds, sServerData.Sounds, PLATFORM_LINE_LENGTH))
	{
		LogError("[Sounds] [Config Validation] Unexpected error encountered loading: \"%s\"", buffer);
		return;
	}
	
	if (sServerData.Sounds == null)
	{
		LogError("[Sounds] [Config Validation] Invalid Handle 0 (error: 4)");
		LogError("[Sounds] [Config Validation] server restart");
		return;
	}
	
	SoundsOnCacheData();
	
	ConfigSetConfigLoaded(File_Sounds, true);
	ConfigSetConfigReloadFunc(File_Sounds, GetFunctionByName(GetMyHandle(), "SoundsOnConfigReload"));
	ConfigSetConfigHandle(File_Sounds, sServerData.Sounds);
	
	PlayerSoundsOnOnLoad();
}

void SoundsOnCacheData()
{
	static char buffer[PLATFORM_LINE_LENGTH];
	ConfigGetConfigPath(File_Sounds, buffer, sizeof(buffer));

	KeyValues kv;
	if (!ConfigOpenConfigFile(File_Sounds, kv))
	{
		LogError("[Sounds] [Config Validation] Unexpected error caching data from sounds config file: \"%s\"", buffer);
		return;
	}

	int size = sServerData.Sounds.Length;
	if (!size)
	{
		LogError("[Sounds] [Config Validation] No usable data found in sounds config file: \"%s\"", buffer);
		return;
	}

	for (int i = 0; i < size; i++)
	{
		SoundsGetKey(i, buffer, sizeof(buffer)); // Index: 0
		kv.Rewind();
		if (!kv.JumpToKey(buffer))
		{
			SetFailState("[Sounds] [Config Validation] Couldn't cache sound data for: \"%s\" (check sounds config)", buffer);
			continue;
		}
		
		ArrayList array = sServerData.Sounds.Get(i);
		
		if (kv.GotoFirstSubKey())
		{
			do
			{
				kv.GetSectionName(buffer, sizeof(buffer));
				
				if (FindCharInString(buffer, '.', true) == -1)
				{
					SetFailState("[Sounds] [Config Validation] Missing sound format: %s", buffer);
					continue;
				}
				
				array.PushString(buffer); // Index: i + 0
				array.Push(kv.GetFloat("volume", 1.0)); // Index: i + 1
				array.Push(kv.GetNum("level", 75)); // Index: i + 2
				array.Push(kv.GetNum("flags", 0)); // Index: i + 3
				array.Push(kv.GetNum("pitch", 100)); // Index: i + 4
				array.Push(kv.GetFloat("duration", 0.0)); // Index: i + 5
				
				Format(buffer, sizeof(buffer), "sound/%s", buffer);
				SoundsPrecacheQuirk(buffer);
			}
			while (kv.GotoNextKey());
		}
	}
	delete kv;
}

public void SoundsOnConfigReload()
{
	SoundsOnLoad();
}

void SoundsOnInit()
{
	PlayerSoundsOnInit();

	AddNormalSoundHook(view_as<NormalSHook>(Hook_PlayerSoundsNormal));
}

void SoundsOnCvarInit()
{
	PlayerSoundsOnCvarInit();
}

void SoundsOnGameModeStart()
{
	AmbientSoundsOnGameModeStart();
	PlayerSoundsOnGameModeStart();
}

void SoundsOnClientDeath(int client)
{
	PlayerSoundsOnClientDeath(client);
	// AmbientSoundsOnClientDeath(client);
}

void SoundsOnClientUpdate(int client)
{
	AmbientSoundsOnClientUpdate(client);
}

public void Hook_OnCvarSounds(ConVar convar, const char[] oldValue, const char[] newValue)
{    
	if (strcmp(oldValue, newValue, false))
	{
		if (sServerData.MapLoaded)
		{
			PlayerSoundsOnOnLoad();
		}
	}
}

void SoundsOnMapEnd()
{
	AmbientOnMapEnd();
}

bool SoundsOnCounter()
{
	return PlayerSoundsOnCounter();
}

void SoundsOnRoundStart()
{
	AmbientGameSoundsRoundStart();
}

void SoundsOnRoundEnd()
{
	AmbientGameSoundsRoundEnd();
}

void SoundsOnClientInfected(int client, int attacker)
{
	PlayerSoundsOnClientInfected(client, attacker);
}

Action SoundsOnClientShoot(int client, int id)
{
	return PlayerSoundsOnClientShoot(client, id) ? Plugin_Stop:Plugin_Continue;
}

void SoundsOnClientHurt(int client, int damagetype)
{
	PlayerSoundsOnClientHurt(client, ((damagetype & DMG_BURN) || (damagetype & DMG_DIRECT)));
}

void SoundsGetKey(int key, char[] sKey, int iMaxLen)
{
	ArrayList array = sServerData.Sounds.Get(key);
	
	array.GetString(SOUNDS_DATA_KEY, sKey, iMaxLen);
}

// int SoundsGetCount(int key)
// {
// 	ArrayList array = sServerData.Sounds.Get(key);
// 	return (array.Length - 1) / SOUNDS_DATA_DURATION;
// }

float SoundsGetSound(int key, int num = 0, char path[PLATFORM_LINE_LENGTH], float& volume, int& level , int& flags, int& pitch)
{
	if (key == -1)
	{
		return 0.0;
	}
	
	if (sServerData.Sounds == null)
	{
		return 0.0;
	}

	ArrayList array = sServerData.Sounds.Get(key);

	int size = (array.Length - 1) / SOUNDS_DATA_DURATION;
	if (num <= size)
	{
		int id = ((num ? num : UTIL_GetRandomInt(1, size)) - 1) * SOUNDS_DATA_DURATION;

		array.GetString(id + SOUNDS_DATA_PATH, path, sizeof(path));
		
		volume = array.Get(id + SOUNDS_DATA_VOLUME);
		level = array.Get(id + SOUNDS_DATA_LEVEL);
		flags = array.Get(id + SOUNDS_DATA_FLAGS);
		pitch = array.Get(id + SOUNDS_DATA_PITCH);
		return array.Get(id + SOUNDS_DATA_DURATION);
	}
	return 0.0;
}

int SoundsKeyToIndex(const char[] key)
{
	static char SoundKey[SMALL_LINE_LENGTH];
	for (int i = 0; i < sServerData.Sounds.Length; i++)
	{
		SoundsGetKey(i, SoundKey, sizeof(SoundKey));

		if (!strcmp(key, SoundKey, false))
		{
			return i;
		}
	}
	return -1;
}

bool SoundsPrecacheQuirk(const char[] path)
{
	if (!FileExists(path))
	{
		if (FileExists(path, true))
		{
			PrecacheSound(path[6], true);
			return true;
		}

		LogError("[Sounds] [Config Validation] Invalid sound path. File not found: \"%s\"", path);
		return false;
	}
	
	AddFileToDownloadsTable(path);
	PrecacheSound(path[6], true);
	return true;
}
