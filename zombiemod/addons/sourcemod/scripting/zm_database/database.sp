public void DBConnect(Database db, const char[] error, any data)
{
	if (db == null || error[0])
	{
		LogError("DBConnect: %s", error);
		return;
	}
	
	sServerData.Database = db;
	
	// `aid` INTEGER UNIQUE NOT NULL,
	// `aid` INTEGER PRIMARY KEY,
	
	char driver[8];
	sServerData.Database.Driver.GetIdentifier(driver, sizeof(driver));
	if (strcmp(driver, "mysql", false) == 0)
	{
		sServerData.Database.Query(DB_CreateTableCallback, "CREATE TABLE IF NOT EXISTS `zm_core` (\ 
				`aid` int(11) NOT NULL, \
				`name` varchar(64) NOT NULL DEFAULT 'unknown', \
				`lvl` int(11) NOT NULL DEFAULT 1, \
				`exp` int(11) NOT NULL DEFAULT 0, \
				`ammopacks` int(11) NOT NULL DEFAULT 500, \
				`kills` int(11) NOT NULL DEFAULT 0, \
				`deaths` int(11) NOT NULL DEFAULT 0, \
				`infects` int(11) NOT NULL DEFAULT 0, \
				`Infected` int(11) NOT NULL DEFAULT 0, \
				`boss` int(11) NOT NULL DEFAULT 0, \
				`bosskills` int(11) NOT NULL DEFAULT 0, \
				`offlinetime` int(11) NOT NULL DEFAULT 0, \
				`playtime` int(11) NOT NULL DEFAULT 0, \
				`timestamp` int(11) NOT NULL DEFAULT 0, \
				PRIMARY KEY(`aid`), \
				UNIQUE KEY `aid` (`aid`));", _, DBPrio_High);
				
				// SQL_SetCharset(sServerData.Database, "utf8"); // test
	}
	else
	{
		sServerData.Database.Query(DB_CreateTableCallback, "CREATE TABLE IF NOT EXISTS `zm_core` (\ 
				`aid` INTEGER NOT NULL UNIQUE, \
				`name` TEXT NOT NULL DEFAULT 'unknown', \
				`lvl` INTEGER NOT NULL DEFAULT 1, \
				`exp` INTEGER NOT NULL DEFAULT 0, \
				`ammopacks` INTEGER NOT NULL DEFAULT 500, \
				`kills` INTEGER NOT NULL DEFAULT 0, \
				`deaths` INTEGER NOT NULL DEFAULT 0, \
				`infects` INTEGER NOT NULL DEFAULT 0, \
				`Infected` INTEGER NOT NULL DEFAULT 0, \
				`boss` INTEGER NOT NULL DEFAULT 0, \
				`bosskills` INTEGER NOT NULL DEFAULT 0, \
				`offlinetime` INTEGER NOT NULL DEFAULT 0, \
				`playtime` INTEGER NOT NULL DEFAULT 0, \
				`timestamp` INTEGER NOT NULL DEFAULT 0, \
				PRIMARY KEY(`aid`));", _, DBPrio_High);
	}
}

public void DB_CreateTableCallback(Database db, DBResultSet results, const char[] error, any data)
{
	if (db == null || error[0])
	{
		LogError("DB_CreateTableCallback: %s", error);
		return;
	}
	
	for (int i = 1; i <= MaxClients; ++i)
	{
		OnClientPostAdminCheck(i);
	}
}

public void DB_SelectCallback(Database db, DBResultSet results, const char[] error, int userid)
{
	if (db == null || results == null || error[0])
	{
		LogError("DB_SelectCallback: %s", error);
		return;
	}
	int client = GetClientOfUserId(userid);

	if (IsValidClient(client) && !IsClientSourceTV(client))
	{
		static char buffer[512], PlayerName[64];
		GetClientName(client, buffer, sizeof(buffer));
		bool row = results.FetchRow();
		
		if (row)
		{
			results.FetchString(1, PlayerName, sizeof(PlayerName)); // 1, name
			
			sClientData[client].Level = results.FetchInt(2); // 2, Level
			sClientData[client].Exp = results.FetchInt(3); // 3, Exp
			sClientData[client].AmmoPacks = results.FetchInt(4); // 4, AmmoPacks
			sClientData[client].Kills = results.FetchInt(5); // 5, Kills
			sClientData[client].Deaths = results.FetchInt(6); // 6, Deaths
			sClientData[client].Infects = results.FetchInt(7); // 7, Infects
			sClientData[client].Infected = results.FetchInt(8); // 8, Infected
			sClientData[client].boss = results.FetchInt(9); // 9, boss
			sClientData[client].bosskills = results.FetchInt(10); // 10, bosskills
			sClientData[client].PlayTime = results.FetchInt(12); // 12, PlayTime
			
			if (strcmp(PlayerName, buffer) != 0)
			{
				RequestFrame(Frame_PlayerName, client);
			}
		}
		else
		{
			sServerData.CntPeople++;
			sClientData[client].AmmoPacks = 500;
			
			sServerData.Database.Format(buffer, sizeof(buffer), "INSERT INTO `zm_core` (`aid`, `name`, `timestamp`) VALUES (%d, '%s', %d);", sClientData[client].AccountID, buffer, GetTime());
			sServerData.Database.Query(DB_UpdateCallback, buffer, client, DBPrio_High);
		}
		
		// if (HS_GetClientCookie(client, 4) == 3)
		// {
		// 	SetEntProp(client, Prop_Send, "m_iAccount", sClientData[client].AmmoPacks);
		// }
		// else
		// {
		// 	SetEntProp(client, Prop_Send, "m_iAccount", 0);
		// }
		
		DB_CheckCallbackRankPlace(client);
		
		sClientData[client].Loaded = true;
		CreateForward_OnClientLoaded(client, row);
	}
}

