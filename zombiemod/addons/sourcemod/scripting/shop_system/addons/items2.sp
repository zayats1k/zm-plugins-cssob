public Action OnShopMenuItems2(int client)
{
	if (IsValidClient(client) && ZM_IsClientHuman(client))
	{
		Menu menu = new Menu(MenuHandler_Items2Menu);
		menu.SetTitle("%T\n ", "MENU_SHOP_ITEMS2", client);
		
		char buffer[164];
		FormatEx(buffer, sizeof(buffer), "%T", "HUMAN_MENU_ITEM_VIP", client);
		SS_AddMenuItem4(menu, client, "VIP; 35000", buffer, 35000);
		FormatEx(buffer, sizeof(buffer), "%T", "HUMAN_MENU_ITEM_SUPERVIP", client);
		SS_AddMenuItem4(menu, client, "SUPERVIP; 50000", buffer, 50000);
		FormatEx(buffer, sizeof(buffer), "%T", "HUMAN_MENU_ITEM_SKIN1", client);
		SS_AddMenuItem4(menu, client, "Agent; 25000", buffer, 25000);
		FormatEx(buffer, sizeof(buffer), "%T", "HUMAN_MENU_ITEM_SKIN2", client);
		SS_AddMenuItem4(menu, client, "Gena; 25000", buffer, 25000);
		FormatEx(buffer, sizeof(buffer), "%T", "HUMAN_MENU_ITEM_SKIN3", client);
		SS_AddMenuItem4(menu, client, "Joker; 25000", buffer, 25000);
		
		// FormatEx(buffer, sizeof(buffer), "%T", "HUMAN_MENU_ITEM_SKIN1", client);
		// SS_AddMenuItem4(menu, client, "Tesla; 25000", buffer, 25000);
		// FormatEx(buffer, sizeof(buffer), "%T", "HUMAN_MENU_ITEM_SKIN2", client);
		// SS_AddMenuItem4(menu, client, "Vector; 30000", buffer, 30000);
		// FormatEx(buffer, sizeof(buffer), "%T", "HUMAN_MENU_ITEM_SKIN3", client);
		// SS_AddMenuItem4(menu, client, "Plague; 35000", buffer, 35000);
		// FormatEx(buffer, sizeof(buffer), "%T", "HUMAN_MENU_ITEM_SKIN4", client);
		// SS_AddMenuItem4(menu, client, "Mona; 40000", buffer, 40000);
		// FormatEx(buffer, sizeof(buffer), "%T", "HUMAN_MENU_ITEM_SKIN5", client);
		// SS_AddMenuItem4(menu, client, "Solider; 45000", buffer, 45000);
		
		menu.ExitBackButton = true;
		menu.OptionFlags = MENUFLAG_BUTTON_EXIT|MENUFLAG_BUTTON_EXITBACK;
		menu.Display(client, MENU_TIME_FOREVER);
	}
	return Plugin_Handled;
}

public int MenuHandler_Items2Menu(Menu menu, MenuAction action, int param1, int param2)
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
		if (IsValidClient(param1) && ZM_IsClientHuman(param1))
		{
			char info[32]; char buffer[2][34];
			menu.GetItem(param2, info, sizeof(info));
			ExplodeString(info, "; ", buffer, sizeof(buffer), sizeof(buffer[]));
			
			int ammo = SS_MenuItem_Items2(param1, buffer);
			
			if (ammo == -1)
			{
				return 0;
			}
			
			if (ammo != 0)
			{
				SetClientAmmoPacks(param1, -ammo);
			}
			else
			{
				OnShopMenuWeapons(param1);
			}
		}
		else OnShopMenuItems2(param1);
	}
	else if (action == MenuAction_End) {
		delete menu;
	}
	return 0;
}

int SS_MenuItem_Items2(int client, const char[][] info)
{
	int price = StringToInt(info[1]);
	
	if (IsPlayerAlive(client))
	{
		if (strcmp(info[0], "VIP") == 0)
		{
			VIP_GiveClientVIP(0, client, "VIP", 30);
			UTIL_LogToFile("shop_system", "\"%L\" give VIP(30 days)", client);
		}
		else if (strcmp(info[0], "SUPERVIP") == 0)
		{
			VIP_GiveClientVIP(0, client, "SUPERVIP", 30);
			UTIL_LogToFile("shop_system", "\"%L\" give SUPER VIP(30 days)", client);
		}
		else if (strcmp(info[0], "Tesla") == 0)
		{
			SKIN_GiveClientSKIN(0, client, "Tesla [Fallout]", 30);
			UTIL_LogToFile("shop_system", "\"%L\" give skin(Tesla [Fallout], 30 days)", client);
		}
		else if (strcmp(info[0], "Vector") == 0)
		{
			SKIN_GiveClientSKIN(0, client,"Vector [RE]", 30);
			UTIL_LogToFile("shop_system", "\"%L\" give skin(Vector [RE], 30 days)", client);
		}
		else if (strcmp(info[0], "Plague") == 0)
		{
			SKIN_GiveClientSKIN(0, client, "Plague [Doctor]", 30);
			UTIL_LogToFile("shop_system", "\"%L\" give skin(Plague [Doctor], 30 days)", client);
		}
		else if (strcmp(info[0], "Mona") == 0)
		{
			SKIN_GiveClientSKIN(0, client, "Mona [Anime]", 30);
			UTIL_LogToFile("shop_system", "\"%L\" give skin(Mona [Anime], 30 days)", client);
		}
		else if (strcmp(info[0], "Solider") == 0)
		{
			SKIN_GiveClientSKIN(0, client, "Solider [Bogatyr]", 30);
			UTIL_LogToFile("shop_system", "\"%L\" give skin(Solider [Bogatyr], 30 days)", client);
		}
		else if (strcmp(info[0], "Agent") == 0)
		{
			SKIN_GiveClientSKIN(0, client, "Agent [Crysis]", 30);
			UTIL_LogToFile("shop_system", "\"%L\" give skin(Agent [Crysis], 30 days)", client);
		}
		else if (strcmp(info[0], "Gena") == 0)
		{
			SKIN_GiveClientSKIN(0, client, "Gena [Lacoste]", 30);
			UTIL_LogToFile("shop_system", "\"%L\" give skin(Gena [Lacoste], 30 days)", client);
		}
		else if (strcmp(info[0], "Joker") == 0)
		{
			SKIN_GiveClientSKIN(0, client, "Joker [Cinema]", 30);
			UTIL_LogToFile("shop_system", "\"%L\" give skin(Joker [Cinema], 30 days)", client);
		}
		else return -1;
	}
	else return -1;
	
	return price;
}

void SS_AddMenuItem4(Menu menu, int client, const char[] info, const char[] name, int price)
{
	char buffer[264];
	
	if (price != 0)
	{
		FormatEx(buffer, sizeof(buffer), "%s[%d %T]", name, price, "ammopack 2", client);
		menu.AddItem(info, buffer, (GetClientAmmoPacks(client) >= price) ? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	}
	else
	{
		FormatEx(buffer, sizeof(buffer), "%s", name);
		menu.AddItem(info, buffer);
	}
}