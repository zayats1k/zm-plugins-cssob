enum struct PropData
{
	char name[PLATFORM_MAX_PATH];
	char modelname[PLATFORM_MAX_PATH];
	char classname[PLATFORM_MAX_PATH];
	int price;
}

public Action Command_PropMenu(int client, int first_item)
{
	if (IsValidClient(client) && ZM_IsClientHuman(client))
	{
		if (ZM_IsRespawn(client, 0))
		{
			return Plugin_Handled;
		}
	
		if (ZM_GetCurrentGameMode() != m_ModeNormal)
		{
			PrintToChat_Lang(client, "%T", "chat round gamemode normal", client);
			return Plugin_Handled;
		}
		
		PropData pd; char buffer[164], info[32];
		
		Menu menu = new Menu(MenuHandler_PropsMenu);
		menu.SetTitle("%T", "MENU_SHOP_PROPS_2", client, sClientData[client].PropLevel);
		
		SetGlobalTransTarget(client);
		for (int i = 0; i < sServerData.ArrayProps.Length; i++)
		{
			sServerData.ArrayProps.GetArray(i, pd, sizeof(pd));
			FormatEx(buffer, sizeof(buffer), IsTranslatedForLanguage(pd.name, GetServerLanguage()) ? "%t":"%s", pd.name);
			FormatEx(info, sizeof(info), "%s; %d", pd.name, pd.price);
			
			SS_AddMenuItem3(menu, client, info, buffer, i, pd.price);
		}
		
		menu.ExitBackButton = true;
		menu.OptionFlags = MENUFLAG_BUTTON_EXIT|MENUFLAG_BUTTON_EXITBACK;
		menu.Display(client, MENU_TIME_FOREVER);
	}
	return Plugin_Handled;
}

void SS_AddMenuItem3(Menu menu, int client, const char[] info, const char[] name, int item, int price)
{
	char buffer[264];
	
	if (price != 0)
	{
		int up = price * (sClientData[client].PriceUp_PROPS[item] + 1);
		FormatEx(buffer, sizeof(buffer), "%s[%d %T]", name, up, "ammopack 2", client);
		menu.AddItem(info, buffer, (GetClientAmmoPacks(client) >= up && sClientData[client].PropLevel > 0) ? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	}
	else
	{
		FormatEx(buffer, sizeof(buffer), "%s", name);
		menu.AddItem(info, buffer);
	}
}

public int MenuHandler_PropsMenu(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
		{
			if (IsValidClient(param1))
			{
				Command_Shop(param1, 0);
			}
		}
	}
	else if (action == MenuAction_Select)
	{
		if (IsValidClient(param1) && IsPlayerAlive(param1) && ZM_IsClientHuman(param1))
		{
			if (ZM_IsRespawn(param1, 0))
			{
				return 0;
			}
		
			if (ZM_GetCurrentGameMode() != m_ModeNormal)
			{
				PrintToChat_Lang(param1, "%T", "chat round gamemode normal", param1);
				EmitSoundToClient(param1, SOUND_BUTTON_MENU);
				return 0;
			}
			
			if (GetEntitySequence(param1) != 0)
			{
				EmitSoundToClient(param1, SOUND_BUTTON_MENU);
				return 0;
			}
			
			if (sClientData[param1].PropLevel <= 0)
			{
				Command_PropMenu(param1, 0);
				return 0;
			}
			
			char info[64]; char buffer[2][164];
			menu.GetItem(param2, info, sizeof(info));
			ExplodeString(info, "; ", buffer, sizeof(buffer), sizeof(buffer[]));
			int price = StringToInt(buffer[1]);
			
			if (SetClientPriceUp(param1, param2, price) > GetClientAmmoPacks(param1))
			{
				ZM_PrintToChat(param1, _, "%T", "CHAT_NO_AMMOPACKS", param1);
				return 0;
			}
			
			float origin[3], angles[3], pos[3];
			if (!SetTeleportEndPoint(param1, pos, angles))
			{
				PrintToChat_Lang(param1, "%T", "PROP_TELEPORT", param1);
				Command_PropMenu(param1, 0);
				return 0;
			}
			
			GetClientAbsOrigin(param1, origin);
			if (GetVectorDistance(origin, pos) >= 60)
			{
				PrintToChat_Lang(param1, "%T", "PROP_DISTANCE", param1);
				Command_PropMenu(param1, 0);
				return 0;
			}
			
			int index = sServerData.ArrayProps.FindString(buffer[0]);
			
			if (index != -1)
			{
				PropData pd;
				sServerData.ArrayProps.GetArray(index, pd);
				
				int entity = CreateEntityByName(pd.classname); // prop_dynamic_override 
				
				DispatchKeyValue(entity, "physicsmode", "2");
				DispatchKeyValue(entity, "physdamagescale", "0.0");
				DispatchKeyValue(entity, "model", pd.modelname);
				DispatchKeyValue(entity, "Solid", "6");
				DispatchSpawn(entity);
				
				if (StrContains(pd.classname, "prop_physics") > -1)
				{
					pos[2] += 12.0;
					angles[2] += 50.0;
					angles[1] -= 90.0;
				}
				
				TeleportEntity(entity, pos, angles, NULL_VECTOR);
				
				DataPack data = new DataPack();
				RequestFrame(Frame_EntityStuck, data);
				data.WriteCell(GetClientUserId(param1));
				data.WriteCell(EntIndexToEntRef(entity));
				data.WriteCell(param2);
				data.WriteCell(price);
			}
			
			// Command_PropMenu(param1, menu.Selection);
		}
	}
	else if (action == MenuAction_End) {
		delete menu;
	}
	return 0;
}

public void Frame_EntityStuck(DataPack data)
{
	data.Reset();
	int client = GetClientOfUserId(data.ReadCell());
	int entity = EntRefToEntIndex(data.ReadCell());
	int item = data.ReadCell();
	int price = data.ReadCell();
	delete view_as<DataPack>(data);
	
	if (IsValidEntityf(entity) && CheckStuckInEntity(entity))
	{
		if (IsValidClient(client))
		{
			PrintToChat_Lang(client, "%T", "PROP_STUCK", client);
		}
		
		AcceptEntityInput(entity, "kill");
		return;
	}
	
	if (IsValidClient(client))
	{
		sClientData[client].PropLevel--;
		sClientData[client].PriceUp_PROPS[item]++;
		
		SetClientAmmoPacks(client, -price * (sClientData[client].PriceUp_PROPS[item]));
		Command_PropMenu(client, 0);
	}
}