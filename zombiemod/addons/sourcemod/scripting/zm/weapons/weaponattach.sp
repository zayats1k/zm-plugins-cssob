enum
{
	Type_Primary,
	Type_Secondary,
	Type_C4,
	Type_Max
}

void WeaponAttachOnUnload() 
{
	for (int i = 1; i <= MaxClients; i++) 
	{
		if (IsValidClient(i)) 
		{
			WeaponAttachRemoveAddons(i);
			OnClientDisconnect_Post(i);
			
			if (sClientData[i].IsCustom)
			{
				UTIL_AddEffect(sClientData[i].ViewModel[1], EF_NODRAW);
				UTIL_RemoveEffect(sClientData[i].ViewModel[0], EF_NODRAW);
			}
		}
	}
}

void WeaponAttachOnClientUpdate(int client)
{
	WeaponAttachRemoveAddons(client);
}

void WeaponAttachOnClientSpawn(int client)
{
	WeaponAttachRemoveAddons(client);
}

void WeaponAttachOnClientDeath(int client)
{
	WeaponAttachRemoveAddons(client);
}

void WeaponAttachSetAddons(int client)
{
	if (IsValidClient(client) && IsPlayerAlive(client) && GetEntityMoveType(client) == MOVETYPE_NONE)
	{
		if (GetEntProp(client, Prop_Send, "m_iObserverMode") != 0)
		{
			return;
		}
	}

	int bits = GetEntProp(client, Prop_Send, "m_iAddonBits");
	
	int bits_to_remove;
	if (bits & CSAddon_PrimaryWeapon)
	{
		if (!(sClientData[client].PrevAddonBits & CSAddon_PrimaryWeapon))
		{
			if (sClientData[client].AddonEntity[Type_Primary] > 0 && IsValidEdict(sClientData[client].AddonEntity[Type_Primary]))
			{
				AcceptEntityInput(sClientData[client].AddonEntity[Type_Primary], "kill");
			}
			
			sClientData[client].AddonEntity[Type_Primary] = 0;
			
			int weapon = GetPlayerWeaponSlot(client, 0);
			
			if (weapon != -1)
			{
				WeaponAttachCreateAddons(client, weapon, Type_Primary, "primary");
			}
		}
	}
	else if (sClientData[client].PrevAddonBits & CSAddon_PrimaryWeapon)
	{
		if (sClientData[client].AddonEntity[Type_Primary] > 0 && IsValidEdict(sClientData[client].AddonEntity[Type_Primary]))
		{
			AcceptEntityInput(sClientData[client].AddonEntity[Type_Primary], "kill");
		}
		
		sClientData[client].AddonEntity[Type_Primary] = 0;
	}
	if (bits & CSAddon_SecondaryWeapon)
	{
		if (!(sClientData[client].PrevAddonBits & CSAddon_SecondaryWeapon))
		{
			if (sClientData[client].AddonEntity[Type_Secondary] > 0 && IsValidEdict(sClientData[client].AddonEntity[Type_Secondary]))
			{
				AcceptEntityInput(sClientData[client].AddonEntity[Type_Secondary], "kill");
			}
			
			sClientData[client].AddonEntity[Type_Secondary] = 0;
			
			int weapon = GetPlayerWeaponSlot(client, 1);
			
			if (weapon != -1)
			{
				WeaponAttachCreateAddons(client, weapon, Type_Secondary, "pistol");
			}
		}
	}
	else if (sClientData[client].PrevAddonBits & CSAddon_SecondaryWeapon)
	{
		if (sClientData[client].AddonEntity[Type_Secondary] > 0 && IsValidEdict(sClientData[client].AddonEntity[Type_Secondary]))
		{
			AcceptEntityInput(sClientData[client].AddonEntity[Type_Secondary], "kill");
		}
		
		sClientData[client].AddonEntity[Type_Secondary] = 0;
	}
	if (bits & CSAddon_C4)
	{
		if (!(sClientData[client].PrevAddonBits & CSAddon_C4))
		{
			if (sClientData[client].AddonEntity[Type_C4] > 0 && IsValidEdict(sClientData[client].AddonEntity[Type_C4]))
			{
				AcceptEntityInput(sClientData[client].AddonEntity[Type_C4], "kill");
			}
			
			sClientData[client].AddonEntity[Type_C4] = 0;
			
			int weapon = GetPlayerWeaponSlot(client, 4);
			
			if (weapon != -1)
			{
				WeaponAttachCreateAddons(client, weapon, Type_C4, "c4");
			}
		}
	}
	else if (sClientData[client].PrevAddonBits & CSAddon_C4)
	{
		if (sClientData[client].AddonEntity[Type_C4] > 0 && IsValidEdict(sClientData[client].AddonEntity[Type_C4]))
		{
			AcceptEntityInput(sClientData[client].AddonEntity[Type_C4], "kill");
		}
		
		sClientData[client].AddonEntity[Type_C4] = 0;
	}
	
	if (sClientData[client].AddonEntity[Type_Primary] != 0)
	{
		bits_to_remove |= CSAddon_PrimaryWeapon;
	}
	if (sClientData[client].AddonEntity[Type_Secondary] != 0)
	{
		bits_to_remove |= CSAddon_SecondaryWeapon;
	}
	if (sClientData[client].AddonEntity[Type_C4] != 0)
	{
		bits_to_remove |= CSAddon_C4;
	}
	
	SetEntProp(client, Prop_Send, "m_iAddonBits", bits &~ bits_to_remove);
	sClientData[client].PrevAddonBits = bits;
}

