GlobalForward hOnClientExp;
GlobalForward hOnClientExp_Post;
GlobalForward hOnClientLevelUp;
GlobalForward hOnClientPlayTime;
GlobalForward hOnClientLoaded;
GlobalForward hOnClientTransfer;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	hOnClientExp = new GlobalForward("OnClientExp", ET_Ignore, Param_Cell, Param_CellByRef);
	hOnClientExp_Post = new GlobalForward("OnClientExp_Post", ET_Ignore, Param_Cell);
	hOnClientLevelUp = new GlobalForward("OnClientLevelUp", ET_Ignore, Param_Cell);
	hOnClientPlayTime = new GlobalForward("OnClientPlayTime", ET_Ignore, Param_Cell, Param_Cell);
	hOnClientLoaded = new GlobalForward("OnClientLoaded", ET_Ignore, Param_Cell, Param_Cell);
	hOnClientTransfer = new GlobalForward("OnClientTransfer", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	
	CreateNative("IsClientLoaded", Native_IsClientLoaded);
	CreateNative("GetClientExp", Native_GetClientExp);
	CreateNative("GetClientExp2", Native_GetClientExp2);
	CreateNative("GetClientLevel", Native_GetClientLevel);
	CreateNative("GetLevelMax", Native_GetLevelMax);
	CreateNative("GetCntPeople", Native_GetCntPeople);
	CreateNative("SetClientExp", Native_SetClientExp);
	CreateNative("SetClientLevel", Native_SetClientLevel);
	
	CreateNative("GetClientAmmoPacks", Native_GetClientAmmoPacks);
	CreateNative("SetClientAmmoPacks", Native_SetClientAmmoPacks);
	
	RegPluginLibrary("zm_database");
	return APLRes_Success;
}

public int Native_IsClientLoaded(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return sClientData[client].Loaded;
}

public int Native_GetClientExp(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return sClientData[client].Exp;
}

public int Native_GetClientExp2(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return GetClientExpUp(client);
}

public int Native_GetClientLevel(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return sClientData[client].Level-1;
}

public int Native_GetCntPeople(Handle plugin, int numParams)
{
	return sServerData.CntPeople;
}

public int Native_GetLevelMax(Handle plugin, int numParams)
{
	return sServerData.ArrayLevels.Length;
}

public int Native_SetClientExp(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	SetClientExp(client, -1, GetNativeCell(2));
	return 0;
}

public int Native_SetClientLevel(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	SetClientLevel(client, GetNativeCell(2));
	return 0;
}

public int Native_GetClientAmmoPacks(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return sClientData[client].AmmoPacks;
}

public int Native_SetClientAmmoPacks(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int ammo = GetNativeCell(2);
	
	SetClientAmmoPacks(client, ammo);
	return 0;
}

void CreateForward_OnClientExp(int client, int& exp)
{
	Call_StartForward(hOnClientExp);
	Call_PushCell(client);
	Call_PushCellRef(exp);
	Call_Finish();
}

void CreateForward_OnClientExp_Post(int client)
{
	Call_StartForward(hOnClientExp_Post);
	Call_PushCell(client);
	Call_Finish();
}

void CreateForward_OnClientLevelUp(int client)
{
	Call_StartForward(hOnClientLevelUp);
	Call_PushCell(client);
	Call_Finish();
}

void CreateForward_OnClientPlayTime(int client, int time)
{
	Call_StartForward(hOnClientPlayTime);
	Call_PushCell(client);
	Call_PushCell(time);
	Call_Finish();
}

void CreateForward_OnClientLoaded(int client, bool row)
{
	Call_StartForward(hOnClientLoaded);
	Call_PushCell(client);
	Call_PushCell(row);
	Call_Finish();
}

void CreateForward_OnClientTransfer(int client, int accountID1, int accountID2)
{
	Call_StartForward(hOnClientTransfer);
	Call_PushCell(client);
	Call_PushCell(accountID1);
	Call_PushCell(accountID2);
	Call_Finish();
}