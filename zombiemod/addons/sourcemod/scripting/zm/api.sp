enum struct ForwardData
{
	GlobalForward OnGameModeStart;
	GlobalForward OnGameModeEnd;
	GlobalForward OnCheckRoundTimeExpired;
	GlobalForward OnClientValidateDamage;
	GlobalForward OnClientDamaged;
	GlobalForward OnHudText;
	GlobalForward OnClientJoinTeamed;
	GlobalForward OnClientModel;
	GlobalForward OnClientUpdated;
	GlobalForward OnClientRespawn;
	GlobalForward OnClientValidateClass;
	GlobalForward OnPlayFootStep;
	GlobalForward OnPlayerSpawn;
	GlobalForward OnWeaponCreated;
	GlobalForward OnWeaponAnimationEvent;
	GlobalForward OnWeaponDeploy;
	GlobalForward OnWeaponBullet;
	GlobalForward OnWeaponHolster;
	GlobalForward OnWeaponDrop;
	GlobalForward OnWeaponDrop2;
	GlobalForward OnWeaponRunCmd;
	GlobalForward OnEngineExecute;

	void OnForwardInit()
	{
		this.OnGameModeStart = new GlobalForward("ZM_OnGameModeStart", ET_Ignore, Param_Cell);
		this.OnGameModeEnd = new GlobalForward("ZM_OnGameModeEnd", ET_Ignore, Param_Cell);
		this.OnCheckRoundTimeExpired = new GlobalForward("ZM_OnCheckRoundTimeExpired", ET_Hook, Param_Cell, Param_String);
	
		this.OnClientValidateDamage = new GlobalForward("ZM_OnClientValidateDamage", ET_Ignore, Param_Cell, Param_CellByRef, Param_CellByRef, Param_FloatByRef, Param_CellByRef);
		this.OnClientDamaged = new GlobalForward("ZM_OnClientDamaged", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Float, Param_Cell); 
		this.OnHudText = new GlobalForward("ZM_OnHudText", ET_Hook, Param_Cell, Param_String);
		this.OnClientJoinTeamed = new GlobalForward("ZM_OnClientJoinTeamed", ET_Ignore, Param_Cell, Param_Cell);
		
		this.OnClientModel = new GlobalForward("ZM_OnClientModel", ET_Hook, Param_Cell, Param_String);
		this.OnClientUpdated = new GlobalForward("ZM_OnClientUpdated", ET_Ignore, Param_Cell, Param_Cell);
		this.OnClientRespawn = new GlobalForward("ZM_OnClientRespawn", ET_Ignore, Param_Cell, Param_Cell);
		this.OnClientValidateClass = new GlobalForward("ZM_OnClientValidateClass", ET_Hook, Param_Cell, Param_Cell);
		this.OnPlayFootStep = new GlobalForward("ZM_OnPlayFootStep", ET_Hook, Param_Cell, Param_String, Param_Cell, Param_Cell, Param_Cell, Param_Float, Param_Cell);
		this.OnPlayerSpawn = new GlobalForward("ZM_OnPlayerSpawn", ET_Hook, Param_Cell);
		
		this.OnWeaponCreated = new GlobalForward("ZM_OnWeaponCreated", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
		this.OnWeaponAnimationEvent = new GlobalForward("ZM_OnWeaponAnimationEvent", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Float, Param_Float, Param_Cell);
		this.OnWeaponDeploy = new GlobalForward("ZM_OnWeaponDeploy", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
		this.OnWeaponBullet = new GlobalForward("ZM_OnWeaponBullet", ET_Ignore, Param_Cell, Param_Cell, Param_Array, Param_Cell);
		this.OnWeaponHolster = new GlobalForward("ZM_OnWeaponHolster", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
		this.OnWeaponDrop = new GlobalForward("ZM_OnWeaponDrop", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
		this.OnWeaponDrop2 = new GlobalForward("ZM_OnWeaponDrop2", ET_Ignore, Param_Cell, Param_Cell);
		this.OnWeaponRunCmd = new GlobalForward("ZM_OnWeaponRunCmd", ET_Hook, Param_Cell, Param_CellByRef, Param_Cell, Param_Cell, Param_Cell);
	
		this.OnEngineExecute = new GlobalForward("ZM_OnEngineExecute", ET_Ignore);
	}
	
	//
	void _OnGameModeEnd(CSRoundEndReason reason)
	{
		Call_StartForward(this.OnGameModeEnd);
		Call_PushCell(reason);
		Call_Finish();
	}
	void _OnGameModeStart(int gamemode)
	{
		Call_StartForward(this.OnGameModeStart);
		Call_PushCell(gamemode);
		Call_Finish();
	}
	void _OnCheckRoundTimeExpired()
	{
		Call_StartForward(this.OnCheckRoundTimeExpired);
		Call_Finish();
	}
	
	//
    void _OnClientValidateDamage(int client, int& attacker, int& inflictor, float& damage, int& damagetype)
    {
        Call_StartForward(this.OnClientValidateDamage);
        Call_PushCell(client);
        Call_PushCellRef(attacker);
        Call_PushCellRef(inflictor);
        Call_PushFloatRef(damage);
        Call_PushCellRef(damagetype);
        Call_Finish();
    }
	void _OnClientDamaged(int client, int attacker, int inflictor, float damage, int damagetype)
	{
		Call_StartForward(this.OnClientDamaged);
		Call_PushCell(client);
		Call_PushCell(attacker);
		Call_PushCell(inflictor);
		Call_PushFloat(damage);
		Call_PushCell(damagetype);
		Call_Finish();
	}
	Action _OnHudText(int client, const char[] name)
	{
		Action result = Plugin_Continue;
		Call_StartForward(this.OnHudText);
		Call_PushCell(client);
		Call_PushString(name);
		Call_Finish(result);
		return result;
	}
	void _OnClientJoinTeamed(int client, int team)
	{
		Call_StartForward(this.OnClientJoinTeamed);
		Call_PushCell(client);
		Call_PushCell(team);
		Call_Finish();
	}
	
	//
	Action _OnClientModel(int client, const char[] model)
	{
		Action result = Plugin_Continue;
		Call_StartForward(this.OnClientModel);
		Call_PushCell(client);
		Call_PushString(model);
		Call_Finish(result);
		return result;
	}
	void _OnClientUpdated(int client, int attacker)
	{
		Call_StartForward(this.OnClientUpdated);
		Call_PushCell(client);
		Call_PushCell(attacker);
		Call_Finish();
	}
	void _OnClientRespawn(int client, int RespawnTimer)
	{
		Call_StartForward(this.OnClientRespawn);
		Call_PushCell(client);
		Call_PushCell(RespawnTimer);
		Call_Finish();
	}
	void _OnClientValidateClass(int client, int id, Action &result)
	{
		Call_StartForward(this.OnClientValidateClass);
		Call_PushCell(client);
		Call_PushCell(id);
		Call_Finish(result);
	}
	Action _OnPlayFootStep(int client, const char[] sound, int channel, int level, int flags, float volume, int pitch)
	{
		Action result = Plugin_Continue;
		Call_StartForward(this.OnPlayFootStep);
		Call_PushCell(client);
		Call_PushString(sound);
		Call_PushCell(channel);
		Call_PushCell(level);
		Call_PushCell(flags);
		Call_PushFloat(volume);
		Call_PushCell(pitch);
		Call_Finish(result);
		return result;
	}
	Action _OnPlayerSpawn(int client)
	{
		Action result = Plugin_Continue;
		Call_StartForward(this.OnPlayerSpawn);
		Call_PushCell(client);
		Call_Finish(result);
		return result;
	}
	
	//
	void _OnWeaponCreated(int client, int weapon, int id)
	{
		Call_StartForward(this.OnWeaponCreated);
		Call_PushCell(client);
		Call_PushCell(weapon);
		Call_PushCell(id);
		Call_Finish();
	}
	void _OnWeaponAnimationEvent(int client, int weapon, int sequence, float fCycle, float fPrevCycle, int id)
	{
		Call_StartForward(this.OnWeaponAnimationEvent);
		Call_PushCell(client);
		Call_PushCell(weapon);
		Call_PushCell(sequence);
		Call_PushFloat(fCycle);
		Call_PushFloat(fPrevCycle);
		Call_PushCell(id);
		Call_Finish();
	}
	void _OnWeaponDeploy(int client, int weapon, int id)
	{
		Call_StartForward(this.OnWeaponDeploy);
		Call_PushCell(client);
		Call_PushCell(weapon);
		Call_PushCell(id);
		Call_Finish();
	}
	void _OnWeaponBullet(int client, int weapon, const float bullet[3], int id)
	{
		Call_StartForward(this.OnWeaponBullet);
		Call_PushCell(client);
		Call_PushCell(weapon);
		Call_PushArray(bullet, 3);
		Call_PushCell(id);
		Call_Finish();
	}
	void _OnWeaponHolster(int client, int weapon, int id)
	{
		Call_StartForward(this.OnWeaponHolster);
		Call_PushCell(client);
		Call_PushCell(weapon);
		Call_PushCell(id);
		Call_Finish();
	}
	void _OnWeaponDrop(int client, int weapon, int id)
	{
		Call_StartForward(this.OnWeaponDrop);
		Call_PushCell(client);
		Call_PushCell(weapon);
		Call_PushCell(id);
		Call_Finish();
	}
	void _OnWeaponDrop2(int weapon, int id)
	{
		Call_StartForward(this.OnWeaponDrop2);
		Call_PushCell(weapon);
		Call_PushCell(id);
		Call_Finish();
	}
	Action _OnWeaponRunCmd(int client, int& buttons, int LastButtons, int weapon, int id)
	{
		Action result = Plugin_Continue;
		Call_StartForward(this.OnWeaponRunCmd);
		Call_PushCell(client);
		Call_PushCellRef(buttons);
		Call_PushCell(LastButtons);
		Call_PushCell(weapon);
		Call_PushCell(id);
		Call_Finish(result);
		return result;
	}
	
	//
	void _OnEngineExecute()
	{
		Call_StartForward(this.OnEngineExecute);
		Call_Finish();
	}
}
ForwardData sForwardData;

APLRes APIOnNativeInit()
{
	sForwardData.OnForwardInit();
	
	MenusOnNativeInit();
	SkinsOnNativeInit();
	ClassesOnNativeInit();
	WeaponsAPIOnNativeInit();
	GameModesOnNativeInit();
	
	CreateNative("ZM_SetPlayerSpotted", Native_SetPlayerSpotted);
	CreateNative("ZM_LookupAttachment", Native_LookupAttachment);
	CreateNative("ZM_GetHudSync", Native_GetHudSync);
	CreateNative("ZM_RespawnPlayer", Native_RespawnPlayer);
	CreateNative("ZM_SpawnTeleportToRespawn", Native_SpawnTeleportToRespawn);
	CreateNative("ZM_TerminateRound", Native_TerminateRound);
	CreateNative("ZM_TakeDamage", Native_TakeDamage);
	CreateNative("ZM_IsRespawn", Native_IsRespawn);
	CreateNative("ZM_IsClientZombie", Native_IsClientZombie);
	CreateNative("ZM_IsClientHuman", Native_IsClientHuman);
	CreateNative("ZM_IsClientCustom", Native_IsClientCustom);
	CreateNative("ZM_IsMapLoaded", Native_IsMapLoaded);
	CreateNative("ZM_IsNewRound", Native_IsNewRound);
	CreateNative("ZM_IsEndRound", Native_IsEndRound);
	CreateNative("ZM_IsStartedRound", Native_IsStartedRound);
	CreateNative("ZM_GetHumanAmount", Native_GetHumanAmount);
	CreateNative("ZM_GetZombieAmount", Native_GetZombieAmount);
	CreateNative("ZM_GetAliveAmount", Native_GetAliveAmount);
	CreateNative("ZM_GetRandomHuman", Native_GetRandomHuman);
	CreateNative("ZM_GetRandomZombie", Native_GetRandomZombie);
	CreateNative("ZM_GetRoundTime", Native_GetRoundTime);
	CreateNative("ZM_ApplyKnock", Native_ApplyKnock);
	CreateNative("ZM_GetSvaeDefaultCart", Native_GetSvaeDefaultCart);
	
	CreateNative("ZM_PrintToChat", Native_PrintToChat);
	CreateNative("ZM_PrintToChatAll", Native_PrintToChatAll);
	
	RegPluginLibrary("zombiemod");
	return APLRes_Success;
}

public int Native_GetSvaeDefaultCart(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if (!UTIL_ValidateClient(client)) {
		return 0;
	}
	
	if (sClientData[client].DefaultCart != null)
	{
		return sClientData[client].DefaultCart.Length;
	}
	return 0;
}

public int Native_SetPlayerSpotted(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	sClientData[client].PlayerSpotted = !GetNativeCell(2);
	sClientData[client].PlayerSpott = GetNativeCell(3);
	return 0;
}

public int Native_LookupAttachment(Handle plugin, int numParams)
{
	static char attach[SMALL_LINE_LENGTH];
	
	int entity = GetNativeCell(1);
	GetNativeString(2, attach, sizeof(attach));
	return ToolsLookupAttachment(entity, attach); 
}

public int Native_GetHudSync(Handle plugin, int numParams)
{
	return view_as<int>(sServerData.SyncHudClass);
}

public int Native_RespawnPlayer(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if (!UTIL_ValidateClient(client)) {
		return false;
	}
	return ToolsForceToRespawn(client);
}

public int Native_SpawnTeleportToRespawn(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if (!UTIL_ValidateClient(client)) {
		return false;
	}
	
	SpawnTeleportToRespawn(client);
	return true;
}

public int Native_TerminateRound(Handle plugin, int numParams)
{
	return ZombieModTerminateRound();
}

public int Native_TakeDamage(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int attacker = GetNativeCell(2);
	int inflictor = GetNativeCell(3);
	float damage = GetNativeCell(4);
	int damagetype = GetNativeCell(5);

	Action result = Hook_OnTakeDamage(client, attacker, inflictor, damage, damagetype);
	
	if (result == Plugin_Changed)
	{
		if (!IsValidEdict(inflictor)) inflictor = client;
		if (!IsValidClient(attacker)) attacker = client;
		SDKHooks_TakeDamage(client, inflictor, attacker, damage, damagetype);
	}
	
	return (result != Plugin_Continue) ? true:false;
} 

public int Native_IsRespawn(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if (!UTIL_ValidateClient(client)) {
		return false;
	}
	
	int mode = GetNativeCell(2);
	
	if (mode != -1)
	{
		if (ModesGetRespawn(sServerData.RoundMode) == mode)
		{
			return false;
		}
	}
	
	return (sClientData[client].RespawnTimer == null) ? false : true;
}

public int Native_ApplyKnock(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if (!UTIL_ValidateClient(client)) {
		return false;
	}
	
	int attacker = GetNativeCell(2);
	if (!UTIL_ValidateClient(attacker)) {
		return false;
	}
	
	int inflictor = GetNativeCell(3);
	float KnockRatio = GetNativeCell(4);
	int damagetype = GetNativeCell(5);
	
	static char classname[SMALL_LINE_LENGTH];
	GetNativeString(6, classname, sizeof(classname));
	
	HitGroupsApplyKnock(client, attacker, inflictor, KnockRatio, damagetype, classname);
	return true;
}

public int Native_IsClientZombie(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return sClientData[client].Zombie;
}

public int Native_IsClientHuman(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return !sClientData[client].Zombie;
}

public int Native_IsClientCustom(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return sClientData[client].Custom;
}

public int Native_IsMapLoaded(Handle plugin, int numParams)
{
	return sServerData.MapLoaded;
}

public int Native_IsNewRound(Handle hPlugin, int iNumParams)
{
	return sServerData.RoundNew;
}

public int Native_IsEndRound(Handle plugin, int numParams)
{
	return sServerData.RoundEnd;
}

public int Native_IsStartedRound(Handle plugin, int numParams)
{
	return sServerData.RoundStart;
}

public int Native_GetHumanAmount(Handle plugin, int numParams)
{
	return GetHumans();
}

public int Native_GetZombieAmount(Handle plugin, int numParams)
{
	return GetZombies();
}

public int Native_GetAliveAmount(Handle plugin, int numParams)
{
	return fnGetAlive();
}

public int Native_GetRandomHuman(Handle plugin, int numParams)
{
	return GetRandomHuman();
}

public int Native_GetRandomZombie(Handle plugin, int numParams)
{
	return GetRandomZombie();
}

public int Native_GetRoundTime(Handle plugin, int numParams)
{
	return view_as<int>(sServerData.GetRoundTime);
}

public int Native_PrintToChat(Handle plugin, int numParams)
{
	static char format[PLATFORM_LINE_LENGTH];
	int client = GetNativeCell(1);
	int target = GetNativeCell(2);
	
	if (!UTIL_ValidateClient(client)) {
		return false;
	}
	
	FormatNativeString(0, 3, 4, sizeof(format), _, format);
	
	static char buffer[SMALL_LINE_LENGTH], translation[PLATFORM_LINE_LENGTH];
	sCvarList.CHAT_PREFIX.GetString(buffer, sizeof(buffer));
	TranslationPluginFormatString(-1, -1, buffer, sizeof(buffer));
	
	VFormat(translation, sizeof(translation), format, 2);
	TranslationPluginFormatString(client, target, translation, sizeof(translation));

	PrintToChat(client, "\x01%s %s", buffer, translation);
	return true;
}

public int Native_PrintToChatAll(Handle plugin, int numParams)
{
	int target = GetNativeCell(1);

	static char format[PLATFORM_LINE_LENGTH];
	FormatNativeString(0, 2, 3, sizeof(format), _, format);
	
	static char buffer[SMALL_LINE_LENGTH], translation[PLATFORM_LINE_LENGTH];
	sCvarList.CHAT_PREFIX.GetString(buffer, sizeof(buffer));
	TranslationPluginFormatString(-1, -1, buffer, sizeof(buffer));
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && !IsFakeClient(i))
		{
			SetGlobalTransTarget(i);
			VFormat(translation, sizeof(translation), format, 1);
			TranslationPluginFormatString(-1, target, translation, sizeof(translation));
			PrintToChat(i, "\x01%s %s", buffer, translation);
		}
	}
	return 0;
}