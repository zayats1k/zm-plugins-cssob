#if defined _zombiemod_included
 #endinput
#endif
#define _zombiemod_included

#if !defined _sdkhooks_included
 #include <sdktools>
#endif

#include <sdkhooks>
#include <cstrike>
#include <utils>

#include "zm/activity_list.inc"
#include "zm/weapons.inc"
#include "zm/gamemodes.inc"
#include "zm/classes.inc"
#include "zm/skins.inc"
#include "zm/tools.inc"

forward void ZM_OnCheckRoundTimeExpired();

forward void ZM_OnClientValidateDamage(int client, int& attacker, int& inflicter, float& damage, int& damagetype);
forward void ZM_OnClientDamaged(int client, int attacker, int inflicter, float damage, int damagetype);

forward void ZM_OnEngineExecute();
forward Action ZM_OnPlayFootStep(int client, const char[] sound, int channel, int level, int flags, float volume, int pitch);
forward Action ZM_OnPlayerSpawn(int client);
forward void ZM_OnClientRespawn(int client, int respawn_timer);
forward void ZM_OnClientJoinTeamed(int client, int team);

native bool ZM_TakeDamage(int client, int attacker, int inflictor, float damage, int damagetype = DMG_GENERIC);
native void ZM_ApplyKnock(int client, int attacker, int inflictor, float KnockRatio = 1.0, int damagetype = DMG_GENERIC, const char[] classname = NULL_STRING);
native void ZM_OpenMenuSub(int client, const char[] name);
native void ZM_PrintToChat(int client, int target = -1, any ...);
native void ZM_PrintToChatAll(int target = -1, any ...);

native Handle ZM_GetHudSync();
native bool ZM_TerminateRound();
native bool ZM_RespawnPlayer(int client);
native void ZM_SpawnTeleportToRespawn(int client);
native bool ZM_IsRespawn(int client, int mode = -1);
native bool ZM_IsClientZombie(int client);
native bool ZM_IsClientHuman(int client);
native bool ZM_IsClientCustom(int client);
native int ZM_GetSvaeDefaultCart(int client);

native bool ZM_IsMapLoaded();
native bool ZM_IsNewRound();
native bool ZM_IsEndRound();
native bool ZM_IsStartedRound();
native float ZM_GetRoundTime();

native int ZM_GetHumanAmount();
native int ZM_GetZombieAmount();
native int ZM_GetAliveAmount();
native int ZM_GetRandomHuman();
native int ZM_GetRandomZombie();

public SharedPlugin __pl_zombiemod = 
{
	name = "zombiemod",
	file = "zombiemod.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_zombiemod_SetNTVOptional()
{
	MarkNativeAsOptional("ZM_IsClientZombie");
	MarkNativeAsOptional("ZM_IsClientHuman");
}
#endif
