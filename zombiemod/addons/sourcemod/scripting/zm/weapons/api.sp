void WeaponsAPIOnNativeInit() 
{
	CreateNative("ZM_SpawnWeapon", Native_SpawnWeapon);
	CreateNative("ZM_GetClientViewModel", Native_GetClientViewModel);
	CreateNative("ZM_FireBullets", Native_FireBullets);
	CreateNative("ZM_GetFRightHand", Native_GetRightHand);
	CreateNative("ZM_WeaponAttachRemoveAddons", Native_WeaponAttachRemoveAddons);
	CreateNative("ZM_SendWeaponAnim", Native_SendWeaponAnim);
	
	CreateNative("ZM_GetWeaponNameID", Native_GetWeaponNameID);
	CreateNative("ZM_GetNumberWeapon", Native_GetNumberWeapon);
	CreateNative("ZM_GetWeaponName", Native_GetWeaponName);
	CreateNative("ZM_GetWeaponEntity", Native_GetWeaponEntity);
	CreateNative("ZM_GetWeaponDamage", Native_GetWeaponDamage);
	CreateNative("ZM_GetWeaponKnockBack", Native_GetWeaponKnockBack);
	CreateNative("ZM_GetWeaponSpeed", Native_GetWeaponSpeed);
	CreateNative("ZM_GetWeaponClip", Native_GetWeaponClip);
	CreateNative("ZM_GetWeaponAmmo", Native_GetWeaponAmmo);
	CreateNative("ZM_GetWeaponModelView", Native_GetWeaponModelView);
	CreateNative("ZM_GetWeaponModelViewID", Native_GetWeaponModelViewID);
	CreateNative("ZM_GetWeaponModelWorld", Native_GetWeaponModelWorld);    
	CreateNative("ZM_GetWeaponModelWorldID", Native_GetWeaponModelWorldID); 
}

public int Native_SpawnWeapon(Handle plugin, int numParams)
{
	char buffer[64], classname[64];
	GetNativeString(1, classname, sizeof(classname));
	GetNativeString(2, buffer, sizeof(buffer));
	
	float origin[3], angles[3];
	GetNativeArray(3, origin, sizeof(origin));
	GetNativeArray(4, angles, sizeof(angles));
	
	origin[2] += 5.0;
	return SpawnWeapon(classname, buffer, origin, angles);
}

public int Native_GetRightHand(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if (!UTIL_ValidateClient(client)) {
		return -1;
	}
	return sClientData[client].RightHand;
}

public int Native_WeaponAttachRemoveAddons(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if (!UTIL_ValidateClient(client)) {
		return false;
	}
	
	WeaponAttachRemoveAddons(client);
	return true;
}

public int Native_SendWeaponAnim(Handle plugin, int numParams)
{
	if (hSDKCallSendWeaponAnim)
	{
		int weapon = GetNativeCell(1);
		int anim = GetNativeCell(2);
	
		SDKCall(hSDKCallSendWeaponAnim, weapon, anim);
	}
	return 0;
}

public int Native_GetClientViewModel(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if (!UTIL_ValidateClient(client)) {
		return -1;
	}
	return sClientData[client].ViewModel[GetNativeCell(2)];
}

public int Native_FireBullets(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);

	if (!UTIL_ValidateClient(client)) {
		return false;
	}
	
	float angle[2]; GetNativeArray(5, angle, 2);
	OnCreateBullet(client, GetNativeCell(2), GetNativeCell(3), GetNativeCell(4), angle, GetNativeCell(6), GetNativeCell(7));
	return true;
}

public int Native_GetWeaponNameID(Handle plugin, int numParams)
{
	int maxLen;
	GetNativeStringLength(1, maxLen);

	if (!maxLen) {
		LogError("[Weapons] [Native Validation] Can't find weapon with an empty name");
		return -1;
	}

	static char name[SMALL_LINE_LENGTH];                                         
	GetNativeString(1, name, sizeof(name));
	return WeaponsEntityToIndex(name, GetNativeCell(2));
}

public int Native_GetNumberWeapon(Handle plugin, int numParams)
{
	return sServerData.Weapons.Length;
}

public int Native_GetWeaponName(Handle plugin, int numParams)
{
	int id = GetNativeCell(1);
	
	if (id >= sServerData.Weapons.Length) {
		LogError("[Weapons] [Native Validation] Invalid the weapon index (%d)", id);
		return -1;
	}
	
	int maxLen = GetNativeCell(3);

	if (!maxLen) {
		LogError("[Weapons] [Native Validation] No buffer size");
		return -1;
	}
	
	static char name[SMALL_LINE_LENGTH];
	WeaponsGetName(id, name, sizeof(name));

	return SetNativeString(2, name, maxLen);
}

