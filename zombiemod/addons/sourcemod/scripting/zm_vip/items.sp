// static const char MENU_VIP[][][] = {
// 	{"item_armor",				"MENU_ITEM_ARMOR_100"},
// 	{"item_armor_health",		"MENU_ITEM_ARMOR_50_HEALTH_50"},
// 	{"weapon_sg550",				"MENU_WEAPON_SG550"},
// 	{"weapon_m249",				"MENU_WEAPON_M249"},
// 	{"weapon_dinfinity",			"MENU_WEAPON_DINFINITY"},
// 	{"weapon_mp5gitar",			"MENU_WEAPON_MP5GITAR"},
// 	{"weapon_rpg",				"MENU_WEAPON_RPG"},
// 	{"weapon_shieldgrenade",		"MENU_WEAPON_SHIELDGRENADE"},
// };
// 
// static const char MENU_SUPERVIP[][][] = {
// 	{"shopmenu_items",			"MENU_VIP_SHOP_ITEMS"},
// 	{"weapon_shieldgrenade",		"MENU_WEAPON_SHIELDGRENADE"},
// 	{"weapon_sg550",				"MENU_WEAPON_SG550"},
// 	{"weapon_m249",				"MENU_WEAPON_M249"},
// 	{"weapon_dinfinity",			"MENU_WEAPON_DINFINITY"},
// 	{"weapon_mp5gitar",			"MENU_WEAPON_MP5GITAR"},
// 	{"weapon_frostgun",			"MENU_WEAPON_FROSTGUN"},
// 	{"weapon_rpg",				"MENU_WEAPON_RPG"},
// 	{"weapon_m134",				"MENU_WEAPON_M134"},
// 	{"weapon_salamander",		"MENU_WEAPON_SALAMANDER"},
// 	{"weapon_gauss",				"MENU_WEAPON_GAUSS"},
// 	{"weapon_ethereal",			"MENU_WEAPON_ETHEREAL"},
// 	{"weapon_m3shark",			"MENU_WEAPON_M3SHARK"},
// 	{"weapon_tripmine",			"MENU_WEAPON_TRIPMINE"}
// };
// 
// static const char MENU_MAXIMUM[][][] = {
// 	{"shopmenu_items",			"MENU_VIP_SHOP_ITEMS"},
// 	{"weapon_shieldgrenade",		"MENU_WEAPON_SHIELDGRENADE"},
// 	{"weapon_sg550",				"MENU_WEAPON_SG550"},
// 	{"weapon_m249",				"MENU_WEAPON_M249"},
// 	{"weapon_dinfinity",			"MENU_WEAPON_DINFINITY"},
// 	{"weapon_mp5gitar",			"MENU_WEAPON_MP5GITAR"},
// 	{"weapon_frostgun",			"MENU_WEAPON_FROSTGUN"},
// 	{"weapon_rpg",				"MENU_WEAPON_RPG"},
// 	{"weapon_m134",				"MENU_WEAPON_M134"},
// 	{"weapon_salamander",		"MENU_WEAPON_SALAMANDER"},
// 	{"weapon_gauss",				"MENU_WEAPON_GAUSS"},
// 	{"weapon_ethereal",			"MENU_WEAPON_ETHEREAL"},
// 	{"weapon_m3shark",			"MENU_WEAPON_M3SHARK"},
// 	{"weapon_tripmine",			"MENU_WEAPON_TRIPMINE"},
// 	{"weapon_awp_buff",			"MENU_WEAPON_AWP_BUFF"},
// 	{"weapon_m32",				"MENU_WEAPON_M32"},
// 	{"weapon_laserfist",			"MENU_WEAPON_LASERFIST"},
// 	{"weapon_thunderbolt",		"MENU_WEAPON_THUNDERBOLT"}
// };
// 
// //////////////////////////////////////////
// static const char MENU_ZE_VIP[][][] = {
// 	{"item_armor",				"MENU_ITEM_ARMOR_100"},
// 	{"item_armor_health",		"MENU_ITEM_ARMOR_50_HEALTH_50"},
// 	{"weapon_sg550",				"MENU_WEAPON_SG550"},
// 	{"weapon_m249",				"MENU_WEAPON_M249"}
// };
// 
// static const char MENU_ZE_SUPERVIP[][][] = {
// 	{"weapon_sg550",				"MENU_WEAPON_SG550"},
// 	{"weapon_m249",				"MENU_WEAPON_M249"},
// 	{"weapon_freeze",			"MENU_WEAPON_FREEZE"}
// };
// 
// static const char MENU_ZE_MAXIMUM[][][] = {
// 	{"leader",					"MENU_VIP_LEADER"},
// 	{"weapon_sg550",				"MENU_WEAPON_SG550"},
// 	{"weapon_m249",				"MENU_WEAPON_M249"},
// 	{"weapon_freeze",			"MENU_WEAPON_FREEZE"}
// };