void WeaponAttachCreateAddons(int client, int weapon, int type, const char[] attachment)
{
	int id = WeaponsGetCustomID(weapon);
	if (id != -1)
	{		
		int index = WeaponsGetModelWorldID(id);
		if (index != 0)
		{
			char buffer[PLATFORM_MAX_PATH]; buffer[0] = '\0';
			GetPrecachedModelOfIndex(index, buffer, sizeof(buffer));
			
			if (buffer[0])
			{
				sClientData[client].AddonEntity[type] = CreateEntityByName("prop_dynamic_override");
				DispatchKeyValue(sClientData[client].AddonEntity[type], "model", buffer);
				DispatchKeyValue(sClientData[client].AddonEntity[type], "spawnflags", "256");
				DispatchKeyValue(sClientData[client].AddonEntity[type], "solid", "0");
				DispatchSpawn(sClientData[client].AddonEntity[type]);
				ToolsSetOwner(sClientData[client].AddonEntity[type], client);
				
				SetVariantString("!activator");
				AcceptEntityInput(sClientData[client].AddonEntity[type], "SetParent", client, sClientData[client].AddonEntity[type]);
				
				SetVariantString(attachment);
				AcceptEntityInput(sClientData[client].AddonEntity[type], "SetParentAttachment", sClientData[client].AddonEntity[type]);
				
				float origin[3], angles[3];
				WeaponsGetModelOrigin(id, origin);
				if (RoundToFloor(origin[0]) || RoundToFloor(origin[1]) || RoundToFloor(origin[2])) {
					WeaponsGetModelAngles(id, angles);
					TeleportEntity(sClientData[client].AddonEntity[type], origin, angles, NULL_VECTOR);
				}
				
				SDKHook(sClientData[client].AddonEntity[type], SDKHook_SetTransmit, OnTransmit);
			}
		}
	}
}

public Action OnTransmit(int entity, int client)
{
	int owner = ToolsGetOwner(entity);
	if (owner == client || (GetEntProp(client, Prop_Send, "m_iObserverMode") == 4 && owner == GetEntPropEnt(client, Prop_Send, "m_hObserverTarget")))
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

stock void GetPrecachedModelOfIndex(int index, char[] buffer, int maxlength)
{
	static int _iPrecachedModelsTable = INVALID_STRING_TABLE;
	if (_iPrecachedModelsTable == INVALID_STRING_TABLE)
	{
		_iPrecachedModelsTable = FindStringTable("modelprecache");
	}
	ReadStringTable(_iPrecachedModelsTable, index, buffer, maxlength);
}

void WeaponAttachRemoveAddons(int client)
{
	for (int i = 0; i < Type_Max; i++)
	{
		if (sClientData[client].AddonEntity[i] > 0 && IsValidEntity(sClientData[client].AddonEntity[i]))
		{
			AcceptEntityInput(sClientData[client].AddonEntity[i], "kill");
		}
		sClientData[client].AddonEntity[i] = -1;
	}
}