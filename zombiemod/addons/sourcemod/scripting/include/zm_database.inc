#if defined _zm_database_included
 #endinput
#endif
#define _zm_database_included

native int IsClientLoaded(int client);
native int GetClientExp(int client);
native int GetClientExp2(int client);
native int GetClientLevel(int client);
native int GetLevelMax();
native int GetClientExpMultiplier(int client);
native int GetCntPeople();
native void SetClientExp(int client, int value);
native void SetClientLevel(int client, int value);
native void SetClientExpMultiplier(int client, int multiplier, int time);
native int GetClientAmmoPacks(int client);
native void SetClientAmmoPacks(int client, int value);
forward void OnClientExp(int client, int& exp);
forward void OnClientExp_Post(int client);
forward void OnClientLevelUp(int client);
forward void OnClientPlayTime(int client, int time);
forward void OnClientLoaded(int client, bool row);
forward void OnClientTransfer(int client, int accountID1, int accountID2);

public SharedPlugin __pl_zm_database = 
{
	name = "zm_database",
	file = "zm_database.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_zm_database_SetNTVOptional()
{
	MarkNativeAsOptional("GetClientAmmoPacks");
	MarkNativeAsOptional("SetClientAmmoPacks");
}
#endif