#include <sourcemod>
#include <zombiemod>
#include <clientprefs>
#include <SteamWorks> // https://github.com/hexa-core-eu/SteamWorks/releases
#include <vphysics> // https://forums.alliedmods.net/showthread.php?t=136350
#include <zm_vip_system>
#include <zm_database>
#include <zm_player_animation>

#pragma semicolon 1
#pragma newdecls required
// #pragma dynamic 3276800

public Plugin myinfo = {
	name = "[ZM] Core",
	author = "0kEmo",
	version = "1.0 (2025.05.11)"
};

#define SOUND_BUTTON_CMD_ERROR "buttons/button10.wav"
#define SOUND_BUTTON_MENU_ERROR "buttons/button11.wav"
// #define SOUND_NULL "common/null.wav"

#include "zm/global.sp"
#include "zm/cvars.sp"
#include "zm/api.sp"
#include "zm/translation.sp" 
#include "zm/config.sp"
#include "zm/decryptor.sp"
#include "zm/downloads.sp"

#include "zm/visualeffects/playereffects.sp"
#include "zm/visualeffects/ragdoll.sp"
#include "zm/visualeffects.sp"

#include "zm/extraitems.sp"
#include "zm/cookies.sp"
#include "zm/huds.sp"

#include "zm/soundeffects/soundeffects.sp"
#include "zm/soundeffects/playersounds.sp"
#include "zm/soundeffects/ambientsounds.sp"
#include "zm/sounds.sp"

#include "zm/playerclasses/tools_functions.sp"
#include "zm/playerclasses/classmenu.sp"
#include "zm/playerclasses/runcmd.sp"
#include "zm/playerclasses/spawn.sp"
#include "zm/playerclasses/death.sp"
#include "zm/playerclasses/health.sp"
#include "zm/playerclasses/teleport.sp"
#include "zm/playerclasses/jumpboost.sp"
#include "zm/playerclasses/marketmenu.sp"
#include "zm/playerclasses/market.sp"
#include "zm/playerclasses/apply.sp"
#include "zm/playerclasses/tools.sp"
#include "zm/playerclasses/account.sp"
#include "zm/playerclasses/skins.sp"
#include "zm/playerclasses/antistick.sp"
#include "zm/playerclasses/costumesmenu.sp"
#include "zm/classes.sp"

#include "zm/weapons/weaponattach.sp"
#include "zm/weapons/weaponmod.sp"
#include "zm/weapons/api.sp"
#include "zm/weapons.sp"

#include "zm/hitgroups.sp"
#include "zm/costumes.sp"
#include "zm/zombiemod.sp"
#include "zm/adminmenu.sp"

#include "zm/menus.sp"
#include "zm/blockcommands.sp"

#include "zm/gamemodes.sp"

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	sServerData.Late = late;
	return APIOnNativeInit();
}

public void OnPluginStart()
{
	PrintToServer("[ZombieMod] Loading");

	TranslationOnInit();
	
	ConfigOnInit();
	CookiesInit();
	CvarsOnInit();
	
	ZombieModInit();
	
	ClassesOnInit();
	ClassMenuOnInit();
	CostumesMenuOnInit();
	
	HudsOnCvarInit();
	SoundsOnCvarInit();
	JumpBoostOnCvarInit();
	AntiStickOnInit();
	WeaponsOnInit();
	WeaponModOnInit();
	VEffectsOnInit();
	CostumesOnInit();
	
	MenusOnInit();
	
	BlockCommandsOnInit();
	SoundsOnInit();
	
	AdminsOnInit();
	
	PrintToServer("[ZombieMod] Loaded");
}

public void OnPluginEnd()
{
	WeaponsOnUnload();
	CostumesOnUnload();
}

public void OnMapStart()
{
	ConfigOnCacheData();
	
	ClassesOnLoad(true);
	HudsOnLoad();
	SoundsOnLoad();
	MenusOnLoad();
	WeaponsOnLoad();
	WeaponModOnLoad();
	BlockCommandsOnLoad();
	AdminsOnLoad();
	DownloadsOnLoad();
	ClassesOnLoad();
	CostumesOnLoad();
	ExtraItemsOnLoad();
	SkinsOnLoad();
	
	VEffectsOnLoad();
	
	ToolsOnLoad();
	GameModesOnLoad();
	ZombieModOnLoad();
}

public void OnMapEnd()
{
	ZombieModOnMapEnd();
	SoundsOnMapEnd();
}

public void OnAutoConfigsBuffered()
{
	ConfigOnLoad();
}

public void OnConfigsExecuted()
{
	ConfigOnLoad(".post");
	ZombieModOnConfigsExecuted();
}

public void OnClientConnected(int client)
{
	sClientData[client].ResetVars();
	sClientData[client].ResetTimers();
}

public void OnClientDisconnect_Post(int client)
{
	sClientData[client].ResetVars();
	sClientData[client].ResetTimers();
	
	ZombieModOnClientDisconnectPost(client);
	ClassesOnClientDisconnectPost(client);
}

public void OnClientPutInServer(int client)
{
	CvarsOnClientPutInServer(client);
}

public void OnClientPostAdminCheck(int client)
{
	ZombieModOnClientInit(client);
	ToolsOnClientInit(client);
	HitGroupsOnClientInit(client);
	WeaponsOnClientInit(client);
	ClassesOnClientInit(client);
	CostumesOnClientInit(client);
	
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		SoundsOnClientUpdate(client);
		SkinsOnClientInit(client);
		
		if (AreClientCookiesCached(client))
		{
			OnClientCookiesCached(client);
		}
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (entity > -1)
	{
		ZombieModOnEntityCreated(entity, classname);
		HitGroupsOnEntityCreated(entity, classname);
		MarketOnEntityCreated(entity, classname);
		WeaponModnEntityCreated(entity, classname);
	}
}

public void OnPlayerSequencePre(int client, int entity, const char[] anim)
{
	if (IsValidClient(client))
	{
		CostumesOnPlayerSequencePre(client);
		WeaponModOnPlayerSequencePre(client);
	}
}

public void OnResetPlayerSequence(int client, bool player)
{
	if (IsValidClient(client))
	{
		CostumesOnResetPlayerSequence(client);
		
		if (IsPlayerAlive(client))
		{
			WeaponModOnResetPlayerSequence(client, player);
		}
	}
}