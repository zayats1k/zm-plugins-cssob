enum
{
	CLASSES_DATA_NAME,
	CLASSES_DATA_INFO,
	CLASSES_DATA_DESCRIPTION,
	
	CLASSES_DATA_LEVEL,
	CLASSES_DATA_GENDER,
	CLASSES_DATA_TYPE,
	CLASSES_DATA_ZOMBIE,
	CLASSES_DATA_WEAPON,
	CLASSES_DATA_MODEL,
	CLASSES_DATA_GROUP,
	CLASSES_DATA_GROUP_FLAGS,
	CLASSES_DATA_ARMOR,
	CLASSES_DATA_HEALTH,
	CLASSES_DATA_REGEN_HEALTH,
	CLASSES_DATA_HEAL_COUNTDOWN,
	CLASSES_DATA_REGEN_INTERVAL,
	CLASSES_DATA_SPEED,
	CLASSES_DATA_GRAVITY,
	CLASSES_DATA_KNOCKBACK,
	CLASSES_DATA_SCALE,
	CLASSES_DATA_FALL,
	CLASSES_DATA_ARMOR2,
	CLASSES_DATA_EFFECT_NAME,
	CLASSES_DATA_EFFECT_ATTACH,
	CLASSES_DATA_EFFECT_TIME,
	
	// sounds
	CLASSES_DATA_SOUND_DEATH,
	CLASSES_DATA_SOUND_INFECT,
	CLASSES_DATA_SOUND_RESPAWN,
	CLASSES_DATA_SOUND_HURT,
	CLASSES_DATA_SOUND_BURN,
	CLASSES_DATA_SOUND_KILLS
};

void ClassesOnInit()
{
	TeleportOnCommandInit();
	MarketOnCommandInit();
	
	SpawnOnInit();
	DeathOnInit();
	JumpBoostOnInit();
	ToolsOnInit();
}

void ClassesOnClientInit(int client)
{
	DeathOnClientInit(client);
	// JumpBoostOnClientInit(client);
	AntiStickClientInit(client);
}

void ClassesOnClientDisconnectPost(int client)
{
	AntiStickOnClientDisconnect(client);
}

void ClassesOnLoad(bool init = false)
{
	if (!init) 
	{
		SpawnOnLoad();
	}
	
	ConfigRegisterConfig(File_Classes, Structure_KeyValue, CONFIG_FILE_ALIAS_CLASSES);

	static char buffer[PLATFORM_LINE_LENGTH];
	if (!ConfigGetFullPath(CONFIG_FILE_ALIAS_CLASSES, buffer, sizeof(buffer)))
	{
		LogError("[Classes] [Config Validation] Missing classes config file: \"%s\"", buffer);
		return;
	}

	ConfigSetConfigPath(File_Classes, buffer);
	if (!ConfigLoadConfig(File_Classes, sServerData.Classes, PLATFORM_LINE_LENGTH))
	{
		LogError("[Classes] [Config Validation] Unexpected error encountered loading: \"%s\"", buffer);
		return;
	}

	if (sServerData.Classes == null)
	{
		LogError("[Classes] [Config Validation] Invalid Handle 0 (error: 4)");
		LogError("[Classes] [Config Validation] server restart");
		return;
	}

	ClassesOnCacheData(init);

	ConfigSetConfigLoaded(File_Classes, true);
	ConfigSetConfigReloadFunc(File_Classes, GetFunctionByName(GetMyHandle(), "ClassesOnConfigReload"));
	ConfigSetConfigHandle(File_Classes, sServerData.Classes);
}

