void MarketMenuOnCommandInit()
{
	HookConVarChange(sCvarList.MARKET_MENU_COMMANDS, Hook_OnCvarMarket);
	
	MarketOnCvarLoad();
}

public void Hook_OnCvarMarket(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (strcmp(oldValue, newValue, false) != 0)
	{
		MarketOnCvarLoad();
	}
}

void MarketOnCvarLoad()
{
	AddConVarCommand(sCvarList.MARKET_MENU_COMMANDS, Command_MarketMenu);
}

public Action Command_MarketMenu(int client, int args)
{
	char commands[2];
	sCvarList.MARKET_MENU_COMMANDS.GetString(commands, sizeof(commands));
	ReplaceString(commands, sizeof(commands), " ", "");
	if (!hasLength(commands)) {
		return Plugin_Continue;
	}

	if (IsValidClient(client))
	{
		MarketMenu(client);
	}
	return Plugin_Handled;
}

void MarketMenu(int client)
{
	static char buffer[NORMAL_LINE_LENGTH], info[SMALL_LINE_LENGTH];
	
	if (IsPlayerAlive(client) && (!sClientData[client].Zombie && !sCvarList.MARKET_HUMAN_OPEN_ALL.BoolValue))
	{
		return;
	} 
	
	Menu menu = new Menu(MenuHandler_MarketMenu);

	SetGlobalTransTarget(client);
	FormatEx(buffer, sizeof(buffer), "%t", "main market");
	menu.SetTitle(buffer);

	if (sCvarList.MARKET_FAVORITES.BoolValue)
	{
		FormatEx(buffer, sizeof(buffer), "%t", "market favorites menu");
		menu.AddItem("-1", buffer);
	}
	
	for (int i = 0; i < sServerData.Sections.Length; i++)
	{
		sServerData.Sections.GetString(i, buffer, sizeof(buffer));

		FormatEx(buffer, sizeof(buffer), "%t", buffer);
		IntToString(i, info, sizeof(info));
		menu.AddItem(info, buffer, MenusGetItemDraw(sClientData[client].Zombie || sClientData[client].PickWeaponRound[i] == true || MarketIsBuyTimeExpired(client, i) ? false:true));
	}
	
	if (!menu.ItemCount)
	{
		FormatEx(buffer, sizeof(buffer), "%t", "menu empty");
		menu.AddItem("empty", buffer, ITEMDRAW_DISABLED);
	}

	menu.ExitBackButton = true;
	menu.OptionFlags = MENUFLAG_BUTTON_EXIT|MENUFLAG_BUTTON_EXITBACK;
	menu.Display(client, MENU_TIME_FOREVER); 
}

public int MenuHandler_MarketMenu(Menu menu, MenuAction action, int param1, int param2)
{   
	switch (action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack || param2 == MenuCancel_Exit)
			{
				if (!IsValidClient(param1)) {
					return 0;
				}
				
				int id[2]; id = MenusCommandToArray("zmarket");
				if (id[0] != -1)
				{
					SubMenu(param1, id[0]);
				}
				else
				{
					char commands[2]; sCvarList.CLASSES_MENU_COMMANDS_ZOMBIE.GetString(commands, sizeof(commands));
					ReplaceString(commands, sizeof(commands), " ", "");
					if (hasLength(commands)) {
						ClassClientMenu(param1, "choose zombieclass", sServerData.Zombie, sClientData[param1].ZombieClassNext);
					}
				}
			}
		}
		case MenuAction_Select:
		{
			if (!IsValidClient(param1)) {
				return 0;
			}
			static char buffer[SMALL_LINE_LENGTH];
			menu.GetItem(param2, buffer, sizeof(buffer));
			int id = StringToInt(buffer);

			switch (id)
			{
				case -1: MarketBuyMenu(param1, MenuType_FavEdit, _, ClassGetType(sClientData[param1].Class));
				default:
				{
					if (sClientData[param1].PickWeaponRound[id] == true)
					{
						EmitSoundToClient(param1, SOUND_BUTTON_MENU_ERROR);
						return 0;
					}
				
					if (!IsPlayerAlive(param1) || MarketIsBuyTimeExpired(param1, id))
					{
						// TranslationPrintHintText(param1, true, "block buying time");
						EmitSoundToClient(param1, SOUND_BUTTON_MENU_ERROR);    
						return 0;
					}
				
					sServerData.Sections.GetString(id, buffer, sizeof(buffer));

					MarketBuyMenu(param1, id, buffer);
				}
			}
		}
	}
	return 0;
}

