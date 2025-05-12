#if defined _zm_skin_system_included
 #endinput
#endif
#define _zm_skin_system_included

native void SKIN_GiveClientSKIN(int client, int target, const char[] skin, int day, int accountID = 0);

public SharedPlugin __pl_zm_skin_system = 
{
	name = "zm_skin_system",
	file = "zm_skin_system.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_zm_skin_system_SetNTVOptional()
{
	MarkNativeAsOptional("SKIN_GiveClientSKIN");
}
#endif