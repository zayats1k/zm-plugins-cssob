enum
{
	WEAPONS_DATA_NAME,
	WEAPONS_DATA_ENTITY,
	WEAPONS_DATA_TYPES,
	WEAPONS_DATA_SLOT,
	WEAPONS_DATA_RESTRICT,
	WEAPONS_DATA_CLIP,
	WEAPONS_DATA_AMMO,
	WEAPONS_DATA_SPEED,
	WEAPONS_DATA_JUMP,
	WEAPONS_DATA_DAMAGE,
	WEAPONS_DATA_KNOCKBACK,
	WEAPONS_DATA_DROP,
	WEAPONS_DATA_MUZZLE,
	WEAPONS_DATA_INFECTION,
	WEAPONS_DATA_TRACER,
	WEAPONS_DATA_SOUND,
	WEAPONS_DATA_MODEL_VIEW,
	WEAPONS_DATA_MODEL_VIEW_ID,
	WEAPONS_DATA_MODEL_WORLD,
	WEAPONS_DATA_MODEL_WORLD_ID,
	WEAPONS_DATA_MODEL_ORIGIN,
	WEAPONS_DATA_MODEL_ANGLES
};

void WeaponsOnUnload()
{
	WeaponAttachOnUnload();
}

void WeaponsOnInit()
{
	AddTempEntHook("Shotgun Shot", Hook_WeaponsOnShoot);
}

void WeaponsOnClientInit(int client)
{
	// SDKHook(client, SDKHook_WeaponCanUse, Hook_WeaponCanUse);
	SDKUnhook(client, SDKHook_WeaponCanUse, Hook_WeaponCanUse);
	SDKHook(client, SDKHook_PostThinkPost, Hook_PostThinkPost);
	SDKHook(client, SDKHook_WeaponSwitch, Hook_WeaponSwitch);
	
	WeaponModOnClientInit(client);
}

void WeaponsOnClientSpawn(int client)
{
	if (IsPlayerAlive(client))
	{
		WeaponAttachOnClientSpawn(client);
	}
}

void WeaponsOnClientDeath(int client)
{
	SDKUnhook(client, SDKHook_WeaponCanUse, Hook_WeaponCanUse);
	
	WeaponAttachOnClientDeath(client);
}

public void Frame_WeaponsOnClientUpdate(int userid)
{
	int client = GetClientOfUserId(userid);
	
	if (client)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client) && !IsClientObserver(client))
		{
			sClientData[client].SpawnCheck = true;
		}
		
		WeaponAttachOnClientUpdate(client);
	}
}

void WeaponsOnLoad()
{
	ConfigRegisterConfig(File_Weapons, Structure_KeyValue, CONFIG_FILE_ALIAS_WEAPONS);
	
	static char buffer[PLATFORM_LINE_LENGTH];
	if (!ConfigGetFullPath(CONFIG_FILE_ALIAS_WEAPONS, buffer, sizeof(buffer)))
	{
		LogError("[Weapons] [Config Validation] Missing weapons config file: \"%s\"", buffer);
		return;
	}
	ConfigSetConfigPath(File_Weapons, buffer);
	
	if (!ConfigLoadConfig(File_Weapons, sServerData.Weapons))
	{
		LogError("[Weapons] [Config Validation] Unexpected error encountered loading: \"%s\"", buffer);
		return;
	}
	
	if (sServerData.Weapons == null)
	{
		LogError("[Weapons] [Config Validation] Invalid Handle 0 (error: 4)");
		LogError("[Weapons] [Config Validation] server restart");
		return;
	}
	
	WeaponsOnCacheData();
	
	ConfigSetConfigLoaded(File_Weapons, true);
	ConfigSetConfigReloadFunc(File_Weapons, GetFunctionByName(GetMyHandle(), "WeaponsOnConfigReload"));
	ConfigSetConfigHandle(File_Weapons, sServerData.Weapons);
}