void MarketBuyMenu(int client, int section = MenuType_Buy, char[] title = "market favorites menu", int type = -1) 
{
	bool bMenu = (section != MenuType_FavBuy); bool edit = (section == MenuType_FavAdd || section == MenuType_FavEdit);
	static char buffer[NORMAL_LINE_LENGTH], name[SMALL_LINE_LENGTH], info[NORMAL_LINE_LENGTH];
	
	static int iTypes[MAXPLAYERS+1];
	if (type != -1) 
		iTypes[client] = type;
	else type = iTypes[client];
	
	Menu menu = MarketSectionToHandle(section);
	int size = MarketSectionToCount(client, section);
	SetGlobalTransTarget(client);

	switch (section)
	{
		case MenuType_FavEdit:
		{
			FormatEx(buffer, sizeof(buffer), "%t", "market favorite add");
			menu.AddItem("-1", buffer);
		}
	}
	
	// if (edit && type != -1) {
	// 	sServerData.Types.GetString(type, title, SMALL_LINE_LENGTH);
	// }

	menu.SetTitle("%t", title);
	
	int lvl = GetClientLevel(client);
	
	bool enabled = false;
	int amount, price, level, weapon;
	for (int i = 0; i < size; i++)
	{
		int id = MarketSectionToIndex(client, section, i);

		if (edit)
		{
			// if (!ClassHasTypeBits(ItemsGetTypes(id), type))
			// {
			// 	continue;
			// }
			
			ItemsGetName(id, name, sizeof(name));
			ItemsGetGroup(id, info, sizeof(info));
			level = ItemsGetSectionID(id);
			
			if (sClientData[client].DefaultCart != null && section == MenuType_FavAdd)
			{
				if (sClientData[client].PickWeapon[level] == true)
				{
					continue;
				}
			
				int index = sClientData[client].DefaultCart.FindValue(id);
				if (index != -1)
				{
					continue;
				}
			}
			
			if (section == MenuType_FavAdd)
			{
				if (ITEM_VIP_LEVEL(client, id, info))
				{
					continue;
				}
				
				if (strcmp(name, "weapon_knife", false) == 0)
				{
					continue;
				}
			}
			
			sServerData.Sections.GetString(level, info, sizeof(info));
			FormatEx(buffer, sizeof(buffer), "%t [%t]", name, info);
			
			IntToString(id, info, sizeof(info));
			menu.AddItem(info, buffer);
		}
		else
		{
			if (!ItemsHasAccessByType(client, id))
			{
				continue;
			}    
			
			if (bMenu && ItemsGetSectionID(id) != section) 
			{
				continue;
			}

			ItemsGetName(id, name, sizeof(name));
			ItemsGetGroup(id, info, sizeof(info));
			price = ItemsGetPrice(id);
			level = ItemsGetLevel(id);
			weapon = ItemsGetWeaponID(id);
			
			enabled = false;
			if (!ITEM_VIP_LEVEL(client, i, info))
			{
				enabled = true;
			}
			
			if (hasLength(info))
			{
				if (level <= lvl || enabled)
				{
					FormatEx(buffer, sizeof(buffer), "%t%t", name, info);
				}
				else
				{
					FormatEx(buffer, sizeof(buffer), "%t%t%t", name, info, "menu level", level);
				}
			}
			else
			{
				if (level <= lvl || enabled)
				{
					FormatEx(buffer, sizeof(buffer), "%t", name);
				}
				else
				{
					FormatEx(buffer, sizeof(buffer), "%t%t", name, "menu level", level);
				}
			}
			
			if (GetEntProp(client, Prop_Send, "m_iAccount") < price)
			{
				FormatEx(buffer, sizeof(buffer), "%t%t", name, "menu price", price);
				enabled = false;
			}
			else if (weapon != -1 && WeaponsFindByID(client, weapon) != -1)
			{
				FormatEx(buffer, sizeof(buffer), "%t%t", name, "menu weapon");
				enabled = false;
			}

			IntToString(id, info, sizeof(info));
			menu.AddItem(info, buffer, MenusGetItemDraw(enabled && !MarketIsBuyTimeExpired(client, ItemsGetSectionID(id))));
		}
		
		amount++;
	}
	
	if (!amount)
	{
		FormatEx(buffer, sizeof(buffer), "%t", "menu empty");
		menu.AddItem("empty", buffer, ITEMDRAW_DISABLED);
	}
	
	menu.ExitBackButton = true;
	menu.OptionFlags = MENUFLAG_BUTTON_EXIT | MENUFLAG_BUTTON_EXITBACK;
	if (!bMenu && !amount) delete menu;
	else menu.Display(client, MENU_TIME_FOREVER); 
}

