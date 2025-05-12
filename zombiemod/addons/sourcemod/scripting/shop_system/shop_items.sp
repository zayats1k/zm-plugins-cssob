#include <zombiemod>
#include <zm_database>
#include <zm_player_animation>
#include <intmap> // https://github.com/Ilusion9/intmap-inc-sm

#pragma semicolon 1
#pragma newdecls required

#if SOURCEMOD_V_MINOR < 10
	#error This plugin only compile on SourceMod 1.10+
#endif

public Plugin myinfo = {
	name = "[ZShop] Items",
	author = "0kEmo",
	version = "3.0"
};

#define SOUND_BUTTON_MENU "buttons/button11.wav"

//////////
#define MODELS_HEALTH "models/healthvial.mdl" // "models/items/healthkit.mdl"
#define SOUND_HEALTH "items/smallmedkit1.wav"

#define MAX_COUNTTIMER 60 // 90
#define MAX_SLOT 5
//////////////
enum struct ServerData
{
	IntMap TrieEntity1;
	IntMap TrieEntity2;
	IntMap TrieEntity3;
	int OwnerEntityOffset;
	
	void Clear()
	{
		delete this.TrieEntity1;
		delete this.TrieEntity2;
		delete this.TrieEntity3;
		this.OwnerEntityOffset = -1;
	}
}
ServerData sServerData;

enum struct ClientData
{
	int PriceUp[10];
}
ClientData sClientData[MAXPLAYERS+1];

int m_HumanSniper, m_HumanSurvivor, m_HumanMemesis;
int m_ModeSwarm;

public void OnPluginStart()
{
	LoadTranslations("zombiemod_shop.phrases");
	LoadTranslations("shop_props.phrases");
	LoadTranslations("utils.phrases");

	RegConsoleCmd("shop_items", Command_ItemMenu);
	
	sServerData.TrieEntity1 = new IntMap();
	sServerData.TrieEntity2 = new IntMap();
	sServerData.TrieEntity3 = new IntMap();
	
	sServerData.OwnerEntityOffset = FindSendPropInfo("CBaseEntity", "m_hOwnerEntity");

	HookEvent("round_end", Event_RoundEnd);
	HookEvent("round_start", Event_RoundStart);
}

public void OnPluginEnd()
{
	sServerData.Clear();
	
	UnhookEvent("round_start", Event_RoundStart);
}

public void OnMapStart()
{
	PrecacheModel(MODELS_HEALTH, true);
	PrecacheSound(SOUND_HEALTH, true);
	PrecacheSound(SOUND_BUTTON_MENU, true);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		for (int x = 0; x < 10; x++)
		{
			sClientData[i].PriceUp[x] = 0;
		}
	}
}

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
	m_ModeSwarm = ZM_GetGameModeNameID("swarm mode");
	m_HumanMemesis = ZM_GetClassNameID("zombie_nemesis");
	m_HumanSniper = ZM_GetClassNameID("human_sniper");
	m_HumanSurvivor = ZM_GetClassNameID("human_survivor");
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && !IsFakeClient(i))
		{
			for (int x = 0; x < 10; x++)
			{
				sClientData[i].PriceUp[x] = 0;
			}
		}
	}
	return Plugin_Continue;
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	sServerData.TrieEntity1.Clear();
	sServerData.TrieEntity2.Clear();
	sServerData.TrieEntity3.Clear();
}

public Action Command_ItemMenu(int client, int first_item)
{
	if (IsValidClient(client) && IsPlayerAlive(client) && ZM_IsClientHuman(client))
	{
		int mode = ZM_GetCurrentGameMode();
		if (ZM_IsStartedRound() && mode == m_ModeSwarm) {
			return Plugin_Handled;
		}
		
		int classid = ZM_GetClientClass(client);
		if (classid == m_HumanSniper || classid == m_HumanSurvivor || classid == m_HumanMemesis) {
			return Plugin_Handled;
		}
		
		Menu menu = new Menu(MenuHandler_ItemsMenu);
		menu.SetTitle("%T", "MENU_SHOP_ITEM_TITLE", client);
		
		char buffer[164];
		FormatEx(buffer, sizeof(buffer), "%T", "HUMAN_MENU_ITEM_AMMO", client);
		SS_AddMenuItem(menu, client, "hpward; 1; 260", buffer, 0, 260, 1);
		
		menu.Display(client, MENU_TIME_FOREVER);
	}
	return Plugin_Handled;
}