void ClassesOnCacheData(bool init)
{
	static char buffer[PLATFORM_LINE_LENGTH];
	ConfigGetConfigPath(File_Classes, buffer, sizeof(buffer));

	KeyValues kv;
	if (!ConfigOpenConfigFile(File_Classes, kv))
	{
		LogError("[Classes] [Config Validation] Unexpected error caching data from classes config file: \"%s\"", buffer);
		return;
	}
	
	if (sServerData.Types == null)
	{
		sServerData.Types = new ArrayList(SMALL_LINE_LENGTH);
	}
	else
	{
		sServerData.Types.Clear();
	}
	
	int size = sServerData.Classes.Length;
	if (!size)
	{
		LogError("[Classes] [Config Validation] No usable data found in classes config file: \"%s\"", buffer);
		return;
	}
	
	static char sWeapon[SMALL_LINE_LENGTH][SMALL_LINE_LENGTH]; 
	
	for (int i = 0; i < size; i++)
	{
		ClassGetName(i, buffer, sizeof(buffer)); // Index: 0
		kv.Rewind();
		if (!kv.JumpToKey(buffer))
		{
			SetFailState("[Classes] [Config Validation] Couldn't cache class data for: \"%s\" (check classes config)", buffer);
			continue;
		}
		
		if (init) 
		{
			kv.GetString("type", buffer, sizeof(buffer), "");
			int id = sServerData.Types.FindString(buffer);
			if (id == -1)                    
			{                                                                      
				id = sServerData.Types.Length;
				if (id == 31)
				{
					SetFailState("[Classes] [Config Validation] Unique class types exceeds the limit! (Max 32)");
				}
				sServerData.Types.PushString(buffer);
			}
			continue;
		}
		
		if (!TranslationIsPhraseExists(buffer))
		{
			SetFailState("[Classes] [Config Validation] Couldn't cache class name: \"%s\" (check translation file)", buffer);
			continue;
		}
		
		ArrayList array = sServerData.Classes.Get(i);

		kv.GetString("info", buffer, sizeof(buffer), "");
		if (hasLength(buffer) && !TranslationIsPhraseExists(buffer))
		{
			LogError("[Classes] [Config Validation] Couldn't cache class info: \"%s\" (check translation file)", buffer);
		}
		array.PushString(buffer); // Index: 1
		
		kv.GetString("description", buffer, sizeof(buffer), "");
		if (hasLength(buffer) && !TranslationIsPhraseExists(buffer))
		{
			LogError("[Classes] [Config Validation] Couldn't cache class description: \"%s\" (check translation file)", buffer);
		}
		array.PushString(buffer); // Index: 2
		
		array.Push(kv.GetNum("level", 0)); // Index: 3
		array.Push(kv.GetNum("gender", 0)); // Index: 4
		kv.GetString("type", buffer, sizeof(buffer), "");
		if (hasLength(buffer) && !TranslationIsPhraseExists(buffer))
		{
			LogError("[Classes] [Config Validation] Couldn't cache class type: \"%s\" (check translation file)", buffer);
		}
		int id = sServerData.Types.FindString(buffer);
		if (id == -1)
		{                                                                      
			id = sServerData.Types.Length;
			if (id == 31)
			{
				SetFailState("[Classes] [Config Validation] Unique class types exceeds the limit! (Max 32)");
			}
			sServerData.Types.PushString(buffer);
		}
		array.Push(id); // Index: 5
		array.Push(ConfigKvGetStringBool(kv, "zombie", "off")); // Index: 6
		
		kv.GetString("weapon", buffer, sizeof(buffer), ""); int iWeapon[SMALL_LINE_LENGTH] = { -1, ... };
		for (int x = 0; x < ExplodeString(buffer, ",", sWeapon, sizeof(sWeapon), sizeof(sWeapon[])); x++)
		{
			TrimString(sWeapon[x]);
			iWeapon[x] = WeaponsEntityToIndex(sWeapon[x]);
			if (iWeapon[x] != -1)
			{
				if (!ClassHasTypeBits(WeaponsGetTypes(iWeapon[x]), id))
					LogError("[Classes] [Config Validation] Class have the weapon: \"%s\" that does not available to use for that class type!", sWeapon[x]);
			}
			else LogError("[Classes] [Config Validation] Couldn't cache weapon data for: \"%s\" (check weapons config)", sWeapon[x]);
		} 
		array.PushArray(iWeapon, sizeof(iWeapon)); // Index: 7
		kv.GetString("model", buffer, sizeof(buffer), "");            
		array.PushString(buffer); // Index: 8
		DecryptPrecacheModel(buffer);
		kv.GetString("group", buffer, sizeof(buffer), "");
		array.PushString(buffer); // Index: 9
		array.Push(ConfigGetAdmFlags(buffer)); // Index: 10
		
		array.Push(kv.GetNum("armor", 0)); // Index: 11
		array.Push(kv.GetNum("health", 0)); // Index: 12
		
		array.Push(kv.GetNum("regenerate", 0)); // Index: 13
		array.Push(kv.GetFloat("countdown", 0.0)); // Index: 14
		array.Push(kv.GetFloat("interval", 0.0)); // Index: 15
		
		array.Push(kv.GetFloat("speed", 0.0)); // Index: 16
		array.Push(kv.GetFloat("gravity", 0.0)); // Index: 17
		array.Push(kv.GetFloat("knockback", 0.0)); // Index: 18
		array.Push(kv.GetFloat("scale", 1.0)); // Index: 19
		
		array.Push(ConfigKvGetStringBool(kv, "fall", "on")); // Index: 20
		array.Push(ConfigKvGetStringBool(kv, "heavyarmor", "on")); // Index: 21
		kv.GetString("effect", buffer, sizeof(buffer), "");
		array.PushString(buffer); // Index: 22
		kv.GetString("attachment", buffer, sizeof(buffer), "");        
		array.PushString(buffer); // Index: 23
		array.Push(kv.GetFloat("time", 0.0)); // Index: 24
		
		kv.GetString("death", buffer, sizeof(buffer), "");
		array.Push(SoundsKeyToIndex(buffer)); // Index: 25
		
		kv.GetString("infect", buffer, sizeof(buffer), "");
		array.Push(SoundsKeyToIndex(buffer)); // Index: 26
		kv.GetString("respawn", buffer, sizeof(buffer), "");
		array.Push(SoundsKeyToIndex(buffer)); // Index: 27
		kv.GetString("hurt", buffer, sizeof(buffer), "");
		array.Push(SoundsKeyToIndex(buffer)); // Index: 28
		kv.GetString("burn", buffer, sizeof(buffer), "");
		array.Push(SoundsKeyToIndex(buffer)); // Index: 29
		kv.GetString("kills", buffer, sizeof(buffer), "");
		array.Push(SoundsKeyToIndex(buffer)); // Index: 30
	}
	
	sServerData.Zombie = sServerData.Types.FindString("zombie");
	sServerData.Human = sServerData.Types.FindString("human");
	
	delete kv;
}

