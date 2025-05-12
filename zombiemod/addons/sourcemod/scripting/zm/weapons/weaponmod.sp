Handle hDHookGiveNamedItem;
Handle hDHookGetPlayerMaxSpeed;
Handle hDHookGetMaxClip;
Handle hDHookGivePlayerAmmo;
Handle hDHookWeaponHolster;

Handle hSDKCallTouch;
Handle hSDKCallSendWeaponAnim;

int m_TracerTableID;

void WeaponModOnInit()
{
	if (sServerData.Late)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				OnClientPostAdminCheck(i);
				
				sClientData[i].ViewModel[0] = GetEntPropEnt(i, Prop_Send, "m_hViewModel");
				
				int PVM = MaxClients+1;
				while ((PVM = FindEntityByClassname(PVM, "predicted_viewmodel")) != -1)
				{
					if (WeaponsGetOwner(PVM) == i)
					{
						if (GetEntProp(PVM, Prop_Send, "m_nViewModelIndex") == 1)
						{
							sClientData[i].ViewModel[1] = PVM;
							break;
						}
					}
				}
			}
		}
		sServerData.Late = false;
	}

	int offset;
	
	fnInitGameConfOffset(sServerData.SDKTools, offset, "GiveNamedItem");
	hDHookGiveNamedItem = DHookCreate(offset, HookType_Entity, ReturnType_CBaseEntity, ThisPointer_CBaseEntity, OnGiveNamedItem);
	DHookAddParam(hDHookGiveNamedItem, HookParamType_CharPtr, -1, DHookPass_ByVal);
	DHookAddParam(hDHookGiveNamedItem, HookParamType_Int, -1, DHookPass_ByVal);
	if (hDHookGiveNamedItem == null) {
		LogError("[GameData] Failed to create DHook for \"GiveNamedItem\". Update \"SourceMod\"");
	}
	
	fnInitGameConfOffset(sServerData.Config, offset, "CCSPlayer::GetPlayerMaxSpeed");
	hDHookGetPlayerMaxSpeed = DHookCreate(offset, HookType_Entity, ReturnType_Float, ThisPointer_CBaseEntity, OnGetPlayerMaxSpeed);
	if (hDHookGetPlayerMaxSpeed == null) {
		LogError("[GameData] Failed to create DHook for \"CCSPlayer::GetPlayerMaxSpeed\". Update virtual offset in \"%s\"", PLUGIN_CONFIG);
	}
	
	fnInitGameConfOffset(sServerData.Config, offset, "GetMaxClip");
	hDHookGetMaxClip = DHookCreate(offset, HookType_Entity, ReturnType_Int, ThisPointer_CBaseEntity, OnGetMaxClip);
	if (hDHookGetMaxClip == null) {
		LogError("[GameData] Failed to create DHook for \"GetMaxClip\". Update virtual offset in \"%s\"", PLUGIN_CONFIG);
	}
	
	fnInitGameConfOffset(sServerData.SDKTools, offset, "GiveAmmo");
	hDHookGivePlayerAmmo = DHookCreate(offset, HookType_Entity, ReturnType_Int, ThisPointer_CBaseEntity, GiveAmmo);
	DHookAddParam(hDHookGivePlayerAmmo, HookParamType_Int);
	DHookAddParam(hDHookGivePlayerAmmo, HookParamType_Int);
	DHookAddParam(hDHookGivePlayerAmmo, HookParamType_Bool);
	if (hDHookGivePlayerAmmo == null) {
		LogError("[GameData] Failed to create DHook for \"GiveAmmo\". Update \"SourceMod\"");
	}
	
	fnInitGameConfOffset(sServerData.Config, offset, "Holster");
	hDHookWeaponHolster = DHookCreate(offset, HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity, OnHolster);
	DHookAddParam(hDHookWeaponHolster, HookParamType_CBaseEntity);
	if (hDHookWeaponHolster == null) {
		LogError("[GameData] Failed to create DHook for \"Holster\". Update virtual offset in \"%s\"", PLUGIN_CONFIG);
	}
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(sServerData.Config, SDKConf_Virtual, "Touch");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	if ((hSDKCallTouch = EndPrepSDKCall()) == null) {
		LogError("[GameData] Failed to load SDK call \"Touch\". Update signature in \"%s\"", PLUGIN_CONFIG);
	}
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(sServerData.Config, SDKConf_Virtual, "SendWeaponAnim");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	if ((hSDKCallSendWeaponAnim = EndPrepSDKCall()) == null) {
		LogError("[GameData] Failed to load SDK call \"SendWeaponAnim\". Update signature in \"%s\"", PLUGIN_CONFIG);
	}
	
	HookEvent("bullet_impact", Hook_BulletImpact, EventHookMode_Post);
	
	AddCommandListener(Command_Drop, "drop");
}

