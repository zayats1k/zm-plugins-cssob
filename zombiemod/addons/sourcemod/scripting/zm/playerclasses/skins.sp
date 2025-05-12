enum
{
	SKINS_DATA_KEY,
	SKINS_DATA_GENDER,
	SKINS_DATA_MODEL,
	SKINS_DATA_EMOTE,
	SKINS_DATA_SOUND_DEATH,
	SKINS_DATA_SOUND_KILSS,
	Skins_DATA_SOUND_HURT
};

void SkinsOnClientInit(int client)
{
	sClientData[client].Skin = SkinsKeyToIndex(client);
}

void SkinsOnLoad()
{
	ConfigRegisterConfig(File_Skins, Structure_KeyValue, CONFIG_FILE_ALIAS_SKINS);

	static char buffer[PLATFORM_LINE_LENGTH];
	if (!ConfigGetFullPath(CONFIG_FILE_ALIAS_SKINS, buffer, sizeof(buffer)))
	{
		LogError("[Skins] [Config Validation] Missing skins config file: \"%s\"", buffer);
		return;
	}

	ConfigSetConfigPath(File_Skins, buffer);
	if (!ConfigLoadConfig(File_Skins, sServerData.Skins, PLATFORM_LINE_LENGTH))
	{
		LogError("[Skins] [Config Validation] Unexpected error encountered loading: \"%s\"", buffer);
		return;
	}
	
	if (sServerData.Skins == null)
	{
		LogError("[Skins] [Config Validation] Invalid Handle 0 (error: 4)");
		LogError("[Skins] [Config Validation] server restart");
		return;
	}
	
	SkinsOnCacheData();

	ConfigSetConfigLoaded(File_Skins, true);
	ConfigSetConfigReloadFunc(File_Skins, GetFunctionByName(GetMyHandle(), "SkinsOnConfigReload"));
	ConfigSetConfigHandle(File_Skins, sServerData.Skins);
}

void SkinsOnCacheData()
{
	static char buffer[PLATFORM_LINE_LENGTH];
	ConfigGetConfigPath(File_Skins, buffer, sizeof(buffer));

	KeyValues kv;
	if (!ConfigOpenConfigFile(File_Skins, kv))
	{
		LogError("[Skins] [Config Validation] Unexpected error caching data from skins config file: \"%s\"", buffer);
		return;
	}
	
	int size = sServerData.Skins.Length;
	if (!size)
	{
		return;
	}
	
	for (int i = 0; i < size; i++)
	{
		SkinGetKey(i, buffer, sizeof(buffer)); // Index: 0
		kv.Rewind();
		if (!kv.JumpToKey(buffer))
		{
			LogError("[Skins] [Config Validation] Couldn't cache skin data for: \"%s\" (check skins config)", buffer);
			continue;
		}

		ArrayList array = sServerData.Skins.Get(i);

		array.Push(kv.GetNum("gender", 0)); // Index: 1
		kv.GetString("model", buffer, sizeof(buffer), "");            
		array.PushString(buffer); // Index: 2
		DecryptPrecacheModel(buffer);
		array.Push(ConfigKvGetStringBool(kv, "emote", "off")); // Index: 3
		kv.GetString("death", buffer, sizeof(buffer), "");
		array.Push(SoundsKeyToIndex(buffer)); // Index: 4
		kv.GetString("kills", buffer, sizeof(buffer), "");
		array.Push(SoundsKeyToIndex(buffer)); // Index: 5
		kv.GetString("hurt", buffer, sizeof(buffer), "");
		array.Push(SoundsKeyToIndex(buffer)); // Index: 6
	}
	delete kv;
}

public void SkinsOnConfigReload()
{
	SkinsOnLoad();
}

void SkinGetKey(int id, char[] name, int maxLen)
{
	ArrayList array = sServerData.Skins.Get(id);
	array.GetString(SKINS_DATA_KEY, name, maxLen);
}

bool SkinsGetGender(int id)
{
	ArrayList array = sServerData.Skins.Get(id);
	return array.Get(SKINS_DATA_GENDER);
}

