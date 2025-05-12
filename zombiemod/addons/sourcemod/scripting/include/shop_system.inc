#if defined _shop_system_included
 #endinput
#endif
#define _shop_system_included

// native int GetClientAmmoPacks(int client);
// native void SetClientAmmoPacks(int client, int value);
native int GetClientPriceUp(int client, int item);
native int SetClientPriceUp(int client, int item);
native float GetClientSkill(int client, int num);
forward Action OnClientItemPickup(int client, int price, const char[] name);

public SharedPlugin __pl_shop_system = 
{
	name = "shop_system",
	file = "shop_system.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

// #if !defined REQUIRE_PLUGIN
// public void __pl_shop_system_SetNTVOptional()
// {
// 	MarkNativeAsOptional("GetClientAmmoPacks");
// 	MarkNativeAsOptional("SetClientAmmoPacks");
// }
// #endif