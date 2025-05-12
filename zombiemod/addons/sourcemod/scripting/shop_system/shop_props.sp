#include <zombiemod>
#include <zm_database>
#include <zm_player_animation>

#pragma semicolon 1
#pragma newdecls required

#if SOURCEMOD_V_MINOR < 10
	#error This plugin only compile on SourceMod 1.10+
#endif

public Plugin myinfo = {
	name = "[ZShop] ZProps",
	author = "0kEmo",
	version = "3.0"
};

#define SOUND_BUTTON_MENU "buttons/button11.wav"

enum struct PropData
{
	char name[PLATFORM_MAX_PATH];
	char modelname[PLATFORM_MAX_PATH];
	char classname[PLATFORM_MAX_PATH];
	int price;
	int heal;
}

enum struct ServerData
{
	ArrayList ArrayProps;
	
	void Clear()
	{
		this.ArrayProps.Clear();
	}
}
ServerData sServerData;

enum struct ClientData
{
	int PropLevel;
	int PriceUp[10];
}
ClientData sClientData[MAXPLAYERS+1];

int m_ModeNormal;

public void OnPluginStart()
{
	LoadTranslations("zombiemod_shop.phrases");
	LoadTranslations("shop_props.phrases");
	LoadTranslations("utils.phrases");
	
	sServerData.ArrayProps = new ArrayList(sizeof(PropData));

	RegConsoleCmd("zprops", Command_PropMenu);
	RegConsoleCmd("props", Command_PropMenu);
	
	HookEvent("round_start", Event_RoundStart);
}

public void OnPluginEnd()
{
	sServerData.Clear();
	
	UnhookEvent("round_start", Event_RoundStart);
}

public void OnMapStart()
{
	PrecacheSound(SOUND_BUTTON_MENU, true);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		for (int x = 0; x < 10; x++)
		{
			sClientData[i].PriceUp[x] = 0;
		}
		
		sClientData[i].PropLevel = 1;
	}
}

