public Action Command_Top(int client, int args)
{
	if (IsValidClient(client) && sClientData[client].AccountID)
	{
		char buffer[512];
		if (args == 1)
		{
			GetCmdArg(1, buffer, sizeof(buffer));
		}
	
		DataPack dp = new DataPack();
		dp.WriteString(buffer);
		dp.WriteCell(client);
		
		sServerData.Database.Format(buffer, sizeof(buffer), "SELECT `aid`, `name`, `lvl`, `playtime` FROM `zm_core` ORDER BY `exp` DESC LIMIT 30000");
		sServerData.Database.Query(DB_SelectTopCallback, buffer, dp);
	}
	return Plugin_Handled;
}

public void DB_SelectTopCallback(Database db, DBResultSet results, const char[] error, DataPack dp)
{
	dp.Reset();

	static char buffer2[64];
	dp.ReadString(buffer2, sizeof(buffer2));
	int client = dp.ReadCell();
	delete dp;
	
	if (db == null || results == null || error[0])
	{
		LogError("DB_SelectTopCallback: %s", error);
		return;
	}

	if (IsValidClient(client))
	{
		char buffer[264], name[64], AccountId[32];
		
		Menu menu = new Menu(MenuHandler_Top);
		
		SetGlobalTransTarget(client);
		
		int aid, lvl;
		for (int i = 0; i < results.RowCount; i++)
		{
			results.FetchRow();
			
			aid = results.FetchInt(0);
			results.FetchString(1, name, sizeof(name));
			lvl = results.FetchInt(2);
			
			if (results.FetchInt(3) < 1)
			{
				continue;
			}
			if (StrContains(name, buffer2, true) != 0)
			{
				continue;
			}
			
			FormatEx(buffer, sizeof(buffer), "%t", "MENU_TOP_PLAYER_LEVEL", name, lvl-1);
			IntToString(aid, AccountId ,sizeof(AccountId));
			menu.AddItem(AccountId, buffer);
		}
		
		if (menu.ItemCount == 0)
		{
			menu.AddItem("", "[ Empty ]", ITEMDRAW_DISABLED);
		}
		
		FormatEx(buffer, sizeof(buffer), "%t", "MENU_TOP", sServerData.CntPeople);
		menu.SetTitle(buffer);
		
		menu.ExitBackButton = true;
		menu.OptionFlags = MENUFLAG_BUTTON_EXIT|MENUFLAG_BUTTON_EXITBACK;
		menu.Display(client, MENU_TIME_FOREVER);
	}
}

