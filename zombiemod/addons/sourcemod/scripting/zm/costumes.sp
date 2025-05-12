enum
{
	COSTUMES_DATA_NAME = 0,
	COSTUMES_DATA_MODEL,
	COSTUMES_DATA_POSITION,
	COSTUMES_DATA_ANGLE,
	COSTUMES_DATA_GROUP,
	COSTUMES_DATA_GROUP_FLAGS,
	COSTUMES_DATA_LEVEL
};

Handle hDHookSetEntityModel;
int DHook_SetEntityModel;

void CostumesOnInit()
{
	fnInitGameConfOffset(sServerData.SDKTools, DHook_SetEntityModel, "SetEntityModel");

	hDHookSetEntityModel = DHookCreate(DHook_SetEntityModel, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, CostumesDhookOnSetEntityModel);
	DHookAddParam(hDHookSetEntityModel, HookParamType_CharPtr);
	
	if (hDHookSetEntityModel == null)
	{
		LogError("[Costumes] [GameData Validation] Failed to create DHook for \"CCSPlayer::SetEntityModel\". Update \"SourceMod\"");
	}
}

void CostumesOnLoad()
{
	ConfigRegisterConfig(File_Costumes, Structure_KeyValue, CONFIG_FILE_ALIAS_COSTUMES);
	
	static char buffer[PLATFORM_LINE_LENGTH];
	if (!ConfigGetFullPath(CONFIG_FILE_ALIAS_COSTUMES, buffer, sizeof(buffer)))
	{
		LogError("[Costumes] [Config Validation] Missing costumes config file: \"%s\"", buffer);
		return;
	}

	ConfigSetConfigPath(File_Costumes, buffer);
	if (!ConfigLoadConfig(File_Costumes, sServerData.Costumes, PLATFORM_LINE_LENGTH))
	{
		LogError("[Costumes] [Config Validation] Unexpected error encountered loading: %s", buffer);
		return;
	}

	CostumesOnCacheData();

	ConfigSetConfigLoaded(File_Costumes, true);
	ConfigSetConfigReloadFunc(File_Costumes, GetFunctionByName(GetMyHandle(), "CostumesOnConfigReload"));
	ConfigSetConfigHandle(File_Costumes, sServerData.Costumes);
}

void CostumesOnCacheData()
{
	static char buffer[PLATFORM_LINE_LENGTH];
	ConfigGetConfigPath(File_Costumes, buffer, sizeof(buffer)); 
	
	KeyValues kv;
	if (!ConfigOpenConfigFile(File_Costumes, kv))
	{
		LogError("[Costumes] [Config Validation] Unexpected error caching data from costumes config file: %s", buffer);
		return;
	}

	int size = sServerData.Costumes.Length;
	if (!size)
	{
		LogError("[Costumes] [Config Validation] No usable data found in costumes config file: %s", buffer);
		return;
	}
	
	for (int i = 0; i < size; i++)
	{
		CostumesGetName(i, buffer, sizeof(buffer)); // Index: 0
		kv.Rewind();
		if (!kv.JumpToKey(buffer))
		{
			LogError("[Costumes] [Config Validation] Couldn't cache costume data for: %s (check costume config)", buffer);
			continue;
		}
		
		if (!TranslationIsPhraseExists(buffer))
		{
			LogError("[Costumes] [Config Validation] Couldn't cache costume name: \"%s\" (check translation file)", buffer);
			continue;
		}

		ArrayList array = sServerData.Costumes.Get(i);
		
		kv.GetString("model", buffer, sizeof(buffer), ""); 
		array.PushString(buffer); // Index: 1
		DecryptPrecacheModel(buffer);
		float vPosition[3]; kv.GetVector("position", vPosition);   
		array.PushArray(vPosition, sizeof(vPosition)); // Index: 2
		float vAngle[3]; kv.GetVector("angle", vAngle);
		array.PushArray(vAngle, sizeof(vAngle)); // Index: 3
		kv.GetString("group", buffer, sizeof(buffer), "");
		array.PushString(buffer); // Index: 4
		array.Push(ConfigGetAdmFlags(buffer)); // Index: 5
		array.Push(kv.GetNum("level", 0)); // Index: 6
	}
	delete kv;
}

