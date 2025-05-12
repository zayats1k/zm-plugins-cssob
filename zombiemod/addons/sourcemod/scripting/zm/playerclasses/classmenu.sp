void ClassMenuOnInit()
{
	HookConVarChange(sCvarList.CLASSES_MENU_COMMANDS_HUMAN, Hook_OnCvarMenuClass);
	HookConVarChange(sCvarList.CLASSES_MENU_COMMANDS_ZOMBIE, Hook_OnCvarMenuClass);
	
	ClassOnCvarLoad();
}

public void Hook_OnCvarMenuClass(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (strcmp(oldValue, newValue, false) != 0)
	{
		ClassOnCvarLoad();
	}
}

void ClassOnCvarLoad()
{
	AddConVarCommand(sCvarList.CLASSES_MENU_COMMANDS_HUMAN, Command_HumanClass);
	AddConVarCommand(sCvarList.CLASSES_MENU_COMMANDS_ZOMBIE, Command_ZombieClass);
}

public Action Command_HumanClass(int client, int args)
{
	char commands[2];
	sCvarList.CLASSES_MENU_COMMANDS_HUMAN.GetString(commands, sizeof(commands));
	ReplaceString(commands, sizeof(commands), " ", "");
	if (!hasLength(commands)) {
		return Plugin_Continue;
	}

	ClassClientMenu(client, "choose humanclass", sServerData.Human, sClientData[client].HumanClassNext);
	return Plugin_Handled;
}

public Action Command_ZombieClass(int client, int args)
{
	char commands[2];
	sCvarList.CLASSES_MENU_COMMANDS_ZOMBIE.GetString(commands, sizeof(commands));
	ReplaceString(commands, sizeof(commands), " ", "");
	if (!hasLength(commands)) {
		return Plugin_Continue;
	}

	ClassClientMenu(client, "choose zombieclass", sServerData.Zombie, sClientData[client].ZombieClassNext);
	return Plugin_Handled;
}

