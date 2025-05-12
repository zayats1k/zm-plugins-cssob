#if defined _zm_vip_system_included
 #endinput
#endif
#define _zm_vip_system_included

forward void VIP_OnClientGiveVIP(int client, int type);

native bool VIP_IsClientVIP(int client);
native bool VIP_IsClientGroup(int client, const char[] group);
native void VIP_GetClientGroup(int client, char[] group, int maxLength);
native bool VIP_GetClientPickMenu(int client);
native void VIP_SetClientPickMenu(int client, bool pick);
native void VIP_GiveClientVIP(int client, int target, const char[] group, int day, int accountID = 0);

public SharedPlugin __pl_zm_vip_system = 
{
	name = "zm_vip_system",
	file = "zm_vip_system.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_zm_vip_system_SetNTVOptional()
{
	MarkNativeAsOptional("VIP_IsClientVIP");
	MarkNativeAsOptional("VIP_IsClientGroup");
	MarkNativeAsOptional("VIP_GetClientGroup");
	MarkNativeAsOptional("VIP_GiveClientVIP");
}
#endif