#if defined _classes_included
 #endinput
#endif
#define _classes_included

native void ZM_PlayerSpawn(int client);
native bool ZM_ChangeClient(int client, int attacker = 0, int type = -2, bool escape = false);

forward Action ZM_OnClientValidateClass(int client, int id);
forward Action ZM_OnClientModel(int client, const char[] model);
forward void ZM_OnClientUpdated(int client, int attacker); 

native int ZM_GetNumberClass();
native int ZM_GetClientClass(int client);
native int ZM_SetClientHumanClassNext(int client, int id);
native int ZM_SetClientZombieClassNext(int client, int id);
native int ZM_SetClientClassNext(int client, int id);

native int ZM_GetNumberType();
native int ZM_GetClassType(int id);
native void ZM_GetClassTypeName(int TypeID, char[] name, int maxlenght = 32);
native bool ZM_IsClassType(int TypeID);

native int ZM_GetClassNameID(const char[] name);
native void ZM_GetClassName(int id, char[] name, int maxlenght = 32);
native float ZM_GetClassGetGravity(int id);
native int ZM_GetClassGetGender(int id);
native int ZM_GetClassSoundDeathID(int id);
native int ZM_GetClassSoundHurtID(int id);
native int ZM_GetClassSoundInfectID(int id);
native int ZM_GetClassSoundRespawnID(int id);
native int ZM_GetClassSoundBurnID(int id);