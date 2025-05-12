public Action OnShopMenuWeapons(int client)
{
	if (IsValidClient(client) && IsClientLoaded(client))
	{
		if (sServerData.RoundEnd) {
			return Plugin_Handled;
		}
		
		if (ZM_IsRespawn(client, 0)) {
			return Plugin_Handled;
		}
		
		int mode = ZM_GetCurrentGameMode();
		if (ZM_IsStartedRound() && mode == m_ModeSwarm) {
			return Plugin_Handled;
		}
		
		int classid = ZM_GetClientClass(client);
		if (classid == m_HumanSniper || classid == m_HumanSurvivor || classid == m_ZombieMemesis) {
			return Plugin_Handled;
		}
		
		Menu menu = new Menu(MenuHandler_ShopMenu);
		
		char buffer[164];
		if (ZM_IsClientHuman(client)) // Human
		{
			FormatEx(buffer, sizeof(buffer), "%T\n ", "MENU_SHOP_WEAPONS", client);
			menu.SetTitle(buffer);
		
			// FormatEx(buffer, sizeof(buffer), "%T", "HUMAN_MENU_ITEM_AMMO", client);
			// SS_AddMenuItem(menu, client, "ammo; 0; -1", buffer, 0, 0, 0);
			
			if (sServerData.IsMapZm)
			{
				FormatEx(buffer, sizeof(buffer), "%T", "HUMAN_MENU_ITEM_M249", client);
				SS_AddMenuItem(menu, client, "m249; 0; 20", buffer, 0, 20, 999);
				FormatEx(buffer, sizeof(buffer), "%T", "HUMAN_MENU_ITEM_SG550", client);
				SS_AddMenuItem(menu, client, "sg550; 0; 20", buffer, 1, 20, 999);
				FormatEx(buffer, sizeof(buffer), "%T", "HUMAN_MENU_ITEM_M134", client);
				SS_AddMenuItem(menu, client, "m134; 0; 60", buffer, 2, 60, 999);
				FormatEx(buffer, sizeof(buffer), "%T", "HUMAN_MENU_ITEM_SALAMANDER", client);
				SS_AddMenuItem(menu, client, "salamander; 0; 40", buffer, 3, 40, 999);
				FormatEx(buffer, sizeof(buffer), "%T", "HUMAN_MENU_ITEM_RPG", client);
				SS_AddMenuItem(menu, client, "rpg; 0; 80", buffer, 4, 80, 999);
				FormatEx(buffer, sizeof(buffer), "%T", "HUMAN_MENU_ITEM_DINFINITY", client);
				SS_AddMenuItem(menu, client, "dinfinity; 0; 35", buffer, 5, 35, 999);
				
				FormatEx(buffer, sizeof(buffer), "%T", "HUMAN_MENU_ITEM_SHIELDGRENADE", client);
				SS_AddMenuItem(menu, client, "shieldgrenade; 0; 70", buffer, 6, 70, 3);
				FormatEx(buffer, sizeof(buffer), "%T", "HUMAN_MENU_ITEM_MP5GITAR", client);
				SS_AddMenuItem(menu, client, "mp5gitar; 0; 28", buffer, 7, 28, 999);
				FormatEx(buffer, sizeof(buffer), "%T", "HUMAN_MENU_ITEM_ETHEREAL", client);
				SS_AddMenuItem(menu, client, "ethereal; 0; 50", buffer, 8, 50, 999);
				FormatEx(buffer, sizeof(buffer), "%T", "HUMAN_MENU_ITEM_AWP_BUFF", client);
				SS_AddMenuItem(menu, client, "awp_buff; 0; 65", buffer, 9, 65, 999);
				FormatEx(buffer, sizeof(buffer), "%T", "HUMAN_MENU_ITEM_GAUSS", client);
				SS_AddMenuItem(menu, client, "gauss; 0; 40", buffer, 10, 40, 999);
				FormatEx(buffer, sizeof(buffer), "%T", "HUMAN_MENU_ITEM_FROSTGUN", client);
				SS_AddMenuItem(menu, client, "frostgun; 0; 45", buffer, 11, 45, 999);
				FormatEx(buffer, sizeof(buffer), "%T", "HUMAN_MENU_ITEM_M32", client);
				SS_AddMenuItem(menu, client, "m32; 0; 115", buffer, 12, 115, 999);
				FormatEx(buffer, sizeof(buffer), "%T", "HUMAN_MENU_ITEM_LASERFIST", client);
				SS_AddMenuItem(menu, client, "laserfist; 0; 130", buffer, 13, 130, 999);
				FormatEx(buffer, sizeof(buffer), "%T", "HUMAN_MENU_ITEM_THUNDERBOLT", client);
				SS_AddMenuItem(menu, client, "thunderbolt; 0; 370", buffer, 14, 370, 1);
			}
			else
			{
				FormatEx(buffer, sizeof(buffer), "%T", "HUMAN_MENU_ITEM_M249", client);
				SS_AddMenuItem(menu, client, "m249; 0; 20", buffer, 0, 20, 4);
				FormatEx(buffer, sizeof(buffer), "%T", "HUMAN_MENU_ITEM_SG550", client);
				SS_AddMenuItem(menu, client, "sg550; 0; 20", buffer, 1, 20, 4);
				FormatEx(buffer, sizeof(buffer), "%T", "HUMAN_MENU_ITEM_FREEZE", client);
				SS_AddMenuItem(menu, client, "freeze; 0; 35", buffer, 2, 35, 1);
			}
		}
		else // Zombie
		{
			FormatEx(buffer, sizeof(buffer), "%T", "MENU_SHOP_ZOMBIE_TITLE", client);
			menu.SetTitle(buffer);
		
			if (sServerData.IsMapZm)
			{
				if (mode == m_ModeNormal)
				{
					// ...
					FormatEx(buffer, sizeof(buffer), "%T", "ZOMBIE_MENU_ITEM_ANTIDOTE", client);
					SS_AddMenuItem(menu, client, "antidote; 1; 230", buffer, 20, 230, 10, true);
					
					if (VIP_IsClientVIP(client))
					{
						FormatEx(buffer, sizeof(buffer), "%T", "ZOMBIE_MENU_ITEM_CLASSES", client);
						menu.AddItem("zclasses; 1; 0", buffer, ITEMDRAW_DISABLED);
					}
					else
					{
						FormatEx(buffer, sizeof(buffer), "%T", "ZOMBIE_MENU_ITEM_CLASSES", client);
						SS_AddMenuItem(menu, client, "zclasses; 1; 60", buffer, 21, 60, 10);
					}
				}
				else
				{
					FormatEx(buffer, sizeof(buffer), "%T", "ZOMBIE_MENU_ITEM_ANTIDOTE", client);
					menu.AddItem("antidote; 1; 0", buffer, ITEMDRAW_DISABLED);
					FormatEx(buffer, sizeof(buffer), "%T", "ZOMBIE_MENU_ITEM_CLASSES", client);
					menu.AddItem("zclasses; 1; 0", buffer, ITEMDRAW_DISABLED);
				}
				
				ZM_GetClassName(classid, buffer, sizeof(buffer));
				if (strcmp(buffer, "zombie_classic") == 0)
				{
					FormatEx(buffer, sizeof(buffer), "%T", "ZOMBIE_CLASSIN_MENU_ITEM_HP", client);
					SS_AddMenuItem(menu, client, "zhealth; 1; 50", buffer, 22, 50, 2);
				}
				else if (strcmp(buffer, "zombie_invisible") == 0)
				{
					FormatEx(buffer, sizeof(buffer), "%T", "ZOMBIE_INVISIBLE_MENU_ITEM_HP", client);
					SS_AddMenuItem(menu, client, "zhealth; 1; 50", buffer, 22, 50, 1);
				}
				else if (strcmp(buffer, "zombie_tank") == 0)
				{
					FormatEx(buffer, sizeof(buffer), "%T", "ZOMBIE_TANK_MENU_ITEM_HP", client);
					SS_AddMenuItem(menu, client, "zhealth; 1; 35", buffer, 22, 35, 1);
					FormatEx(buffer, sizeof(buffer), "%T", "ZOMBIE_TANK_MENU_ITEM_DMG_SKILL", client);
					SS_AddMenuItem(menu, client, "zskills; 1; 40", buffer, 23, 40, 1);
					FormatEx(buffer, sizeof(buffer), "%T", "ZOMBIE_TANK_MENU_ITEM_TIMER_SKILL", client);
					SS_AddMenuItem(menu, client, "zskills2; 1; 35", buffer, 24, 35, 4);
				}
				else if (strcmp(buffer, "zombie_boomer") == 0)
				{
					FormatEx(buffer, sizeof(buffer), "%T", "ZOMBIE_BOOMER_MENU_ITEM_HP", client);
					SS_AddMenuItem(menu, client, "zhealth; 1; 50", buffer, 22, 50, 1);
					FormatEx(buffer, sizeof(buffer), "%T", "ZOMBIE_BOOMER_MENU_ITEM_DMG_SKILL", client);
					SS_AddMenuItem(menu, client, "zskills; 1; 30", buffer, 23, 30, 2);
					FormatEx(buffer, sizeof(buffer), "%T", "ZOMBIE_BOOMER_MENU_ITEM_DMG_EXPLODE_SKILL", client);
					SS_AddMenuItem(menu, client, "zskills2; 1; 25", buffer, 24, 25, 1);
				}
				else if (strcmp(buffer, "zombie_hunter") == 0)
				{
					FormatEx(buffer, sizeof(buffer), "%T", "ZOMBIE_HUNTER_MENU_ITEM_HP", client);
					SS_AddMenuItem(menu, client, "zhealth; 1; 50", buffer, 22, 50, 1);
					FormatEx(buffer, sizeof(buffer), "%T", "ZOMBIE_HUNTER_MENU_ITEM_JUMP_SKILL", client);
					SS_AddMenuItem(menu, client, "zskills; 1; 40", buffer, 23, 40, 1);
				}
				else if (strcmp(buffer, "zombie_smoker") == 0)
				{
					FormatEx(buffer, sizeof(buffer), "%T", "ZOMBIE_SMOKER_MENU_ITEM_HP", client);
					SS_AddMenuItem(menu, client, "zhealth; 1; 25", buffer, 22, 25, 1);
				}
				else if (strcmp(buffer, "zombie_warden") == 0)
				{
					FormatEx(buffer, sizeof(buffer), "%T", "ZOMBIE_WARDEN_MENU_ITEM_HP", client);
					SS_AddMenuItem(menu, client, "zhealth; 1; 30", buffer, 22, 30, 1);
					FormatEx(buffer, sizeof(buffer), "%T", "ZOMBIE_WARDEN_MENU_ITEM_DMG_SKILL", client);
					SS_AddMenuItem(menu, client, "zskills; 1; 25", buffer, 23, 25, 2);
					FormatEx(buffer, sizeof(buffer), "%T", "ZOMBIE_WARDEN_MENU_ITEM_HEAL_SKILL", client);
					SS_AddMenuItem(menu, client, "zskills2; 1; 25", buffer, 24, 25, 2);
				}
				else if (strcmp(buffer, "zombie_spitter") == 0)
				{
					FormatEx(buffer, sizeof(buffer), "%T", "ZOMBIE_SPITTER_MENU_ITEM_HP", client);
					SS_AddMenuItem(menu, client, "zhealth; 1; 20", buffer, 22, 20, 1);
				}
				else if (strcmp(buffer, "zombie_acidheadcrab") == 0)
				{
					FormatEx(buffer, sizeof(buffer), "%T", "ZOMBIE_ACIDHEADCRAB_MENU_ITEM_HP", client);
					SS_AddMenuItem(menu, client, "zhealth; 1; 35", buffer, 22, 35, 1);
				}
				else if (strcmp(buffer, "zombie_witch") == 0)
				{
					FormatEx(buffer, sizeof(buffer), "%T", "ZOMBIE_WITCH_MENU_ITEM_HP", client);
					SS_AddMenuItem(menu, client, "zhealth; 1; 40", buffer, 22, 40, 1);
				}
			}
			else
			{
				FormatEx(buffer, sizeof(buffer), "%T", "ZOMBIE_CLASSIN_MENU_ITEM_HP", client);
				SS_AddMenuItem(menu, client, "zhealth; 1; 50", buffer, 20, 50, 2);
			}
		}
		
		menu.ExitBackButton = true;
		menu.OptionFlags = MENUFLAG_BUTTON_EXIT|MENUFLAG_BUTTON_EXITBACK;
		menu.Display(client, MENU_TIME_FOREVER);
	}
	return Plugin_Handled;
}