public int Native_GetWeaponEntity(Handle plugin, int numParams)
{
	int id = GetNativeCell(1);
	
	if (id >= sServerData.Weapons.Length) {
		LogError("[Weapons] [Native Validation] Invalid the weapon index (%d)", id);
		return -1;
	}
	
	int maxLen = GetNativeCell(3);

	if (!maxLen) {
		LogError("[Weapons] [Native Validation] No buffer size");
		return -1;
	}
	
	static char sEntity[SMALL_LINE_LENGTH];
	WeaponsGetEntity(id, sEntity, sizeof(sEntity));
	return SetNativeString(2, sEntity, maxLen);
}

public int Native_GetWeaponDamage(Handle plugin, int numParams)
{
	int id = GetNativeCell(1);
	if (id >= sServerData.Weapons.Length) {
		LogError("[Weapons] [Native Validation] Invalid the weapon index (%d)", id);
		return -1;
	}
	return view_as<int>(WeaponsGetDamage(id));
}

public int Native_GetWeaponKnockBack(Handle plugin, int numParams)
{
	int id = GetNativeCell(1);
	if (id >= sServerData.Weapons.Length) {
		LogError("[Weapons] [Native Validation] Invalid the weapon index (%d)", id);
		return -1;
	}
	return view_as<int>(WeaponsGetKnockBack(id));
}

public int Native_GetWeaponSpeed(Handle plugin, int numParams)
{
	int id = GetNativeCell(1);
	
	if (id >= sServerData.Weapons.Length) {
		LogError("[Weapons] [Native Validation] Invalid the weapon index (%d)", id);
		return -1;
	}
	return view_as<int>(WeaponsGetSpeed(id));
}

public int Native_GetWeaponClip(Handle plugin, int numParams)
{
	int id = GetNativeCell(1);
	
	if (id >= sServerData.Weapons.Length) {
		LogError("[Weapons] [Native Validation] Invalid the weapon index (%d)", id);
		return -1;
	}
	return WeaponsGetClip(id);
}

public int Native_GetWeaponAmmo(Handle plugin, int numParams)
{
	int id = GetNativeCell(1);
	
	if (id >= sServerData.Weapons.Length) {
		LogError("[Weapons] [Native Validation] Invalid the weapon index (%d)", id);
		return -1;
	}
	return WeaponsGetAmmo(id);
}

public int Native_GetWeaponModelView(Handle plugin, int numParams)
{
	int id = GetNativeCell(1);
	
	if (id >= sServerData.Weapons.Length) {
		LogError("[Weapons] [Native Validation] Invalid the weapon index (%d)", id);
		return -1;
	}
	
	int maxLen = GetNativeCell(3);

	if (!maxLen) {
		LogError("[Weapons] [Native Validation] No buffer size");
		return -1;
	}
	
	static char model[PLATFORM_LINE_LENGTH];
	WeaponsGetModelView(id, model, sizeof(model));
	return SetNativeString(2, model, maxLen);
}

public int Native_GetWeaponModelViewID(Handle plugin, int numParams)
{
	int id = GetNativeCell(1);
	
	if (id >= sServerData.Weapons.Length) {
		LogError("[Weapons] [Native Validation] Invalid the weapon index (%d)", id);
		return -1;
	}
	return WeaponsGetModelViewID(id);
}

public int Native_GetWeaponModelWorld(Handle plugin, int numParams)
{
	int id = GetNativeCell(1);
	
	if (id >= sServerData.Weapons.Length) {
		LogError("[Weapons] [Native Validation] Invalid the weapon index (%d)", id);
		return -1;
	}
	
	int maxLen = GetNativeCell(3);

	if (!maxLen) {
		LogError("[Weapons] [Native Validation] No buffer size");
		return -1;
	}
	
	static char sModel[PLATFORM_LINE_LENGTH];
	WeaponsGetModelWorld(id, sModel, sizeof(sModel));
	return SetNativeString(2, sModel, maxLen);
}

public int Native_GetWeaponModelWorldID(Handle plugin, int numParams)
{
	int id = GetNativeCell(1);
	
	if (id >= sServerData.Weapons.Length) {
		LogError("[Weapons] [Native Validation] Invalid the weapon index (%d)", id);
		return -1;
	}
	return WeaponsGetModelWorldID(id);
}