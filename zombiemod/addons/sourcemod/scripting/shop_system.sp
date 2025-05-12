#include <zombiemod>
#include <zm_database>
#include <zm_player_animation>
#include <zm_vip_system>
#include <zm_skin_system>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name = "[ZM] Shop System", 
	author = "0kEmo", 
	version = "2.4"
};

#define SOUND_BLADECUT "npc/roller/blade_cut.wav"
#define SOUND_BUTTON_MENU "buttons/button11.wav"
#define MODELS_HEALTH "models/healthvial.mdl"
#define SOUND_ITEMICKUP "items/itempickup.wav"
#define SOUND_AMMOPICKUP "items/ammopickup.wav"
#define SOUND_SMALLMEDKIT "items/smallmedkit1.wav"

int m_ZombieClassic, m_HumanSniper, m_HumanSurvivor, m_ZombieMemesis;
int m_ModeNormal, m_ModeSwarm;
int m_ClassID[MAXPLAYERS+1][30];

enum struct ServerData
{
	IntMap TrieEntity1;
	IntMap TrieEntity2;
	IntMap TrieEntity3;
	// ArrayList ArrayProps;
	
	bool RoundEnd;
	bool IsMapZm;

	int bluelaser1;
	int ActiveWeapon;
	int ammoTypeOffset;
	int ammoOffset;
	int vecVelocityOffset;
	
	int OwnerEntityOffset;
	
	void Clear()
	{
		this.RoundEnd = false;
		this.IsMapZm = false;
	
		this.ActiveWeapon = -1;
		this.ammoTypeOffset = -1;
		this.ammoOffset = -1;
		this.vecVelocityOffset = -1;
		this.bluelaser1 = 0;
		
		this.OwnerEntityOffset = -1;
		
		delete this.TrieEntity1;
		delete this.TrieEntity2;
		delete this.TrieEntity3;
		// delete this.ArrayProps;
	}
}
ServerData sServerData;

enum struct ClientData
{
	int PriceUp[30];
	int PriceUp_ITEMS[10];
	// int PriceUp_PROPS[10];
	
	float ZombieSkills[2];
	
	// int PropLevel;
	
	void Clear()
	{
		this.ZombieSkills[0] = 0.0;
		this.ZombieSkills[1] = 0.0;
	}
}
ClientData sClientData[MAXPLAYERS+1];

// #include "shop_system/global.sp"
#include "shop_system/api.sp"
#include "shop_system/addons/weapons_and_zombies.sp"
#include "shop_system/addons/items.sp"
// #include "shop_system/addons/props.sp"
#include "shop_system/addons/items2.sp"

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("zombiemod_shop.phrases");
	LoadTranslations("zombiemod_gamemodes.phrases");
	LoadTranslations("utils.phrases");
	
	sServerData.TrieEntity1 = new IntMap();
	sServerData.TrieEntity2 = new IntMap();
	sServerData.TrieEntity3 = new IntMap();
	// sServerData.ArrayProps = new ArrayList(sizeof(PropData));

	sServerData.OwnerEntityOffset = FindSendPropInfo("CBaseEntity", "m_hOwnerEntity");
	sServerData.ActiveWeapon = FindSendPropInfo("CAI_BaseNPC", "m_hActiveWeapon");
	sServerData.ammoTypeOffset = FindSendPropInfo("CWeaponCSBase", "m_iPrimaryAmmoType");
	sServerData.ammoOffset = FindSendPropInfo("CCSPlayer", "m_iAmmo");
	sServerData.vecVelocityOffset = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	
	RegConsoleCmd("zshop", Command_Shop);
	RegConsoleCmd("shop", Command_Shop);
	// RegConsoleCmd("zprops", Command_PropMenu);
	// RegConsoleCmd("props", Command_PropMenu);
	RegConsoleCmd("zp_shop_items", Command_ItemsMenu);
	
	RegConsoleCmd("ammo", Command_ammo);
}

public void OnPluginEnd()
{
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (IsClientInGame(i))
		{
			OnClientDisconnect(i);
		}
	}
	
	UnhookEvent("round_start", Event_RoundStart);
	UnhookEvent("round_end", Event_RoundEnd);
	
	sServerData.Clear();
}