public void ClassesOnConfigReload()
{
	ClassesOnLoad();
}

void ClassGetName(int id, char[] name, int maxLen)
{
	if (sServerData.Classes == null) {
		return;
	}
	
	ArrayList array = sServerData.Classes.Get(id);
	array.GetString(CLASSES_DATA_NAME, name, maxLen);
}

void ClassGetInfo(int id, char[] info, int maxLen)
{
	if (sServerData.Classes == null) {
		return;
	}
	
	ArrayList array = sServerData.Classes.Get(id);
	array.GetString(CLASSES_DATA_INFO, info, maxLen);
}

void ClassGetDescription(int id, char[] info, int maxLen)
{
	if (sServerData.Classes == null) {
		return;
	}
	
	ArrayList array = sServerData.Classes.Get(id);
	array.GetString(CLASSES_DATA_DESCRIPTION, info, maxLen);
}

int ClassGetLevel(int id)
{
	if (sServerData.Classes == null)
	{
		return false;
	}
	
	ArrayList array = sServerData.Classes.Get(id);
	return array.Get(CLASSES_DATA_LEVEL);
}

bool ClassGetGender(int id)
{
	if (sServerData.Classes == null)
	{
		return false;
	}
	
	ArrayList array = sServerData.Classes.Get(id);
	return array.Get(CLASSES_DATA_GENDER);
}

int ClassGetType(int id)
{
	if (sServerData.Classes == null)
	{
		return -1;
	}

	ArrayList array = sServerData.Classes.Get(id);
	return array.Get(CLASSES_DATA_TYPE);
}

bool ClassIsZombie(int id)
{
	if (sServerData.Classes == null) {
		return false;
	}
	
	ArrayList array = sServerData.Classes.Get(id);
	return array.Get(CLASSES_DATA_ZOMBIE);
}