void WeaponsOnCacheData()
{
	static char buffer[PLATFORM_LINE_LENGTH], weaponname[NORMAL_LINE_LENGTH], buffers[3][10];
	ConfigGetConfigPath(File_Weapons, buffer, sizeof(buffer));
	
	KeyValues kv;
	if (!ConfigOpenConfigFile(File_Weapons, kv))
	{
		LogError("[Weapons] [Config Validation] Unexpected error caching data from weapons config file: \"%s\"", buffer);
		return;
	}

	int size = sServerData.Weapons.Length;
	
	if (!size)
	{
		LogError("[Weapons] [Config Validation] No usable data found in weapons config file: \"%s\"", buffer);
		return;
	}
	for (int i = 0; i < size; i++)
	{
		WeaponsGetName(i, buffer, sizeof(buffer)); // Index: 0
		kv.Rewind();
		if (!kv.JumpToKey(buffer))
		{
			SetFailState("[Weapons] [Config Validation] Couldn't cache weapon data for: \"%s\" (check weapons config)", buffer);
			continue;
		}
		
		FormatEx(weaponname, sizeof(weaponname), "%s", buffer);
		
		ArrayList array = sServerData.Weapons.Get(i); 
 
		kv.GetString("entity", buffer, sizeof(buffer), "");
		array.PushString(buffer); // Index: 1
		WeaponsScriptsFile(buffer, weaponname);
		
		kv.GetString("types", buffer, sizeof(buffer), "human");  
		array.Push(ClassTypeToIndex(buffer)); // Index: 2
		
		array.Push(kv.GetNum("Slot", 0)); // Index: 3
		array.Push(kv.GetNum("restrict", 0)); // Index: 4
		
		array.Push(kv.GetNum("clip", 0)); // Index: 5
		array.Push(kv.GetNum("ammo", 0)); // Index: 6
		array.Push(kv.GetFloat("speed", 0.0)); // Index: 7
		array.Push(kv.GetFloat("jump", 0.0)); // Index: 8
		array.Push(kv.GetFloat("damage", 1.0)); // Index: 9
		array.Push(kv.GetFloat("knockback", 1.0)); // Index: 10
		
		array.Push(ConfigKvGetStringBool(kv, "drop", "off")); // Index: 11
		array.Push(ConfigKvGetStringBool(kv, "muzzle", "on")); // Index: 12
		array.Push(ConfigKvGetStringBool(kv, "infect", "off")); // Index: 13
		array.Push(ConfigKvGetStringBool(kv, "tracer", "off")); // Index: 14
		
		kv.GetString("sound", buffer, sizeof(buffer), "");
		array.Push(SoundsKeyToIndex(buffer)); // Index: 15
		
		kv.GetString("view", buffer, sizeof(buffer), "");
		array.PushString(buffer); // Index: 16
		array.Push(DecryptPrecacheModel(buffer)); // Index: 17
		kv.GetString("world", buffer, sizeof(buffer), "");
		array.PushString(buffer); // Index: 18
		array.Push(DecryptPrecacheModel(buffer)); // Index: 19
		
		float origin[3]; kv.GetString("origin", buffer, sizeof(buffer), "0.0 0.0 0.0");
		ExplodeString(buffer, " ", buffers, sizeof(buffers), sizeof(buffers[]));
		for (int c = 0; c < 3; c++) origin[c] = StringToFloat(buffers[c]);
		array.PushArray(origin, sizeof(origin)); // Index: 20
		
		float angles[3]; kv.GetString("angles", buffer, sizeof(buffer), "0.0 0.0 0.0");
		ExplodeString(buffer, " ", buffers, sizeof(buffers), sizeof(buffers[]));
		for (int c = 0; c < 3; c++) angles[c] = StringToFloat(buffers[c]);
		array.PushArray(angles, sizeof(angles)); // Index: 21
	}

	delete kv;
}

public void WeaponsOnConfigReload()
{
	WeaponsOnLoad();
}

void WeaponsGetName(int id, char[] name, int naxLen)
{
	if (sServerData.Weapons == null) {
		return;
	}

	ArrayList array = sServerData.Weapons.Get(id);
	array.GetString(WEAPONS_DATA_NAME, name, naxLen);
}