public int MenuHandler_ShopMenu(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
		{
			if (IsValidClient(param1))
			{
				if (ZM_IsClientHuman(param1)) // Human
				{
					Command_Shop(param1, 0);
				}
				else
				{
					ZM_OpenMenuSub(param1, "zshop");
				}
			}
		}
	}
	else if (action == MenuAction_Select)
	{
		if (IsValidClient(param1))
		{
			if (sServerData.RoundEnd)
			{
				EmitSoundToClient(param1, SOUND_BUTTON_MENU);
				return 0;
			}
			
			if (ZM_IsRespawn(param1, 0))
			{
				EmitSoundToClient(param1, SOUND_BUTTON_MENU);
				return 0;
			}
			
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
			
			if (ZM_IsClientHuman(param1))
			{
				if (GetEntitySequence(param1) != 0) {
					EmitSoundToClient(param1, SOUND_BUTTON_MENU);
					return 0;
				}
			}
			
			char info[32]; char buffer[3][34];
			menu.GetItem(param2, info, sizeof(info));
			ExplodeString(info, "; ", buffer, sizeof(buffer), sizeof(buffer[]));
			
			int item = !ZM_IsClientHuman(param1) ? param2 + 20:param2;
			int ammo = SS_MenuItem(param1, item, buffer);
			
			if (ammo == -1)
			{
				return 0;
			}
			
			if (ammo != 0)
			{
				SetClientAmmoPacks(param1, -ammo);
				
				if (item != 21)
				{
					sClientData[param1].PriceUp[item]++;
				}
			}
			else
			{
				OnShopMenuWeapons(param1);
			}
		}
	}
	else if (action == MenuAction_End) {
		delete menu;
	}
	return 0;
}

