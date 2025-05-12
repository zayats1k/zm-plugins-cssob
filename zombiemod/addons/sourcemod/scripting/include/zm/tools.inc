#if defined _tools_included
 #endinput
#endif
#define _tools_included

native void ZM_SetPlayerSpotted(int client, bool spotted = true, bool spott = false);
native int ZM_LookupAttachment(int entity, const char[] name);