public int MenuHandler_ItemsMenu(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		if (IsValidClient(param1) && IsPlayerAlive(param1) && ZM_IsClientHuman(param1))
		{
			if (ZM_IsStartedRound() && ZM_GetCurrentGameMode() == m_ModeSwarm)
			{
				EmitSoundToClient(param1, SOUND_BUTTON_MENU);
				return 0;
			}
			
			int id = ZM_GetClientClass(param1);
			if (id == m_HumanSniper || id == m_HumanSurvivor || id == m_HumanMemesis)
			{
				EmitSoundToClient(param1, SOUND_BUTTON_MENU);
				return 0;
			}
			
			if (GetEntitySequence(param1) != 0)
			{
				EmitSoundToClient(param1, SOUND_BUTTON_MENU);
				return 0;
			}
			
			char info[34]; char buffer[3][34];
			menu.GetItem(param2, info, sizeof(info));
			ExplodeString(info, "; ", buffer, sizeof(buffer), sizeof(buffer[]));
			int price = StringToInt(buffer[1]);
			
			if (SetClientPriceUp(param1, param2, price) > GetClientAmmoPacks(param1))
			{
				ZM_PrintToChat(param1, _, "%t", "CHAT_NO_AMMOPACKS");
				return 0;
			}
			
			int ammo = SS_MenuItem(param1, param2, buffer);
			
			if (view_as<bool>(StringToInt(info[1])) == true)
			{
				return 0;
			}
			
			if (ammo == -1)
			{
				return 0;
			}
			
			if (ammo != 0)
			{
				SetClientAmmoPacks(param1, -ammo);
				sClientData[param1].PriceUp[param2]++;
			}
			else
			{
				Command_ItemMenu(param1, 0);
			}
		}
	}
	return 0;
}

int SS_MenuItem(int client, int item, const char[][] info)
{
	int price = StringToInt(info[2]);
	
	if (IsPlayerAlive(client))
	{
		if (strcmp(info[0], "hpward") == 0)
		{
			float origin[3], angles[3], pos[3];
			if (!SetTeleportEndPoint(client, pos, angles))
			{
				PrintToChat_Lang(client, "%T", "PROP_TELEPORT", client);
				Command_ItemMenu(client, 0);
				return 0;
			}
			
			GetClientAbsOrigin(client, origin);
			if (GetVectorDistance(origin, pos) >= 60)
			{
				PrintToChat_Lang(client, "%T", "PROP_DISTANCE", client);
				Command_ItemMenu(client, 0);
				return 0;
			}
			
			int ent = CreateEntityByName("prop_dynamic_override");
			if (ent != -1)
			{
				DispatchKeyValue(ent, "model", MODELS_HEALTH);
				DispatchSpawn(ent);
				
				TeleportEntity(ent, origin, NULL_VECTOR, NULL_VECTOR);
				
				SetEntProp(ent, Prop_Send, "m_usSolidFlags", 8);
				SetEntDataEnt2(ent, sServerData.OwnerEntityOffset, client);
				
				DataPack data = new DataPack();
				RequestFrame(Frame_EntityStuck_HEALTH, data);
				data.WriteCell(GetClientUserId(client));
				data.WriteCell(EntIndexToEntRef(ent));
				data.WriteCell(item);
				data.WriteCell(price);
			}
		}
		else return 0;
	}
	else return 0;
	return SetClientPriceUp(client, item, price);
}

public void Frame_EntityStuck_HEALTH(DataPack data)
{
	data.Reset();
	int client = GetClientOfUserId(data.ReadCell());
	int entity = EntRefToEntIndex(data.ReadCell());
	int item = data.ReadCell();
	int price = data.ReadCell();
	delete view_as<DataPack>(data);
	
	if (IsValidEntityf(entity) && CheckStuckInEntity(entity))
	{
		if (IsValidClient(client))
		{
			PrintToChat_Lang(client, "%T", "PROP_STUCK", client);
		}
		
		AcceptEntityInput(entity, "kill");
		return;
	}
	
	if (IsValidClient(client))
	{
		float origin[3]; GetClientAbsOrigin(client, origin);
		int effect = UTIL_CreateParticle(entity, "info_health_", "info_health_main_v1", origin, true);
		
		SetEntPropEnt(entity, Prop_Data, "m_hMoveChild", effect);
		SetEntPropEnt(effect, Prop_Data, "m_hEffectEntity", entity);
		
		sServerData.TrieEntity1.SetValue(entity, MAX_COUNTTIMER);
		sServerData.TrieEntity2.SetValue(entity, 0);
		sServerData.TrieEntity3.SetValue(entity, 0);
		CreateTimer(1.0, Timer_Heal, EntIndexToEntRef(entity), TIMER_REPEAT);
				
		SetClientAmmoPacks(client, -SetClientPriceUp(client, item, price));
		sClientData[client].PriceUp[item]++;
	}
}

