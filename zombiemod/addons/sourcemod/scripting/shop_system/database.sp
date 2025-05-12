public void DBConnect(Database db, const char[] error, any data)
{
	if (db == null || error[0])
	{
		LogError("DBConnect: %s", error);
		return;
	}
	sServerData.Database = db;
	
	sServerData.Database.Query(DB_CreateTableCallback, "CREATE TABLE IF NOT EXISTS `ss_users` (\
			`account_id` INTEGER PRIMARY KEY UNIQUE NOT NULL, \
			`ap` INTEGER NOT NULL DEFAULT 0);", _, DBPrio_High);
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

	if (IsValidClient(client) && !IsFakeClient(client) && !IsClientSourceTV(client))
	{
		static char buffer[512];
		
		if (results.FetchRow())
		{
			sClientData[client].AmmoPacks = results.FetchInt(0);
		}
		else
		{
			sClientData[client].AmmoPacks = 500;
			sServerData.Database.Format(buffer, sizeof(buffer), "INSERT INTO `ss_users` (`account_id`, `ap`) VALUES (%d, 500);", sClientData[client].AccountID);
			sServerData.Database.Query(DB_UpdateCallback, buffer, _, DBPrio_High);
		}
		
		sClientData[client].Loaded = true;
	}
}

void DBClientUpdate(int client)
{
	if (sClientData[client].Loaded && sClientData[client].AccountID)
	{
		if (sClientData[client].AmmoPacks <= 0) sClientData[client].AmmoPacks = 0;
		if (sClientData[client].AmmoPacks > 60000) sClientData[client].AmmoPacks = 60000;
		
		static char buffer[512];
		sServerData.Database.Format(buffer, sizeof(buffer), "UPDATE `ss_users` SET `ap` = %d WHERE `account_id` = %d;", sClientData[client].AmmoPacks, sClientData[client].AccountID);
		sServerData.Database.Query(DB_UpdateCallback, buffer, _, DBPrio_Low);
	}
}

public void DB_UpdateCallback(Database db, DBResultSet results, const char[] error, any data)
{
	if (db == null || results == null || error[0]) LogError("DB_UpdateCallback: %s", error);
}