public void OnMapStart()
{
	PrecacheModel(SOUND_BLADECUT, true);
	PrecacheModel(MODELS_HEALTH, true);
	PrecacheSound(SOUND_BUTTON_MENU, true);
	PrecacheSound(SOUND_ITEMICKUP, true);
	PrecacheSound(SOUND_AMMOPICKUP, true);
	PrecacheSound(SOUND_SMALLMEDKIT, true);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		for (int x = 0; x < 30; x++)
		{
			sClientData[i].PriceUp[x] = 0;
			m_ClassID[i][x] = 0;
			
			if (x < 10)
			{
				sClientData[i].PriceUp_ITEMS[x] = 0;
				// sClientData[i].PriceUp_PROPS[x] = 0;
			}
		}
		
		// sClientData[i].PropLevel = 1;
		sClientData[i].ZombieSkills[0] = 0.0;
		sClientData[i].ZombieSkills[1] = 0.0;
	}
	
	char mapname[PLATFORM_MAX_PATH];
	GetCurrentMap(mapname, sizeof(mapname));
	sServerData.IsMapZm = (strncmp(mapname, "ze_", 3, false) != 0);
}

// public void OnConfigsExecuted()
// {
// 	sServerData.ArrayProps.Clear();
// 
// 	char buffer[PLATFORM_MAX_PATH];
// 	BuildPath(Path_SM, buffer, sizeof(buffer), "configs/zombiemod/props.ini");
// 
// 	KeyValues kv = new KeyValues("props");
// 	if (kv.ImportFromFile(buffer) && kv.GotoFirstSubKey())
// 	{
// 		PropData pd;
// 		
// 		do {
// 			kv.GetString("name", buffer, sizeof(buffer), "");
// 			strcopy(pd.name, sizeof(pd.name), buffer);
// 			
// 			kv.GetSectionName(buffer, sizeof(buffer));
// 			strcopy(pd.modelname, sizeof(pd.modelname), buffer);
// 			PrecacheModel(buffer);
// 			
// 			kv.GetString("classname", buffer, sizeof(buffer), "prop_physics");
// 			strcopy(pd.classname, sizeof(pd.classname), buffer);
// 			
// 			pd.price = kv.GetNum("price", 0);
// 			
// 			sServerData.ArrayProps.PushArray(pd);
// 		}
// 		while (kv.GotoNextKey());
// 	}
// 	delete kv;
// }

public void OnLibraryAdded(const char[] name)
{
	if (!strcmp(name, "zombiemod", false))
	{
		if (ZM_IsMapLoaded())
		{
			ZM_OnEngineExecute();
		}
	}
}

public void ZM_OnEngineExecute()
{
	m_ModeNormal = ZM_GetGameModeNameID("normal mode");
	m_ModeSwarm = ZM_GetGameModeNameID("swarm mode");
	m_ZombieClassic = ZM_GetClassNameID("zombie_classic");
	m_ZombieMemesis = ZM_GetClassNameID("zombie_nemesis");
	m_HumanSniper = ZM_GetClassNameID("human_sniper");
	m_HumanSurvivor = ZM_GetClassNameID("human_survivor");
}

public void OnClientConnected(int client)
{
	sClientData[client].Clear();
}

public void OnClientDisconnect(int client)
{
	sClientData[client].Clear();
}