public int MarketBuyMenuSlots1(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				if (!IsValidClient(param1)) {
					return 0;
				}

				MarketMenu(param1);
				SaveChoiceToCookies(param1);
			}
			else if (param2 != MenuCancel_Exit || param2 != MenuCancel_Interrupted || param2 != MenuCancel_Disconnected)
			{
				if (!IsValidClient(param1)) {
					return 0;
				}
				
				SaveChoiceToCookies(param1);
			}
		}
		case MenuAction_Select:
		{
			if (!IsValidClient(param1)) {
				return 0;
			}
			static char buffer[CHAT_LINE_LENGTH], weaponname[SMALL_LINE_LENGTH];
			menu.GetItem(param2, buffer, sizeof(buffer));
			int id = StringToInt(buffer);

			switch (id)
			{
				case -1: MarketBuyMenu(param1, MenuType_FavAdd, "market favorite add 2");
				default:
				{
					int index = sClientData[param1].DefaultCart.FindValue(id);
					if (index != -1)
					{
						int section = ItemsGetSectionID(id);
						sClientData[param1].PickWeapon[section] = false;
						
						int size = sClientData[param1].DefaultCart.Length;
						if (size == 1) {
							delete sClientData[param1].DefaultCart;
						}
						else sClientData[param1].DefaultCart.Erase(index);
					}
					
					ItemsGetName(id, weaponname, sizeof(weaponname));
					Format(buffer, sizeof(buffer), "%T", weaponname, param1);
			
					TranslationPrintToChat(param1, "favorite deleted", buffer);
					
					MarketBuyMenu(param1, MenuType_FavEdit);
				}
			}
		}
	}
	return 0;
}

public int MarketBuyMenuSlots2(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				if (!IsValidClient(param1)) {
					return 0;
				}
				
				MarketBuyMenu(param1, MenuType_FavEdit);
			}
			else if (param2 != MenuCancel_Exit || param2 != MenuCancel_Interrupted || param2 != MenuCancel_Disconnected)
			{
				if (!IsValidClient(param1)) {
					return 0;
				}
				
				SaveChoiceToCookies(param1);
			}
		}
		case MenuAction_Select:
		{
			if (!IsValidClient(param1)) {
				return 0;
			}
		   
			static char buffer[CHAT_LINE_LENGTH], weaponname[SMALL_LINE_LENGTH];
			menu.GetItem(param2, buffer, sizeof(buffer));
			int id = StringToInt(buffer);
			
			if (sClientData[param1].DefaultCart == null) {
				sClientData[param1].DefaultCart = new ArrayList();
			}
			
			int section = ItemsGetSectionID(id);
			sClientData[param1].DefaultCart.Push(id);
			
			ItemsGetName(id, weaponname, sizeof(weaponname));
			Format(buffer, sizeof(buffer), "%T", weaponname, param1);
			
			TranslationPrintToChat(param1, "favorite added", buffer);
			
			sClientData[param1].PickWeapon[section] = true;
			MarketBuyMenu(param1, MenuType_FavEdit);
		}
	}
	return 0;
}

void SaveChoiceToCookies(int client)
{
	static char buffer[SMALL_LINE_LENGTH], buffer2[SMALL_LINE_LENGTH]; int len = 0;
	sServerData.CookieWeapons.Get(client, buffer2, sizeof(buffer2));
	
	int size = MarketSectionToCount(client, MenuType_FavEdit);
	
	if (size != 0)
	{
		for (int i = 0; i < size; i++)
		{
			int id = MarketSectionToIndex(client, MenuType_FavEdit, i);
			len += Format(buffer[len], sizeof(buffer)-len, "|%d", id);
		}
		
		if (strcmp(buffer2, buffer[1], false) != 0)
		{
			sServerData.CookieWeapons.Set(client, buffer[1]);
			TranslationPrintToChat(client, "favorite saved");
		}
	}
	else
	{
		if (buffer2[0])
		{
			sServerData.CookieWeapons.Set(client, "");
			TranslationPrintToChat(client, "favorite saved");
		}
	}
}

