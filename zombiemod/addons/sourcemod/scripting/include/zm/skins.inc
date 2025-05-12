#if defined _skins_included
 #endinput
#endif
#define _skins_included

native int ZM_GetNumberSkin();
native int ZM_GetClientSkin(int client);
native void ZM_SetClientSkin(int client, int SetID);
native void ZM_GetSkinName(int id, char[] name, int maxlenght = 32);
native bool ZM_GetSkinsGender(int id);
native bool ZM_IsClientEmote(int id);
native int ZM_GetSkinsSoundDeathID(int id);