void WeaponsGetEntity(int id, char[] name, int naxLen)
{
	if (sServerData.Weapons == null) {
		return;
	}
	
	ArrayList array = sServerData.Weapons.Get(id);
	array.GetString(WEAPONS_DATA_ENTITY, name, naxLen);
}

int WeaponsGetTypes(int id)
{
	if (sServerData.Weapons == null) {
		return -1;
	}
	
	ArrayList array = sServerData.Weapons.Get(id);
	return array.Get(WEAPONS_DATA_TYPES);
}

int WeaponsGetSlot(int id)
{
	if (sServerData.Weapons == null) {
		return 0;
	}
	
	ArrayList array = sServerData.Weapons.Get(id);
	return array.Get(WEAPONS_DATA_SLOT);
}

int WeaponsGetRestrict(int id)
{
	if (sServerData.Weapons == null) {
		return 0;
	}
	
	ArrayList array = sServerData.Weapons.Get(id);
	return array.Get(WEAPONS_DATA_RESTRICT);
}

int WeaponsGetClip(int id)
{
	if (sServerData.Weapons == null) {
		return 0;
	}
	
	ArrayList array = sServerData.Weapons.Get(id);
	return array.Get(WEAPONS_DATA_CLIP);
}

int WeaponsGetAmmo(int id)
{
	if (sServerData.Weapons == null) {
		return 0;
	}
	
	ArrayList array = sServerData.Weapons.Get(id);
	return array.Get(WEAPONS_DATA_AMMO);
}

float WeaponsGetSpeed(int id)
{
	if (sServerData.Weapons == null) {
		return 0.0;
	}
	
	ArrayList array = sServerData.Weapons.Get(id);
	return array.Get(WEAPONS_DATA_SPEED);
}

float WeaponsGetDamage(int id)
{
	if (sServerData.Weapons == null) {
		return 1.0;
	}
	
	ArrayList array = sServerData.Weapons.Get(id);
	return array.Get(WEAPONS_DATA_DAMAGE);
}

float WeaponsGetKnockBack(int id)
{
	if (sServerData.Weapons == null) {
		return 1.0;
	}
	
	ArrayList array = sServerData.Weapons.Get(id);
	return array.Get(WEAPONS_DATA_KNOCKBACK);
}

float WeaponsGetJump(int id)
{
	if (sServerData.Weapons == null) {
		return 0.0;
	}
	
	ArrayList array = sServerData.Weapons.Get(id);
	return array.Get(WEAPONS_DATA_JUMP);
}

int WeaponsIsDrop(int id)
{
	if (sServerData.Weapons == null) {
		return 0;
	}
	
	ArrayList array = sServerData.Weapons.Get(id);
	return array.Get(WEAPONS_DATA_DROP);
}

int WeaponsIsMuzzle(int id)
{
	if (sServerData.Weapons == null) {
		return 0;
	}
	
	ArrayList array = sServerData.Weapons.Get(id);
	return array.Get(WEAPONS_DATA_MUZZLE);
}

bool WeaponsIsInfection(int id)
{
	if (sServerData.Weapons == null) {
		return false;
	}
	
	ArrayList array = sServerData.Weapons.Get(id);
	return array.Get(WEAPONS_DATA_INFECTION);
}

bool WeaponsIsTracer(int id)
{
	if (sServerData.Weapons == null) {
		return false;
	}
	
	ArrayList array = sServerData.Weapons.Get(id);
	return array.Get(WEAPONS_DATA_TRACER);
}

void WeaponsGetModelView(int id, char[] model, int naxLen)
{
	if (sServerData.Weapons == null) {
		return;
	}
	
	ArrayList array = sServerData.Weapons.Get(id);
	array.GetString(WEAPONS_DATA_MODEL_VIEW, model, naxLen);
}

int WeaponsGetModelViewID(int id)
{
	if (sServerData.Weapons == null) {
		return -1;
	}
	
	ArrayList array = sServerData.Weapons.Get(id);
	return array.Get(WEAPONS_DATA_MODEL_VIEW_ID);
}