static const char MENU_VIP[][][] = {
	{"item_armor",				"MENU_ITEM_ARMOR_100"},
	{"item_armor_health",		"MENU_ITEM_ARMOR_50_HEALTH_50"},
	{"weapon_sg550",				"MENU_WEAPON_SG550"},
	{"weapon_m249",				"MENU_WEAPON_M249"},
	{"weapon_awp_buff",			"MENU_WEAPON_AWP_BUFF"},
	{"weapon_dinfinity",			"MENU_WEAPON_DINFINITY"},
	{"weapon_mp5gitar",			"MENU_WEAPON_MP5GITAR"},
	{"weapon_shieldgrenade",		"MENU_WEAPON_SHIELDGRENADE"}
};

static const char MENU_SUPERVIP[][][] = {
	{"shopmenu_items",			"MENU_VIP_SHOP_ITEMS"},
	{"weapon_sg550",				"MENU_WEAPON_SG550"},
	{"weapon_m249",				"MENU_WEAPON_M249"},
	{"weapon_awp_buff",			"MENU_WEAPON_AWP_BUFF"},
	{"weapon_rpg",				"MENU_WEAPON_RPG"},
	{"weapon_m134",				"MENU_WEAPON_M134"},
	{"weapon_dinfinity",			"MENU_WEAPON_DINFINITY"},
	{"weapon_mp5gitar",			"MENU_WEAPON_MP5GITAR"},
	{"weapon_frostgun",			"MENU_WEAPON_FROSTGUN"},
	{"weapon_shieldgrenade",		"MENU_WEAPON_SHIELDGRENADE"},
	{"weapon_salamander",		"MENU_WEAPON_SALAMANDER"},
	{"weapon_gauss",				"MENU_WEAPON_GAUSS"},
	{"weapon_ethereal",			"MENU_WEAPON_ETHEREAL"},
	{"weapon_m32",				"MENU_WEAPON_M32"},
	{"weapon_laserfist",			"MENU_WEAPON_LASERFIST"}
};

//////////////////////////////////////////
static const char MENU_ZE_VIP[][][] = {
	{"item_armor",				"MENU_ITEM_ARMOR_100"},
	{"item_armor_health",		"MENU_ITEM_ARMOR_50_HEALTH_50"},
	{"weapon_sg550",				"MENU_WEAPON_SG550"},
	{"weapon_m249",				"MENU_WEAPON_M249"}
};

static const char MENU_ZE_SUPERVIP[][][] = {
	{"weapon_sg550",				"MENU_WEAPON_SG550"},
	{"weapon_m249",				"MENU_WEAPON_M249"}
};

public void ZM_OnClientUpdated(int client, int attacker)
{
	if (IsValidClient(client) && ZM_IsClientHuman(client) && sClientData[client].IsPlayerVIP)
	{
		if (strcmp(sClientData[client].group, "SUPERVIP") == 0 || strcmp(sClientData[client].group, "MAXIMUM") == 0)
		{
			int hp = GetClientHealth(client);
			SetEntProp(client, Prop_Send, "m_iHealth", hp+50);
			SetEntProp(client, Prop_Data, "m_iMaxHealth", hp+50);
			SetEntProp(client, Prop_Send, "m_ArmorValue", 100);
		}
		
		if (ZM_IsNewRound() == true)
		{
			sClientData[client].PickMenu = false;
		}
	}
}