void ClassGetModel(int id, char[] name, int maxLen)
{
	if (sServerData.Classes == null) {
		return;
	}
	
	ArrayList array = sServerData.Classes.Get(id);
	array.GetString(CLASSES_DATA_MODEL, name, maxLen);
}

void ClassGetGroup(int id, char[] group, int maxLen)
{
	if (sServerData.Classes == null) {
		return;
	}

	ArrayList array = sServerData.Classes.Get(id);
	array.GetString(CLASSES_DATA_GROUP, group, maxLen);
}

int ClassGetGroupFlags(int id)
{
	if (sServerData.Classes == null) {
		return -1;
	}
	
	ArrayList array = sServerData.Classes.Get(id);
	return array.Get(CLASSES_DATA_GROUP_FLAGS);
}

void ClassGetWeapon(int id, int[] weapon, int maxLen)
{
	if (sServerData.Classes == null) {
		return;
	}
	
	ArrayList array = sServerData.Classes.Get(id);
	array.GetArray(CLASSES_DATA_WEAPON, weapon, maxLen);
}

int ClassGetArmor(int id)
{
	if (sServerData.Classes == null) {
		return 0;
	}
	
	ArrayList array = sServerData.Classes.Get(id);
	return array.Get(CLASSES_DATA_ARMOR);
}

int ClassGetHealth(int id)
{
	if (sServerData.Classes == null) {
		return 100;
	}
	
	ArrayList array = sServerData.Classes.Get(id);
	return array.Get(CLASSES_DATA_HEALTH);
}

int ClassGetRegenHealth(int id)
{
	if (sServerData.Classes == null) {
		return 100;
	}
	
	ArrayList array = sServerData.Classes.Get(id);
	return array.Get(CLASSES_DATA_REGEN_HEALTH);
}

float ClassGetHealCountdown(int id)
{
	if (sServerData.Classes == null) {
		return 0.0;
	}
	
	ArrayList array = sServerData.Classes.Get(id);
	return array.Get(CLASSES_DATA_HEAL_COUNTDOWN);
}

float ClassGetRegenInterval(int id)
{
	if (sServerData.Classes == null) {
		return 0.0;
	}
	
	ArrayList array = sServerData.Classes.Get(id);
	return array.Get(CLASSES_DATA_REGEN_INTERVAL);
}

float ClassGetSpeed(int id)
{
	if (sServerData.Classes == null) {
		return 0.0;
	}
	
	ArrayList array = sServerData.Classes.Get(id);
	return array.Get(CLASSES_DATA_SPEED);
}

float ClassGetKnockBack(int id)
{
	if (sServerData.Classes == null) {
		return 1.0;
	}
	
	ArrayList array = sServerData.Classes.Get(id);
	return array.Get(CLASSES_DATA_KNOCKBACK);
}

float ClassGetScale(int id)
{
	if (sServerData.Classes == null) {
		return 1.0;
	}
	
	ArrayList array = sServerData.Classes.Get(id);
	return array.Get(CLASSES_DATA_SCALE);
}

bool ClassIsFall(int id)
{
	if (sServerData.Classes == null) {
		return false;
	}
	
	ArrayList array = sServerData.Classes.Get(id);
	return array.Get(CLASSES_DATA_FALL);
}

bool ClassIsArmor(int id)
{
	if (sServerData.Classes == null) {
		return false;
	}
	
	ArrayList array = sServerData.Classes.Get(id);
	return array.Get(CLASSES_DATA_ARMOR2);
}

float ClassGetGravity(int id)
{
	if (sServerData.Classes == null) {
		return 0.0;
	}
	
	ArrayList array = sServerData.Classes.Get(id);
	return array.Get(CLASSES_DATA_GRAVITY);
}

void ClassGetEffectName(int id, char[] name, int maxLen)
{
	if (sServerData.Classes == null) {
		return;
	}
	
	ArrayList array = sServerData.Classes.Get(id);
	array.GetString(CLASSES_DATA_EFFECT_NAME, name, maxLen);
}