void CostumesOnUnload() 
{
	for (int i = 1; i <= MaxClients; i++) 
	{
		if (IsValidClient(i))
		{
			CostumesRemove(i);
		}
	}
}

public void CostumesOnConfigReload()
{
	CostumesOnLoad();
}

void CostumesOnClientInit(int client)
{
	static int id[MAXPLAYERS+1] = {-1, ...};
	
	if (hDHookSetEntityModel)
	{
		id[client] = DHookEntity(hDHookSetEntityModel, true, client);
	}
	else
	{
		LogError("[Costumes] [DHook Validation] Failed to attach DHook to \"CCSPlayer::SetEntityModel\". Update \"SourceMod\"");
	}
}

void CostumesOnClientDeath(int client)
{
	CostumesRemove(client);
}

void CostumesOnClientSpawn(int client)
{
	CostumesRemove(client);
}

void CostumesGetName(int id, char[] sName, int maxLen)
{
	if (id == -1)
	{
		strcopy(sName, maxLen, "");
		return;
	}
	
	ArrayList array = sServerData.Costumes.Get(id);
	
	array.GetString(COSTUMES_DATA_NAME, sName, maxLen);
} 

void CostumesGetModel(int id, char[] model, int maxLen)
{
	ArrayList array = sServerData.Costumes.Get(id);
	array.GetString(COSTUMES_DATA_MODEL, model, maxLen);
}

void CostumesGetPosition(int id, float position[3])
{
	ArrayList array = sServerData.Costumes.Get(id);
	array.GetArray(COSTUMES_DATA_POSITION, position, sizeof(position));
}

void CostumesGetAngle(int id, float angle[3])
{
	ArrayList array = sServerData.Costumes.Get(id);
	array.GetArray(COSTUMES_DATA_ANGLE, angle, sizeof(angle));
}

void CostumesGetGroup(int id, char[] group, int maxLen)
{
	ArrayList array = sServerData.Costumes.Get(id);
	array.GetString(COSTUMES_DATA_GROUP, group, maxLen);
} 

int CostumesGetGroupFlags(int id)
{
	ArrayList array = sServerData.Costumes.Get(id);
	return array.Get(COSTUMES_DATA_GROUP_FLAGS);
}

int CostumesGetLevel(int id)
{
	ArrayList array = sServerData.Costumes.Get(id);
	return array.Get(COSTUMES_DATA_LEVEL);
}

int CostumesNameToIndex(const char[] name)
{
	static char costumeName[SMALL_LINE_LENGTH];
	for (int i = 0; i < sServerData.Costumes.Length; i++)
	{
		CostumesGetName(i, costumeName, sizeof(costumeName));
		if (!strcmp(name, costumeName, false))
		{
			return i;
		}
	}
	return -1;
}
void CostumesOnFakeClientThink(int client)
{
	if (GetRandomInt(0, 10))
	{
		return
	} 
	
	int id = GetRandomInt(0, sServerData.Costumes.Length - 1);
	sClientData[client].Costume = id;
	RequestFrame(Frame_CostumesCreateEntity, GetClientUserId(client));
}


public MRESReturn CostumesDhookOnSetEntityModel(int client)
{
	RequestFrame(Frame_CostumesCreateEntity, GetClientUserId(client));
	return MRES_Handled;
}

void CostumesOnPlayerSequencePre(int client)
{
	RequestFrame(Frame_CostumesCreateEntity, GetClientUserId(client));
}

void CostumesOnResetPlayerSequence(int client)
{
	RequestFrame(Frame_CostumesCreateEntity, GetClientUserId(client));
}

public void Frame_CostumesCreateEntity(int userid)
{
	CostumesCreateEntity(GetClientOfUserId(userid));
}