void SkinsGetModel(int id, char[] info, int maxLen)
{
	ArrayList array = sServerData.Skins.Get(id);
	array.GetString(SKINS_DATA_MODEL, info, maxLen);
}

bool SkinsIsEmote(int id)
{
	ArrayList array = sServerData.Skins.Get(id);
	return array.Get(SKINS_DATA_EMOTE);
}

int SkinsGetSoundDeathID(int id)
{
	ArrayList array = sServerData.Skins.Get(id);
	return array.Get(SKINS_DATA_SOUND_DEATH);
}

int SkinsGetSoundKillsID(int id)
{
	ArrayList array = sServerData.Skins.Get(id);
	return array.Get(SKINS_DATA_SOUND_KILSS);
}

int SkinsGetSoundHurtID(int id)
{
	ArrayList array = sServerData.Skins.Get(id);
	return array.Get(Skins_DATA_SOUND_HURT);
}

int SkinsKeyToIndex(int client)
{
	static char steamid[SMALL_LINE_LENGTH], steamid2[SMALL_LINE_LENGTH];
	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	
	for (int i = 0; i < sServerData.Skins.Length; i++)
	{
		SkinGetKey(i, steamid2, sizeof(steamid2));
		
		if (!strcmp(steamid, steamid2, false)) {
			return i;
		}
	}
	return -1;
}

void SkinsOnNativeInit()
{
	CreateNative("ZM_GetClientSkin", Native_GetClientSkin);
	CreateNative("ZM_SetClientSkin", Native_SetClientSkin);
	CreateNative("ZM_GetNumberSkin", Native_GetNumberSkin);
	CreateNative("ZM_GetSkinName", Native_GetSkinnName);
	CreateNative("ZM_GetSkinsGender", Native_GetSkinsGender);
	CreateNative("ZM_IsClientEmote", Native_IsClientEmote);
	CreateNative("ZM_GetSkinsSoundDeathID", Native_GetSkinsSoundDeathID);
}

public int Native_GetClientSkin(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if (!UTIL_ValidateClient(client)) {
		return false;
	}
	
	return sClientData[client].Skin;
}

public int Native_SetClientSkin(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if (!UTIL_ValidateClient(client)) {
		return false;
	}
	
	sClientData[client].Skin = GetNativeCell(2);
	return true;
}

public int Native_GetSkinnName(Handle plugin, int numParams)
{
	int id = GetNativeCell(1);
	
	if (id >= sServerData.Skins.Length) {
		LogError("[Skins] [Native Validation] Invalid the skin index (%d)", id);
		return -1;
	}
	
	if (id == -1) {
		return false;
	}
	
	int maxLen = GetNativeCell(3);

	if (!maxLen) {
		LogError("[Skins] [Native Validation] No buffer size");
		return -1;
	}
	
	static char name[SMALL_LINE_LENGTH];
	SkinGetKey(id, name, sizeof(name));
	return SetNativeString(2, name, maxLen);
}

public int Native_GetNumberSkin(Handle plugin, int numParams)
{
	return sServerData.Skins.Length;
}

public int Native_GetSkinsGender(Handle plugin, int numParams)
{
	int id = GetNativeCell(1);

	if (id >= sServerData.Skins.Length) {
		LogError("[Skins] [Native Validation] Invalid the skin index (%d)", id);
		return -1;
	}
	
	if (id == -1) {
		return false;
	}
	
	return SkinsGetGender(id);
}

public int Native_IsClientEmote(Handle plugin, int numParams)
{
	int id = GetNativeCell(1);

	if (id >= sServerData.Skins.Length) {
		LogError("[Skins] [Native Validation] Invalid the skin index (%d)", id);
		return -1;
	}
	
	if (id == -1) {
		return false;
	}
	
	return SkinsIsEmote(id);
}

public int Native_GetSkinsSoundDeathID(Handle plugin, int numParams)
{
	int id = GetNativeCell(1);

	if (id >= sServerData.Skins.Length) {
		LogError("[Skins] [Native Validation] Invalid the skin index (%d)", id);
		return -1;
	}
	
	if (id == -1) {
		return -1;
	}
	
	return SkinsGetSoundDeathID(id);
}