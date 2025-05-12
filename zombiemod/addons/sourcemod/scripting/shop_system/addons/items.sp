#define MAX_HPWARD_COUNTTIMER 60 // 90
#define MAX_HPWARD_SLOT 5

public Action Command_ItemsMenu(int client, int args)
{
	if (IsValidClient(client) && ZM_IsClientHuman(client))
	{
		int mode = ZM_GetCurrentGameMode();
		if (ZM_IsStartedRound() && mode == m_ModeSwarm) {
			return Plugin_Handled;
		}
		
		int classid = ZM_GetClientClass(client);
		if (classid == m_HumanSniper || classid == m_HumanSurvivor || classid == m_ZombieMemesis) {
			return Plugin_Handled;
		}
		
		if (ZM_IsRespawn(client, 0))
		{
			return Plugin_Handled;
		}
		
		Menu menu = new Menu(MenuHandler_ItemsMenu);
		menu.SetTitle("%T\n ", "MENU_SHOP_ITEMS", client);
		
		char buffer[164];
		FormatEx(buffer, sizeof(buffer), "%T", "HUMAN_MENU_ITEM_AMMO", client);
		SS_AddMenuItem2(menu, client, "ammo; 0; -1", buffer, 0, 0, 0, true);
		
		if (sServerData.IsMapZm)
		{
			FormatEx(buffer, sizeof(buffer), "%T", "HUMAN_MENU_ITEM_HPWARD", client);
			SS_AddMenuItem2(menu, client, "hpward; 1; 470", buffer, 2, 470, 1, false);
		}
		
		menu.ExitBackButton = true;
		menu.OptionFlags = MENUFLAG_BUTTON_EXIT|MENUFLAG_BUTTON_EXITBACK;
		menu.Display(client, MENU_TIME_FOREVER);
	}
	return Plugin_Handled;
}

public int MenuHandler_ItemsMenu(Menu menu, MenuAction action, int param1, int param2)
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
			if (ZM_IsStartedRound() && ZM_GetCurrentGameMode() == m_ModeSwarm)
			{
				EmitSoundToClient(param1, SOUND_BUTTON_MENU);
				return 0;
			}
			
			int id = ZM_GetClientClass(param1);
			if (id == m_HumanSniper || id == m_HumanSurvivor || id == m_ZombieMemesis)
			{
				EmitSoundToClient(param1, SOUND_BUTTON_MENU);
				return 0;
			}
			
			if (ZM_IsRespawn(param1, 0))
			{
				return 0;
			}
			
			if (GetEntitySequence(param1) != 0)
			{
				EmitSoundToClient(param1, SOUND_BUTTON_MENU);
				return 0;
			}
			
			char info[34]; char buffer[3][34];
			menu.GetItem(param2, info, sizeof(info));
			ExplodeString(info, "; ", buffer, sizeof(buffer), sizeof(buffer[]));
			int num = StringToInt(buffer[1]);
			int price = StringToInt(buffer[2]);
			
			if (num == 1)
			{
				if (!GetClientVIPGroup(param1))
				{
					if (SetClientPriceUp2(param1, param2, price) > GetClientAmmoPacks(param1))
					{
						ZM_PrintToChat(param1, _, "%T", "CHAT_NO_AMMOPACKS", param1);
						return 0;
					}
				}
			}
			else
			{
				if (SetClientPriceUp2(param1, param2, price) > GetClientAmmoPacks(param1))
				{
					ZM_PrintToChat(param1, _, "%T", "CHAT_NO_AMMOPACKS", param1);
					return 0;
				}
			}
			
			int ammo = SS_MenuItem_Items(param1, param2, buffer);
			if (ammo == -1)
			{
				return 0;
			}
			
			if (ammo != 0)
			{
				if (GetClientVIPGroup(param1) && num == 1)
				{
					sClientData[param1].PriceUp_ITEMS[param2]++;
					SetClientPickMenu(param1, true);
					Command_ItemsMenu(param1, 0);
					return 0;
				}
				
				SetClientAmmoPacks(param1, -ammo);
				sClientData[param1].PriceUp_ITEMS[param2]++;
				Command_ItemsMenu(param1, 0);
			}
			// else
			// {
			// 	Command_ItemsMenu(param1, 0);
			// }
		}
		else Command_ItemsMenu(param1, 0);
	}
	else if (action == MenuAction_End) {
		delete menu;
	}
	return 0;
}