void WeaponsGetModelWorld(int id, char[] model, int naxLen)
{
	if (sServerData.Weapons == null) {
		return;
	}
	
	ArrayList array = sServerData.Weapons.Get(id);
	array.GetString(WEAPONS_DATA_MODEL_WORLD, model, naxLen);
}

int WeaponsGetModelWorldID(int id)
{
	if (sServerData.Weapons == null) {
		return -1;
	}
	
	ArrayList array = sServerData.Weapons.Get(id);
	return array.Get(WEAPONS_DATA_MODEL_WORLD_ID);
}

int WeaponsGetSoundID(int id)
{
	if (sServerData.Weapons == null) {
		return -1;
	}
	
	ArrayList array = sServerData.Weapons.Get(id);
	return array.Get(WEAPONS_DATA_SOUND);
}

void WeaponsGetModelOrigin(int id, float origin[3])
{
	if (sServerData.Weapons == null) {
		return;
	}
	
	ArrayList array = sServerData.Weapons.Get(id);
	array.GetArray(WEAPONS_DATA_MODEL_ORIGIN, origin, sizeof(origin));
}

void WeaponsGetModelAngles(int id, float angles[3])
{
	if (sServerData.Weapons == null) {
		return;
	}
	
	ArrayList array = sServerData.Weapons.Get(id);
	array.GetArray(WEAPONS_DATA_MODEL_ANGLES, angles, sizeof(angles));
}

int WeaponsEntityToIndex(const char[] name, bool noprefix = false)
{
	if (sServerData.Weapons == null) {
		return -1;
	}
	
	char weaponname[64];
	for (int i = 0; i < sServerData.Weapons.Length; i++)
	{
		WeaponsGetName(i, weaponname, sizeof(weaponname));
		
		if (noprefix)
		{
			ReplaceString(weaponname, sizeof(weaponname), "weapon_", "");
			ReplaceString(weaponname, sizeof(weaponname), "item_", "");
		}
		
		if (strcmp(name, weaponname, false) == 0) {
			return i;
		}
	}
	return -1;
}

int WeaponsFindByID(int client, int id)
{
	for (int i = 0; i < ToolsGetMyWeapons(client); i++)
	{
		int weapon = ToolsGetWeapon(client, i);
		
		if (weapon != -1) {
			if (WeaponsGetCustomID(weapon) == id) {
				return weapon;
			}
		}
	}
	return -1;
}

int WeaponsGetCustomID(int entity)
{
	return GetEntProp(entity, Prop_Data, "m_iMaxHealth");
}

void WeaponsSetCustomID(int entity, int id)
{
	if (entity != -1)
	{
		SetEntProp(entity, Prop_Data, "m_iMaxHealth", id);
	}
}

int WeaponsGetOwner(int weapon)
{
	return GetEntPropEnt(weapon, Prop_Send, "m_hOwner");
}

int WeaponsGetAmmoType(int weapon)
{
	return GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
}

Action WeaponsOnRunCmd(int client, int& buttons, int LastButtons)
{
	static int weapon; weapon = ToolsGetActiveWeapon(client);

	if (weapon == -1 || !sClientData[client].RunCmd)
	{
		return Plugin_Continue;
	}
	return WeaponMODOnRunCmd(client, buttons, LastButtons, weapon);
}

public Action Hook_WeaponsOnShoot(const char[] te_name, const int[] Players, int numClients, float delay)
{ 
	int client = TE_ReadNum("m_iPlayer") + 1;

	if (!IsValidClient(client) || !IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}
	
	int weapon = ToolsGetActiveWeapon(client);
	
	if (weapon == -1)
	{
		return Plugin_Continue;
	}
	return WeaponMODOnShoot(client, weapon);
}