public int MenuHandler_Top(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
		{
			if (IsValidClient(param1))
			{
				ZM_OpenMenuSub(param1, "top");
			}
		}
	}
	else if (action == MenuAction_Select)
	{
		char info[64];
		menu.GetItem(param2, info, sizeof(info));
		int aid = StringToInt(info);
		
		if (aid != sClientData[param1].AccountID)
		{
			char query[512];
			sServerData.Database.Format(query, sizeof(query), "SELECT * FROM `zm_core` WHERE `aid` = %d", aid);
			sServerData.Database.Query(DB_SelectRankCallback, query, param1);
		}
		else
		{
			Command_Rank(param1, 0);
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public void DB_SelectRankCallback(Database db, DBResultSet results, const char[] error, int client)
{
	if (db == null || results == null || error[0])
	{
		LogError("DB_SelectRankCallback: %s", error);
		return;
	}

	if (IsValidClient(client))
	{
		if (results.FetchRow())
		{
			char buffer[500], PlayerName[64], buffer2[64], buffer4[64];
			char CommasAmmoPacks[16], CommasExp[16], CommasExpUp[16], CommasKills[16], CommasDeaths[16], CommasInfects[16], CommasInfected[16], Commasboss[16], Commasbosskills[16];
			
			int aid = results.FetchInt(0); // 2, aid
			results.FetchString(1, PlayerName, sizeof(PlayerName)); // 1, name
			
			SetGlobalTransTarget(client);
			
			int target = GetPlayerOnline(aid);
			if (IsValidClient(target) && !IsFakeClient(target) && sClientData[target].Loaded)
			{
				GetClientName(target, PlayerName, sizeof(PlayerName));
				UTIL_AddCommas(sClientData[target].AmmoPacks, CommasAmmoPacks, sizeof(CommasAmmoPacks));
				UTIL_AddCommas(sClientData[target].Exp, CommasExp, sizeof(CommasExp));
				UTIL_AddCommas(GetClientExpUp(target), CommasExpUp, sizeof(CommasExpUp));
				UTIL_AddCommas(sClientData[target].Kills, CommasKills, sizeof(CommasKills));
				UTIL_AddCommas(sClientData[target].Deaths, CommasDeaths, sizeof(CommasDeaths));
				UTIL_AddCommas(sClientData[target].Infects, CommasInfects, sizeof(CommasInfects));
				UTIL_AddCommas(sClientData[target].Infected, CommasInfected, sizeof(CommasInfected));
				UTIL_AddCommas(sClientData[target].boss, Commasboss, sizeof(Commasboss));
				UTIL_AddCommas(sClientData[target].bosskills, Commasbosskills, sizeof(Commasbosskills));
				
				SecondsToTime(sClientData[target].PlayTime, buffer2, sizeof(buffer2), target);
				FormatEx(buffer, sizeof(buffer), "%t\n%t\n%t%t\n%t%t\n%t%t\n%t%t\n%t",
				"MENU_RANK_PLAYER", PlayerName,
				"MENU_RANK_AMMOPACKS", CommasAmmoPacks,
				"MENU_RANK_LEVEL", sClientData[target].Level-1,
				"MENU_RANK_EXP", CommasExp, CommasExpUp,
				"MENU_RANK_KILLS", CommasKills,
				"MENU_RANK_DEATHS", CommasDeaths,
				"MENU_RANK_INFECTS", CommasInfects,
				"MENU_RANK_INFECTED", CommasInfected,
				"MENU_RANK_BOSSKILLS", Commasbosskills,
				"MENU_RANK_BOSS", Commasboss,
				"MENU_RANK_PLAYTIME", buffer2);
			}
			else
			{
				int Level = results.FetchInt(2); // 2, Level
				UTIL_AddCommas(results.FetchInt(3), CommasExp, sizeof(CommasExp)); // 3, Exp
				UTIL_AddCommas(GetExpUp(Level), CommasExpUp, sizeof(CommasExpUp));
				UTIL_AddCommas(results.FetchInt(4), CommasAmmoPacks, sizeof(CommasAmmoPacks)); // 4, AmmoPacks
				UTIL_AddCommas(results.FetchInt(5), CommasKills, sizeof(CommasKills)); // 5, Kills
				UTIL_AddCommas(results.FetchInt(6), CommasDeaths, sizeof(CommasDeaths)); // 6, Deaths
				UTIL_AddCommas(results.FetchInt(7), CommasInfects, sizeof(CommasInfects)); // 7, Infects
				UTIL_AddCommas(results.FetchInt(8), CommasInfected, sizeof(CommasInfected)); // 8, Infected
				UTIL_AddCommas(results.FetchInt(9), Commasboss, sizeof(Commasboss)); // 9, boss
				UTIL_AddCommas(results.FetchInt(10), Commasbosskills, sizeof(Commasbosskills)); // 10, bosskills
				
				int Time = GetTime() - results.FetchInt(11); // 11, Time
				int PlayTime = results.FetchInt(12); // 12, PlayTime
				
				SecondsToTime(PlayTime, buffer2, sizeof(buffer2), client);
				SecondsToTime(Time, buffer4, sizeof(buffer4), client);
				
				FormatEx(buffer, sizeof(buffer), "%t\n%t\n%t%t\n%t%t\n%t%t\n%t%t\n%t\n%t",
				"MENU_RANK_PLAYER", PlayerName,
				"MENU_RANK_AMMOPACKS", CommasAmmoPacks,
				"MENU_RANK_LEVEL", Level-1,
				"MENU_RANK_EXP", CommasExp, CommasExpUp,
				"MENU_RANK_KILLS", CommasKills,
				"MENU_RANK_DEATHS", CommasDeaths,
				"MENU_RANK_INFECTS", CommasInfects,
				"MENU_RANK_INFECTED", CommasInfected,
				"MENU_RANK_BOSSKILLS", Commasbosskills,
				"MENU_RANK_BOSS", Commasboss,
				"MENU_RANK_PLAYTIME", buffer2,
				"MENU_RANK_OFFLINETIME", buffer4);
			}
			
			Panel panel = new Panel();
			panel.SetTitle(buffer);
			panel.DrawText(" ");
			
			panel.CurrentKey = 8;
			FormatEx(buffer, sizeof(buffer), "%t", "MENU_BACK");
			panel.DrawItem(buffer);
			
			panel.CurrentKey = 10;
			FormatEx(buffer, sizeof(buffer), "%t", "MENU_EXIT");
			panel.DrawItem(buffer);
		
			panel.Send(client, MenuHandler_Rank, MENU_TIME_FOREVER);
			delete panel;
		}
	}
}

public Action Command_Rank(int client, int args)
{
	if (IsValidClient(client) && sClientData[client].AccountID)
	{
		char buffer[500], name[64], buffer2[64];
		
		Panel panel = new Panel();
		
		GetClientName(client, name, sizeof(name));
		
		SecondsToTime(sClientData[client].PlayTime, buffer2, sizeof(buffer2), client);
		
		char CommasAmmoPacks[16], CommasExp[16], CommasExpUp[16], CommasKills[16], CommasDeaths[16], CommasInfects[16], CommasInfected[16], Commasboss[16], Commasbosskills[16];
		UTIL_AddCommas(sClientData[client].AmmoPacks, CommasAmmoPacks, sizeof(CommasAmmoPacks));
		UTIL_AddCommas(sClientData[client].Exp, CommasExp, sizeof(CommasExp));
		UTIL_AddCommas(GetClientExpUp(client), CommasExpUp, sizeof(CommasExpUp));
		UTIL_AddCommas(sClientData[client].Kills, CommasKills, sizeof(CommasKills));
		UTIL_AddCommas(sClientData[client].Deaths, CommasDeaths, sizeof(CommasDeaths));
		UTIL_AddCommas(sClientData[client].Infects, CommasInfects, sizeof(CommasInfects));
		UTIL_AddCommas(sClientData[client].Infected, CommasInfected, sizeof(CommasInfected));
		UTIL_AddCommas(sClientData[client].boss, Commasboss, sizeof(Commasboss));
		UTIL_AddCommas(sClientData[client].bosskills, Commasbosskills, sizeof(Commasbosskills));
				
		SetGlobalTransTarget(client);
		FormatEx(buffer, sizeof(buffer), "%t\n%t\n%t\n%t%t\n%t%t\n%t%t\n%t%t\n%t",
		"MENU_RANK_PLAYER", name,
		"MENU_RANK_PLACE", sClientData[client].RankPlace, sServerData.CntPeople,
		"MENU_RANK_AMMOPACKS", CommasAmmoPacks,
		"MENU_RANK_LEVEL", sClientData[client].Level-1,
		"MENU_RANK_EXP", CommasExp, CommasExpUp,
		"MENU_RANK_KILLS", CommasKills,
		"MENU_RANK_DEATHS", CommasDeaths,
		"MENU_RANK_INFECTS", CommasInfects,
		"MENU_RANK_INFECTED", CommasInfected,
		"MENU_RANK_BOSSKILLS", Commasbosskills,
		"MENU_RANK_BOSS", Commasboss,
		"MENU_RANK_PLAYTIME", buffer2);
		
		panel.SetTitle(buffer);
		panel.DrawText(" ");
	
		panel.CurrentKey = 8;
		FormatEx(buffer, sizeof(buffer), "%t", "MENU_BACK");
		panel.DrawItem(buffer);
	
		panel.CurrentKey = 10;
		FormatEx(buffer, sizeof(buffer), "%t", "MENU_EXIT");
		panel.DrawItem(buffer);
		
		panel.Send(client, MenuHandler_Rank, MENU_TIME_FOREVER);
		delete panel;
	}
	return Plugin_Handled;
}

public int MenuHandler_Rank(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select || param2 == 10)
	{
		if (param2 == 8)
		{
			Command_Top(param1, 0);
		}
	}
	return 0;
}