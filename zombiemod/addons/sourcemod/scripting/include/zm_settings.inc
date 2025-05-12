#if defined _zm_settings_included
 #endinput
#endif
#define _zm_settings_included

native int HS_GetClientCookie(int client, int id);
native void HS_SetClientCookie(int client, int id, bool toggle);

forward void HS_OnClientHudSettings(int client, int id, const char[] name);

stock void PrintText(int client, int id, Handle sync, const char[] format, any ...)
{
	char buffer[254];
	VFormat(buffer, sizeof(buffer), format, 5);
	
	if (HS_GetClientCookie(client, id) == 2)
	{
		ShowSyncHudText(client, sync, buffer);
	}
	else if (HS_GetClientCookie(client, id) == 3)
	{
		PrintHintText(client, buffer);
	}
}

public SharedPlugin __pl_zm_settings = 
{
	name = "zm_settings",
	file = "zm_settings.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};