void WeaponModOnLoad()
{
	int index = FindStringTable("EffectDispatch");
	LockStringTables(false);
	AddToStringTable(index, "Tracer");
	LockStringTables(true);
	
	m_TracerTableID = FindStringIndex(index, "Tracer"); // FindStringTable("EffectDispatch")
}

public Action Command_Drop(int client, char[] command, int args)
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		if (GetEntitySequence(client) != 0) {
			return Plugin_Handled;
		}
	
		int weapon = ToolsGetActiveWeapon(client);

		if (weapon != -1)
		{
			int id = WeaponsGetCustomID(weapon);
			if (id != -1)
			{
				if (!WeaponsIsDrop(id)) 
				{
					return Plugin_Handled;
				}
				
				if (GetPlayerWeaponSlot(client, 3) != -1)
				{
					if (GetEntProp(weapon, Prop_Data, "m_nSequence") == 5)
					{
						return Plugin_Handled;
					}
				
					WeaponsDrop(client, weapon);
					return Plugin_Handled;
				}
			}
		}
	}
	return Plugin_Continue;
}

void WeaponModOnClientInit(int client)
{
	if (hDHookGetPlayerMaxSpeed)
	{
		DHookEntity(hDHookGetPlayerMaxSpeed, true, client);
	}

	if (hDHookGiveNamedItem)
	{
		DHookEntity(hDHookGiveNamedItem, false, client);
	}
	
	if (hDHookGivePlayerAmmo)
	{
		DHookEntity(hDHookGivePlayerAmmo, false, client);
	}
}

void WeaponsModOnClientSpawn(int client)
{
	int c4 = GetPlayerWeaponSlot(client, 4); // c4
	if (c4 != -1)
	{
		int index = WeaponsGetCustomID(c4);
		if (index != -1)
		{
			DataPack data = new DataPack();
			data.WriteCell(index);
			data.WriteCell(GetClientUserId(client));
			RequestFrame(Frame_WeaponsModOnClientSpawn, data);
		}
	}
}

public void Frame_WeaponsModOnClientSpawn(DataPack data)
{
	data.Reset();
	int index = data.ReadCell();
	int client = GetClientOfUserId(data.ReadCell());
	delete data;
	
	if (IsValidClient(client) && !IsFakeClient(client) && IsPlayerAlive(client))
	{
		WeaponsGive(client, index);
	}
}

Action WeaponMODOnShoot(int client, int weapon) 
{ 
	int index = WeaponsGetCustomID(weapon);
	if (index != -1)    
	{
		if (sClientData[client].IsCustom) // Custom Weapon
		{
			// SetVariantString("!activator");
			// AcceptEntityInput(sClientData[client].ViewModel[0], "SetParent", client, sClientData[client].ViewModel[0], 0);
			// SetVariantString("muzzle_flash");
			// AcceptEntityInput(sClientData[client].ViewModel[0], "SetParentAttachment", client, sClientData[client].ViewModel[0], 0);
		
			if (WeaponsIsMuzzle(index))
			{
				if (!HasEntProp(weapon, Prop_Data, "m_bSilencerOn") || !GetEntProp(weapon, Prop_Data, "m_bSilencerOn"))
				{
					TE_SetupMuzzleFlash(view_as<float>({-3000.0, -3000.0, -3000.0}), view_as<float>({0.0, 0.0, 0.0}), 0.0, 1);
					
					int numPlayers = 0; int players[65];
					for (int i = 1; i <= MaxClients; i++)
					{
						if (i != client && IsClientInGame(i) && !IsFakeClient(i) && (GetEntPropEnt(i, Prop_Send, "m_hObserverTarget") != client || GetEntProp(i, Prop_Send, "m_iObserverMode") != 4))
						{
							players[numPlayers++] = i;
						}
					}
					TE_Send(players, numPlayers);
				}
				return Plugin_Stop;
			}
		}
		return SoundsOnClientShoot(client, index);
	}
	return Plugin_Continue;
}