public Action Timer_Heal(Handle timer, any data)
{
	int ent = EntRefToEntIndex(data);
	if (ent < 1 || !IsValidEdict(ent))
	{
		sServerData.TrieEntity3.SetValue(ent, 0);
		return Plugin_Stop;
	}
	static int iCount;
	sServerData.TrieEntity1.GetValue(ent, iCount);
	
	if (iCount < 1 || ZM_IsEndRound())
	{
		sServerData.TrieEntity3.SetValue(ent, 0);
		sServerData.TrieEntity1.SetValue(ent, 0);
		AcceptEntityInput(ent, "Kill");
		return Plugin_Stop;
	}
	static int clients[MAXPLAYERS+1], clientx, iCountSlot;
	float EntityOrigin[3], PlayerOrigin[3];
	
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", EntityOrigin);
	
	sServerData.TrieEntity1.SetValue(ent, --iCount);
	sServerData.TrieEntity3.GetValue(ent, clientx);
	
	if (clientx == 0)
	{
		int count;
		for (int i = 1; i <= MaxClients; ++i)
		{
			if (IsValidClient(i) && IsPlayerAlive(i) && ZM_IsClientHuman(i))
			{
				GetClientAbsOrigin(i, PlayerOrigin);
				if (GetVectorDistance(EntityOrigin, PlayerOrigin) <= 200)
				{
					if (GetClientHealth(i) < GetEntProp(i, Prop_Data, "m_iMaxHealth"))
					{
						count++;
						
						if (count > 1 && clients[0] == i)
						{
							// PrintToChatAll("[TEST] %d - %d", clients[0], count);
							clients[0] = 0;
							continue;
						}
					
						clients[count] = i;
					}
				}
			}
		}
		
		if (count != 0)
		{
			sServerData.TrieEntity2.SetValue(ent, MAX_SLOT);
			sServerData.TrieEntity3.SetValue(ent, clients[GetRandomInt(1, count)]);
		}
	}
	sServerData.TrieEntity2.GetValue(ent, iCountSlot);
	sServerData.TrieEntity3.GetValue(ent, clientx);
	
	if (!(iCountSlot < 1) && IsValidClient(clientx) && IsPlayerAlive(clientx) && ZM_IsClientHuman(clientx))
	{
		GetClientAbsOrigin(clientx, PlayerOrigin);
		
		if (GetVectorDistance(EntityOrigin, PlayerOrigin) <= 200)
		{
			int hp = GetClientHealth(clientx);
			int maxhp = GetEntProp(clientx, Prop_Data, "m_iMaxHealth");
			
			if (hp < maxhp)
			{
				SetEntityHealth(clientx, UTIL_Clamp(hp+5, 0, maxhp));
				EmitSoundToAll(MODELS_HEALTH, clientx);
				
				PlayerOrigin[2] += GetRandomFloat(16.0, 50.0);
				int effect = UTIL_CreateParticle(ent, "info_health_", "info_health_beam_v1", PlayerOrigin);
				SetVariantString("!activator");
				AcceptEntityInput(effect, "SetParent", clientx, effect);
				UTIL_RemoveEntity(effect, 0.2);
				UTIL_ScreenFade(clientx, 1.0, 0.1, FFADE_IN, {0, 128, 0, 30});
				
				sServerData.TrieEntity2.SetValue(ent, --iCountSlot);
				return Plugin_Continue;
			}
		}
	}
	
	clients[0] = clientx;
	sServerData.TrieEntity3.SetValue(ent, 0);
	return Plugin_Continue;
}

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
	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), format, 3);
	ReplaceString(buffer, sizeof(buffer), "#", "\x07");
	PrintToChat(client, "%s", buffer);
}

void SS_AddMenuItem(Menu menu, int client, const char[] info, const char[] name, int item, int price, int x)
{
	char buffer[264];
	
	if (price != 0)
	{
		if (x != 0)
		{
			int up = SetClientPriceUp(client, item, price);
			if (up <= price * x)Format(buffer, sizeof(buffer), "%s[%d %T]", name, up, "ammopack 2", client);
			else Format(buffer, sizeof(buffer), "%s[✔]", name);
			menu.AddItem(info, buffer, (GetClientAmmoPacks(client) >= up && up <= price * x) ? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
		}
		else
		{
			Format(buffer, sizeof(buffer), "%s[✘]", name);
			menu.AddItem(info, buffer, ITEMDRAW_DISABLED);
		}
	}
	else
	{
		Format(buffer, sizeof(buffer), "%s", name);
		menu.AddItem(info, buffer);
	}
}

int SetClientPriceUp(int client, int item, int price)
{
	return price * (sClientData[client].PriceUp[item] + 1);
}