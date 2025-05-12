enum
{
	ADMINS_DATA_NAME,
	ADMINS_DATA_ACCESS,
	ADMINS_DATA_CLASSES,
	ADMINS_DATA_TELEPORT,
	ADMINS_DATA_MODES
};

void AdminsOnLoad()
{
	static char buffer[PLATFORM_LINE_LENGTH];
	ConfigRegisterConfig(File_Admins, Structure_KeyValue, CONFIG_FILE_ALIAS_ADMINS);
	
	if (!ConfigGetFullPath(CONFIG_FILE_ALIAS_ADMINS, buffer, sizeof(buffer)))
	{
		LogError("[Admins] [Config Validation] Missing admins config file: \"%s\"", buffer);
		return;
	}
	
	ConfigSetConfigPath(File_Admins, buffer);
	
	if (!ConfigLoadConfig(File_Admins, sServerData.Admins, SMALL_LINE_LENGTH))
	{
		LogError("[Admins] [Config Validation] Unexpected error encountered loading: \"%s\"", buffer);
		return;
	}
	
	if (sServerData.Admins == null)
	{
		LogError("[Admins] [Config Validation] Invalid Handle 0 (error: 4)");
		LogError("[Admins] [Config Validation] server restart");
		return;
	}
	
	AdminsOnCacheData();
	
	ConfigSetConfigLoaded(File_Admins, true);
	ConfigSetConfigReloadFunc(File_Admins, GetFunctionByName(GetMyHandle(), "AdminsOnConfigReload"));
	ConfigSetConfigHandle(File_Admins, sServerData.Admins);
}

void AdminsOnCacheData()
{
	static char buffer[PLATFORM_LINE_LENGTH];
	ConfigGetConfigPath(File_Admins, buffer, sizeof(buffer));

	KeyValues kv;
	if (!ConfigOpenConfigFile(File_Admins, kv))
	{
		LogError("[Admins] [Config Validation] Unexpected error caching data from admins config file: \"%s\"", buffer);
		return;
	}

	int size = sServerData.Admins.Length;
	if (!size)
	{
		LogError("[Admins] [Config Validation] No usable data found in admins config file: \"%s\"", buffer);
		return;
	}
	
	for (int i = 0; i < size; i++)
	{
		AdminsGetName(i, buffer, sizeof(buffer)); // Index: 0
		
		kv.Rewind();
		if (!kv.JumpToKey(buffer))
		{
			continue;
		}
		
		ArrayList array = sServerData.Admins.Get(i);
		array.Push(kv.GetNum("access", 0)); // Index: 1
		array.Push(kv.GetNum("classes", 0)); // Index: 2
		array.Push(kv.GetNum("teleport", 0)); // Index: 3
		array.Push(kv.GetNum("modes", 0)); // Index: 4
	}
	delete kv;
}

public void AdminsOnConfigReload()
{
	AdminsOnLoad();
}

void AdminsGetName(int id, char[] name, int naxLen)
{
	ArrayList array = sServerData.Admins.Get(id);
	array.GetString(ADMINS_DATA_NAME, name, naxLen);
}

bool AdminsIsAccess(int client, int type)
{
	static char steamid[SMALL_LINE_LENGTH], steamid2[SMALL_LINE_LENGTH];
	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	
	for (int i = 0; i < sServerData.Admins.Length; i++)
	{
		AdminsGetName(i, steamid2, sizeof(steamid2));
		
		if (strcmp(steamid, steamid2, false) == 0)
		{
			ArrayList array = sServerData.Admins.Get(i);
			return view_as<bool>(array.Get(type));
		}
	}
	return false;
}

void AdminsOnInit()
{
	RegConsoleCmd("zadmin", Command_Zadmin);
	
	RegConsoleCmd("zm_class_menu", Command_ClassMenu);
	RegConsoleCmd("zm_teleport_menu", Command_TeleportMenu);
	RegConsoleCmd("zm_mode_menu", Command_ModesMenu);
}