int SS_MenuItem_Items(int client, int item, const char[][] info)
{
	int price = StringToInt(info[2]);
	
	if (IsPlayerAlive(client))
	{
		char buffer[164];
	
		if (strcmp(info[0], "hpward") == 0)
		{
			float origin[3], angles[3], pos[3];
			if (!SetTeleportEndPoint(client, pos, angles))
			{
				PrintToChat_Lang(client, "%T", "PROP_TELEPORT", client);
				Command_ItemsMenu(client, 0);
				return -1;
			}
			
			GetClientAbsOrigin(client, origin);
			if (GetVectorDistance(origin, pos) >= 60)
			{
				PrintToChat_Lang(client, "%T", "PROP_DISTANCE", client);
				Command_ItemsMenu(client, 0);
				return -1;
			}
			
			int ent = CreateEntityByName("prop_dynamic_override");
			if (ent != -1)
			{
				DispatchKeyValue(ent, "model", MODELS_HEALTH);
				DispatchSpawn(ent);
				
				TeleportEntity(ent, pos, angles, NULL_VECTOR);
				
				SetEntProp(ent, Prop_Send, "m_usSolidFlags", 8);
				SetEntDataEnt2(ent, sServerData.OwnerEntityOffset, client);
				
				DataPack data = new DataPack();
				RequestFrame(Frame_EntityStuck_HEALTH, data);
				data.WriteCell(GetClientUserId(client));
				data.WriteCell(EntIndexToEntRef(ent));
				data.WriteCell(item);
				data.WriteCell(price);
			}
			
			return -1;
		}
		else if (strcmp(info[0], "ammo") == 0)
		{
			int weapon = GetEntDataEnt2(client, sServerData.ActiveWeapon);
			
			if (IsValidEdict(weapon) && GetEntityClassname(weapon, buffer, sizeof(buffer)))
			{
				if (StrContains(buffer, "weapon_knife", true) != 0 && strcmp(buffer, "weapon_hegrenade") != 0 && strcmp(buffer, "weapon_smokegrenade") != 0 && strcmp(buffer, "weapon_flashbang") != 0
				&& strcmp(buffer, "weapon_shieldgrenade") != 0 && strcmp(buffer, "weapon_rpg") != 0 && strcmp(buffer, "weapon_m32") != 0 && strcmp(buffer, "weapon_gauss") != 0
				&& strcmp(buffer, "weapon_tripmine") != 0 && strcmp(buffer, "weapon_freeze") != 0)
				{
					int weaponid = ZM_GetWeaponNameID(buffer);
					int i_curAmmo = GetAmmoCount(client, weapon);
					int i_needAmmo = ZM_GetWeaponAmmo(weaponid) - i_curAmmo;
					
					if (i_needAmmo <= 0)
					{
						ZM_PrintToChat(client, _, "%T", "CHAT_WEAPON_AMMO_MAX", client);
						Command_ItemsMenu(client, 0);
						return -1;
					}
					
					int m_iCost;
					// if (strcmp(buffer, "weapon_rpg") == 0)
					// 	m_iCost = RoundToCeil(i_needAmmo * 10.0);
					// else if (strcmp(buffer, "weapon_m32") == 0)
					// 	m_iCost = RoundToCeil(i_needAmmo * 3.5);
					// if (strcmp(buffer, "weapon_gauss") == 0)
					// 	m_iCost = RoundToCeil(i_needAmmo * 0.037);
					
					if (strcmp(buffer, "weapon_thunderbolt") == 0)
						m_iCost = RoundToCeil(i_needAmmo * 5.0);
					else if (strcmp(buffer, "weapon_salamander") == 0)
						m_iCost = RoundToCeil(i_needAmmo * 0.0888);
					else if (strcmp(buffer, "weapon_frostgun") == 0)
						m_iCost = RoundToCeil(i_needAmmo * 0.0555);
					else if (strcmp(buffer, "weapon_awp_buff") == 0)
						m_iCost = RoundToCeil(i_needAmmo * 0.7333);
					else if (strcmp(buffer, "weapon_ethereal") == 0)
						m_iCost = RoundToCeil(i_needAmmo * 0.1555);
					else if (strcmp(buffer, "weapon_laserfist") == 0)
						m_iCost = RoundToCeil(i_needAmmo * 0.0566);
					else if (strcmp(buffer, "weapon_m3shark") == 0)
						m_iCost = RoundToCeil(i_needAmmo * 0.41);
					else m_iCost = RoundToCeil(i_needAmmo * 0.0333);
					
					if (GetClientAmmoPacks(client) < m_iCost)
					{
						ZM_PrintToChat(client, _, "%T", "CHAT_WEAPON_NO_AMMOPACKS", client, (m_iCost - GetClientAmmoPacks(client)));
						return -1;
					}
					
					EmitSoundToAll(SOUND_AMMOPICKUP, client);
					GiveAmmo(client, weapon, i_needAmmo);
					SetClientAmmoPacks(client, -m_iCost);
					return -1;
				}
			}
			
			ZM_PrintToChat(client, _, "%T", "CHAT_BLOCK_WEAPONS", client);
			Command_ItemsMenu(client, 0);
			return -1;
		}
		else if (strcmp(info[0], "ammocrate") == 0)
		{
			switch(CreateForward_OnClientItemPickup(client, price, "ammocrate"))
			{
				case Plugin_Changed:
				{
					return price;
				}
				case Plugin_Handled:
				{
					Command_ItemsMenu(client, 0);
					return -1;
				}
				case Plugin_Stop:
				{
					return -1;
				}
			}
		}
		else if (strcmp(info[0], "armor") == 0)
		{
			if (GetEntProp(client, Prop_Data, "m_ArmorValue") >= 50)
			{
				ZM_PrintToChat(client, _, "%T", "CHAT_ARMOR_MAX", client);
				Command_ItemsMenu(client, 0);
				return -1;
			}
		
			SetEntProp(client, Prop_Data, "m_ArmorValue", 50);
			EmitSoundToAll(SOUND_AMMOPICKUP, client);
		}
		else return -1;
	}
	else return -1;
	
	return SetClientPriceUp2(client, item, price);
}