void Maket_OnClientCookiesCached(int client)
{
	if (sClientData[client].DefaultCart == null) {
		sClientData[client].DefaultCart = new ArrayList();
	}

	static char buffer[SMALL_LINE_LENGTH];
	sServerData.CookieWeapons.Get(client, buffer, sizeof(buffer));
	
	if (!buffer[0])
	{
		return;
	}
	
	char exp[10][SMALL_LINE_LENGTH]; int id = -1; int level = 0;
	for (int i; i < ExplodeString(buffer, "|", exp, sizeof(exp), sizeof(exp[])); i++)
	{
		id = StringToInt(exp[i]);
		
		if (id == -1 || !exp[i][0]) {
			continue;
		}
		
		if (id >= sServerData.ExtraItems.Length)
		{
			continue;
		}
		
		level = ItemsGetSectionID(id);
		sClientData[client].PickWeapon[level] = true;
		sClientData[client].DefaultCart.Push(id);
	}
}

public int MarketBuyMenuSlots3(Menu menu, MenuAction action, int param1, int param2)
{
	return MarketBuyMenuSlots(menu, action, param1, param2, true);
}

public int MarketBuyMenuSlots4(Menu menu, MenuAction action, int param1, int param2)
{
	return MarketBuyMenuSlots(menu, action, param1, param2);
}

int MarketBuyMenuSlots(Menu menu, MenuAction action, int param1, int param2, bool bFavorites = false)
{
	switch (action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				if (!IsValidClient(param1)) {
					return 0;
				}
				
				if (MarketIsBuyTimeExpired(param1) && (!sClientData[param1].Zombie && !sCvarList.MARKET_HUMAN_OPEN_ALL.BoolValue))
				{
					int id[2]; id = MenusCommandToArray("zmarket");
					if (id[0] != -1) SubMenu(param1, id[0]);
				}
				else
				{
					MarketMenu(param1);
				}
			}
		}
		case MenuAction_Select:
		{
			if (!IsValidClient(param1) || !IsPlayerAlive(param1)) {
				return 0;
			}

			static char buffer[SMALL_LINE_LENGTH];
			menu.GetItem(param2, buffer, sizeof(buffer));
			int id = StringToInt(buffer);

			switch (id)
			{
				case -1:
				{
					int size = sClientData[param1].ShoppingCart.Length;
					for (int i = 0; i < size; i++)
					{
						id = sClientData[param1].ShoppingCart.Get(i);

						if (MarketBuyItem(param1, id))
						{
							sClientData[param1].ShoppingCart.Erase(i);
							size--; i--;
						}
					}
					
					if (size == 0)
					{
						delete sClientData[param1].ShoppingCart;
					}
				}
				default:
				{
					if (MarketBuyItem(param1, id))
					{
						if (bFavorites)
						{
							int index = sClientData[param1].ShoppingCart.FindValue(id);
							if (index != -1)
							{
								int size = sClientData[param1].ShoppingCart.Length;
								if (size == 1)
								{
									delete sClientData[param1].ShoppingCart;
								}
								else
								{
									sClientData[param1].ShoppingCart.Erase(index);
									MarketBuyMenu(param1, MenuType_FavBuy);
								}
							}
						}
						else MarketMenu(param1);
					}
					else
					{
						// ItemsGetName(id, buffer, sizeof(buffer));
						// TranslationPrintHintText(param1, true, "block buying item", buffer);
						// PrintToChatAll("[buy] %s", buffer);
						// EmitSoundToClient(param1, SOUND_BUY_ITEM_FAILED, SOUND_FROM_PLAYER, SNDCHAN_ITEM);
					}
				}
			}
		}
	}
	
	return 0;
}

Menu MarketSectionToHandle(int section)
{
	switch (section)
	{
		case MenuType_FavEdit: {
			return new Menu(MarketBuyMenuSlots1);
		}
		case MenuType_FavAdd: {
			return new Menu(MarketBuyMenuSlots2);
		}
		case MenuType_FavBuy: {
			return new Menu(MarketBuyMenuSlots3);
		}
		default: {
			return new Menu(MarketBuyMenuSlots4);
		}
	}
}

int MarketSectionToIndex(int client, int section, int id)
{
	switch (section)
	{
		case MenuType_FavEdit: {
			return sClientData[client].DefaultCart.Get(id);
		}
		case MenuType_FavBuy: {
			return sClientData[client].ShoppingCart.Get(id);
		}
		default: {
			return id;
		}
	}
}

int MarketSectionToCount(int client, int section)
{
	switch (section)
	{
		case MenuType_FavEdit: {
			return sClientData[client].DefaultCart != null ? sClientData[client].DefaultCart.Length : 0;
		}
		case MenuType_FavBuy: {
			return sClientData[client].ShoppingCart != null ? sClientData[client].ShoppingCart.Length : 0;
		}
		default: {
			return sServerData.ExtraItems.Length;
		}
	}
}