public Action Command_Zadmin(int client, int args)
{
	if (IsValidClient(client))
	{
		if (!AdminsIsAccess(client, ADMINS_DATA_ACCESS))
		{
			TranslationPrintToChat(client, "no access");
			return Plugin_Handled;
		}
	
		static char buffer[NORMAL_LINE_LENGTH];
	
		Menu menu = new Menu(MenuHandler_ZAdminMenu);
		
		SetGlobalTransTarget(client);
		
		FormatEx(buffer, sizeof(buffer), "%t", "zadmin main title");
		menu.SetTitle(buffer);
		
		FormatEx(buffer, sizeof(buffer), "%t", "zadmin main modes");
		menu.AddItem("modes", buffer, MenusGetItemDraw(AdminsIsAccess(client, ADMINS_DATA_MODES)));
		
		FormatEx(buffer, sizeof(buffer), "%t", "zadmin main classes");
		menu.AddItem("classes", buffer, MenusGetItemDraw(AdminsIsAccess(client, ADMINS_DATA_CLASSES)));
		
		FormatEx(buffer, sizeof(buffer), "%t", "zadmin main force teleport");
		menu.AddItem("Teleport", buffer, MenusGetItemDraw(AdminsIsAccess(client, ADMINS_DATA_TELEPORT)));
		
		menu.Display(client, MENU_TIME_FOREVER);
	}
	return Plugin_Handled;
}

public int MenuHandler_ZAdminMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				if (!IsValidClient(param1))
				{
					return 0;
				}
				
				int id[2]; id = MenusCommandToArray("zm_class_menu");
				if (id[0] != -1) SubMenu(param1, id[0]);
			}
		}
		case MenuAction_Select:
		{
			if (!IsValidClient(param1))
			{
				return 0;
			}
			
			switch(param2)
			{
				case 0: // modes
				{
					DisplayModesMenu(param1);
				}
				case 1: // classes
				{
					DisplayClassesMenu(param1);
				}
				case 2: // teleport
				{
					DisplayTeleportMenu(param1);
				}
			}
		}
	}
	return 0;
}
//////////////////////////////////////////////////////////
public Action Command_ClassMenu(int client, int args)
{
	if (IsValidClient(client))
	{
		if (!AdminsIsAccess(client, ADMINS_DATA_CLASSES))
		{
			TranslationPrintToChat(client, "no access");
			return Plugin_Handled;
		}
	
		DisplayClassesMenu(client);
	}
	return Plugin_Handled;
}

void DisplayClassesMenu(int client, int item = 0)
{
	if (!sServerData.RoundStart)
	{
		TranslationPrintToChat(client, "block classes round");
		EmitSoundToClient(client, SOUND_BUTTON_MENU_ERROR);
		return;
	}

	static char buffer[NORMAL_LINE_LENGTH], type[SMALL_LINE_LENGTH], info[SMALL_LINE_LENGTH];

	Menu menu = new Menu(MenuHandler_ClassesMenu);
	SetGlobalTransTarget(client);
	
	FormatEx(buffer, sizeof(buffer), "%t:\n ", "zadmin main classes");
	menu.SetTitle(buffer);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && GetClientTeam(i) > CS_TEAM_SPECTATOR)
		{
			sServerData.Types.GetString(ClassGetType(sClientData[i].Class), type, sizeof(type));
			
			FormatEx(buffer, sizeof(buffer), "%N [%t]", i, IsPlayerAlive(i) ? type : "dead");
	
			IntToString(GetClientUserId(i), info, sizeof(info));
			menu.AddItem(info, buffer);
		}
	}
	
	if (!menu.ItemCount)
	{
		FormatEx(buffer, sizeof(buffer), "%t", "menu empty");
		menu.AddItem("empty", buffer, ITEMDRAW_DISABLED);
	}
	
	menu.ExitBackButton = true;
	menu.OptionFlags = MENUFLAG_BUTTON_EXIT | MENUFLAG_BUTTON_EXITBACK;
	menu.DisplayAt(client, item, MENU_TIME_FOREVER);
}