int SS_MenuItem(int client, int item, const char[][] info)
{
	if (ZM_IsClientHuman(client) == view_as<bool>(StringToInt(info[1])))
	{
		//PrintToChat(client, "\x071E90FF[NextWin Shop] \x07FFFFFF ... #1");
		return 0;
	}
	// char buffer[164];
	
	int price = StringToInt(info[2]);
	if (SetClientPriceUp(client, item, price) > GetClientAmmoPacks(client))
	{
		ZM_PrintToChat(client, _, "%T", "CHAT_NO_AMMOPACKS", client);
		return 0;
	}
	
	int mode = ZM_GetCurrentGameMode();
	
	if (IsPlayerAlive(client))
	{
		if (strcmp(info[0], "antidote") == 0)
		{
			if (mode != m_ModeNormal) {
				return 0;
			}
			
			if (!(GetZombies() > 3))
			{
				ZM_PrintToChat(client, _, "%T", "CHAT_ANTIDOTE_ZOMBIES", client);
				return 0;
			}
			
			ZM_ChangeClient(client, _, -3);
			
			EmitSoundToAll(SOUND_SMALLMEDKIT, client);
			
			float origin[3]; GetClientAbsOrigin(client, origin);
			UTIL_CreateParticle(-2, "nw_player_", "player_humn_1", origin, true);
			// UTIL_ScreenFade(client, 1.0, 0.1, {0, 0, 128, 128}, FFADE_IN);
				
			origin[2] -= 5.0;
			TE_DynamicLight(origin, 0, 0, 255, 2, 1000.0, 1.0, 1000.0);
			TE_SendToAll();
			
			char temp[164];
			KeyValues kv = new KeyValues("Stuff", "title");
			kv.SetColor("color", 0, 255, 255, 255);
			kv.SetNum("level", 1);
			kv.SetNum("time", 1);
			
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsValidClient(i) && !IsFakeClient(i))
				{
					FormatEx(temp, sizeof(temp), "%T", "HUD_ANTIDOTE", i, client);  // cl_showpluginmessages 1
					kv.SetString("title", temp);
					
					CreateDialog(i, kv, DialogType_Msg);
				}
			}
			delete kv;
			
			// CreateTimer(1.0, Timer_ItemPickUp, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
			
			return SetClientPriceUp(client, item, price, true);
			
		}
		// else if (strcmp(info[0], "ammo") == 0)
		// {
		// 	int weapon = GetEntDataEnt2(client, sServerData.ActiveWeapon);
		// 	
		// 	if (IsValidEdict(weapon) && GetEntityClassname(weapon, buffer, sizeof(buffer)))
		// 	{
		// 		if (strcmp(buffer, "weapon_knife") != 0 && strcmp(buffer, "weapon_hegrenade") != 0
		// 		&& strcmp(buffer, "weapon_smokegrenade") != 0 && strcmp(buffer, "weapon_flashbang") != 0)
		// 		{
		// 			if (strcmp(buffer, "weapon_rpg") == 0 || strcmp(buffer, "weapon_m32") == 0 || strcmp(buffer, "weapon_shieldgrenade") == 0
		// 			|| strcmp(buffer, "weapon_gauss") == 0)
		// 			{
		// 				return 0;
		// 			}
		// 			
		// 			int weaponid = ZM_GetWeaponNameID(buffer);
		// 			int i_curAmmo = GetAmmoCount(client, weapon);
		// 			int i_needAmmo = ZM_GetWeaponAmmo(weaponid) - i_curAmmo;
		// 			
		// 			if (i_needAmmo <= 0) {
		// 				return 0;
		// 			}
		// 			
		// 			int m_iCost;
		// 			// if (strcmp(buffer, "weapon_rpg") == 0)
		// 			// 	m_iCost = RoundToCeil(i_needAmmo * 10.0);
		// 			// else if (strcmp(buffer, "weapon_m32") == 0)
		// 			// 	m_iCost = RoundToCeil(i_needAmmo * 3.5);
		// 			// if (strcmp(buffer, "weapon_gauss") == 0)
		// 			// 	m_iCost = RoundToCeil(i_needAmmo * 0.037);
		// 			
		// 			if (strcmp(buffer, "weapon_thunderbolt") == 0)
		// 				m_iCost = RoundToCeil(i_needAmmo * 5.0);
		// 			else if (strcmp(buffer, "weapon_salamander") == 0)
		// 				m_iCost = RoundToCeil(i_needAmmo * 0.0888);
		// 			else if (strcmp(buffer, "weapon_frostgun") == 0)
		// 				m_iCost = RoundToCeil(i_needAmmo * 0.0555);
		// 			else if (strcmp(buffer, "weapon_awp_buff") == 0)
		// 				m_iCost = RoundToCeil(i_needAmmo * 0.7333);
		// 			else m_iCost = RoundToCeil(i_needAmmo * 0.0333);
		// 			
		// 			if (GetClientAmmoPacks(client) < m_iCost)
		// 			{
		// 				ZM_PrintToChat(client, _, "%T", "CHAT_WEAPON_NO_AMMOPACKS", client, (m_iCost - GetClientAmmoPacks(client)));
		// 				return 0;
		// 			}
		// 			
		// 			EmitSoundToAll(SOUND_AMMOPICKUP, client);
		// 			GiveAmmo(client, weapon, i_needAmmo);
		// 			SetClientAmmoPacks(client, -m_iCost);
		// 		}
		// 		else
		// 		{
		// 			ZM_PrintToChat(client, _, "%T", "CHAT_BLOCK_WEAPONS", client);
		// 			return 0;
		// 		}
		// 	}
		// 	else
		// 	{
		// 		ZM_PrintToChat(client, _, "%T", "CHAT_BLOCK_WEAPONS", client);
		// 		return 0;
		// 	}
		// }
		else if (strcmp(info[0], "zhealth") == 0)
		{
			char class[64]; int classhp = 0;
			ZM_GetClassName(ZM_GetClientClass(client), class, sizeof(class));
			
			if (strcmp(class, "zombie_invisible") == 0) classhp = 1000;
			else if (strcmp(class, "zombie_tank") == 0) classhp = 3000;
			else if (strcmp(class, "zombie_boomer") == 0) classhp = 2000;
			else if (strcmp(class, "zombie_hunter") == 0) classhp = 1000;
			else if (strcmp(class, "zombie_smoker") == 0) classhp = 2000;
			else if (strcmp(class, "zombie_warden") == 0) classhp = 2500;
			else if (strcmp(class, "zombie_spitter") == 0) classhp = 2000;
			else if (strcmp(class, "zombie_acidheadcrab") == 0) classhp = 1500;
			else if (strcmp(class, "zombie_witch") == 0) classhp = 1900;
			else classhp = 3000;
			
			SetEntityHealth(client, GetClientHealth(client) + classhp);
			UTIL_ScreenFade(client, 1.0, 0.1, FFADE_IN, {0, 206, 0, 5});
		}
		else if (strcmp(info[0], "zskills") == 0)
		{
			char class[64]; float skill = 0.0;
			ZM_GetClassName(ZM_GetClientClass(client), class, sizeof(class));
			
			if (strcmp(class, "zombie_tank") == 0) skill = GetRandomFloat(0.5, 1.5);
			else if (strcmp(class, "zombie_boomer") == 0) skill = GetRandomFloat(2.0, 3.0);
			else if (strcmp(class, "zombie_warden") == 0) skill = GetRandomFloat(1.0, 2.0);
			else if (strcmp(class, "zombie_hunter") == 0) skill = 100.0;
			
			sClientData[client].ZombieSkills[0] += skill;
			UTIL_ScreenFade(client, 1.0, 0.1, FFADE_IN, {128, 128, 0, 5});
		}
		else if (strcmp(info[0], "zskills2") == 0)
		{
			char class[64]; float skill = 0.0;
			ZM_GetClassName(ZM_GetClientClass(client), class, sizeof(class));
			
			if (strcmp(class, "zombie_tank") == 0) skill = GetRandomFloat(1.2, 1.6);
			else if (strcmp(class, "zombie_boomer") == 0) skill = GetRandomFloat(1.0, 2.0);
			else if (strcmp(class, "zombie_warden") == 0) skill = GetRandomFloat(1.5, 3.5);
			
			sClientData[client].ZombieSkills[1] += skill;
			UTIL_ScreenFade(client, 1.0, 0.1, FFADE_IN, {128, 128, 0, 5});
		}
		else if (strcmp(info[0], "zclasses") == 0)
		{
			if (mode != m_ModeNormal) {
				return 0;
			}
		
			for (int x = 0; x < 30; x++) {
				m_ClassID[client][x] = 0;
			}
			
			// ClassMenu(client, 0);
		}
		else if (strcmp(info[0], "rpg") == 0)
		{
			GivePlayerItem(client, "weapon_rpg");
			// EquipPlayerWeapon(client, index);
		}
		else if (strcmp(info[0], "m249") == 0)
		{
			EmitSoundToAll(SOUND_ITEMICKUP, client);
			int index = GivePlayerItem(client, "weapon_m249");
			EquipPlayerWeapon(client, index);
		}
		else if (strcmp(info[0], "sg550") == 0)
		{
			EmitSoundToAll(SOUND_ITEMICKUP, client);
			int index = GivePlayerItem(client, "weapon_sg550");
			EquipPlayerWeapon(client, index);
		}
		else if (strcmp(info[0], "awp_buff") == 0)
		{
			EmitSoundToAll(SOUND_ITEMICKUP, client);
			int index = GivePlayerItem(client, "weapon_awp_buff");
			EquipPlayerWeapon(client, index);
		}
		else if (strcmp(info[0], "m134") == 0)
		{
			EmitSoundToAll(SOUND_ITEMICKUP, client);
			int index = GivePlayerItem(client, "weapon_m134");
			EquipPlayerWeapon(client, index);
		}
		else if (strcmp(info[0], "ethereal") == 0)
		{
			EmitSoundToAll(SOUND_ITEMICKUP, client);
			int index = GivePlayerItem(client, "weapon_ethereal");
			EquipPlayerWeapon(client, index);
		}
		else if (strcmp(info[0], "dinfinity") == 0)
		{
			EmitSoundToAll(SOUND_ITEMICKUP, client);
			int index = GivePlayerItem(client, "weapon_dinfinity");
			EquipPlayerWeapon(client, index);
		}
		else if (strcmp(info[0], "frostgun") == 0)
		{
			EmitSoundToAll(SOUND_ITEMICKUP, client);
			int index = GivePlayerItem(client, "weapon_frostgun");
			EquipPlayerWeapon(client, index);
		}
		else if (strcmp(info[0], "shieldgrenade") == 0)
		{
			EmitSoundToAll(SOUND_ITEMICKUP, client);
			GivePlayerItem(client, "weapon_shieldgrenade");
		}
		else if (strcmp(info[0], "freeze") == 0)
		{
			EmitSoundToAll(SOUND_ITEMICKUP, client);
			GivePlayerItem(client, "weapon_freeze");
		}
		else if (strcmp(info[0], "tripmine") == 0)
		{
			EmitSoundToAll(SOUND_ITEMICKUP, client);
			GivePlayerItem(client, "weapon_tripmine");
		}
		else if (strcmp(info[0], "gauss") == 0)
		{
			EmitSoundToAll(SOUND_ITEMICKUP, client);
			int index = GivePlayerItem(client, "weapon_gauss");
			EquipPlayerWeapon(client, index);
		}
		else if (strcmp(info[0], "thunderbolt") == 0)
		{
			EmitSoundToAll(SOUND_ITEMICKUP, client);
			int index = GivePlayerItem(client, "weapon_thunderbolt");
			EquipPlayerWeapon(client, index);
		}
		else if (strcmp(info[0], "m32") == 0)
		{
			EmitSoundToAll(SOUND_ITEMICKUP, client);
			int index = GivePlayerItem(client, "weapon_m32");
			EquipPlayerWeapon(client, index);
		}
		else if (strcmp(info[0], "salamander") == 0)
		{
			EmitSoundToAll(SOUND_ITEMICKUP, client);
			int index = GivePlayerItem(client, "weapon_salamander");
			EquipPlayerWeapon(client, index);
		}
		else if (strcmp(info[0], "mp5gitar") == 0)
		{
			EmitSoundToAll(SOUND_ITEMICKUP, client);
			int index = GivePlayerItem(client, "weapon_mp5gitar");
			EquipPlayerWeapon(client, index);
		}
		else if (strcmp(info[0], "laserfist") == 0)
		{
			EmitSoundToAll(SOUND_ITEMICKUP, client);
			int index = GivePlayerItem(client, "weapon_laserfist");
			EquipPlayerWeapon(client, index);
		}
		else return 0;
	}
	else
	{
		if (strcmp(info[0], "zclasses") == 0)
		{
			if (mode != m_ModeNormal) {
				return 0;
			}
		
			for (int x = 0; x < 30; x++) {
				m_ClassID[client][x] = 0;
			}
			
			// ClassMenu(client, 0);
		}
		else return 0;
	}
	return SetClientPriceUp(client, item, price);
}