void ClassGetEffectAttach(int id, char[] sAttach, int maxLen)
{
	if (sServerData.Classes == null) {
		return;
	}
	
	ArrayList array = sServerData.Classes.Get(id);
	array.GetString(CLASSES_DATA_EFFECT_ATTACH, sAttach, maxLen);
}

float ClassGetEffectTime(int id)
{
	if (sServerData.Classes == null) {
		return 0.0;
	}
	
	ArrayList array = sServerData.Classes.Get(id);
	return array.Get(CLASSES_DATA_EFFECT_TIME);
}

int ClassGetSoundDeathID(int id)
{
	if (sServerData.Classes == null) {
		return -1;
	}
	
	ArrayList array = sServerData.Classes.Get(id);
	return array.Get(CLASSES_DATA_SOUND_DEATH);
}

int ClassGetSoundInfectID(int id)
{
	if (sServerData.Classes == null) {
		return -1;
	}
	
	ArrayList array = sServerData.Classes.Get(id);
	return array.Get(CLASSES_DATA_SOUND_INFECT);
}

int ClassGetSoundRespawnID(int id)
{
	if (sServerData.Classes == null) {
		return -1;
	}
	
	ArrayList array = sServerData.Classes.Get(id);
	return array.Get(CLASSES_DATA_SOUND_RESPAWN);
}

int ClassGetSoundBurnID(int id)
{
	if (sServerData.Classes == null) {
		return -1;
	}
	
	ArrayList array = sServerData.Classes.Get(id);
	return array.Get(CLASSES_DATA_SOUND_BURN);
}

int ClassGetSoundHurtID(int id)
{
	if (sServerData.Classes == null) {
		return -1;
	}
	
	ArrayList array = sServerData.Classes.Get(id);
	return array.Get(CLASSES_DATA_SOUND_HURT);
}

int ClassGetSoundKillsID(int id)
{
	if (sServerData.Classes == null) {
		return -1;
	}
	
	ArrayList array = sServerData.Classes.Get(id);
	return array.Get(CLASSES_DATA_SOUND_KILLS);
}

int ClassNameToIndex(const char[] name)
{
	if (sServerData.Classes == null) {
		return -1;
	}
	
	static char classname[SMALL_LINE_LENGTH];
	for (int i = 0; i < sServerData.Classes.Length; i++)
	{
		ClassGetName(i, classname, sizeof(classname));
		if (!strcmp(name, classname, false)) {
			return i;
		}
	}
	return -1;
}

int ClassTypeToIndex(const char[] buffer)
{
	if (sServerData.Classes == null) {
		return -1;
	}
	
	static char class[SMALL_LINE_LENGTH][SMALL_LINE_LENGTH]; int type;
	for (int i = 0; i < ExplodeString(buffer, ",", class, sizeof(class), sizeof(class[])); i++)
	{
		TrimString(class[i]);

		int id = sServerData.Types.FindString(class[i]);
		if (id != -1)
		{
			SetBit(type, id);
		}
	}
	return type;
}

int ClassTypeToRandomClassIndex(int type)
{
	if (sServerData.Classes == null) {
		return -1;
	}
	
	int total; static int class[MAXPLAYERS+1];
	for (int i = 0; i < sServerData.Classes.Length; i++)
	{
		if (ClassGetType(i) == type)
		{
			class[total++] = i;
		}
	}
	return (total) ? class[UTIL_GetRandomInt(0, total-1)] : -1;
}

stock bool ClassHasTypeBits(int types, int type)
{
	return (!types || CheckBit(types, type));
}