public int MenuHandler_ClassesMenu(Menu menu, MenuAction action, int param1, int param2)
{   
	switch (action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				if (!IsValidClient(param1))
				{
					return 0;
				}
			
				Command_Zadmin(param1, 0);
			}
		}
		case MenuAction_Select:
		{
			if (!IsValidClient(param1))
			{
				return 0;
			}

			if (!sServerData.RoundStart)
			{
				DisplayClassesMenu(param1, menu.Selection);
				
				TranslationPrintToChat(param1, "block using menu");
				EmitSoundToClient(param1, SOUND_BUTTON_MENU_ERROR);
				return 0;
			}
			
			static char buffer[SMALL_LINE_LENGTH];
			menu.GetItem(param2, buffer, sizeof(buffer));
			int target = GetClientOfUserId(StringToInt(buffer));
			
			if (target && GetClientTeam(target) > CS_TEAM_SPECTATOR)
			{
				if (!IsPlayerAlive(target))
				{
					ToolsForceToRespawn(target);
				}
				else
				{
					DisplayClassesOptionMenu(param1, target);
					return 0;
				}
			}
			else
			{
				TranslationPrintToChat(param1, "block selecting target");
				
				EmitSoundToClient(param1, SOUND_BUTTON_MENU_ERROR);
			}
			
			DisplayClassesMenu(param1, menu.Selection);
		}
	}
	return 0;
}

void DisplayClassesOptionMenu(int client, int target)
{
	static char buffer[NORMAL_LINE_LENGTH], type[SMALL_LINE_LENGTH], info[SMALL_LINE_LENGTH];
	
	Menu menu = new Menu(MenuHandler_ClassesListMenu);
	
	SetGlobalTransTarget(client);
	
	menu.SetTitle("%N\n ", target);
	
	int size = sServerData.Types.Length;
	for (int i = 0; i < size; i++)
	{
		sServerData.Types.GetString(i, type, sizeof(type));
		
		FormatEx(buffer, sizeof(buffer), "%t", type);
		FormatEx(info, sizeof(info), "%d %d", i, GetClientUserId(target));
		menu.AddItem(info, buffer, (ClassGetType(sClientData[target].Class) != i) ? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	}
	
	if (!size)
	{
		FormatEx(buffer, sizeof(buffer), "%t", "menu empty");
		menu.AddItem("empty", buffer, ITEMDRAW_DISABLED);
	}
	
	menu.ExitBackButton = true;
	menu.OptionFlags = MENUFLAG_BUTTON_EXIT|MENUFLAG_BUTTON_EXITBACK;
	menu.Display(client, MENU_TIME_FOREVER); 
}   

public int MenuHandler_ClassesListMenu(Menu menu, MenuAction action, int param1, int param2)
{   
	switch (action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				if (!IsValidClient(param1))
				{
					return 0;
				}
				
				DisplayClassesMenu(param1);
			}
		}
		case MenuAction_Select:
		{
			if (!IsValidClient(param1))
			{
				return 0;
			}
			
			if (!sServerData.RoundEnd)
			{
				// OnRoundInfected();
				
				static char buffer[SMALL_LINE_LENGTH], info[2][SMALL_LINE_LENGTH];
				menu.GetItem(param2, buffer, sizeof(buffer));
				ExplodeString(buffer, " ", info, sizeof(info), sizeof(info[]));
				int id = StringToInt(info[0]); int target = GetClientOfUserId(StringToInt(info[1]));
	
				if (target && IsPlayerAlive(target))
				{
					UTIL_LogToFile("zm_core", "[Classes] Admin: \"%L\", Player: \"%L\" (Class: %d)", param1, target, id);
					ApplyOnClientUpdate(target, _, id, false);
				}
				else
				{
					TranslationPrintToChat(param1, "block selecting target");
					EmitSoundToClient(param1, SOUND_BUTTON_MENU_ERROR);
				}
			}
			else
			{
				EmitSoundToClient(param1, SOUND_BUTTON_MENU_ERROR);
			}
			
			DisplayClassesMenu(param1);
		}
	}
	return 0;
}
//////////////////////////////////////////////////////////
public Action Command_TeleportMenu(int client, int args)
{
	if (IsValidClient(client))
	{
		if (!AdminsIsAccess(client, ADMINS_DATA_TELEPORT))
		{
			TranslationPrintToChat(client, "no access");
			return Plugin_Handled;
		}
	
		DisplayTeleportMenu(client);
	}
	return Plugin_Handled;
}