void WeaponModnEntityCreated(int weapon, const char[] classname)
{
	if (classname[0] == 'w' && classname[1] == 'e' && classname[6] == '_') // weapon_
	{
		SDKHook(weapon, SDKHook_SpawnPost, WeaponModOnWeaponSpawn);
	}
	else if (StrEqual(classname, "predicted_viewmodel", false))
	{
		SDKHook(weapon, SDKHook_SpawnPost, WeaponModOnEntitySpawned);
	}
	else
	{
		int len = strlen(classname) - 11;
		
		if (len > 0)
		{
			if (!strncmp(classname[len], "_proj", 5, false))
			{
				SDKHook(weapon, SDKHook_SpawnPost, WeaponModOnGrenadeSpawn);
			}
		}
	}
}

public void WeaponModOnWeaponSpawn(int weapon)
{
	char weaponname[NORMAL_LINE_LENGTH];
	GetEntityClassname(weapon, weaponname, sizeof(weaponname));
	
	int index = WeaponsEntityToIndex(weaponname);
	
	if (index != -1)
	{
		WeaponsSetCustomID(weapon, index);
		
		if (hDHookWeaponHolster)
		{
			DHookEntity(hDHookWeaponHolster, true, weapon);
		}
		
		if (WeaponsGetModelWorldID(index) != 0)
		{
			RequestFrame(Frame_NextToDrop, EntIndexToEntRef(weapon));
		}
		
		RequestFrame(WeaponMODOnWeaponSpawnPost, EntIndexToEntRef(weapon));
	}
}

public void WeaponModOnEntitySpawned(int entity)
{
	int owner = WeaponsGetOwner(entity);
	
	if (IsValidClient(owner))
	{
		sClientData[owner].ViewModel[GetEntProp(entity, Prop_Send, "m_nViewModelIndex")] = entity;
	}
}

public void WeaponMODOnWeaponSpawnPost(int ref) 
{
	int weapon = EntRefToEntIndex(ref);
	if (weapon != -1)
	{
		int index = WeaponsGetCustomID(weapon);
		if (index != -1)
		{
			if (WeaponsGetAmmoType(weapon) != -1)
			{
				int clip = WeaponsGetClip(index);
				if (clip)
				{
					SetEntProp(weapon, Prop_Data, "m_iClip1", clip);
					
					if (hDHookGetMaxClip) 
					{
						DHookEntity(hDHookGetMaxClip, true, weapon);
					}
				}
			}
			
			sForwardData._OnWeaponCreated(-1, weapon, index);
		}
	}
}

