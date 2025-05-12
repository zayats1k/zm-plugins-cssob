GlobalForward hOnClientItemPickup;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	hOnClientItemPickup = new GlobalForward("OnClientItemPickup", ET_Hook, Param_Cell, Param_Cell, Param_String);

	CreateNative("GetClientPriceUp", Native_GetClientPriceUp);
	CreateNative("SetClientPriceUp", Native_SetClientPriceUp);
	CreateNative("GetClientSkill", Native_GetClientSkill);
	
	RegPluginLibrary("shop_system");
	return APLRes_Success;
}

public int Native_GetClientPriceUp(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int item = GetNativeCell(2);
	
	return sClientData[client].PriceUp[item];
}

public int Native_SetClientPriceUp(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int item = GetNativeCell(2);
	
	return sClientData[client].PriceUp[item] += 1;
}

public int Native_GetClientSkill(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int num = GetNativeCell(2);
	
	return view_as<int>(sClientData[client].ZombieSkills[num]);
}

Action CreateForward_OnClientItemPickup(int client, int price, const char[] name)
{
	Action result = Plugin_Continue;
	Call_StartForward(hOnClientItemPickup);
	Call_PushCell(client);
	Call_PushCell(price);
	Call_PushString(name);
	Call_Finish(result);
	return result;
}