public Action Command_Transfer(int client, int args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "Usage transfer <Old AccountID> to <New AccountID>");
		return Plugin_Handled;
	}
	
	char accountID1[32], accountID2[32];
	
	DataPack data = new DataPack();
	
	data.WriteCell(GetClientUserId(client));
	
	GetCmdArg(1, accountID1, sizeof(accountID1));
	int aid1 = StringToInt(accountID1);
	data.WriteCell(aid1);
	
	GetCmdArg(2, accountID2, sizeof(accountID2));
	int aid2 = StringToInt(accountID2);
	data.WriteCell(aid2);
	
	static char buffer[512];
	sServerData.Database.Format(buffer, sizeof(buffer), "SELECT * FROM `zm_core` WHERE `aid` = '%d'", aid1);
	sServerData.Database.Query(DB_SelectTransferCallback, buffer, data);
	
	CreateForward_OnClientTransfer(client, aid1, aid2);
	return Plugin_Handled;
}

public void DB_SelectTransferCallback(Database db, DBResultSet results, const char[] error, DataPack data)
{
	data.Reset();
	int client = GetClientOfUserId(data.ReadCell());
	int accountID1 = data.ReadCell();
	int accountID2 = data.ReadCell();
	delete data;
	
	if (db == null || results == null || error[0])
	{
		LogError("DB_SelectTransferCallback: %s", error);
		return;
	}
	
	char buffer[512];
	if (results.FetchRow())
	{
		data = new DataPack();
		data.WriteCell(GetClientUserId(client));
		data.WriteCell(results.FetchInt(2)); // 2, Level
		data.WriteCell(results.FetchInt(3)); // 3, Exp
		data.WriteCell(results.FetchInt(4)); // 4, AmmoPacks
		data.WriteCell(results.FetchInt(5)); // 5, Kills
		data.WriteCell(results.FetchInt(6)); // 6, Deaths
		data.WriteCell(results.FetchInt(7)); // 7, Infects
		data.WriteCell(results.FetchInt(8)); // 8, Infected
		data.WriteCell(results.FetchInt(9)); // 9, boss
		data.WriteCell(results.FetchInt(10)); // 10, bosskills
		data.WriteCell(results.FetchInt(11)); // 11, time
		data.WriteCell(results.FetchInt(12)); // 12, PlayTime
		data.WriteCell(results.FetchInt(13)); // 13, timestamp
		data.WriteCell(accountID1);
		data.WriteCell(accountID2);
		
		sServerData.Database.Format(buffer, sizeof(buffer), "SELECT * FROM `zm_core` WHERE `aid` = '%d'", accountID2);
		sServerData.Database.Query(DB_SelectTransfer2Callback, buffer, data);
	}
	else
	{
		PrintToChat(client, "[ZM.TRANSFER.ERROR] Not Found AccountID1: %d", accountID1);
		UTIL_LogToFile("zm_database", "[ZM.TRANSFER.ERROR] Not Found AccountID1: %d", accountID1);
	}
}

