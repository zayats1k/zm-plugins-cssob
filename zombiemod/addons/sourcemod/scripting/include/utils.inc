#if defined _utils_included
 #endinput
#endif
#define _utils_included

#define SMALL_LINE_LENGTH 32
#define NORMAL_LINE_LENGTH 64
#define BIG_LINE_LENGTH 128
#define CHAT_LINE_LENGTH 192
#define PLATFORM_LINE_LENGTH 256
#define HUGE_LINE_LENGTH 512
#define CONSOLE_LINE_LENGTH 1024
#define FILE_LINE_LENGTH 2048
#define hasLength(%0) (%0[0] != NULL_STRING[0])

// GetEntProp(client, Prop_Send, "m_lifeState");
#define	LIFE_ALIVE 0 // alive
#define	LIFE_DYING 1 // playing death animation or still falling off of a ledge waiting to hit ground
#define	LIFE_DEAD 2 // dead. lying still.
#define LIFE_RESPAWNABLE 3
#define LIFE_DISCARDBODY 4

// SetEntProp(client, Prop_Send, "m_iPlayerState", CSPlayerState);
enum CSPlayerState
{
	// Happily running around in the game.
	// You can't move though if CSGameRules()->IsFreezePeriod() returns true.
	// This state can jump to a bunch of other states like STATE_PICKINGCLASS or STATE_DEATH_ANIM.
	STATE_ACTIVE=0,

	// This is the state you're in when you first enter the server.
	// It's switching between intro cameras every few seconds, and there's a level info
	// screen up.
	STATE_WELCOME,			// Show the level intro screen.

	// During these states, you can either be a new player waiting to join, or
	// you can be a live player in the game who wants to change teams.
	// Either way, you can't move while choosing team or class (or while any menu is up).
	STATE_PICKINGTEAM,			// Choosing team.
	STATE_PICKINGCLASS,			// Choosing class.

	STATE_DEATH_ANIM,			// Playing death anim, waiting for that to finish.
	STATE_DEATH_WAIT_FOR_KEY,	// Done playing death anim. Waiting for keypress to go into observer mode.
	STATE_OBSERVER_MODE,		// Noclipping around, watching players, etc.
	NUM_PLAYER_STATES
};

#include "utils/clients.inc"
#include "utils/entitys.inc"
#include "utils/tempents.inc"
#include "utils/trace.inc"
#include "utils/log.inc"

////////////////////////////////
#define SetBit(%1,%2) (%1 |= (1<<%2))
#define ClearBit(%1,%2) (%1 &= ~(1<<%2))
#define ToogleBit(%1,%2) (%1 ^= (1<<%2))
#define CheckBit(%1,%2) (%1 & (1<<%2))

#define CSAddon_NONE 0
#define CSAddon_Flashbang1 (1<<0)
#define CSAddon_Flashbang2 (1<<1)
#define CSAddon_HEGrenade (1<<2)
#define CSAddon_SmokeGrenade (1<<3)
#define CSAddon_C4 (1<<4)
#define CSAddon_DefuseKit (1<<5)
#define CSAddon_PrimaryWeapon (1<<6)
#define CSAddon_SecondaryWeapon (1<<7)
#define CSAddon_Holster (1<<8) 

#define	SF_NORESPAWN ( 1 << 30 )

stock int UTIL_GetRandomInt(int min, int max)
{
    int random = GetURandomInt();

    if (random == 0) {
        random++;
    }

    return RoundToCeil(float(random) / (float(2147483647) / float(max - min + 1))) + min - 1;
}

stock any UTIL_Clamp(any num, any min, any max) 
{
	return (num < min ? min : num && num > max ? max : num);
}

stock bool GetConVarColor(const ConVar convar, int color[4])
{
	static char szColor[4][16];
	convar.GetString(szColor[0], sizeof(szColor[]));

	if (ExplodeString(szColor[0], " ", szColor, 4, sizeof(szColor[])) == 4)
	{
		color[0] = StringToInt(szColor[0]);
		color[1] = StringToInt(szColor[1]);
		color[2] = StringToInt(szColor[2]);
		color[3] = StringToInt(szColor[3]);
		return true;
	}

	return false;
}

stock bool GetConVarPosition(const ConVar convar, float position[2])
{
	static char szPosition[2][10];
	convar.GetString(szPosition[0], sizeof(szPosition[]));

	if (ExplodeString(szPosition[0], " ", szPosition, 2, sizeof(szPosition[])) == 2)
	{
		position[0] = StringToFloat(szPosition[0]);
		position[1] = StringToFloat(szPosition[1]);
		return true;
	}
	return false;
}

stock void ClearArrayList(ArrayList array)
{
	int size = array.Length;
	if (!size) {
		return;
	}
	
	for (int i = 0; i < size; i++)
	{
		ArrayList list = array.Get(i);
		delete list;
	}
	
	array.Clear();
}

stock void StringToLower(char[] buffer)
{
	for (int i = 0; i < strlen(buffer); i++) {
		buffer[i] = CharToLower(buffer[i]);
	}
}

stock int UTIL_GetAccountIDFromSteamID(const char[] SteamID)
{
	if (!strncmp(SteamID, "STEAM_", 6))
	{
		return StringToInt(SteamID[10]) << 1 | (SteamID[8] - 48);
	}
	if (!strncmp(SteamID, "[U:1:", 5) && SteamID[strlen(SteamID)-1] == ']')
	{
		char buffer[16];
		strcopy(buffer, sizeof(buffer), SteamID[5]);
		buffer[strlen(buffer)-1] = 0;
		return StringToInt(buffer);
	}
	return StringToInt(SteamID);
}

stock void UTIL_AddCommas(int value, char[] buffer, int bufferLen)
{
	if (value < 0) {
		value = cellmax;
	}
	
	int divisor = 1000;
	while (value >= 1000 || value <= -1000) {
		int offcut = value % divisor;
		value = RoundToFloor(float(value) / float(divisor));
		Format(buffer, bufferLen, ",%03.d%s", offcut, buffer);
	}
	Format(buffer, bufferLen, "%d%s", value, buffer);
}