public void ZM_OnGameModeEnd(CSRoundEndReason reason)
{
	if (GetFeatureStatus(FeatureType_Native, "SetClientAmmoPacks") == FeatureStatus_Available)
	{
		if (reason == CSRoundEnd_Draw)
		{
			return;
		}
		
		if (VIP_GetClientCount() < 3)
		{
			return;
		}
		
		if (!sServerData.IsMapZE)
		{
			return;
		}
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && IsPlayerAlive(i) && !IsFakeClient(i) && sClientData[i].IsPlayerVIP)
			{
				if ((GetGameTime() - sClientData[i].LastMovement) >= 60.0)
				{
					continue;
				}
				
				if (strcmp(sClientData[i].group, "VIP") == 0)
				{
					if (GetClientAmmoPacks(i) >= 10000) // 10, 000 max [VIP]
					{
						// no give ammopacks
						continue;
					}
					
					// give ammopacks
					SetClientAmmoPacks(i, 5);
				}
				else if (strcmp(sClientData[i].group, "SUPERVIP") == 0)
				{
					if (GetClientAmmoPacks(i) >= 35000) // 35, 000 max [SUPERVIP]
					{
						// no give ammopacks
						continue;
					}
					
					// give ammopacks
					SetClientAmmoPacks(i, 50);
				}
				else if (strcmp(sClientData[i].group, "MAXIMUM") == 0)
				{
					if (GetClientAmmoPacks(i) >= 45000) // 45, 000 max [MAXIMUM]
					{
						// no give ammopacks
						continue;
					}
					
					// give ammopacks
					SetClientAmmoPacks(i, 85);
				}
			}
		}
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (IsValidClient(client) && IsPlayerAlive(client) && !IsFakeClient(client) && !IsClientSourceTV(client))
	{
		if (cmdnum <= 0)
		{
			return Plugin_Handled;
		}
	
		if (!(buttons & IN_ATTACK2) && buttons != GetEntProp(client, Prop_Data, "m_afButtonLast"))
		{
			sClientData[client].LastMovement = GetGameTime();
		}
	}
	return Plugin_Continue;
}