void CostumesCreateEntity(int client)
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		CostumesRemove(client);

		if (sClientData[client].Zombie)
		{
			return;
		}
		
		if (sClientData[client].RespawnTimer != null)
		{
			return;
		}
		
		if (!ToolsLookupAttachment(client, "forward"))
		{
			return;
		}
		
		if (sClientData[client].Costume == -1 || sServerData.Costumes.Length <= sClientData[client].Costume)
		{
			sClientData[client].Costume = -1;
			return;
		}
		
		static char group[SMALL_LINE_LENGTH];
		CostumesGetGroup(sClientData[client].Costume, group, sizeof(group));
		if (COSTUMES_VIP_LEVEL(client, sClientData[client].Costume, group))
		{
			sClientData[client].Costume = -1;
			return;
		}

		static char model[PLATFORM_LINE_LENGTH];
		CostumesGetModel(sClientData[client].Costume, model, sizeof(model));
		int anim = GetEntitySequence(client);
		
		int entity = CreateEntityByName("prop_dynamic_override");
		if (entity != -1)
		{
			DispatchKeyValue(entity, "model", model);
			DispatchKeyValue(entity, "spawnflags", "256");
			
			Format(model, sizeof(model), "costume_%d", entity);
			DispatchKeyValue(entity, "targetname", model);
			
			DispatchSpawn(entity);
			AcceptEntityInput(entity, "TurnOn", entity, entity);
			
			ToolsSetOwner(entity, client);
			ToolsSetCollisionGroup(entity, COLLISION_GROUP_DEBRIS_TRIGGER);
			
			static float vPosition[3], vAngle[3], vEntOrigin[3], vEntAngle[3], vForward[3], vRight[3], vVertical[3]; 
			
			if (IsValidEntityf(anim))
			{
				GetClientAbsOrigin(client, vPosition);
				GetClientAnimationAngles(client, vAngle);
			}
			else
			{
				GetClientAbsOrigin(client, vPosition);
				GetClientAbsAngles(client, vAngle);
			}

			CostumesGetPosition(sClientData[client].Costume, vEntOrigin);
			CostumesGetAngle(sClientData[client].Costume, vEntAngle);
			
			AddVectors(vAngle, vEntAngle, vAngle);
			GetAngleVectors(vAngle, vForward, vRight, vVertical);
			vPosition[0] += vRight[0]*vEntOrigin[0]+vForward[0]*vEntOrigin[1]+vVertical[0]*vEntOrigin[2];
			vPosition[1] += vRight[1]*vEntOrigin[0]+vForward[1]*vEntOrigin[1]+vVertical[1]*vEntOrigin[2];
			vPosition[2] += vRight[2]*vEntOrigin[0]+vForward[2]*vEntOrigin[1]+vVertical[2]*vEntOrigin[2];
			TeleportEntity(entity, vPosition, vAngle, NULL_VECTOR);
			
			SetVariantString("!activator");
			if (IsValidEntityf(anim))
				AcceptEntityInput(entity, "SetParent", anim, entity);
			else AcceptEntityInput(entity, "SetParent", client, entity);
			SetVariantString("forward");
			AcceptEntityInput(entity, "SetParentAttachmentMaintainOffset", entity, entity);
			
			SDKHook(entity, SDKHook_SetTransmit, CostumesOnEntityTransmit);
			sClientData[client].AttachmentCostume = EntIndexToEntRef(entity);
		}
	}
}

void CostumesRemove(int client)
{
	int entity = EntRefToEntIndex(sClientData[client].AttachmentCostume);

	if (IsValidEntityf(entity))
	{
		AcceptEntityInput(entity, "Kill");
	}
	
	sClientData[client].AttachmentCostume = -1;
}

public Action CostumesOnEntityTransmit(int entity, int client) 
{
	if (IsValidClient(client))
	{
		if (IsClientObserver(client) && GetEntProp(client, Prop_Send, "m_iObserverMode") == 4)
		{
			int target = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
			if (IsValidClient(target) && target != client) {
				return Plugin_Handled;
			}
		}
		
		int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		if (owner == client && GetEntProp(owner, Prop_Send, "m_iObserverMode") == 0)
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

bool COSTUMES_VIP_LEVEL(int client, int id, const char[] group)
{
	if (CostumesGetLevel(id) != 0)
	{
		if (CostumesGetLevel(id) <= GetClientLevel(client))
		{
			return false;
		}
		
		if (group[0] && VIP_IsClientVIP(client))
		{
			if (!IsClientGroup(client, CostumesGetGroupFlags(id), group))
			{
				return false;
			}
		}
		
		return true;
	}
	else if (group[0] && IsClientGroup(client, CostumesGetGroupFlags(id), group))
	{
		return true;
	}
	return false;
}