public void Frame_EntityStuck_HEALTH(DataPack data)
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
		float origin[3]; GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
		int effect = UTIL_CreateParticle(entity, "info_health_", "info_health_main_v1", origin, true);
		
		SetEntPropEnt(entity, Prop_Data, "m_hMoveChild", effect);
		SetEntPropEnt(effect, Prop_Data, "m_hEffectEntity", entity);
		
		sServerData.TrieEntity1.SetValue(entity, MAX_HPWARD_COUNTTIMER);
		sServerData.TrieEntity2.SetValue(entity, 0);
		sServerData.TrieEntity3.SetValue(entity, 0);
		CreateTimer(1.0, Timer_Heal, EntIndexToEntRef(entity), TIMER_REPEAT);
		
		EmitSoundToAll(SOUND_BLADECUT, entity);
		
		if (GetClientVIPGroup(client))
		{
			SetClientPickMenu(client, true);
			sClientData[client].PriceUp_ITEMS[item]++;
			return;
		}
		
		SetClientAmmoPacks(client, -SetClientPriceUp2(client, item, price));
		sClientData[client].PriceUp_ITEMS[item]++;
	}
}

public Action Timer_Heal(Handle timer, any data)
{
	int ent = EntRefToEntIndex(data);
	if (ent < 1 || !IsValidEdict(ent))
	{
		sServerData.TrieEntity3.SetValue(ent, 0);
		return Plugin_Stop;
	}
	static int iCount;
	sServerData.TrieEntity1.GetValue(ent, iCount);
	
	if (iCount < 1 || ZM_IsEndRound())
	{
		sServerData.TrieEntity3.SetValue(ent, 0);
		sServerData.TrieEntity1.SetValue(ent, 0);
		AcceptEntityInput(ent, "Kill");
		return Plugin_Stop;
	}
	static int clients[MAXPLAYERS+1], clientx, iCountSlot;
	float EntityOrigin[3], PlayerOrigin[3];
	
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", EntityOrigin);
	
	sServerData.TrieEntity1.SetValue(ent, --iCount);
	sServerData.TrieEntity3.GetValue(ent, clientx);
	
	if (clientx == 0)
	{
		int count;
		for (int i = 1; i <= MaxClients; ++i)
		{
			if (IsValidClient(i) && IsPlayerAlive(i) && ZM_IsClientHuman(i))
			{
				GetClientAbsOrigin(i, PlayerOrigin);
				if (GetVectorDistance(EntityOrigin, PlayerOrigin) <= 200)
				{
					if (GetClientHealth(i) < GetEntProp(i, Prop_Data, "m_iMaxHealth"))
					{
						count++;
						
						if (count > 1 && clients[0] == i)
						{
							// PrintToChatAll("[TEST] %d - %d", clients[0], count);
							clients[0] = 0;
							continue;
						}
					
						clients[count] = i;
					}
				}
			}
		}
		
		if (count != 0)
		{
			sServerData.TrieEntity2.SetValue(ent, MAX_HPWARD_SLOT);
			sServerData.TrieEntity3.SetValue(ent, clients[GetRandomInt(1, count)]);
		}
	}
	sServerData.TrieEntity2.GetValue(ent, iCountSlot);
	sServerData.TrieEntity3.GetValue(ent, clientx);
	
	if (!(iCountSlot < 1) && IsValidClient(clientx) && IsPlayerAlive(clientx) && ZM_IsClientHuman(clientx))
	{
		GetClientAbsOrigin(clientx, PlayerOrigin);
		
		if (GetVectorDistance(EntityOrigin, PlayerOrigin) <= 200)
		{
			int hp = GetClientHealth(clientx);
			int maxhp = GetEntProp(clientx, Prop_Data, "m_iMaxHealth");
			
			if (hp < maxhp)
			{
				SetEntityHealth(clientx, UTIL_Clamp(hp+5, 0, maxhp));
				EmitSoundToAll(SOUND_SMALLMEDKIT, clientx);
				
				PlayerOrigin[2] += GetRandomFloat(16.0, 50.0);
				int effect = UTIL_CreateParticle(ent, "info_health_", "info_health_beam_v1", PlayerOrigin);
				SetVariantString("!activator");
				AcceptEntityInput(effect, "SetParent", clientx, effect);
				UTIL_RemoveEntity(effect, 0.2);
				UTIL_ScreenFade(clientx, 1.0, 0.1, FFADE_IN, {0, 128, 0, 30});
				
				sServerData.TrieEntity2.SetValue(ent, --iCountSlot);
				return Plugin_Continue;
			}
		}
	}
	
	clients[0] = clientx;
	sServerData.TrieEntity3.SetValue(ent, 0);
	return Plugin_Continue;
}