public Action Command_VIPMenu(int client, int args)
{
	if (IsValidClient(client))
	{
		if (!sClientData[client].IsPlayerVIP)
		{
			PrintToChat_Lang(client, "%t", "CHAT_VIP_NO_ACCESS");
			return Plugin_Handled;
		}
		
		bool IsItemMenu = (!ZM_IsClientHuman(client) || !IsPlayerAlive(client) || ZM_IsRespawn(client, 0));
		
		if (!IsItemMenu && sClientData[client].PickMenu)
		{
			PrintToChat_Lang(client, "%t", "CHAT_VIP_PICKUP_MENU");
		}
		
		static char buffer[164];
		
		Menu menu = new Menu(MenuHandler_VIPMenu);
		
		FormatEx(buffer, sizeof(buffer), "%T", "VIP_MENU_TITLE", client);
		menu.SetTitle(buffer);
		
		if (sServerData.IsMapZE)
		{
			if (strcmp(sClientData[client].group, "VIP") == 0)
			{
				for (int i = 0; i < sizeof(MENU_VIP); i++)
				{
					FormatEx(buffer, sizeof(buffer), "%T", MENU_VIP[i][1], client);
					menu.AddItem(MENU_VIP[i][0], buffer, (sClientData[client].PickMenu || IsItemMenu) ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
				}
			}
			else if (strcmp(sClientData[client].group, "SUPERVIP") == 0)
			{
				for (int i = 0; i < sizeof(MENU_SUPERVIP); i++)
				{
					FormatEx(buffer, sizeof(buffer), "%T", MENU_SUPERVIP[i][1], client);
					menu.AddItem(MENU_SUPERVIP[i][0], buffer, (sClientData[client].PickMenu || IsItemMenu) ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
				}
			}
			// else if (strcmp(sClientData[client].group, "MAXIMUM") == 0)
			// {
			// 	for (int i = 0; i < sizeof(MENU_MAXIMUM); i++)
			// 	{
			// 		FormatEx(buffer, sizeof(buffer), "%T", MENU_MAXIMUM[i][1], client);
			// 		menu.AddItem(MENU_MAXIMUM[i][0], buffer, (sClientData[client].PickMenu || IsItemMenu) ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
			// 	}
			// }
			else
			{
				FormatEx(buffer, sizeof(buffer), "%T", "VIP_MENU_NO_GROUP", client);
				menu.AddItem("VIP_MENU_NO_GROUP", buffer, ITEMDRAW_DISABLED);
			}
		}
		else
		{
			if (strcmp(sClientData[client].group, "VIP") == 0)
			{
				for (int i = 0; i < sizeof(MENU_ZE_VIP); i++)
				{
					FormatEx(buffer, sizeof(buffer), "%T", MENU_ZE_VIP[i][1], client);
					menu.AddItem(MENU_ZE_VIP[i][0], buffer, (sClientData[client].PickMenu || IsItemMenu) ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
				}
			}
			else if (strcmp(sClientData[client].group, "SUPERVIP") == 0)
			{
				for (int i = 0; i < sizeof(MENU_ZE_SUPERVIP); i++)
				{
					FormatEx(buffer, sizeof(buffer), "%T", MENU_ZE_SUPERVIP[i][1], client);
					menu.AddItem(MENU_ZE_SUPERVIP[i][0], buffer, (sClientData[client].PickMenu || IsItemMenu) ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
				}
			}
			// else if (strcmp(sClientData[client].group, "MAXIMUM") == 0)
			// {
			// 	for (int i = 0; i < sizeof(MENU_ZE_MAXIMUM); i++)
			// 	{
			// 		FormatEx(buffer, sizeof(buffer), "%T", MENU_ZE_MAXIMUM[i][1], client);
			// 		menu.AddItem(MENU_ZE_MAXIMUM[i][0], buffer, (sClientData[client].PickMenu || IsItemMenu) ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
			// 	}
			// }
			else
			{
				FormatEx(buffer, sizeof(buffer), "%T", "VIP_MENU_NO_GROUP", client);
				menu.AddItem("VIP_MENU_NO_GROUP", buffer, ITEMDRAW_DISABLED);
			}
		}
		
		if (!menu.ItemCount)
		{
			menu.AddItem("empty", "Empty", ITEMDRAW_DISABLED);
		}
		
		menu.ExitBackButton = true;
		menu.OptionFlags = MENUFLAG_BUTTON_EXIT|MENUFLAG_BUTTON_EXITBACK;
		menu.Display(client, 0);
	}
	return Plugin_Handled;
}

public int MenuHandler_VIPMenu(Menu menu, MenuAction action, int client, int slot)
{
	if (action == MenuAction_Cancel)
	{
		if (slot == MenuCancel_ExitBack)
		{
			if (IsValidClient(client))
			{
				ZM_OpenMenuSub(client, "vip");
			}
		}
	}
	else if (action == MenuAction_Select)
	{
		if (IsPlayerAlive(client) && ZM_IsClientHuman(client))
		{
			if (ZM_IsRespawn(client)) {
				return 0;
			}
			
			int id = ZM_GetClientClass(client);
			if (id == m_HumanSniper || id == m_HumanSurvivor) {
				return 0;
			}
			
			if (GetEntProp(client, Prop_Send, "m_iObserverMode") != 0) {
				return 0;
			}
		
			char buffer[164];
			menu.GetItem(slot, buffer, sizeof(buffer));
			
			if (strcmp(buffer, "shopmenu_items") == 0)
			{
				FakeClientCommand(client, "zp_shop_items");
				return 0;
			}
			
			if (StrContains(buffer, "weapon_") == 0)
			{
				int index = GivePlayerItem(client, buffer);
				EmitSoundToAll(SOUND_ITEMICKUP, client);
				sClientData[client].PickMenu = true;
				
				if (strcmp(buffer, "weapon_shieldgrenade") != 0 && strcmp(buffer, "weapon_rpg") != 0 && strcmp(buffer, "weapon_tripmine") != 0
				&& strcmp(buffer, "weapon_freeze") != 0)
				{
					EquipPlayerWeapon(client, index);
				}
			}
			else if (strcmp(buffer, "item_armor") == 0)
			{
				SetEntProp(client, Prop_Data, "m_ArmorValue", 100);
				EmitSoundToAll(SOUND_PICKUP, client);
				sClientData[client].PickMenu = true;
			}
			else if (strcmp(buffer, "item_armor_health") == 0)
			{
				int hp = GetClientHealth(client);
				SetEntProp(client, Prop_Data, "m_ArmorValue", 50);
				SetEntProp(client, Prop_Send, "m_iHealth", hp+50);
				SetEntProp(client, Prop_Data, "m_iMaxHealth", hp+50);
				
				EmitSoundToAll(SOUND_PICKUP, client);
				sClientData[client].PickMenu = true;
			}
		}
	}
	else if (action == MenuAction_End) {
		delete menu;
	}
	return 0;
}

public Action command_VIPBuy(int client, const char[] command, int args)
{
	if (IsValidClient(client))
	{
		if (!sClientData[client].IsPlayerVIP)
		{
			command_VIPInfo(client, 0);
			return Plugin_Handled;
		}
		
		FakeClientCommand(client, "vipmenu");
	}
	return Plugin_Handled;
}

public Action command_VIPInfo(int client, int args)
{
	if (IsValidClient(client))
	{
		char buffer[164];
		
		Menu menu = new Menu(VipMenu_SelectCheck);
		
		Format(buffer, sizeof(buffer), "%T", "MENU_TITLE_VIPINFO", client);
		menu.SetTitle(buffer);
		
		Format(buffer, sizeof(buffer), "%T", "MENU_ITEM_VIPINFO_VIP", client);
		menu.AddItem("1", buffer);
		Format(buffer, sizeof(buffer), "%T", "MENU_ITEM_VIPINFO_SUPERVIP", client);
		menu.AddItem("2", buffer);
		// Format(buffer, sizeof(buffer), "%T", "MENU_ITEM_VIPINFO_PREMIUM", client);
		// menu.AddItem("3", buffer);
		
		// Format(buffer, sizeof(buffer), "%T", "MENU_ITEM_VIPINFO_MOTD", client);
		// menu.AddItem("4", buffer);
		
		menu.Display(client, MENU_TIME_FOREVER);
	}
	return Plugin_Handled;
}

public int VipMenu_SelectCheck(Menu menu, MenuAction action, int client, int option)
{
	if (action == MenuAction_Select)
	{
		if (IsValidClient(client))
		{
			char buffer[164];
			Menu menuvip = new Menu(VipMenu_Select);
			
			FormatEx(buffer, sizeof(buffer), "%T", "VIP_MENU_TITLE", client);
			menuvip.SetTitle(buffer);
			menuvip.ExitBackButton = true;
			
			if (option == 0)
			{
				for (int i = 0; i < sizeof(MENU_VIP); i++)
				{
					FormatEx(buffer, sizeof(buffer), "%T", MENU_VIP[i][1], client);
					menuvip.AddItem(MENU_VIP[i][0], buffer, ITEMDRAW_DISABLED);
				}
			}
			else if (option == 1)
			{
				for (int i = 0; i < sizeof(MENU_SUPERVIP); i++)
				{
					FormatEx(buffer, sizeof(buffer), "%T", MENU_SUPERVIP[i][1], client);
					menuvip.AddItem(MENU_SUPERVIP[i][0], buffer, ITEMDRAW_DISABLED);
				}
			}
			// else if (option == 2)
			// {
			// 	for (int i = 0; i < sizeof(MENU_MAXIMUM); i++)
			// 	{
			// 		FormatEx(buffer, sizeof(buffer), "%T", MENU_MAXIMUM[i][1], client);
			// 		menuvip.AddItem(MENU_MAXIMUM[i][0], buffer, ITEMDRAW_DISABLED);
			// 	}
			// }
			else if (option == 2)
			{
				QueryClientConVar(client, "cl_disablehtmlmotd", QueryConVar_DisableHtmlMotd_BUYVIP);
			}
			
			menuvip.Display(client, MENU_TIME_FOREVER);
		}
	}
	else if (action == MenuAction_End) delete menu;
	return 0;
}

public int VipMenu_Select(Menu menu, MenuAction action, int client, int option)
{
	if (action == MenuAction_Cancel)
	{
		if (option == MenuCancel_ExitBack)
		{
			command_VIPInfo(client, 0);
		}
	}
	else if (action == MenuAction_End) delete menu;
	return 0;
}

public void QueryConVar_DisableHtmlMotd_BUYVIP(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
{
	if (IsValidClient(client))
	{
		if (result == ConVarQuery_Okay)
		{
			if (StringToInt(cvarValue) == 0)
			{
				ShowMOTDPanel(client, "[VIP]", "...", MOTDPANEL_TYPE_URL);
			}
			else
			{
				ZM_PrintToChat(client, _, "%T", "CHAT_DISABLEHTML_MOTD", client);
			}
		}
	}
}