public void OnConfigsExecuted()
{
	sServerData.Clear();

	char buffer[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, buffer, sizeof(buffer), "configs/zombiemod/props.ini");

	KeyValues kv = new KeyValues("props");
	if (kv.ImportFromFile(buffer) && kv.GotoFirstSubKey())
	{
		PropData pd;
		
		do {
			kv.GetString("name", buffer, sizeof(buffer), "");
			strcopy(pd.name, sizeof(pd.name), buffer);
			
			kv.GetSectionName(buffer, sizeof(buffer));
			strcopy(pd.modelname, sizeof(pd.modelname), buffer);
			PrecacheModel(buffer);
			
			kv.GetString("classname", buffer, sizeof(buffer), "prop_physics");
			strcopy(pd.classname, sizeof(pd.classname), buffer);
			
			pd.price = kv.GetNum("price", 0);
			pd.heal = kv.GetNum("health", 0);
			
			sServerData.ArrayProps.PushArray(pd);
		}
		while (kv.GotoNextKey());
	}
	delete kv;
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
	m_ModeNormal = ZM_GetGameModeNameID("normal mode");
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

public Action Command_PropMenu(int client, int first_item)
{
	if (IsValidClient(client) && IsPlayerAlive(client) && ZM_IsClientHuman(client))
	{
		if (ZM_GetCurrentGameMode() != m_ModeNormal)
		{
			PrintToChat_Lang(client, "%T", "GAME_MODE_NORMAL", client);
			return Plugin_Handled;
		}
		
		PropData pd; char buffer[164], info[32];
		
		Menu menu = new Menu(MenuHandler_PropsMenu);
		menu.SetTitle("%T", "MENU_SHOP_PROPS_2", client, sClientData[client].PropLevel);
		
		SetGlobalTransTarget(client);
		for (int i = 0; i < sServerData.ArrayProps.Length; i++)
		{
			sServerData.ArrayProps.GetArray(i, pd, sizeof(pd));
			FormatEx(buffer, sizeof(buffer), IsTranslatedForLanguage(pd.name, GetServerLanguage()) ? "%t":"%s", pd.name);
			FormatEx(info, sizeof(info), "%s; %d", pd.name, pd.price);
			
			SS_AddMenuItem(menu, client, info, buffer, i, pd.price);
		}
		
		menu.Display(client, MENU_TIME_FOREVER);
	}
	return Plugin_Handled;
}

void SS_AddMenuItem(Menu menu, int client, const char[] info, const char[] name, int item, int price)
{
	char buffer[264];
	
	if (price != 0)
	{
		int up = price * (sClientData[client].PriceUp[item] + 1);
		FormatEx(buffer, sizeof(buffer), "%s[%d %T]", name, up, "ammopack 2", client);
		menu.AddItem(info, buffer, (GetClientAmmoPacks(client) >= up && sClientData[client].PropLevel > 0) ? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	}
	else
	{
		FormatEx(buffer, sizeof(buffer), "%s", name);
		menu.AddItem(info, buffer);
	}
}

public int MenuHandler_PropsMenu(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		if (IsValidClient(param1) && IsPlayerAlive(param1) && ZM_IsClientHuman(param1))
		{
			if (ZM_GetCurrentGameMode() != m_ModeNormal)
			{
				PrintToChat_Lang(param1, "%T", "GAME_MODE_NORMAL", param1);
				EmitSoundToClient(param1, SOUND_BUTTON_MENU);
				return 0;
			}
			
			if (GetEntitySequence(param1) != 0)
			{
				EmitSoundToClient(param1, SOUND_BUTTON_MENU);
				return 0;
			}
			
			if (sClientData[param1].PropLevel <= 0)
			{
				Command_PropMenu(param1, 0);
				return 0;
			}
			
			char info[64]; char buffer[2][164];
			menu.GetItem(param2, info, sizeof(info));
			ExplodeString(info, "; ", buffer, sizeof(buffer), sizeof(buffer[]));
			int price = StringToInt(buffer[1]);
			
			if (SetClientPriceUp(param1, param2, price) > GetClientAmmoPacks(param1))
			{
				ZM_PrintToChat(param1, _, "%t", "CHAT_NO_AMMOPACKS");
				return 0;
			}
			
			float origin[3], angles[3], pos[3];
			if (!SetTeleportEndPoint(param1, pos, angles))
			{
				PrintToChat_Lang(param1, "%T", "PROP_TELEPORT", param1);
				Command_PropMenu(param1, 0);
				return 0;
			}
			
			GetClientAbsOrigin(param1, origin);
			if (GetVectorDistance(origin, pos) >= 60)
			{
				PrintToChat_Lang(param1, "%T", "PROP_DISTANCE", param1);
				Command_PropMenu(param1, 0);
				return 0;
			}
			
			int index = sServerData.ArrayProps.FindString(buffer[0]);
			
			if (index != -1)
			{
				PropData pd;
				sServerData.ArrayProps.GetArray(index, pd);
				
				int entity = CreateEntityByName(pd.classname); // prop_dynamic_override
				
				Format(info, sizeof(info), "props_%d", entity); 
				DispatchKeyValue(entity, "targetname", info);     

				DispatchKeyValue(entity, "massScale", "3.5");
				DispatchKeyValue(entity, "physicsmode", "2");
				DispatchKeyValue(entity, "physdamagescale", "0.0");
				DispatchKeyValue(entity, "model", pd.modelname);
				DispatchKeyValue(entity, "Solid", "6");
				
				DispatchSpawn(entity);
				
				if (StrContains(pd.classname, "prop_physics") > -1)
				{
					pos[2] += 12.0;
					angles[2] += 50.0;
					angles[1] -= 90.0;
				}
				
				TeleportEntity(entity, pos, angles, NULL_VECTOR);
				
				if (pd.heal != 0)
				{
					SetEntProp(entity, Prop_Data, "m_takedamage", 2);
					SetEntProp(entity, Prop_Data, "m_iMaxHealth", pd.heal);
					SetEntProp(entity, Prop_Data, "m_iHealth", pd.heal);
					
					SDKHook(entity, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
				}
				
				DataPack data = new DataPack();
				RequestFrame(Frame_EntityStuck, data);
				data.WriteCell(GetClientUserId(param1));
				data.WriteCell(EntIndexToEntRef(entity));
				data.WriteCell(param2);
				data.WriteCell(price);
			}
			
			// Command_PropMenu(param1, menu.Selection);
		}
	}
	return 0;
}

public Action Hook_OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	if (victim > 0 && IsValidEdict(victim) && IsValidClient(attacker))
	{
		static char classname[32];
		if (inflictor >= 0 && GetEntityClassname(inflictor, classname, sizeof(classname)) &&(strcmp(classname, "env_explosion") == 0))
		{
			return Plugin_Handled;
		}
		
		float origin[3];
		GetEntPropVector(victim, Prop_Send, "m_vecOrigin", origin);
		
		// attack sounds
		TE_SetupSparks(origin, NULL_VECTOR, 1, 1);
		TE_SendToAll();
	}
	return Plugin_Continue;
}

public void Frame_EntityStuck(DataPack data)
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
		sClientData[client].PropLevel--;
		sClientData[client].PriceUp[item]++;
		
		SetClientAmmoPacks(client, -price * (sClientData[client].PriceUp[item]));
		Command_PropMenu(client, 0);
	}
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
	return entity > MaxClients || !entity;
}

public void ZM_OnGameModeStart(int gamemode)
{
	if (gamemode != m_ModeNormal) {
		return;
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && !IsFakeClient(i))
		{
			if (GetClientLevel(i) >= 7)
			{
				sClientData[i].PropLevel = 2; // 2
			}
			else
			{
				sClientData[i].PropLevel = 1; // 1
			}
		}
	}
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
	return entity == ent;
}

stock void PrintToChat_Lang(int client, const char[] format, any ...)
{
	char buffer[254];
	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), format, 3);
	ReplaceString(buffer, sizeof(buffer), "#", "\x07");
	PrintToChat(client, "%s", buffer);
}

int SetClientPriceUp(int client, int item, int price)
{
	return price * (sClientData[client].PriceUp[item] + 1);
}