void ClassClientMenu(int client, const char[] title, int type, int class) 
{
	if (IsValidClient(client))
	{
		static char buffer[PLATFORM_LINE_LENGTH], name[SMALL_LINE_LENGTH], group[SMALL_LINE_LENGTH], info[SMALL_LINE_LENGTH];
		Menu menu = new Menu(type == sServerData.Zombie ? ClassZombieMenuSlots1:ClassHumanMenuSlots1);
		
		SetGlobalTransTarget(client);
		menu.SetTitle("%t", title);
		int lvl = GetClientLevel(client);
		
		Action result; bool enabled = false; int level = 0;
		for (int i = 0; i < sServerData.Classes.Length; i++)
		{
			if (ClassGetType(i) != type)
			{
				continue;
			}
			
			sForwardData._OnClientValidateClass(client, i, result);
			if (result == Plugin_Stop)
			{
				continue;
			}
			
			ClassGetName(i, name, sizeof(name));
			ClassGetDescription(i, info, sizeof(info));
			ClassGetGroup(i, group, sizeof(group));
			level = ClassGetLevel(i);
			
			enabled = false;
			if (!CLASS_VIP_LEVEL(client, i, group))
			{
				enabled = true;
			}
			
			if (hasLength(group))
			{
				if (level <= lvl || enabled)
				{
					if (hasLength(info))
						FormatEx(buffer, sizeof(buffer), "%t%t\n%t", name, group, info);
					else FormatEx(buffer, sizeof(buffer), "%t%t", name, group);
				}
				else
				{
					if (hasLength(info))
						FormatEx(buffer, sizeof(buffer), "%t%t%t\n%t", name, group, "menu level", level, info);
					else FormatEx(buffer, sizeof(buffer), "%t%t%t", name, group, "menu level", level);
				}
			}
			else
			{
				if (level <= lvl || enabled)
				{
					if (hasLength(info))
						FormatEx(buffer, sizeof(buffer), "%t\n%t", name, info);
					else FormatEx(buffer, sizeof(buffer), "%t", name);
				}
				else
				{
					if (hasLength(info))
						FormatEx(buffer, sizeof(buffer), "%t%t\n%t", name, "menu level", level, info);
					else FormatEx(buffer, sizeof(buffer), "%t%t", name, "menu level", level);
				}
			}
			
			IntToString(i, info, sizeof(info));
			menu.AddItem(info, buffer, (enabled && result != Plugin_Handled && class != i) ? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
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
}

public int ClassZombieMenuSlots1(Menu menu, MenuAction action, int param1, int param2)
{
   return ClassMenuSlots(menu, action, param1, param2, "zzombie");
}

public int ClassHumanMenuSlots1(Menu menu, MenuAction action, int param1, int param2)
{
   return ClassMenuSlots(menu, action, param1, param2, "zhuman");
}

int ClassMenuSlots(Menu menu, MenuAction action, int param1, int param2, const char[] command)
{
	switch (action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				if (IsValidClient(param1))
				{
					int id[2]; id = MenusCommandToArray(command);
					if (id[0] != -1) SubMenu(param1, id[0]);
				}
			}
		}
		case MenuAction_Select:
		{
			if (IsValidClient(param1))
			{
				static char buffer[SMALL_LINE_LENGTH];
				menu.GetItem(param2, buffer, sizeof(buffer));
				int id = StringToInt(buffer);
				int type = ClassGetType(id);
				
				Action result;
				sForwardData._OnClientValidateClass(param1, id, result);
				if (result == Plugin_Continue || result == Plugin_Changed)
				{
					if (type == sServerData.Human)
					{
						sClientData[param1].HumanClassNext = id;
						CookiesSetInt(param1, sCvarList.CLASSES_RANDOM_HUMAN.IntValue, sServerData.ClassCookieHuman, id);
					}
					else if (type == sServerData.Zombie)
					{
						sClientData[param1].ZombieClassNext = id;
						CookiesSetInt(param1, sCvarList.CLASSES_RANDOM_ZOMBIE.IntValue, sServerData.ClassCookieZombie, id);
					}
					else
					{
						EmitSoundToClient(param1, SOUND_BUTTON_MENU_ERROR);
						return 0;
					}
					
					ClassGetInfo(id, buffer, sizeof(buffer));
					if (hasLength(buffer)) TranslationPrintToChat(param1, buffer);
				}
			}
		}
	}
	return 0;
}

void HumanValidateClass(int client)
{
	int ClassRandom = sCvarList.CLASSES_RANDOM_HUMAN.IntValue;
	int class = ClassValidateIndex(client, ClassRandom, sServerData.Human);
	
	switch (class)
	{
		case -2: LogError("[Classes] [Config Validation] Couldn't cache any default \"human\" class");
		case -1: { }
		default:
		{
			sClientData[client].HumanClassNext = class;
			sClientData[client].Class = class;
			CookiesSetInt(client, ClassRandom, sServerData.ClassCookieHuman, class);
		}
	}
}

void ZombieValidateClass(int client)
{
	int ClassRandom = sCvarList.CLASSES_RANDOM_ZOMBIE.IntValue;
	int class = ClassValidateIndex(client, ClassRandom, sServerData.Zombie);
	
	switch (class)
	{
		case -2: LogError("[Classes] [Config Validation] Couldn't cache any default \"zombie\" class");
		case -1: { }
		default:
		{
			sClientData[client].ZombieClassNext = class;
			sClientData[client].Class = class;
			CookiesSetInt(client, ClassRandom, sServerData.ClassCookieZombie, class);
		}
	}
}

int ClassValidateIndex(int client, int ClassRandom, int type)
{
	if (sServerData.Classes == null) {
		return -1;
	}

	int size = sServerData.Classes.Length;

	if (ClassRandom == 1)
	{
		if (size > sClientData[client].Class)
		{
			int id = ClassTypeToRandomClassIndex(type);
			if (id != -1)
			{
				return id;
			}
			return -2;
		}
		return -1;
	}
	
	if (IsFakeClient(client) || size <= sClientData[client].Class)
	{
		int id = ClassTypeToRandomClassIndex(type);
		if (id == -1) return -2;
		sClientData[client].Class = id;
	}
	
	Action result; static char group[SMALL_LINE_LENGTH];
	sForwardData._OnClientValidateClass(client, sClientData[client].Class, result);
	ClassGetGroup(sClientData[client].Class, group, sizeof(group));
	
	if (result != Plugin_Continue && result != Plugin_Stop || CLASS_VIP_LEVEL(client, sClientData[client].Class, group) || ClassGetType(sClientData[client].Class) != type)
	{
		for (int i = 0; i < size; i++)
		{
			sForwardData._OnClientValidateClass(client, i, result);
			if (result != Plugin_Continue && result != Plugin_Stop)
			{
				continue;
			}
			
			ClassGetGroup(i, group, sizeof(group));
			if (CLASS_VIP_LEVEL(client, i, group))
			{
				continue;
			}
			
			if (ClassGetType(i) != type)
			{
				continue;
			}
			
			return i;
		}
	}
	else return -1;
	return -2;
}

bool CLASS_VIP_LEVEL(int client, int id, const char[] group)
{
	if (ClassGetLevel(id) != 0)
	{
		if (ClassGetLevel(id) <= GetClientLevel(client))
		{
			return false;
		}
	
		if (group[0] && VIP_IsClientVIP(client))
		{
			if (!IsClientGroup(client, ClassGetGroupFlags(id), group))
			{
				return false;
			}
		}
		
		return true;
	}
	else if (group[0] && IsClientGroup(client, ClassGetGroupFlags(id), group))
	{
		return true;
	}
	return false;
}