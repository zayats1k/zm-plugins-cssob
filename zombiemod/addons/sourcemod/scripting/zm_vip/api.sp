GlobalForward hOnClientGiveVIP;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	hOnClientGiveVIP = new GlobalForward("VIP_OnClientGiveVIP", ET_Ignore, Param_Cell, Param_Cell);

	CreateNative("VIP_IsClientVIP", Native_IsClientVIP);
	CreateNative("VIP_IsClientGroup", Native_IsClientGroup);
	CreateNative("VIP_GetClientGroup", Native_GetClientGroup);
	CreateNative("VIP_GetClientPickMenu", Native_GetClientPickMenu);
	CreateNative("VIP_SetClientPickMenu", Native_SetClientPickMenu);
	CreateNative("VIP_GiveClientVIP", Native_GiveClientVIP);
	
	RegPluginLibrary("zm_vip_system");
	return APLRes_Success;
}

public int Native_IsClientVIP(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if (!UTIL_ValidateClient(client)) {
		return false;
	}
	
	return sClientData[client].IsPlayerVIP;
}

public int Native_IsClientGroup(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if (!UTIL_ValidateClient(client)) {
		return false;
	}
	
	if (!sClientData[client].group[0]) {
		return false;
	}
	
	static char group[SMALL_LINE_LENGTH];
	GetNativeString(2, group, sizeof(group));
	
	return (strcmp(sClientData[client].group, group) == 0)
}

public int Native_GetClientGroup(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if (!UTIL_ValidateClient(client)) {
		return false;
	}
	
	if (!sClientData[client].group[0])
	{
		SetNativeString(2, NULL_STRING, GetNativeCell(3));
		return false;
	}
	
	SetNativeString(2, sClientData[client].group, GetNativeCell(3));
	return true;
}

public int Native_GetClientPickMenu(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if (!UTIL_ValidateClient(client)) {
		return false;
	}
	
	return sClientData[client].PickMenu;
}

public int Native_SetClientPickMenu(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if (!UTIL_ValidateClient(client)) {
		return false;
	}
	
	sClientData[client].PickMenu = GetNativeCell(2);
	return true;
}

public int Native_GiveClientVIP(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int target = GetNativeCell(2);
	
	static char group[SMALL_LINE_LENGTH];
	GetNativeString(3, group, sizeof(group));
	int day = GetNativeCell(4);
	
	if (day < 1)
	{
		LogError("Error: day[0] == 1");
		return false;
	}
	
	if (!group[0])
	{
		LogError("Error: group[0] == null");
		return false;
	}
	
	SetClientVIP(client, target, GetNativeCell(5), day, group);
	return true;
}

void CreateForward_OnClientGiveVIP(int client, int type)
{
	Call_StartForward(hOnClientGiveVIP);
	Call_PushCell(client);
	Call_PushCell(type);
	Call_Finish();
}