void DisplayTeleportMenu(int client, int item = 0)
{
	static char buffer[NORMAL_LINE_LENGTH], type[SMALL_LINE_LENGTH], info[SMALL_LINE_LENGTH];

	Menu menu = new Menu(MenuHandler_TeleportMenu);
	SetGlobalTransTarget(client);
	
	FormatEx(buffer, sizeof(buffer), "%t:\n ", "zadmin main force teleport");
	menu.SetTitle(buffer);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i))
		{
			sServerData.Types.GetString(ClassGetType(sClientData[i].Class), type, sizeof(type));
			
			FormatEx(buffer, sizeof(buffer), "%N [%t]", i, type);
	
			IntToString(GetClientUserId(i), info, sizeof(info));
			menu.AddItem(info, buffer);
		}
	}
	
	if (!menu.ItemCount)
	{
		FormatEx(buffer, sizeof(buffer), "%t", "menu empty");
		menu.AddItem("empty", buffer, ITEMDRAW_DISABLED);
	}
	
	menu.ExitBackButton = true;
	menu.OptionFlags = MENUFLAG_BUTTON_EXIT | MENUFLAG_BUTTON_EXITBACK;
	menu.DisplayAt(client, item, MENU_TIME_FOREVER);
}

public int MenuHandler_TeleportMenu(Menu menu, MenuAction action, int param1, int param2)
{   
	switch (action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				if (!IsValidClient(param1))
				{
					return 0;
				}
				
				Command_Zadmin(param1, 0);
			}
		}
		case MenuAction_Select:
		{
			if (!IsValidClient(param1))
			{
				return 0;
			}

			if (!sServerData.RoundEnd)
			{
				static char buffer[SMALL_LINE_LENGTH];
				menu.GetItem(param2, buffer, sizeof(buffer));
				int target = GetClientOfUserId(StringToInt(buffer));
				
				if (target && IsPlayerAlive(target))
				{
					GetClientName(target, buffer, sizeof(buffer));
					
					if (TeleportClient(target, true))
					{
						TranslationPrintToChat(param1, "teleport command force successful", buffer);
					}
					else
					{
						TranslationPrintToChat(param1, "teleport command force unsuccessful", buffer);
					}
				}
				else
				{
					TranslationPrintToChat(param1, "block selecting target");
					EmitSoundToClient(param1, SOUND_BUTTON_MENU_ERROR);
				}
			}
			else
			{
				EmitSoundToClient(param1, SOUND_BUTTON_MENU_ERROR); 
			}
			
			DisplayTeleportMenu(param1, menu.Selection);
		}
	}
	return 0;
}

//////////////////////////////////////////////////////////
public Action Command_ModesMenu(int client, int args)
{
	if (IsValidClient(client))
	{
		if (!AdminsIsAccess(client, ADMINS_DATA_MODES))
		{
			TranslationPrintToChat(client, "no access");
			return Plugin_Handled;
		}
	
		DisplayModesMenu(client);
	}
	return Plugin_Handled;
}

void DisplayModesMenu(int client, int item = 0, int target = -1)
{
	if (!sServerData.RoundNew)
	{
		TranslationPrintToChat(client, "block starting round");     

		EmitSoundToClient(client, SOUND_BUTTON_MENU_ERROR);
		return;
	}

	static char buffer[NORMAL_LINE_LENGTH], name[SMALL_LINE_LENGTH], info[SMALL_LINE_LENGTH];
	int alive = fnGetAlive();

	Menu menu = new Menu(MenuHandler_ModesMenu);
	
	SetGlobalTransTarget(client);
	
	FormatEx(buffer, sizeof(buffer), "%t:\n ", "zadmin main modes");
	menu.SetTitle(buffer);
	
	if (target != -1)
		FormatEx(buffer, sizeof(buffer), "%N\n \n", target);
	else FormatEx(buffer, sizeof(buffer), "%t\n \n", "menu empty");
	menu.AddItem("-1 -1", buffer);
	
	for (int i = 0; i < sServerData.GameModes.Length; i++)
	{
		ModesGetName(i, name, sizeof(name));
		int minplayer = ModesGetMinPlayers(i);
		
		bool enabled = false;
		
		if (alive < minplayer)
		{
			FormatEx(buffer, sizeof(buffer), "%t%t", name, "menu online", minplayer);
		}
		else
		{
			FormatEx(buffer, sizeof(buffer), "%t", name);
			enabled = true;
		}

		FormatEx(info, sizeof(info), "%d %d", i, (target == -1) ? -1:GetClientUserId(target));
		menu.AddItem(info, buffer, MenusGetItemDraw(enabled));
	}
	
	if (!menu.ItemCount)
	{
		FormatEx(buffer, sizeof(buffer), "%t", "menu empty");
		menu.AddItem("empty", buffer, ITEMDRAW_DISABLED);
	}
	
	menu.ExitBackButton = true;
	menu.OptionFlags = MENUFLAG_BUTTON_EXIT | MENUFLAG_BUTTON_EXITBACK;
	menu.DisplayAt(client, item, MENU_TIME_FOREVER);
}