// api
void ClassesOnNativeInit()
{
	CreateNative("ZM_PlayerSpawn", Native_PlayerSpawn);
	CreateNative("ZM_ChangeClient", Native_ChangeClient);
	CreateNative("ZM_GetNumberClass", Native_GetNumberClass);
	CreateNative("ZM_GetClientClass", Native_GetClientClass);
	CreateNative("ZM_SetClientHumanClassNext", Native_SetClientHumanClassNext);
	CreateNative("ZM_SetClientZombieClassNext", Native_SetClientZombieClassNext);
	CreateNative("ZM_SetClientClassNext", Native_SetClientClassNext);
	
	CreateNative("ZM_GetNumberType", Native_GetNumberType);
	CreateNative("ZM_GetClassType", Native_GetClassType);
	CreateNative("ZM_GetClassTypeName", Native_GetClassTypeName);
	CreateNative("ZM_IsClassType", Native_IsClassType);
	
	CreateNative("ZM_GetClassNameID", Native_GetClassNameID);
	CreateNative("ZM_GetClassName", Native_GetClassName);
	CreateNative("ZM_GetClassGetGravity", Native_GetClassGetGravity);
	CreateNative("ZM_GetClassGetGender", Native_GetClassGetGender);
	CreateNative("ZM_GetClassSoundDeathID", Native_GetClassSoundDeathID);
	CreateNative("ZM_GetClassSoundHurtID", Native_GetClassSoundHurtID);
	CreateNative("ZM_GetClassSoundInfectID", Native_GetClassSoundInfectID);
	CreateNative("ZM_GetClassSoundRespawnID", Native_GetClassSoundRespawnID);
	CreateNative("ZM_GetClassSoundBurnID", Native_GetClassSoundBurnID);
}

public int Native_SetClientHumanClassNext(Handle hPlugin, int iNumParams)
{
	int client = GetNativeCell(1);
	int id = GetNativeCell(2);

	if (id >= sServerData.Classes.Length)
	{
		LogError("[Classes] [Native Validation] Invalid the class index (%d)", id);
		return -1;
	}
	
	sClientData[client].HumanClassNext = id;
	return id;
}

public int Native_SetClientZombieClassNext(Handle hPlugin, int iNumParams)
{
	int client = GetNativeCell(1);
	int id = GetNativeCell(2);

	if (id >= sServerData.Classes.Length)
	{
		LogError("[Classes] [Native Validation] Invalid the class index (%d)", id);
		return -1;
	}
	
	sClientData[client].ZombieClassNext = id;
	return id;
}

public int Native_SetClientClassNext(Handle hPlugin, int iNumParams)
{
	int client = GetNativeCell(1);
	int id = GetNativeCell(2);

	if (id >= sServerData.Classes.Length)
	{
		LogError("[Classes] [Native Validation] Invalid the class index (%d)", id);
		return -1;
	}
	
	int type = ClassGetType(id);
	if (type == sServerData.Human)
	{
		sClientData[client].HumanClassNext = id;
	}
	else if (type == sServerData.Zombie)
	{
		sClientData[client].ZombieClassNext = id;
	}
	return id;
}

public int Native_PlayerSpawn(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);

	if (!IsValidClient(client) || !IsPlayerAlive(client))
	{
		LogError("[Classes] [Native Validation] Invalid the client index (%d)", client);
		return -1;
	}
	
	ApplyOnClientSpawn(client);
	return 0;
}

public int Native_ChangeClient(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);

	if (!IsValidClient(client) || !IsPlayerAlive(client))
	{
		LogError("[Classes] [Native Validation] Invalid the client index (%d)", client);
		return -1;
	}
	
	int attacker = GetNativeCell(2);

	if (attacker > 0 && !IsValidClient(attacker))
	{
		LogError("[Classes] [Native Validation] Invalid the attacker index (%d)", attacker);
		return -1;
	}
	
	int type = GetNativeCell(3);

	if (type == -1 || type >= sServerData.Types.Length)
	{
		LogError("[Classes] [Native Validation] Invalid the type index (%d)", type);
		return -1;
	}

	return ApplyOnClientUpdate(client, attacker, type, GetNativeCell(4));
}

public int Native_GetNumberClass(Handle plugin, int numParams)
{
	return sServerData.Classes.Length;
}

public int Native_GetClientClass(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return sClientData[client].Class;
}

public int Native_GetNumberType(Handle plugin, int numParams)
{
	return sServerData.Types.Length;
}

public int Native_GetClassType(Handle plugin, int numParams)
{
	int id = GetNativeCell(1);

	if (id >= sServerData.Classes.Length) {
		LogError("[Classes] [Native Validation] Invalid the class index (%d)", id);
		return -1;
	}
	return ClassGetType(id);
}