public Action Command_Shop(int client, int args)
{
	// if (!sServerData.IsMapZm)
	// {
	// 	return Plugin_Handled;
	// }
	
	if (IsValidClient(client) && IsClientLoaded(client))
	{
		Menu menu = new Menu(MenuHandler_Shop);
		
		if (ZM_IsClientHuman(client))
		{
			char buffer[164];
			FormatEx(buffer, sizeof(buffer), "%T", "MENU_SHOP_HUMAN_TITLE", client);
			menu.SetTitle(buffer);
		
			if (sServerData.IsMapZm)
			{
				FormatEx(buffer, sizeof(buffer), "%T", "MENU_SHOP_WEAPONS", client);
				menu.AddItem("WEAPONS_1", buffer);
				FormatEx(buffer, sizeof(buffer), "%T", "MENU_SHOP_ITEMS", client);
				menu.AddItem("ITEMS_2", buffer);
				// FormatEx(buffer, sizeof(buffer), "%T", "MENU_SHOP_PROPS", client);
				// menu.AddItem("PROPS_3", buffer);
				FormatEx(buffer, sizeof(buffer), "%T", "MENU_SHOP_ITEMS2", client);
				menu.AddItem("ITEMS2_4", buffer);
			}
			else
			{
				FormatEx(buffer, sizeof(buffer), "%T", "MENU_SHOP_WEAPONS", client);
				menu.AddItem("WEAPONS_1", buffer);
				FormatEx(buffer, sizeof(buffer), "%T", "MENU_SHOP_ITEMS", client);
				menu.AddItem("ITEMS_2", buffer);
				// FormatEx(buffer, sizeof(buffer), "%T", "MENU_SHOP_PROPS", client);
				// menu.AddItem("PROPS_3", buffer, ITEMDRAW_DISABLED);
				FormatEx(buffer, sizeof(buffer), "%T", "MENU_SHOP_ITEMS2", client);
				menu.AddItem("ITEMS2_4", buffer);
			}
			
			menu.ExitBackButton = true;
			menu.OptionFlags = MENUFLAG_BUTTON_EXIT|MENUFLAG_BUTTON_EXITBACK;
			menu.Display(client, MENU_TIME_FOREVER);
		}
		else
		{
			OnShopMenuWeapons(client);
		}
	}
	return Plugin_Handled;
}

public int MenuHandler_Shop(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
		{
			if (IsValidClient(param1))
			{
				ZM_OpenMenuSub(param1, "zshop");
			}
		}
	}
	else if (action == MenuAction_Select)
	{
		if (IsValidClient(param1) && ZM_IsClientHuman(param1))
		{
			if (param2 == 0)
			{
				OnShopMenuWeapons(param1);
			}
			else if (param2 == 1)
			{
				Command_ItemsMenu(param1, 0);
			}
			// else if (param2 == 2)
			// {
			// 	Command_PropMenu(param1, 0);
			// }
			else if (param2 == 2)
			{
				OnShopMenuItems2(param1);
			}
		}
	}
	else if (action == MenuAction_End) delete menu;
	return 0;
}

public void ZM_OnClientUpdated(int client, int attacker)
{
	if (IsValidClient(client))
	{
		int id = ZM_GetClientClass(client);
		
		if (ZM_IsClientZombie(client))
		{
			sClientData[client].PriceUp[22] = 0; // zombie give hp
			sClientData[client].PriceUp[23] = 0; // zombie give skill 1
			sClientData[client].PriceUp[24] = 0; // zombie give skill 2
			sClientData[client].ZombieSkills[0] = 0.0;
			sClientData[client].ZombieSkills[1] = 0.0;
			
			if (ZM_GetCurrentGameMode() != m_ModeNormal) {
				return;
			}
			
			if (m_ZombieClassic == id)
			{
				return;
			}
			
			if (VIP_IsClientVIP(client))
			{
				return;
			}
			
			if (m_ClassID[client][id] < 1)
			{
				m_ClassID[client][id]++;
			}
		}
		// else
		// {
		// 	if (VIP_IsClientVIP(client))
		// 	{
		// 		static char group[SMALL_LINE_LENGTH];
		// 		VIP_GetClientGroup(client, group, sizeof(group));
		// 	
		// 		if (strcmp(group, "SUPERVIP") == 0 || strcmp(group, "MAXIMUM") == 0)
		// 		{
		// 			if (ZM_IsNewRound() == true)
		// 			{
		// 				m_IsClientParachute[client] = true;
		// 			}
		// 		}
		// 	}
		// }
	}
}