public Action Hook_BulletImpact(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	int weapon = ToolsGetActiveWeapon(client);
	
	if (weapon == -1)
	{
		return Plugin_Continue;
	}
	
	static float bullet[3], Eyebullet[3];
	GetClientEyePosition(client, Eyebullet);
	bullet[0] = event.GetFloat("x");
	bullet[1] = event.GetFloat("y");
	bullet[2] = event.GetFloat("z");
	
	int id = WeaponsGetCustomID(weapon);
	if (id != -1)    
	{
		sForwardData._OnWeaponBullet(client, weapon, bullet, id);
		
		if (WeaponsIsTracer(id) == true)
		{
			TE_Start("EffectDispatch");
			TE_WriteNum("m_iEffectName", m_TracerTableID);	
			TE_WriteFloat("m_vStart[0]", Eyebullet[0]);
			TE_WriteFloat("m_vStart[1]", Eyebullet[1]);
			TE_WriteFloat("m_vStart[2]", Eyebullet[2]);
			TE_WriteFloat("m_vOrigin[0]", bullet[0]);
			TE_WriteFloat("m_vOrigin[1]", bullet[1]);
			TE_WriteFloat("m_vOrigin[2]", bullet[2]);
			TE_WriteFloat("m_flScale", 6000.0);
			TE_WriteNum("m_nAttachmentIndex", 1); // 2
			TE_WriteNum("entindex", weapon);
			TE_WriteNum("m_fFlags", 2);
			TE_SendToAll();
		}
	}
	return Plugin_Continue;
}

