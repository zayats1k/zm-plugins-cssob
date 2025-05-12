#if defined _gamemodes_included
 #endinput
#endif
#define _gamemodes_included

forward void ZM_OnGameModeStart(int mode);
native int ZM_GetCurrentGameMode();
native int ZM_GetGameModeNameID(const char[] name);
native void ZM_GetGameModeName(int id, char[] name, int maxlenght = 32);
native bool ZM_IsGameModeInfect(int id);
native int ZM_GetGameModeTypeHuman(int id);
native int ZM_GetGameModeTypeZombie(int id);
native int ZM_GetGameModeMatch(int id);
native int ZM_GetGameModeMinPlayers(int id);
forward void ZM_OnGameModeEnd(CSRoundEndReason reason);
native int ZM_GetNumberGameMode();
native void ZM_SetGameMode(int id = -1, int target = -1);