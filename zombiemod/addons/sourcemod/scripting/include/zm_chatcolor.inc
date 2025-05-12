#if defined _zm_chatcolor_included
 #endinput
#endif
#define _zm_chatcolor_included

forward Action ZM_OnClientSay(int client, char[] text);
forward void ZM_OnClientSayPost(int client, char[] text);

public SharedPlugin __pl_zm_chatcolor = 
{
	name = "zm_chatcolor",
	file = "zm_chatcolor.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};