public Action CS_OnBuyCommand(int client, const char[] classname)
{
	if (IsValidClient(client))
	{
		if (sClientData[client].Zombie)
		{
			return Plugin_Handled;
		}
		
		int index = WeaponsEntityToIndex(classname, true);
		if (index != -1)
		{
			if (WeaponsGetRestrict(index) == 1)
			{
				ClientCommand(client, "play buttons/button11.wav");
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

public Action CS_OnCSWeaponDrop(int client, int weapon)
{
	if (IsValidEdict(weapon))
	{
		if (GetEntitySequence(client) != 0) {
			return Plugin_Handled;
		}
	
		int id = WeaponsGetCustomID(weapon);
		
		if (id != -1)
		{
			if (!WeaponsIsDrop(id)) 
			{
				RemovePlayerItem(client, weapon);
				AcceptEntityInput(weapon, "Kill"); 
				return Plugin_Handled;
			}
			
			if (WeaponsGetModelWorldID(id) != 0)
			{
				sForwardData._OnWeaponDrop(client, weapon, id);
				RequestFrame(Frame_NextToDrop, EntIndexToEntRef(weapon));
			}
		}
		
		float removal = sCvarList.WEAPONS_REMOVE_DROPPED.FloatValue;
		if (removal > 0.0)
		{
			CreateTimer(removal, Timer_OnWeaponRemove, EntIndexToEntRef(weapon), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	return Plugin_Continue;
}

public void Frame_NextToDrop(int ref)
{
	int weapon = EntRefToEntIndex(ref);
	if (weapon == INVALID_ENT_REFERENCE)
	{
		return;
	}
	
	int id = WeaponsGetCustomID(weapon);
	if (id != -1)
	{
		int index = WeaponsGetModelWorldID(id);
		if (index > 0 && GetEntProp(weapon, Prop_Data, "m_iState") == 0)
		{
			int silencer_offset = GetEntSendPropOffs(weapon, "m_bSilencerOn");
			if (silencer_offset != -1 && GetEntData(weapon, silencer_offset))
			{
				SetEntData(weapon, silencer_offset, false, true, true);
				
				HookSingleEntityOutput(weapon, "OnPlayerPickup", OnPlayerPickup, true);
			}
			
			SetEntProp(weapon, Prop_Send, "m_iWorldModelIndex", index);
			sForwardData._OnWeaponDrop2(weapon, id);
		}
	}
}

public void OnPlayerPickup(const char[] output, int weapon, int client, float delay)
{
	int offset = GetEntSendPropOffs(weapon, "m_weaponMode");
	if (offset != -1)
	{
		SetEntProp(weapon, Prop_Send, "m_bSilencerOn", GetEntData(weapon, offset));
	}
	else
	{
		SetEntProp(weapon, Prop_Send, "m_bSilencerOn", true);
	}
}

public Action Timer_OnWeaponRemove(Handle timer, int ref)
{
	int weapon = EntRefToEntIndex(ref);

	if (weapon != -1)
	{
		int client = WeaponsGetOwner(weapon);
		
		if (!IsValidClient(client) || !IsPlayerAlive(client)) 
		{
			AcceptEntityInput(weapon, "Kill");
		}
	}
	return Plugin_Stop;
}

public void WeaponModOnGrenadeSpawn(int grenade)
{
	if (GetEntProp(grenade, Prop_Data, "m_nNextThinkTick") == -1)
	{
		return;
	}

	int client = ToolsGetOwner(grenade);
	if (IsValidClient(client)) 
	{
		int weapon = ToolsGetActiveWeapon(client);
		if (weapon != -1)
		{
			int id = WeaponsGetCustomID(weapon);
			if (id != -1)
			{
				char model[PLATFORM_LINE_LENGTH];
				WeaponsGetModelWorld(id, model, sizeof(model));
				
				if (hasLength(model))
				{
					SetEntityModel(grenade, model);
				}
				
				WeaponsSetCustomID(grenade, id);
				return;
			}
		}
	}
	
	WeaponsSetCustomID(grenade, -1);
}

public void Hook_WeaponSwitch(int client, int weapon)
{
	sClientData[client].RunCmd = false;
}

public void Hook_PostThinkPost(int client)
{
	WeaponAttachSetAddons(client);
	
	if (sClientData[client].ViewModel[0] == -1)
	{
		return;
	}
	
	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	int iSequence = GetEntProp(sClientData[client].ViewModel[0], Prop_Send, "m_nSequence");
	
	if (weapon != sClientData[client].PrevWeapon)
	{
		OnWeaponSwitched(client, weapon, iSequence);
	}
	
	if (weapon == -1)
	{
		sClientData[client].PrevWeapon = -1;
		return;
	}
	
	float fCycle = GetEntPropFloat(sClientData[client].ViewModel[0], Prop_Data, "m_flCycle");
	
	if (sClientData[client].IsCustom)
	{
		float game_time = GetGameTime();
		
		SetEntPropFloat(sClientData[client].ViewModel[1], Prop_Send, "m_flPlaybackRate", GetEntPropFloat(sClientData[client].ViewModel[0], Prop_Send, "m_flPlaybackRate"));
		
		if (sClientData[client].ViewModel[1] > 0)
		{
			float time = GetEngineTime();
			if (time >= sClientData[client].fNextRightHand)
			{
				QueryClientConVar(client, "cl_righthand", ConVarQueryFinished_OnRightHand);
				sClientData[client].fNextRightHand = time + 0.5;
			}
		
			if (fCycle < sClientData[client].PrevCycle)
			{
				if (iSequence == sClientData[client].PrevSeq)
				{
					SetEntProp(sClientData[client].ViewModel[1], Prop_Send, "m_nSequence", 0);
					sClientData[client].NextSequence = game_time + 0.03;
				}
				
				sClientData[client].NextCycle = game_time + 0.05;
			}
			
			int id = WeaponsGetCustomID(weapon);
			if (id != -1) {
				sForwardData._OnWeaponAnimationEvent(client, weapon, iSequence, fCycle, sClientData[client].PrevCycle, id);
			}
			
			if (sClientData[client].NextSequence < game_time)
			{
				SetEntProp(sClientData[client].ViewModel[1], Prop_Send, "m_nSequence", iSequence);
			}
			
			if (sClientData[client].NextCycle < game_time)
			{
				sClientData[client].NextCycle = game_time + 0.05;
			}
		}
	}
	
	if (sClientData[client].SpawnCheck)
	{
		sClientData[client].SpawnCheck = false;
		
		if (sClientData[client].IsCustom)
		{
			UTIL_AddEffect(sClientData[client].ViewModel[0], EF_NODRAW);
			UTIL_RemoveEffect(sClientData[client].ViewModel[1], EF_NODRAW);
			
			int id = WeaponsGetCustomID(weapon);
			if (id != -1)
			{
				int index = WeaponsGetModelWorldID(id);
				if (index > 0) {
					SetEntProp(weapon, Prop_Send, "m_iWorldModelIndex", index);
				}
				
				sForwardData._OnWeaponDeploy(client, weapon, id);
			}
		}
	}
	
	sClientData[client].PrevWeapon = weapon;
	sClientData[client].PrevSeq = iSequence;
	sClientData[client].PrevCycle = fCycle;
}

void OnWeaponSwitched(int client, int weapon, int sequence)
{
	sClientData[client].PrevSeq = 0;
	sClientData[client].NextSequence = 0.0;
	sClientData[client].NextCycle = 0.0;
	sClientData[client].IsCustom = false;
	
	UTIL_AddEffect(sClientData[client].ViewModel[1], EF_NODRAW);
	UTIL_RemoveEffect(sClientData[client].ViewModel[0], EF_NODRAW);
	
	SetEntProp(sClientData[client].ViewModel[1], Prop_Send, "m_nSequence", 0);
	
	if (weapon == -1) {
		return;
	}
	
	int id = WeaponsGetCustomID(weapon);
	if (id != -1)
	{		
		SetEntPropFloat(sClientData[client].ViewModel[0], Prop_Send, "m_flPlaybackRate", 1.0);
		
		int index = WeaponsGetModelViewID(id);
		if (index > 0)
		{
			sClientData[client].IsCustom = true;
			sClientData[client].RunCmd = true;
			
			UTIL_AddEffect(sClientData[client].ViewModel[0], EF_NODRAW);
			UTIL_RemoveEffect(sClientData[client].ViewModel[1], EF_NODRAW);
			
			SetEntProp(sClientData[client].ViewModel[1], Prop_Send, "m_nModelIndex", index);
			SetEntPropEnt(sClientData[client].ViewModel[1], Prop_Send, "m_hWeapon", weapon);
			
			SetEntProp(sClientData[client].ViewModel[1], Prop_Send, "m_nSequence", sequence);
			SetEntPropFloat(sClientData[client].ViewModel[1], Prop_Send, "m_flPlaybackRate", GetEntPropFloat(sClientData[client].ViewModel[0], Prop_Send, "m_flPlaybackRate"));
		}
		
		index = WeaponsGetModelWorldID(id);
		if (index > 0)
		{
			SetEntProp(weapon, Prop_Send, "m_iWorldModelIndex", index);
		}
		
		sForwardData._OnWeaponDeploy(client, weapon, id);
	}
}

void WeaponModOnPlayerSequencePre(int client)
{
	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (weapon != -1)
	{
		int id = WeaponsGetCustomID(weapon);
		if (id != -1)
		{
			sForwardData._OnWeaponHolster(client, weapon, id);
		}
	}
}

void WeaponModOnResetPlayerSequence(int client, bool player)
{
	if (player == true)
	{
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if (weapon != -1)
		{
			int id = WeaponsGetCustomID(weapon);
			if (id != -1)
			{
				sForwardData._OnWeaponDeploy(client, weapon, id);
			}
		}
	}
}

public void ConVarQueryFinished_OnRightHand(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
{
	sClientData[client].RightHand = (StringToInt(cvarValue) == 0);
}

Action WeaponMODOnRunCmd(int client, int& buttons, int LastButtons, int weapon)
{
	// if (GetEntProp(client, Prop_Send, "m_iObserverMode") != 0) {
	// 	return Plugin_Continue;
	// }

	if (GetEntitySequence(client) != 0) {
		return Plugin_Continue;
	}

	static int id; id = WeaponsGetCustomID(weapon);
	if (id != -1) {
		return sForwardData._OnWeaponRunCmd(client, buttons, LastButtons, weapon, id);
	}
	return Plugin_Continue;
}

public MRESReturn OnGiveNamedItem(int client, Handle hReturn, Handle hParams)
{
	char classname[NORMAL_LINE_LENGTH], buffer[NORMAL_LINE_LENGTH];
	DHookGetParamString(hParams, 1, classname, sizeof(classname));
	
	if (IsFakeClient(client))
	{
		return MRES_Ignored; // bot
	}
	
	int index = WeaponsEntityToIndex(classname);
	if (index != -1)
	{
		WeaponsGetEntity(index, buffer, sizeof(buffer));
	
		int weapon = CreateEntityByName(buffer);
		if (weapon == -1)
		{
			return MRES_Ignored;
		}
		
		if (strcmp(buffer, "weapon_c4") == 0)
		{
			int c4 = GetPlayerWeaponSlot(client, 4);
			if (c4 != -1)
			{
				CS_DropWeapon(client, c4, true);
			}
		}
		
		float origin[3];
		GetClientAbsOrigin(client, origin);
		
		int ammo = WeaponsGetAmmo(index); // ...
		if (ammo > 0)
		{
			IntToString(ammo, buffer, sizeof(buffer));
			DispatchKeyValue(weapon, "ammo", buffer);
		}
		
		int clip = WeaponsGetClip(index);
		if (clip > 0)
		{
			SetEntProp(weapon, Prop_Data, "m_iClip1", clip);
		}
		
		DispatchKeyValueVector(weapon, "origin", origin);
		DispatchKeyValue(weapon, "classname", classname);
		DispatchKeyValue(weapon, "spawnflags", "1073741824"); // SF_NORESPAWN
		DispatchSpawn(weapon);
		
		ToolsSetOwner(weapon, client);
		SDKCall(hSDKCallTouch, weapon, client);
		
		if (ammo < 0)
		{
			UTIL_SetReserveAmmo(client, weapon, 0);
			GivePlayerAmmo(client, 99999, WeaponsGetAmmoType(weapon), true);
		}
		
		RequestFrame(Frame_WeaponCreated, EntIndexToEntRef(weapon));
		
		// FakeClientCommand(client, "use %s", classname);
		WeaponsSetCustomID(weapon, index);
		DHookSetReturn(hReturn, weapon);
		return MRES_Supercede;
	}
	return MRES_Ignored;
}

int SpawnWeapon(const char[] classname, const char[] targetname, const float origin[3] = NULL_VECTOR, const float angles[3] = NULL_VECTOR, int client = -1)
{
	int index = WeaponsEntityToIndex(classname);
	
	if (index != -1)
	{
		char buffer[64];
		WeaponsGetEntity(index, buffer, sizeof(buffer));
		
		int weapon = CreateEntityByName(buffer);
		if (weapon != -1)
		{
			if (IsValidClient(client) && IsPlayerAlive(client))
			{
				if (strcmp(buffer, "weapon_c4") == 0)
				{
					int c4 = GetPlayerWeaponSlot(client, 4);
					if (c4 != -1)
					{
						CS_DropWeapon(client, c4, true);
					}
				}
			}
		
			int ammo = WeaponsGetAmmo(index); // ...
			if (ammo > 0)
			{
				IntToString(ammo, buffer, sizeof(buffer));
				DispatchKeyValue(weapon, "ammo", buffer);
			}
			
			int clip = WeaponsGetClip(index);
			if (clip > 0)
			{
				SetEntProp(weapon, Prop_Data, "m_iClip1", clip);
			}
			
			DispatchKeyValue(weapon, "targetname",	targetname);
			DispatchKeyValue(weapon, "classname", classname);
			DispatchKeyValue(weapon, "spawnflags", "1073741824"); // SF_NORESPAWN
			TeleportEntity(weapon, origin, angles, NULL_VECTOR);
			
			DispatchSpawn(weapon);
			ActivateEntity(weapon);
			
			if (IsValidClient(client) && IsPlayerAlive(client))
			{
				ToolsSetOwner(weapon, client);
				SDKCall(hSDKCallTouch, weapon, client);
				
				if (ammo < 0)
				{
					UTIL_SetReserveAmmo(client, weapon, 0);
					GivePlayerAmmo(client, 99999, WeaponsGetAmmoType(weapon), true);
				}
			}
			
			RequestFrame(Frame_WeaponCreated, EntIndexToEntRef(weapon));
			WeaponsSetCustomID(weapon, index);
			return weapon;
		}
	}
	return -1;
}

public void Frame_WeaponCreated(int ref)
{
	int weapon = EntRefToEntIndex(ref);
	if (IsValidEntityf(weapon))
	{
		int index = WeaponsGetCustomID(weapon);
		if (index != -1)
		{
			int owner = ToolsGetOwner(weapon);
			if (owner != -1)
			{
				char classname[NORMAL_LINE_LENGTH];
				WeaponsGetName(index, classname, sizeof(classname));
				FakeClientCommand(owner, "use %s", classname);
				
				sForwardData._OnWeaponCreated(owner, weapon, index);
				
				int ammo = WeaponsGetAmmo(index);
				if (ammo > 0)
				{
					if (owner != -1)
					{
						UTIL_SetReserveAmmo(owner, weapon, ammo);
					}
				}
			}
			
			int clip = WeaponsGetClip(index);
			if (clip > 0)
			{
				SetEntProp(weapon, Prop_Data, "m_iClip1", clip);
			}
		}
	}
}

public MRESReturn OnGetPlayerMaxSpeed(int client, Handle hReturn)
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		if (sServerData.MapLoaded == false)
		{
			return MRES_Ignored;
		}
		
		if (sCvarList.CLASSES_OLD_SPEED.BoolValue == true)
		{
			return MRES_Ignored;
		}
	
		int weapon = ToolsGetActiveWeapon(client);

		if (weapon != -1)
		{
			int index = WeaponsGetCustomID(weapon);
			if (index != -1)
			{
				float speed = WeaponsGetSpeed(index);
				if (speed > 0.0)
				{
					DHookSetReturn(hReturn, speed);
					return MRES_Override;
				}
			}
		}
	
		float speed = ClassGetSpeed(sClientData[client].Class);
		if (speed > 0.0)
		{
			DHookSetReturn(hReturn, speed);
			return MRES_Override;
		}
	}
	return MRES_Ignored;
}

public MRESReturn OnGetMaxClip(int weapon, Handle hReturn, Handle hParams)
{
	if (IsValidEdict(weapon))
	{
		int index = WeaponsGetCustomID(weapon);
		if (index != -1)
		{
			int clip = WeaponsGetClip(index);
			if (clip)
			{
				DHookSetReturn(hReturn, clip);
				return MRES_Override;
			}
		}
	}
	return MRES_Ignored;
}

public MRESReturn GiveAmmo(int client, Handle hReturn, Handle hParams)
{
	int count = DHookGetParam(hParams, 1);
	int ammotype = DHookGetParam(hParams, 2);
	// bool suppressSound = DHookGetParam(hParams, 3);
	
	if (ammotype == -1) {
		return MRES_Ignored;
	}
	
	for (int i = 0; i < 2; i++)
	{
		int weapon = GetPlayerWeaponSlot(client, i);
		if (weapon == -1) {
			continue;
		}
		
		if (GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType") != ammotype)
		{
			continue;
		}
		
		int index = WeaponsGetCustomID(weapon);
		if (index == -1) {
			continue;
		}
		
		int ammo = WeaponsGetAmmo(index);
		if (ammo < 0) {
			continue;
		}
		
		int ammo_count = GetEntProp(client, Prop_Send, "m_iAmmo", _, ammotype);
		
		if (ammo_count == -1) {
			continue;
		}
		
		int iDiferrence = ammo - ammo_count;
		if (iDiferrence < 1)
		{
			DHookSetReturn(hReturn, 0);
		}
		else
		{
			if (count > iDiferrence) {
				count = iDiferrence;
			}
			
			SetEntProp(client, Prop_Send, "m_iAmmo", ammo_count+count, _, ammotype);
			DHookSetReturn(hReturn, count);
		}
		return MRES_Supercede;
	}
	return MRES_Ignored;
}

public MRESReturn OnHolster(int weapon, Handle hReturn, Handle hParams)
{
	int id = WeaponsGetCustomID(weapon);
	if (id != -1)
	{
		int client = WeaponsGetOwner(weapon);
		sForwardData._OnWeaponHolster(client, weapon, id);
	}
	return MRES_Ignored;
}