public int MenuHandler_ModesMenu(Menu menu, MenuAction action, int param1, int param2)
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
				
				Command_Zadmin(param1, 0);
			}
		}
		case MenuAction_Select:
		{
			if (!IsValidClient(param1)) {
				return 0;
			}
			
			if (!sServerData.RoundNew)
			{
				TranslationPrintToChat(param1, "block starting round");
				EmitSoundToClient(param1, SOUND_BUTTON_MENU_ERROR);
				return 0;
			}
			
			static char buffer[SMALL_LINE_LENGTH], info[2][SMALL_LINE_LENGTH];
			menu.GetItem(param2, buffer, sizeof(buffer));
			ExplodeString(buffer, " ", info, sizeof(info), sizeof(info[]));
			int id = StringToInt(info[0]); int target = StringToInt(info[1]);
			
			if (target != -1)
			{
				target = GetClientOfUserId(target);
				
				if (!target || !IsPlayerAlive(target))
				{
					TranslationPrintToChat(param1, "block selecting target");
				
					DisplayModesMenu(param1, menu.Selection);
					EmitSoundToClient(param1, SOUND_BUTTON_MENU_ERROR);    
					return 0;
				}
			}
			
			if (id == -1)
			{
				ModesOptionMenu(param1);
				return 0;
			}
			
			if (target != -1)
				UTIL_LogToFile("zm_core", "[GameModes] Admin: \"%L\", Player: \"%L\" (mode: %d)", param1, target, id);
			else UTIL_LogToFile("zm_core", "[GameModes] Admin: \"%L\", Player: \"unknown\" (mode: %d)", param1, id);
			
			ZombieModOnBegin(id, target);
		}
	}
	return 0;
}

void ModesOptionMenu(int client)
{
	static char buffer[NORMAL_LINE_LENGTH], info[SMALL_LINE_LENGTH];
	
	Menu menu = new Menu(MenuHandler_ModesListMenu);

	SetGlobalTransTarget(client);
	
	menu.SetTitle("%t", "zadmin modes option");

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i))
		{
			FormatEx(buffer, sizeof(buffer), "%N", i);
		
			IntToString(GetClientUserId(i), info, sizeof(info));
			menu.AddItem(info, buffer);
		}
	}
	
	if (!menu.ItemCount)
	{
		FormatEx(buffer, sizeof(buffer), "%t", "menu empty");
		menu.AddItem("empty", buffer, ITEMDRAW_DISABLED);
	}
	
	menu.ExitBackButton = true;
	menu.OptionFlags = MENUFLAG_BUTTON_EXIT | MENUFLAG_BUTTON_EXITBACK;
	menu.Display(client, MENU_TIME_FOREVER); 
}

public int MenuHandler_ModesListMenu(Menu menu, MenuAction action, int param1, int param2)
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
			
				DisplayModesMenu(param1);
			}
		}
		case MenuAction_Select:
		{
			if (!IsValidClient(param1)) {
				return 0;
			}
			
			static char buffer[SMALL_LINE_LENGTH];
			menu.GetItem(param2, buffer, sizeof(buffer));
			int target = GetClientOfUserId(StringToInt(buffer));

			if (target && IsPlayerAlive(target))
			{
				DisplayModesMenu(param1, _, target);
				return 0;
			}
			
			TranslationPrintToChat(param1, "block selecting target");
			
			ModesOptionMenu(param1);
			EmitSoundToClient(param1, SOUND_BUTTON_MENU_ERROR); 
		}
	}
	return 0;
}