public int Native_GetClassTypeName(Handle plugin, int numParams)
{
	int TypeID = GetNativeCell(1);

	if (TypeID >= sServerData.Types.Length) {
		LogError("[Classes] [Native Validation] Invalid the type index (%d)", TypeID);
		return -1;
	}
	
	int maxLen = GetNativeCell(3);
	if (!maxLen) {
		LogError("[Classes] [Native Validation] No buffer size");
		return -1;
	}

	static char name[SMALL_LINE_LENGTH];
	sServerData.Types.GetString(TypeID, name, sizeof(name));
	return SetNativeString(2, name, maxLen);
}

public int Native_IsClassType(Handle plugin, int numParams)
{
	int TypeID = GetNativeCell(1);

	if (TypeID >= sServerData.Types.Length) {
		LogError("[Classes] [Native Validation] Invalid the type index (%d)", TypeID);
		return -1;
	}
	return (TypeID == sServerData.Human || TypeID == sServerData.Zombie);
}

public int Native_GetClassNameID(Handle plugin, int numParams)
{
	int maxLen; GetNativeStringLength(1, maxLen);
	if (!maxLen) {
		LogError("[Classes] [Native Validation] Can't find class with an empty name");
		return -1;
	}
	
	static char name[SMALL_LINE_LENGTH];
	GetNativeString(1, name, sizeof(name));
	return ClassNameToIndex(name); 
}

public int Native_GetClassName(Handle plugin, int numParams)
{
	int id = GetNativeCell(1);

	if (id >= sServerData.Classes.Length) {
		LogError("[Classes] [Native Validation] Invalid the class index (%d)", id);
		return -1;
	}
	
	int maxLen = GetNativeCell(3);

	if (!maxLen) {
		LogError("[Classes] [Native Validation] No buffer size");
		return -1;
	}
	
	static char name[SMALL_LINE_LENGTH];
	ClassGetName(id, name, sizeof(name));
	return SetNativeString(2, name, maxLen);
}

public int Native_GetClassGetGravity(Handle plugin, int numParams)
{
	int id = GetNativeCell(1);

	if (id >= sServerData.Classes.Length) {
		LogError("[Classes] [Native Validation] Invalid the class index (%d)", id);
		return -1;
	}
	return view_as<int>(ClassGetGravity(id));
}

public int Native_GetClassGetGender(Handle plugin, int numParams)
{
	int id = GetNativeCell(1);

	if (id >= sServerData.Classes.Length) {
		LogError("[Classes] [Native Validation] Invalid the class index (%d)", id);
		return -1;
	}
	return ClassGetGender(id);
}

public int Native_GetClassSoundDeathID(Handle plugin, int numParams)
{
	int id = GetNativeCell(1);

	if (id >= sServerData.Classes.Length) {
		LogError("[Classes] [Native Validation] Invalid the class index (%d)", id);
		return -1;
	}
	return ClassGetSoundDeathID(id);
}

public int Native_GetClassSoundHurtID(Handle plugin, int numParams)
{
	int id = GetNativeCell(1);

	if (id >= sServerData.Classes.Length) {
		LogError("[Classes] [Native Validation] Invalid the class index (%d)", id);
		return -1;
	}
	return ClassGetSoundHurtID(id);
}

public int Native_GetClassSoundInfectID(Handle plugin, int numParams)
{
	int id = GetNativeCell(1);

	if (id >= sServerData.Classes.Length) {
		LogError("[Classes] [Native Validation] Invalid the class index (%d)", id);
		return -1;
	}
	return ClassGetSoundInfectID(id);
}

public int Native_GetClassSoundRespawnID(Handle plugin, int numParams)
{
	int id = GetNativeCell(1);

	if (id >= sServerData.Classes.Length) {
		LogError("[Classes] [Native Validation] Invalid the class index (%d)", id);
		return -1;
	}
	return ClassGetSoundRespawnID(id);
}

public int Native_GetClassSoundBurnID(Handle plugin, int numParams)
{
	int id = GetNativeCell(1);

	if (id >= sServerData.Classes.Length) {
		LogError("[Classes] [Native Validation] Invalid the class index (%d)", id);
		return -1;
	}
	return ClassGetSoundBurnID(id);
}