public Action ZM_OnClientValidateClass(int client, int id)
{
	if (m_ZombieClassic == id)
	{
		return Plugin_Stop;
	}

	if (m_ClassID[client][id] >= 1)
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public void VIP_OnClientGiveVIP(int client, int type)
{
	if (type != 0)
	{
		return;
	}
	
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		for (int x = 0; x < 30; x++)
		{
			m_ClassID[client][x] = 0;
		}
	}
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	sServerData.RoundEnd = false;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			// if (GetClientLevel(i) >= 7)
			// {
			// 	sClientData[i].PropLevel = 2; // 2
			// }
			// else
			// {
			// 	sClientData[i].PropLevel = 1; // 1
			// }

		
			for (int x = 0; x < 30; x++)
			{
				sClientData[i].PriceUp[x] = 0;
				m_ClassID[i][x] = 0;
				
				if (x < 10)
				{
					sClientData[i].PriceUp_ITEMS[x] = 0;
					// sClientData[i].PriceUp_PROPS[x] = 0;
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	sServerData.TrieEntity1.Clear();
	sServerData.TrieEntity2.Clear();
	sServerData.TrieEntity3.Clear();
	
	// SS_EventRoundEnd();
	sServerData.RoundEnd = true;
	return Plugin_Continue;
}

////////////////////
stock bool SetTeleportEndPoint(int client, float origin[3], float angles[3])
{
	GetClientEyePosition(client, origin);
	GetClientEyeAngles(client, angles);

	Handle trace = TR_TraceRayFilterEx(origin, angles, MASK_SHOT, RayType_Infinite, _TraceFilter);

	if (TR_DidHit(trace))
	{
		float norm[3], degrees = angles[1];
		TR_GetEndPosition(origin, trace);
		TR_GetPlaneNormal(trace, norm);
		GetVectorAngles(norm, angles);
		
		if (norm[2] > 0.98) // if (norm[2] == 1.0)
		{
			angles[0] = 0.0;
			angles[1] = 180.0 + degrees;
			
			delete trace;
			return true;
		}
	}
	delete trace;
	return false;
}

public bool _TraceFilter(int entity, int contentsMask)
{
	return (entity > MaxClients || !entity);
}

stock bool CheckStuckInEntity(int entity)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i) && IsClientStuckInEntity(i, entity))
		{
			return true;
		}
	}
	return false;
}

stock bool IsClientStuckInEntity(int client, int entity)
{
	float origin[3], min[3], max[3];
	GetClientAbsOrigin(client, origin);
	GetClientMins(client, min);
	GetClientMaxs(client, max);
	TR_TraceHullFilter(origin, origin, min, max, MASK_PLAYERSOLID, TraceEntityFilter, entity);
	return TR_DidHit();
}

public bool TraceEntityFilter(int entity, int contentsMask, int ent) 
{
	return (entity == ent);
}

stock void PrintToChat_Lang(int client, const char[] format, any ...)
{
	char buffer[254];
	VFormat(buffer, sizeof(buffer), format, 3);
	ReplaceString(buffer, sizeof(buffer), "\\n", "\n");
	ReplaceString(buffer, sizeof(buffer), "#", "\x07");
	ReplaceString(buffer, sizeof(buffer), "{default}", "\x01");
	
	SetGlobalTransTarget(client);
	PrintToChat(client, "%s", buffer);
}

bool GetClientVIPGroup(int client)
{
	if (VIP_IsClientVIP(client) && VIP_GetClientPickMenu(client) == false)
	{
		static char group[SMALL_LINE_LENGTH];
		VIP_GetClientGroup(client, group, sizeof(group));
	
		if (strcmp(group, "VIP") == 0)
		{
			return false;
		}
		else if (strcmp(group, "SUPERVIP") == 0)
		{
			return true;
		}
		else if (strcmp(group, "MAXIMUM") == 0)
		{
			return true;
		}
	}
	return false;
}

bool SetClientPickMenu(int client, bool pick)
{
	if (VIP_IsClientVIP(client) && VIP_GetClientPickMenu(client) == false)
	{
		static char group[SMALL_LINE_LENGTH];
		VIP_GetClientGroup(client, group, sizeof(group));
	
		if (strcmp(group, "VIP") == 0)
		{
			return false;
		}
		else if (strcmp(group, "SUPERVIP") == 0)
		{
			VIP_SetClientPickMenu(client, pick);
			return true;
		}
		else if (strcmp(group, "MAXIMUM") == 0)
		{
			VIP_SetClientPickMenu(client, pick);
			return true;
		}
	}
	return false;
}