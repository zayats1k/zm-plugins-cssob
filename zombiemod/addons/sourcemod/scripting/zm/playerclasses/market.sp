enum /* MenuType */
{
	MenuType_FavEdit = -3,
	MenuType_FavAdd, 
	MenuType_FavBuy,
	MenuType_Buy
};

void MarketOnCommandInit()
{
	MarketMenuOnCommandInit();
}

void MarketOnEntityCreated(int entity, const char[] classname)
{
	if (!strcmp(classname, "func_buyzone", false))
	{
		AcceptEntityInput(entity, "kill");
	}
}

void MarketOnClientUpdate(int client)
{
	RequestFrame(Frame_MarketOnClientUpdate, GetClientUserId(client));
}

public void Frame_MarketOnClientUpdate(int userid)
{
	int client = GetClientOfUserId(userid);
	
	if (IsValidClient(client) && IsPlayerAlive(client) && !sClientData[client].Zombie)
	{
		for (int x = 0; x < 10; x++) {
			sClientData[client].PickWeaponRound[x] = false;
		}
	
		if (sServerData.RoundNew)
		{
			if (sCvarList.MARKET_MENU.BoolValue)
			{
				Command_MarketMenu(client, 0);
			}
		}
		
		if (GetPlayerWeaponSlot(client, 3) == -1)
		{
			GivePlayerItem(client, "weapon_hegrenade");
		}

		if (sCvarList.MARKET_FAVORITES.BoolValue)
		{
			MarketResetShoppingCart(client); 
			
			if (sClientData[client].DefaultCart != null)
			{
				int size = sClientData[client].ShoppingCart.Length;
				for (int i = 0; i < size; i++)
				{
					int id = sClientData[client].ShoppingCart.Get(i);
					
					if (WeaponsFindBySlot(client, ItemsGetWeaponID(id)) != -1)
					{
						continue;
					}
					
					if (MarketBuyItem(client, id))
					{
						sClientData[client].ShoppingCart.Erase(i);
						size--; i--;
					}
				}
				
				if (size == 0)
				{
					delete sClientData[client].ShoppingCart;
				}
			}
		}
	}
}

int WeaponsFindBySlot(int client, int id)
{
	if (id != -1)
	{
		int slot = WeaponsGetSlot(id);
	
		if (slot != 2)
		{
			return GetPlayerWeaponSlot(client, slot);
		}
	}
	return -1;
}

void MarketResetShoppingCart(int client)
{
	if (sClientData[client].DefaultCart != null)
	{
		delete sClientData[client].ShoppingCart;
		sClientData[client].ShoppingCart = sClientData[client].DefaultCart.Clone();
	}
}

bool MarketBuyItem(int client, int id)
{
	int section = ItemsGetSectionID(id);
	
	if (sClientData[client].PickWeaponRound[section] == true)
	{
		return false;
	}
	
	if (!ItemsHasAccessByType(client, id) || MarketIsBuyTimeExpired(client, section) || !MarketIsItemAvailable(client, id)) 
	{
		return false;
	}
	
	sClientData[client].PickWeaponRound[section] = true;
	WeaponsGive(client, ItemsGetWeaponID(id), true);
	return true;
}

bool MarketIsItemAvailable(int client, int id)
{
	int price = ItemsGetPrice(id);
	int account = AccountGetClientCash(client);
	
	if (price && account < price)
	{
		return false;
	}

	int weapon = ItemsGetWeaponID(id);
	if (weapon != -1 && WeaponsFindByID(client, weapon) != -1)
	{
		return false;
	}
	
	static char group[SMALL_LINE_LENGTH]; ItemsGetGroup(id, group, sizeof(group));
	if (ITEM_VIP_LEVEL(client, id, group)) {
		return false;
	}
	
	if (price != 0)
	{
		AccountSetClientCash(client, account - price);
	}
	return true;
}

bool MarketIsBuyTimeExpired(int client, int section = -1)
{
	if (section == sServerData.Sections.Length - 1)
	{
		return false;
	}
	return sCvarList.MARKET_OFF_WHEN_STARTED.BoolValue && sServerData.RoundStart && (GetGameTime() - sClientData[client].SpawnTime > sCvarList.MARKET_BUYTIME.FloatValue);
}

bool ITEM_VIP_LEVEL(int client, int id, const char[] group)
{
	if (ItemsGetLevel(id) != 0)
	{
		if (ItemsGetLevel(id) <= GetClientLevel(client))
		{
			return false;
		}
		
		if (group[0] && VIP_IsClientVIP(client))
		{
			if (!IsClientGroup(client, ItemsGetGroupFlags(id), group))
			{
				return false;
			}
		}
		
		return true;
	}
	else if (group[0] && IsClientGroup(client, ItemsGetGroupFlags(id), group))
	{
		return true;
	}
	return false;
}