public Action Hook_OnTakeDamage_DMGFALL(int victim, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	if (damagetype == DMG_FALL)
	{
		if (IsValidClient(victim))
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public Action Command_ammo(int client, int args)
{
	// if (!sServerData.IsMapZm)
	// {
	// 	return Plugin_Handled;
	// }
	
	if (IsValidClient(client) && IsClientLoaded(client))
	{
		char buffer[164];
		int weapon = GetEntDataEnt2(client, sServerData.ActiveWeapon);
		
		Command_ItemsMenu(client, 0);
		
		if (IsValidEdict(weapon) && GetEntityClassname(weapon, buffer, sizeof(buffer)))
		{
			if (StrContains(buffer, "weapon_knife", true) != 0 && strcmp(buffer, "weapon_hegrenade") != 0 && strcmp(buffer, "weapon_smokegrenade") != 0 && strcmp(buffer, "weapon_flashbang") != 0
			&& strcmp(buffer, "weapon_shieldgrenade") != 0 && strcmp(buffer, "weapon_rpg") != 0 && strcmp(buffer, "weapon_m32") != 0 && strcmp(buffer, "weapon_gauss") != 0
			&& strcmp(buffer, "weapon_tripmine") != 0 && strcmp(buffer, "weapon_freeze") != 0)
			{
				int weaponid = ZM_GetWeaponNameID(buffer);
				int i_curAmmo = GetAmmoCount(client, weapon);
				int i_needAmmo = ZM_GetWeaponAmmo(weaponid) - i_curAmmo;
				
				if (i_needAmmo <= 0)
				{
					ZM_PrintToChat(client, _, "%T", "CHAT_WEAPON_AMMO_MAX", client);
					return Plugin_Handled;
				}
				
				int m_iCost;
				// if (strcmp(buffer, "weapon_rpg") == 0)
				// 	m_iCost = RoundToCeil(i_needAmmo * 10.0);
				// else if (strcmp(buffer, "weapon_m32") == 0)
				// 	m_iCost = RoundToCeil(i_needAmmo * 3.5);
				// if (strcmp(buffer, "weapon_gauss") == 0)
				// 	m_iCost = RoundToCeil(i_needAmmo * 0.037);
				
				if (strcmp(buffer, "weapon_thunderbolt") == 0)
					m_iCost = RoundToCeil(i_needAmmo * 5.0);
				else if (strcmp(buffer, "weapon_salamander") == 0)
					m_iCost = RoundToCeil(i_needAmmo * 0.0888);
				else if (strcmp(buffer, "weapon_frostgun") == 0)
					m_iCost = RoundToCeil(i_needAmmo * 0.0555);
				else if (strcmp(buffer, "weapon_awp_buff") == 0)
					m_iCost = RoundToCeil(i_needAmmo * 0.7333);
				else if (strcmp(buffer, "weapon_ethereal") == 0)
					m_iCost = RoundToCeil(i_needAmmo * 0.1555);
				else if (strcmp(buffer, "weapon_laserfist") == 0)
					m_iCost = RoundToCeil(i_needAmmo * 0.0566);
				else if (strcmp(buffer, "weapon_m3shark") == 0)
					m_iCost = RoundToCeil(i_needAmmo * 0.41);
				else m_iCost = RoundToCeil(i_needAmmo * 0.0333);
				
				if (GetClientAmmoPacks(client) < m_iCost)
				{
					ZM_PrintToChat(client, _, "%T", "CHAT_WEAPON_NO_AMMOPACKS", client, (m_iCost - GetClientAmmoPacks(client)));
					return Plugin_Handled;
				}
				
				EmitSoundToAll(SOUND_AMMOPICKUP, client);
				GiveAmmo(client, weapon, i_needAmmo);
				SetClientAmmoPacks(client, -m_iCost);
				return Plugin_Handled;
			}
		}
		
		ZM_PrintToChat(client, _, "%T", "CHAT_BLOCK_WEAPONS", client);
	}
	return Plugin_Handled;
}

void SS_AddMenuItem2(Menu menu, int client, const char[] info, const char[] name, int item, int price, int x, bool pick)
{
	char buffer[264];
	
	if (GetClientVIPGroup(client) && pick == false)
	{
		FormatEx(buffer, sizeof(buffer), "%s[%T]", name, "VIP PickMenu", client);
		menu.AddItem(info, buffer);
		return;
	}
	
	if (price != 0)
	{
		if (x == -1)
		{
			FormatEx(buffer, sizeof(buffer), "%s[%d %T]", name, price, "ammopack 2", client);
			menu.AddItem(info, buffer, (GetClientAmmoPacks(client) >= price) ? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
			return;
		}
	
		if (x != 0)
		{
			int up = SetClientPriceUp2(client, item, price);
			if (up <= price * x)FormatEx(buffer, sizeof(buffer), "%s[%d %T]", name, up, "ammopack 2", client);
			else FormatEx(buffer, sizeof(buffer), "%s[✔]", name);
			menu.AddItem(info, buffer, (GetClientAmmoPacks(client) >= up && up <= price * x) ? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
		}
		else
		{
			FormatEx(buffer, sizeof(buffer), "%s[✘]", name);
			menu.AddItem(info, buffer, ITEMDRAW_DISABLED);
		}
	}
	else
	{
		FormatEx(buffer, sizeof(buffer), "%s", name);
		menu.AddItem(info, buffer);
	}
}

int SetClientPriceUp2(int client, int item, int price)
{
	return price * (sClientData[client].PriceUp_ITEMS[item] + 1);
}