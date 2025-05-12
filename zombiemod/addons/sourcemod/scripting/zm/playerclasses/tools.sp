Handle hDHookIsValidTarget;
Handle hSDKCallFireBullets;
Handle hSDKCallLookupAttachment;
Handle hSDKCallWeapon_ShootPosition;

int Player_bAccount;
int Player_bPlayerSpotted;

bool m_bCheckNullPtr;

void ToolsOnInit()
{
	int offset;
	
	fnInitSendPropOffset(Player_bAccount, "CCSPlayer", "m_iAccount");
	fnInitSendPropOffset(Player_bPlayerSpotted, "CCSPlayerResource", "m_bPlayerSpotted");
	
	fnInitGameConfOffset(sServerData.Config, offset, "IsValidObserverTarget");
	hDHookIsValidTarget = DHookCreate(offset, HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity, Hook_IsValidTarget);
	DHookAddParam(hDHookIsValidTarget, HookParamType_CBaseEntity);
	if (hDHookIsValidTarget == null) {
		LogError("[GameData] Failed to create DHook for \"IsValidObserverTarget\". Update virtual offset in \"%s\"", PLUGIN_CONFIG);
	}
	
	m_bCheckNullPtr = (GetFeatureStatus(FeatureType_Native, "DHookIsNullParam") == FeatureStatus_Available);
	
	Handle hDHookGiveDefaultItems = DHookCreateFromConf(sServerData.Config, "GiveDefaultItems");
	if (!DHookEnableDetour(hDHookGiveDefaultItems, false, DHook_GiveDefaultItemsPre)) {
		LogError("[GameData] Failed to create DHook for \"GiveDefaultItems\". Update virtual offset in \"%s\"", PLUGIN_CONFIG);
	}
	
	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetFromConf(sServerData.Config, SDKConf_Signature, "FX_FireBullets");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	if ((hSDKCallFireBullets = EndPrepSDKCall()) == null) {
		LogError("[GameData] Failed to load SDK call \"FX_FireBullets\". Update signature in \"%s\"", PLUGIN_CONFIG);
	}
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(sServerData.Config, SDKConf_Signature, "LookupAttachment");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	if ((hSDKCallLookupAttachment = EndPrepSDKCall()) == null){
		LogError("[GameData] Failed to load SDK call \"LookupAttachment\". Update signature in \"%s\"", PLUGIN_CONFIG);
	}
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(sServerData.Config, SDKConf_Virtual, "Weapon_ShootPosition");
	PrepSDKCall_SetReturnInfo(SDKType_Vector, SDKPass_ByValue);
	if ((hSDKCallWeapon_ShootPosition = EndPrepSDKCall()) == null){
		LogError("[GameData] Failed to load SDK call \"Weapon_ShootPosition\". Update signature in \"%s\"", PLUGIN_CONFIG);
	}
}

void ToolsOnLoad()
{
	sServerData.PlayerManager = GetPlayerResourceEntity();
	
	SDKHook(sServerData.PlayerManager, SDKHook_ThinkPost, Hook_ThinkPostRadar);
}

void ToolsOnClientInit(int client)
{
	if (!IsFakeClient(client))
	{
		if (hDHookIsValidTarget)
		{
			DHookEntity(hDHookIsValidTarget, true, client);
		}
	}
}

public MRESReturn DHook_GiveDefaultItemsPre(int pThis)
{
	return MRES_Supercede;
}

public void Hook_ThinkPostRadar(int entity)
{
	for (int i = 1; i < MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i))
		{
			if (sClientData[i].RespawnTimer != null)
			{
				SetEntProp(entity, Prop_Send, "m_bAlive", false, _, i);
			}
			
			if (sClientData[i].PlayerSpotted == true)
			{
				SetEntData(entity, Player_bPlayerSpotted + i, sClientData[i].PlayerSpott, 4, true);
			}
		}
	}
	
	// 
	// for (int i = 1; i <= MaxClients; i++) 
	// {
	// 	if (IsValidClient(i))
	// 	{
	// 		PrintCenterText(i, "[] %d", GetEntProp(i, Prop_Send, "m_bHasDefuser"));
	// 		SetEntProp(i, Prop_Send, "m_bHasDefuser", 1);
	// 	}
	// }
}

public MRESReturn Hook_IsValidTarget(int pThis, Handle hReturn, Handle hParams)
{
	if (m_bCheckNullPtr && DHookIsNullParam(hParams, 1))
	{
		return MRES_Ignored;
	}
	
	if (IsValidClient(pThis) && !IsPlayerAlive(pThis))
	{
		if (GetEntProp(pThis, Prop_Send, "m_iObserverMode") == 4)
		{
			int target = DHookGetParam(hParams, 1);
			if (IsValidClient(target) && IsPlayerAlive(target) && GetEntProp(target, Prop_Send, "m_iObserverMode") != 0)
			{
				SetEntProp(pThis, Prop_Send, "m_iObserverMode", 5);
				// DHookSetReturn(hReturn, true);
			}
		}
	}
	return MRES_Ignored;
}

void OnCreateBullet(int client, int weaponID, int mode, int seed, float angle2[2], float spread, float inaccuracy)
{
	static float position[3], angle[3];
	GetShootPosition(client, position);
	GetClientEyeAngles(client, angle);
	
	angle[0] += angle2[0];
	angle[1] += angle2[1];
	
	TE_Start("Shotgun Shot");
	TE_WriteVector("m_vecOrigin", position);
	TE_WriteFloat("m_vecAngles[0]", angle[0]);
	TE_WriteFloat("m_vecAngles[1]", angle[1]);
	TE_WriteNum("m_iWeaponID", 24); // 6|9|24
	TE_WriteNum("m_iMode", mode);
	TE_WriteNum("m_iSeed", seed);
	TE_WriteNum("m_iPlayer", client - 1);
	TE_WriteFloat("m_fInaccuracy", inaccuracy);
	TE_WriteFloat("m_fSpread", spread);
	TE_SendToAll();

	bool bCompensation = view_as<bool>(GetEntProp(client, Prop_Data, "m_bLagCompensation"));
	if (bCompensation) SetEntProp(client, Prop_Data, "m_bLagCompensation", false);
	
	if (hSDKCallFireBullets)
	{
		SDKCall(hSDKCallFireBullets, client, position, angle, weaponID, mode, seed, inaccuracy, spread, 0.0);
	}
	
	SetEntProp(client, Prop_Data, "m_bLagCompensation", bCompensation);
}

int ToolsLookupAttachment(int entity, char[] attach)
{
	if (!hSDKCallLookupAttachment)
	{
		return 0;
	}

	return SDKCall(hSDKCallLookupAttachment, entity, attach);
}

void GetShootPosition(int client, float pos[3])
{
	SDKCall(hSDKCallWeapon_ShootPosition, client, pos);
}

stock void fnInitGameConfOffset(GameData gameConf, int& offset, const char[] key)
{
	if ((offset = gameConf.GetOffset(key)) == -1)
	{
		LogError("GameData Validation Failed to get offset: \"%s\"", key);
	}
}

stock void fnInitGameFromConf(GameData gameConf, Handle& handle, const char[] name)
{
	if ((handle = DHookCreateFromConf(gameConf, name)) == null)
	{
		LogError("GameData Validation Failed to get signature: \"%s\"", name);
	}
}

stock void fnInitSendPropOffset(int& offset, const char[] class, const char[] prop)
{
	if ((offset = FindSendPropInfo(class, prop)) == -1)
	{
		LogError("GameData Validation Failed to find send prop: \"%s\"", prop);
	}
}