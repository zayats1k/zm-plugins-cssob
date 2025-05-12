void CostumesMenuOnInit()
{
	HookConVarChange(sCvarList.COSTUMES_MENU_COMMANDS, Hook_OnCvarMenuCostumes);
	
	CostumesOnCvarLoad();
}

public void Hook_OnCvarMenuCostumes(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (strcmp(oldValue, newValue, false) != 0)
	{
		CostumesOnCvarLoad();
	}
}

void CostumesOnCvarLoad()
{
	AddConVarCommand(sCvarList.COSTUMES_MENU_COMMANDS, Command_CostumesMenu);
}

public Action Command_CostumesMenu(int client, int args)
{
	char commands[2];
	sCvarList.COSTUMES_MENU_COMMANDS.GetString(commands, sizeof(commands));
	ReplaceString(commands, sizeof(commands), " ", "");
	if (!hasLength(commands)) {
		return Plugin_Continue;
	}

	if (IsValidClient(client))
	{
		CostumesMenu(client);
	}
	return Plugin_Handled;
}

void CostumesMenu(int client)
{
	static char buffer[NORMAL_LINE_LENGTH], name[SMALL_LINE_LENGTH], info[SMALL_LINE_LENGTH];

	Menu menu = new Menu(CostumesMenuSlots);
	
	SetGlobalTransTarget(client);
	
	menu.SetTitle("%t", "costumes menu");
	
	FormatEx(buffer, sizeof(buffer), "%t", "costumes remove");
	menu.AddItem("-1", buffer, MenusGetItemDraw(sClientData[client].Costume != -1));
	
	if (ToolsLookupAttachment(client, "forward"))
	{
		int lvl = GetClientLevel(client);
		
		bool enabled = false;
		int level;
		
		for (int i = 0; i < sServerData.Costumes.Length; i++)
		{
			CostumesGetName(i, name, sizeof(name));
			CostumesGetGroup(i, info, sizeof(info));
			level = CostumesGetLevel(i);
			
			enabled = false;
			if (!COSTUMES_VIP_LEVEL(client, i, info))
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
		
			IntToString(i, info, sizeof(info));
			menu.AddItem(info, buffer, MenusGetItemDraw(enabled && sClientData[client].Costume != i));
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

public int CostumesMenuSlots(Menu menu, MenuAction action, int client, int slot)
{
	switch (action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Cancel:
		{
			if (slot == MenuCancel_ExitBack)
			{
				if (!IsValidClient(client))
				{
					return 0;
				}
				
				int id[2]; id = MenusCommandToArray("zcostume");
				if (id[0] != -1) SubMenu(client, id[0]);
			}
		}
		case MenuAction_Select:
		{
			if (!IsValidClient(client))
			{
				return 0;
			}
			
			static char buffer[SMALL_LINE_LENGTH];
			menu.GetItem(slot, buffer, sizeof(buffer));
			int id = StringToInt(buffer);
			
			switch (id)
			{
				case -1:
				{
					CostumesRemove(client);
					
					sClientData[client].Costume = -1;
					sServerData.CookieCostume.Set(client, "");
				}
				default:
				{
					sClientData[client].Costume = id;
					
					CostumesGetName(id, buffer, sizeof(buffer));
					sServerData.CookieCostume.Set(client, buffer);
					
					CostumesCreateEntity(client);
				}
			}
		}
	}
	return 0;
}