public void Frame_PlayerName(int client)
{
	if (IsValidClient(client) && !IsClientSourceTV(client))
	{
		static char buffer[512], name[64];
		GetClientName(client, name, sizeof(name));
		
		sServerData.Database.Format(buffer, sizeof(buffer), "UPDATE `zm_core` SET `name` = '%s' WHERE `aid` = %d;", name, sClientData[client].AccountID);
		sServerData.Database.Query(DB_UpdateCallback, buffer, client, DBPrio_Low);
	}
}

public Action DataBaseOnCommandListened(int client, const char[] command, int argc)
{
	if (!client)
	{
		for (int i = 1; i <= MaxClients; ++i)
		{
			if (!sClientData[i].Loaded)
			{
				continue;
			}
			
			DB_ClientUpdate(i);
			
			sClientData[i].Loaded = false;
		}
	}
	return Plugin_Continue;
}

void DB_ClientUpdate(int client, const char[] column = "", any ...)
{
	if (sClientData[client].Loaded && sClientData[client].AccountID)
	{
		static char buffer[512], buffer2[512];
		if (column[0])
		{
			VFormat(buffer2, sizeof(buffer2), column, 3);
			sServerData.Database.Format(buffer, sizeof(buffer), "UPDATE `zm_core` SET %s WHERE `aid` = %d;", buffer2, sClientData[client].AccountID);
		}
		else
		{
			sServerData.Database.Format(buffer, sizeof(buffer), "UPDATE `zm_core` SET \
					`lvl` = %d, \
					`exp` = %d, \
					`ammopacks` = %d, \
					`kills` = %d, \
					`deaths` = %d, \
					`infects` = %d, \
					`infected` = %d, \
					`boss` = %d, \
					`bosskills` = %d, \
					`offlinetime` = %d, \
					`playtime` = %d \
					WHERE `aid` = %d;",
					sClientData[client].Level,
					sClientData[client].Exp,
					sClientData[client].AmmoPacks,
					sClientData[client].Kills,
					sClientData[client].Deaths,
					sClientData[client].Infects,
					sClientData[client].Infected,
					sClientData[client].boss,
					sClientData[client].bosskills,
					GetTime(),
					sClientData[client].PlayTime,
					sClientData[client].AccountID);
		}
		
		sServerData.Database.Query(DB_UpdateCallback, buffer, _, DBPrio_Low);
	}
}

public Action Timer_DBCheckCallbackCnt(Handle timer)
{
	static char buffer[256];
	sServerData.Database.Format(buffer, sizeof(buffer), "SELECT * FROM `zm_core`");
	sServerData.Database.Query(DB_CheckCallbackCnt, buffer);
	return Plugin_Stop;
}

public void DB_CheckCallbackCnt(Database db, DBResultSet results, const char[] error, any data)
{
	if (db == null || results == null || error[0])
	{
		LogError("DB_CheckCallbackCnt: %s", error);
		return;
	}
	
	sServerData.CntPeople = results.RowCount;
	delete results;
}

void DB_CheckCallbackRankPlace(int client)
{
	static char buffer[256];
	sServerData.Database.Format(buffer, sizeof(buffer), "SELECT COUNT(*) FROM `zm_core` WHERE (`exp` >= %d);", sClientData[client].Exp);
	sServerData.Database.Query(DB_CheckCallbackPlace, buffer, GetClientUserId(client));
}

public void DB_CheckCallbackPlace(Database db, DBResultSet results, const char[] error, int userid)
{
	if (db == null || results == null || error[0])
	{
		LogError("DB_CheckCallback2: %s", error);
		return;
	}
	
	int client = GetClientOfUserId(userid);
	
	if (IsValidClient(client) && !IsFakeClient(client) && !IsClientSourceTV(client))
	{
		if (results.HasResults && results.FetchRow())
		{
			sClientData[client].RankPlace = results.FetchInt(0);
		}
	}
}

public void DB_UpdateCallback(Database db, DBResultSet results, const char[] error, any data)
{
	if (db == null || results == null || error[0])
	{
		LogError("DB_UpdateCallback: %s", error);
	}
}