public void DB_SelectTransfer2Callback(Database db, DBResultSet results, const char[] error, DataPack data)
{
	data.Reset();
	int client = GetClientOfUserId(data.ReadCell());
	int Level = data.ReadCell(); // 2, Level
	int Exp = data.ReadCell(); // 3, Exp
	int AmmoPacks = data.ReadCell(); // 4, AmmoPacks
	int Kills = data.ReadCell(); // 5, Kills
	int Deaths = data.ReadCell(); // 6, Deaths
	int Infects = data.ReadCell(); // 7, Infects
	int Infected = data.ReadCell(); // 8, Infected
	int boss = data.ReadCell(); // 9, boss
	int bosskills = data.ReadCell(); // 10, bosskills
	int Time = data.ReadCell(); // 11, time
	int PlayTime = data.ReadCell(); // 12, PlayTime
	int timestamp = data.ReadCell(); // 13, timestamp
	int accountID1 = data.ReadCell();
	int accountID2 = data.ReadCell();
	delete data;
	
	if (db == null || results == null || error[0])
	{
		LogError("DB_SelectTransfer2Callback: %s", error);
		return;
	}
	
	char buffer[512];
	if (results.FetchRow())
	{
		int Level2 = results.FetchInt(2);  // 2, Level
		int Exp2 = results.FetchInt(3); // 3, Exp
		int AmmoPacks2 = results.FetchInt(4); // 4, AmmoPacks
		int Kills2 = results.FetchInt(5); // 5, Kills
		int Deaths2 = results.FetchInt(6); // 6, Deaths
		int Infects2 = results.FetchInt(7); // 7, Infects
		int Infected2 = results.FetchInt(8); // 8, Infected
		int boss2 = results.FetchInt(9); // 9, boss
		int bosskills2 = results.FetchInt(10); // 10, bosskills
		int Time2 = results.FetchInt(11); // 11, time
		int PlayTime2 = results.FetchInt(12); // 12, PlayTime
		int timestamp2 = results.FetchInt(13); // 13, timestamp
		
		sServerData.Database.Format(buffer, sizeof(buffer), "UPDATE `zm_core` SET \
		`lvl` = %d, `exp` = %d, `ammopacks` = %d, `kills` = %d, `deaths` = %d, `infects` = %d, `Infected` = %d, `boss` = %d, `bosskills` = %d, `offlinetime` = %d, `playtime` = %d, `timestamp` = %d WHERE `aid` = %d;",
		Level2, Exp2, AmmoPacks2, Kills2, Deaths2, Infects2, Infected2, boss2, bosskills2, Time2, PlayTime2, timestamp2, accountID1);
		sServerData.Database.Query(DB_UpdateCallback, buffer, _, DBPrio_Low);
		
		sServerData.Database.Format(buffer, sizeof(buffer), "UPDATE `zm_core` SET \
		`lvl` = %d, `exp` = %d, `ammopacks` = %d, `kills` = %d, `deaths` = %d, `infects` = %d, `Infected` = %d, `boss` = %d, `bosskills` = %d, `offlinetime` = %d, `playtime` = %d, `timestamp` = %d WHERE `aid` = %d;",
		Level, Exp, AmmoPacks, Kills, Deaths, Infects, Infected, boss, bosskills, Time, PlayTime, timestamp, accountID2);
		sServerData.Database.Query(DB_UpdateCallback, buffer, _, DBPrio_Low);
		
		int target = GetPlayerOnline(accountID1);
		if (IsValidClient(target) && !IsFakeClient(target))
		{
			sClientData[target].Level = Level2; // 2, Level
			sClientData[target].Exp = Exp2; // 3, Exp
			sClientData[target].AmmoPacks = AmmoPacks2; // 4, AmmoPacks
			sClientData[target].Kills = Kills2; // 5, Kills
			sClientData[target].Deaths = Deaths2; // 6, Deaths
			sClientData[target].Infects = Infects2; // 7, Infects
			sClientData[target].Infected = Infected2; // 8, Infected
			sClientData[target].boss = boss2; // 9, boss
			sClientData[target].bosskills = bosskills2; // 10, bosskills
			sClientData[target].PlayTime = PlayTime2; // 12, PlayTime
			
			// if (HS_GetClientCookie(target, 4) == 3)
			// {
			// 	SetEntProp(target, Prop_Send, "m_iAccount", sClientData[target].AmmoPacks);
			// }
			
			DB_CheckCallbackRankPlace(target);
		}
	
		int target2 = GetPlayerOnline(accountID2);
		if (IsValidClient(target2) && !IsFakeClient(target2))
		{
			sClientData[target2].Level = Level; // 2, Level
			sClientData[target2].Exp = Exp; // 3, Exp
			sClientData[target2].AmmoPacks = AmmoPacks; // 4, AmmoPacks
			sClientData[target2].Kills = Kills; // 5, Kills
			sClientData[target2].Deaths = Deaths; // 6, Deaths
			sClientData[target2].Infects = Infects; // 7, Infects
			sClientData[target2].Infected = Infected; // 8, Infected
			sClientData[target2].boss = boss; // 9, boss
			sClientData[target2].bosskills = bosskills; // 10, bosskills
			sClientData[target2].PlayTime = PlayTime; // 12, PlayTime
			
			// if (HS_GetClientCookie(target2, 4) == 3)
			// {
			// 	SetEntProp(target2, Prop_Send, "m_iAccount", sClientData[target2].AmmoPacks);
			// }
			
			DB_CheckCallbackRankPlace(target2);
		}
		
		PrintToChat(client, "[ZM] Transfer AccountID1: %d to AccountID2: %d", accountID1, accountID2);
		UTIL_LogToFile("zm_database", "[ZM.TRANSFER] Transfer AccountID1: %d to AccountID2: %d", accountID1, accountID2);
	}
	else
	{
		PrintToChat(client, "[ZM.TRANSFER.ERROR] Not Found AccountID2: %d", accountID2);
		UTIL_LogToFile("zm_database", "[ZM.TRANSFER.ERROR] Not Found AccountID2: %d", accountID2);
	}
}