public Action Hook_WeaponCanUse(int client, int weapon)
{
	if (IsValidEdict(weapon))
	{
		if (sClientData[client].RespawnTimer != null)
		{
			return Plugin_Handled;
		}
	
		char classname[64];
		GetEdictClassname(weapon, classname, sizeof(classname));
		
		// if (IsFakeClient(client) && StrContains(classname, "weapon_knife", true) == 0)
		// {
		// 	return Plugin_Continue; // bot knife
		// }
		
		int index = WeaponsGetCustomID(weapon);
		if (index != -1)
		{
			if (!WeaponsHasAccessByType(client, index)) 
			{
				return Plugin_Handled;
			}
			
			if (WeaponsGetRestrict(index) == 1)
			{
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

bool WeaponsRemoveAll(int client, bool drop = false)
{
	int count = 0; bool remove = false;
	WeaponsRemoveClientGrenades(client);
	
	for (int i = 0; i < ToolsGetMyWeapons(client); i++)
	{
		int weapon = ToolsGetWeapon(client, i);
		
		if (weapon != -1)
		{
			count++;
			
			int id = WeaponsGetCustomID(weapon);
			if (id != -1)
			{
				if (!WeaponsHasAccessByType(client, id))
				{
					if (drop && WeaponsIsDrop(id))
					{
						WeaponsDrop(client, weapon);
					}
					else
					{
						RemovePlayerItem(client, weapon);
						AcceptEntityInput(weapon, "Kill");
					}
					
					remove = true;
				}
				else
				{
					if (sClientData[client].Zombie) // ...
					{
						RemovePlayerItem(client, weapon);
						AcceptEntityInput(weapon, "Kill");
					}
				}
			}
		}
	}
	
	if (remove)
	{
		ToolsSetHelmet(client, false);
		ToolsSetArmor(client, 0);
		ToolsSetDefuser(client, false);
	}
	return (remove || !count);
}

void WeaponsDrop(int client, int weapon)
{
	if (IsValidEdict(weapon)) 
	{
		if (ToolsGetOwner(weapon) != client)
		{
			ToolsSetOwner(weapon, client);
		}

		CS_DropWeapon(client, weapon, false, false);
	}
}

int WeaponsGive(int client, int id, bool drop = false)
{
	if (id != -1)   
	{
		if (!WeaponsHasAccessByType(client, id)) 
		{
			return -1;
		}
		
		if (drop)
		{
			int weapon = GetPlayerWeaponSlot(client, WeaponsGetSlot(id));
			
			if (weapon != -1) {
				WeaponsDrop(client, weapon);
			}
		}
		
		static char classname[64];
		WeaponsGetName(id, classname, sizeof(classname));
		
		float origin[3], angles[3];
		GetClientEyePosition(client, origin);
		GetClientEyeAngles(client, angles);
		
		origin[2] += 5.0;
		return SpawnWeapon(classname, "", origin, angles, client);
	}
	return -1;
}

void WeaponsRemoveClientGrenades(int client)
{
	int grenade = GetPlayerWeaponSlot(client, 3);
	while (grenade != -1) {
		WeaponsDrop(client, grenade);
		grenade = GetPlayerWeaponSlot(client, 3);
	}
}

stock void WeaponsScriptsFile(const char[] weaponname1, const char[] weaponname2)
{
	if (!DirExists("scripts")) {
		CreateDirectory("scripts", 511);
	}
	
	if (strcmp(weaponname1, weaponname2, false) == 0) {
		return;
	}
	
	static char source[NORMAL_LINE_LENGTH];
	FormatEx(source, sizeof(source), "scripts/%s.txt", weaponname2);
	if (FileExists(source)) {
		return;
	}
	
	FormatEx(source, sizeof(source), "scripts/%s.ctx", weaponname1);
	Handle file = OpenFile(source, "rb", true);
	if (file != null)
	{
		FormatEx(source, sizeof(source), "scripts/%s.ctx", weaponname2);
		Handle copytarget = OpenFile(source, "wb");
		if (copytarget != null)
		{
			int readcache;
	
			int buffer[64];
			while (!IsEndOfFile(file))
			{
				readcache = ReadFile(file, buffer, sizeof(buffer), 1);
				WriteFile(copytarget, buffer, readcache, 1);
			}
		}
		delete copytarget;
	}
	delete file;
}

bool WeaponsHasAccessByType(int client, int id)
{
	return ClassHasTypeBits(WeaponsGetTypes(id), ClassGetType(sClientData[client].Class));
}