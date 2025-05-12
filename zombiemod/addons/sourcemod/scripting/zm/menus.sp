enum
{
	MENUS_DATA_NAME,
	MENUS_DATA_GROUP,
	MENUS_DATA_GROUP_FLAGS,
	MENUS_DATA_COMMAND,
	MENUS_DATA_SUBMENU
};

void MenusOnInit()
{
	HookConVarChange(sCvarList.MENU_COMMANDS, Hook_OnCvarMenus);
	
	MenusOnCvarLoad();
}

public void Hook_OnCvarMenus(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (strcmp(oldValue, newValue, false) != 0)
	{
		MenusOnCvarLoad();
	}
}

void MenusOnCvarLoad()
{
	AddConVarCommand(sCvarList.MENU_COMMANDS, Command_MainMenu);
}

void MenusOnLoad()
{
	static char buffer[PLATFORM_LINE_LENGTH];
	ConfigRegisterConfig(File_Menus, Structure_KeyValue, CONFIG_FILE_ALIAS_MENUS);
	
	if (!ConfigGetFullPath(CONFIG_FILE_ALIAS_MENUS, buffer, sizeof(buffer)))
	{
		LogError("[Menus] [Config Validation] Missing menus config file: \"%s\"", buffer);
		return;
	}
	
	ConfigSetConfigPath(File_Menus, buffer);
	
	if (!ConfigLoadConfig(File_Menus, sServerData.Menus, SMALL_LINE_LENGTH))
	{
		LogError("[Menus] [Config Validation] Unexpected error encountered loading: \"%s\"", buffer);
		return;
	}
	
	if (sServerData.Menus == null)
	{
		LogError("[Menus] [Config Validation] Invalid Handle 0 (error: 4)");
		LogError("[Menus] [Config Validation] server restart");
		return;
	}
	
	MenusOnCacheData();
	
	ConfigSetConfigLoaded(File_Menus, true);
	ConfigSetConfigReloadFunc(File_Menus, GetFunctionByName(GetMyHandle(), "MenusOnConfigReload"));
	ConfigSetConfigHandle(File_Menus, sServerData.Menus);
}

void MenusOnCacheData()
{
	static char buffer[PLATFORM_LINE_LENGTH];
	ConfigGetConfigPath(File_Menus, buffer, sizeof(buffer));

	KeyValues kv;
	if (!ConfigOpenConfigFile(File_Menus, kv))
	{
		LogError("[Menus] [Config Validation] Unexpected error caching data from menus config file: \"%s\"", buffer);
		return;
	}

	int size = sServerData.Menus.Length;
	if (!size)
	{
		LogError("[Menus] [Config Validation] No usable data found in menus config file: \"%s\"", buffer);
		return;
	}
	
	for (int i = 0; i < size; i++)
	{
		MenusGetName(i, buffer, sizeof(buffer)); // Index: 0
		
		kv.Rewind();
		if (!kv.JumpToKey(buffer))
		{
			SetFailState("[Menus] [Config Validation] Couldn't cache menu data for: \"%s\" (check menus config)", buffer);
			continue;
		}
		
		if (!TranslationIsPhraseExists(buffer))
		{
			SetFailState("[Menus] [Config Validation] Couldn't cache menu name: \"%s\" (check translation file)", buffer);
		}
		
		ArrayList array = sServerData.Menus.Get(i);
		kv.GetString("group", buffer, sizeof(buffer), "");  
		array.PushString(buffer); // Index: 1
		array.Push(ConfigGetAdmFlags(buffer)); // Index: 2
		kv.GetString("command", buffer, sizeof(buffer), "");
		array.PushString(buffer); // Index: 3
		
		if (kv.JumpToKey("submenu")) // Index: 4
		{
			if (kv.GotoFirstSubKey())
			{
				do
				{
					kv.GetSectionName(buffer, sizeof(buffer));
					
					if (!TranslationIsPhraseExists(buffer))
					{
						SetFailState("[Menus] [Config Validation] Couldn't cache submenu name: \"%s\" (check translation file)", buffer);
						continue;
					}

					array.PushString(buffer); // Index: i + 0
					kv.GetString("group", buffer, sizeof(buffer), "");       
					array.PushString(buffer); // Index: i + 1
					array.Push(ConfigGetAdmFlags(buffer)); // Index: i + 2
					kv.GetString("command", buffer, sizeof(buffer), "");
					array.PushString(buffer); // Index: i + 3
				}
				while (kv.GotoNextKey());
			}
			
			kv.GoBack();
			kv.GoBack();
		}
	}

	delete kv;
}

public void MenusOnConfigReload()
{
	MenusOnLoad();
}

void MenusGetName(int id, char[] name, int naxLen, int subMenu = 0)
{
	ArrayList array = sServerData.Menus.Get(id);
	array.GetString(MENUS_DATA_NAME + subMenu, name, naxLen);
}

void MenusGetGroup(int id, char[] group, int naxLen, int subMenu = 0)
{
	ArrayList array = sServerData.Menus.Get(id);
	array.GetString(MENUS_DATA_GROUP + subMenu, group, naxLen);
}

int MenusGetGroupFlags(int id, int subMenu = 0)
{
	ArrayList array = sServerData.Menus.Get(id);
	return array.Get(MENUS_DATA_GROUP_FLAGS + subMenu);
}

void MenusGetCommand(int id, char[] cmd, int naxLen, int subMenu = 0)
{
	ArrayList array = sServerData.Menus.Get(id);
	array.GetString(MENUS_DATA_COMMAND + subMenu, cmd, naxLen);
}