stock void GiveAmmo(int client, int weapon, int ammo)
{
	int AmmoType = GetEntData(weapon, sServerData.ammoTypeOffset);
	
	if (AmmoType != -1)
	{
		int i = GetWeaponAmmo(client, AmmoType);
		SetWeaponAmmo(client, AmmoType, i+ammo);
	}
}

stock int GetAmmoCount(int client, int weapon)
{
	int AmmoType = GetEntData(weapon, sServerData.ammoTypeOffset);
	
	if (AmmoType != -1)
	{
		return GetEntData(client, sServerData.ammoOffset + (AmmoType * 4));
	}
	return 0;
}

stock int GetWeaponAmmo(int client, int slot)
{
    return GetEntData(client, sServerData.ammoOffset + (slot * 4));
}  

stock void SetWeaponAmmo(int client, int slot, int ammo)
{
	SetEntData(client, sServerData.ammoOffset + (slot * 4), ammo);
}

stock int GetZombies()
{
	int count;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i) && ZM_IsClientZombie(i))
		{  
			count++;
		}
	}
	return count;
}

void SS_AddMenuItem(Menu menu, int client, const char[] info, const char[] name, int item, int price, int x, bool s = false)
{
	char buffer[264];
	
	if (price != 0)
	{
		if (x != 0)
		{
			int up = SetClientPriceUp(client, item, price, s);
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

int SetClientPriceUp(int client, int item, int price, bool s = false)
{
	if (s == true)
	{
		return price * (sClientData[client].PriceUp[item] + 1) + RoundToCeil(100.0 * (GetGameTime() - GameRules_GetPropFloat("m_fRoundStartTime") + ZM_GetRoundTime()) * 0.01);
	}
	return price * (sClientData[client].PriceUp[item] + 1);
}