public Action Command_MainMenu(int client, int args)
{
	char commands[2];
	sCvarList.MENU_COMMANDS.GetString(commands, sizeof(commands));
	ReplaceString(commands, sizeof(commands), " ", "");
	if (!hasLength(commands)) {
		return Plugin_Continue;
	}

	if (IsValidClient(client))
	{
		static char buffer[NORMAL_LINE_LENGTH], name[SMALL_LINE_LENGTH], info[SMALL_LINE_LENGTH];
		Menu menu = new Menu(MenuHandler_MainMenu);
		
		SetGlobalTransTarget(client);
		menu.SetTitle("%t", "main menu");
		
		for (int i = 0; i < sServerData.Menus.Length; i++)
		{
			MenusGetName(i, name, sizeof(name));
			MenusGetGroup(i, info, sizeof(info));
			
			bool bMissGroup = IsClientGroup(client, MenusGetGroupFlags(i), info);
		
			if (bMissGroup)
			{
				FormatEx(buffer, sizeof(buffer), "%t%t", name, "menu group", info);
			}
			else
			{
				FormatEx(buffer, sizeof(buffer), "%t", name);
			}
			
			IntToString(i, info, sizeof(info));
			menu.AddItem(info, buffer, MenusGetItemDraw(!bMissGroup));
		}
		
		if (!menu.ItemCount)
		{
			FormatEx(buffer, sizeof(buffer), "%t", "menu empty");
			menu.AddItem("empty", buffer, ITEMDRAW_DISABLED);
		}
		
		menu.ExitButton = true;
		menu.OptionFlags = MENUFLAG_BUTTON_EXIT;
		menu.Display(client, MENU_TIME_FOREVER); 
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public int MenuHandler_MainMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if (IsValidClient(param1))
			{
				static char buffer[SMALL_LINE_LENGTH];
				menu.GetItem(param2, buffer, sizeof(buffer));
				int id = StringToInt(buffer);
				
				MenusGetCommand(id, buffer, sizeof(buffer));
				if (hasLength(buffer))
				{
					FakeClientCommand(param1, buffer);
				}
				else
				{
					SubMenu(param1, id);
				}
			}
		}
		case MenuAction_End: delete menu;
	}
	return 0;
}

void SubMenu(int client, int id)
{
	ArrayList array = sServerData.Menus.Get(id);

	int size = array.Length;
	if (!(size - MENUS_DATA_SUBMENU))
	{
		Command_MainMenu(client, 0);
		return;
	}
	
	static char buffer[NORMAL_LINE_LENGTH], name[SMALL_LINE_LENGTH], info[SMALL_LINE_LENGTH];
	MenusGetName(id, buffer, sizeof(buffer));
	Menu menu = new Menu(MenuHandler_SubMenu);
	
	SetGlobalTransTarget(client);
	menu.SetTitle("%t", buffer);
	
	for (int i = MENUS_DATA_SUBMENU; i < size; i += MENUS_DATA_SUBMENU)
	{
		MenusGetName(id, name, sizeof(name), i);
		MenusGetGroup(id, info, sizeof(info), i);
		
		bool bMissGroup = IsClientGroup(client, MenusGetGroupFlags(id, i), info);

		if (bMissGroup)
		{
			FormatEx(buffer, sizeof(buffer), "%t%t", name, "menu group", info);
		}
		else
		{
			FormatEx(buffer, sizeof(buffer), "%t", name);
		}

		FormatEx(info, sizeof(info), "%d %d", id, i);
		menu.AddItem(info, buffer, MenusGetItemDraw(!bMissGroup));
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

public int MenuHandler_SubMenu(Menu menu, MenuAction mAction, int client, int mSlot)
{
	switch (mAction)
	{
		case MenuAction_Cancel:
		{
			if (mSlot == MenuCancel_ExitBack)
			{
				if (IsValidClient(client))
				{
					Command_MainMenu(client, 0);
				}
			}
		}
		case MenuAction_Select:
		{
			if (IsValidClient(client))
			{
				static char buffer[SMALL_LINE_LENGTH];
				menu.GetItem(mSlot, buffer, sizeof(buffer));
				static char info[2][SMALL_LINE_LENGTH];
				ExplodeString(buffer, " ", info, sizeof(info), sizeof(info[]));
				int id = StringToInt(info[0]); int i = StringToInt(info[1]);
				
				MenusGetCommand(id, buffer, sizeof(buffer), i);
				
				if (hasLength(buffer))
				{
					FakeClientCommand(client, buffer);
				}
			}
		}
		case MenuAction_End: delete menu;
	}
	return 0;
}

void MenusOnNativeInit() 
{
	CreateNative("ZM_OpenMenuSub", Native_OpenMenuSub);
}

public int Native_OpenMenuSub(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if (!UTIL_ValidateClient(client)) {
		return -1;
	}
	
	static char command[SMALL_LINE_LENGTH];
	GetNativeString(2, command, sizeof(command));
	static int id[2]; id = MenusCommandToArray(command);
	
	if (id[0] != -1)
	{
		SubMenu(client, id[0]);
	}
	return 0;
}

int[] MenusCommandToArray(const char[] command)
{
	static char MenuCommand[SMALL_LINE_LENGTH];
	int id[2] = {-1, 0};
	
	for (int i = 0; i < sServerData.Menus.Length; i++)
	{
		ArrayList arrayMenu = sServerData.Menus.Get(i);
		for (int x = 0; x < arrayMenu.Length; x += MENUS_DATA_SUBMENU)
		{
			MenusGetCommand(i, MenuCommand, sizeof(MenuCommand), x);
			
			if (!strcmp(command, MenuCommand, false))
			{
				id[0] = i; id[1] = x;
				return id;
			}
		}
	}
	
	return id;
}

int MenusGetItemDraw(bool condition)
{
	return condition ? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED;
}