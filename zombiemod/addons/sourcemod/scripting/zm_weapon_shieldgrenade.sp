#include <zombiemod>

#pragma semicolon 1
#pragma newdecls required

#define MODEL_SHIELD "models/player/technology/angel_shield.mdl"
#define MAX_COUNTTIMER 300

static const char g_model[][] = {
	"models/zombiecity/weapons/shield_grenade/v_shield_grenade.dx80.vtx",
	"models/zombiecity/weapons/shield_grenade/v_shield_grenade.dx90.vtx",
	"models/zombiecity/weapons/shield_grenade/v_shield_grenade.mdl",
	"models/zombiecity/weapons/shield_grenade/v_shield_grenade.sw.vtx",
	"models/zombiecity/weapons/shield_grenade/v_shield_grenade.vvd",
	"models/zombiecity/weapons/shield_grenade/w_shield_grenade.dx80.vtx",
	"models/zombiecity/weapons/shield_grenade/w_shield_grenade.dx90.vtx",
	"models/zombiecity/weapons/shield_grenade/w_shield_grenade.mdl",
	"models/zombiecity/weapons/shield_grenade/w_shield_grenade.phy",
	"models/zombiecity/weapons/shield_grenade/w_shield_grenade.sw.vtx",
	"models/zombiecity/weapons/shield_grenade/w_shield_grenade.vvd",
	"materials/models/zombiecity/weapons/shield_grenade/handfinal256.vmt",
	"materials/models/zombiecity/weapons/shield_grenade/handfinal256.vtf",
	"materials/models/zombiecity/weapons/shield_grenade/holyhandgrenadeskin.vmt",
	"materials/models/zombiecity/weapons/shield_grenade/holyhandgrenadeskin.vtf"
};

static const char g_model2[][] = {
	"models/player/technology/angel_shield.dx80.vtx",
	"models/player/technology/angel_shield.dx90.vtx",
	MODEL_SHIELD,
	"models/player/technology/angel_shield.sw.vtx",
	"models/player/technology/angel_shield.vvd",
	"materials/models/player/technology/angel_shield/angel_shield.vmt",
	"materials/models/player/technology/angel_shield/angel_shield_dudv.vtf",
	"materials/models/player/technology/angel_shield/angel_shield_dx7.vmt",
	"materials/models/player/technology/angel_shield/angel_shield_dx7.vtf",
	"materials/models/player/technology/angel_shield/angel_shield_n.vtf",
	"materials/models/player/technology/angel_shield/angel_shield_tint.vtf"
};

public Plugin myinfo = {
	name = "[ZM] Weapon shieldgrenade",
	author = "0kEmo",
	version = "1.0"
};

IntMap TrieEntity;
int m_Weapon;
int m_vecOrigin = -1;

public void OnPluginStart()
{
	TrieEntity = new IntMap();
	
	m_vecOrigin = FindSendPropInfo("CBaseEntity", "m_vecOrigin");
	
	HookEvent("round_end", Event_RoundEnd);
}

public void OnMapStart()
{
	char mapname[PLATFORM_MAX_PATH];
	GetCurrentMap(mapname, sizeof(mapname));
	if (!strncmp(mapname, "ze_", 3, false)) {
		return;
	}

	for (int i = 0; i < sizeof(g_model); i++) {
		AddFileToDownloadsTable(g_model[i]);
	}
	for (int i = 0; i < sizeof(g_model2); i++) {
		AddFileToDownloadsTable(g_model2[i]);
	}

	PrecacheModel(MODEL_SHIELD, true);
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
	m_Weapon = ZM_GetWeaponNameID("weapon_shieldgrenade");
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	TrieEntity.Clear();
	return Plugin_Continue;
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if (StrEqual(classname, "smokegrenade_projectile"))
    {
		RequestFrame(OnGrenadeCreatedPost, EntIndexToEntRef(entity));
    }
}

public void OnGrenadeCreatedPost(int ref)
{
	int entity = EntRefToEntIndex(ref);
	if (entity != INVALID_ENT_REFERENCE)
	{
		static char classname[32];
		GetEntityClassname(entity, classname, sizeof(classname));
		
		if (strcmp(classname, "smokegrenade_projectile") == 0)
		{
			if (GetEntProp(entity, Prop_Data, "m_iMaxHealth") == m_Weapon)
			{
				SetEntProp(entity, Prop_Data, "m_nNextThinkTick", -1);
				SDKHook(entity, SDKHook_StartTouchPost, Hook_StartTouchPost);
			}
		}
	}
}

public Action Hook_StartTouchPost(int entity, int other)
{
	if (IsValidEdict(other))
	{
		int thrower = GetEntPropEnt(entity, Prop_Data, "m_hThrower");
		if (UTIL_IsEntityOnground2(entity) || thrower == other) {
			return Plugin_Continue;
		}
		
		CreateTimer(1.5, Timer_ShieldGrenade, EntIndexToEntRef(entity));
		SDKUnhook(entity, SDKHook_StartTouchPost, Hook_StartTouchPost);
	}
	return Plugin_Continue;
}

public bool Filter_NoPlayer(int entity, int contentsMask, int data)
{
    return (entity == data || 1 <= entity <= MaxClients) ? false : true;
}

public Action Timer_ShieldGrenade(Handle timer, any data)
{
	int entity = EntRefToEntIndex(data);
	if (entity < 1 || !IsValidEdict(entity) || ZM_IsEndRound())
	{
		return Plugin_Stop;
	}
	
	float origin[3]; GetEntDataVector(entity, m_vecOrigin, origin);
	int ent = CreateEntityByName("prop_dynamic_override");
	if (ent != -1)
	{
		DispatchKeyValue(ent, "model", MODEL_SHIELD);
		DispatchSpawn(ent);
		
		TeleportEntity(ent, origin, NULL_VECTOR, NULL_VECTOR);
		
		SetEntProp(ent, Prop_Send, "m_usSolidFlags", 8);
		
		TrieEntity.SetValue(ent, MAX_COUNTTIMER);
		CreateTimer(0.1, Timer_Shield, EntIndexToEntRef(ent), TIMER_REPEAT);
	}
	
	AcceptEntityInput(entity, "kill");
	return Plugin_Continue;
}

public Action Timer_Shield(Handle timer, any data)
{
	int entity = EntRefToEntIndex(data);
	if (entity < 1 || !IsValidEdict(entity)) {
		return Plugin_Stop;
	}
	static int iCount;
	TrieEntity.GetValue(entity, iCount);
	
	if (iCount < 1 || ZM_IsEndRound())
	{
		TrieEntity.SetValue(entity, 0);
		AcceptEntityInput(entity, "Kill");
		return Plugin_Stop;
	}
	float EntityOrigin[3], PlayerOrigin[3], vec[3];
	GetEntDataVector(entity, m_vecOrigin, EntityOrigin);
	
	TrieEntity.SetValue(entity, --iCount);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i))
		{
			GetClientAbsOrigin(i, PlayerOrigin);
			
			if (GetVectorDistance(EntityOrigin, PlayerOrigin) <= 177)
			{
				if (ZM_IsClientHuman(i))
				{
					UTIL_ScreenFade(i, 0.15, 0.15, FFADE_IN, {0, 255, 255, 1});
				}
				else
				{
					SetEntityMoveType(i, MOVETYPE_WALK);
					MakeVectorFromPoints(EntityOrigin, PlayerOrigin, vec);
					NormalizeVector(vec, vec);
					ScaleVector(vec, 300.0);
					TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, vec);
				}
			}
		}
	}
	return Plugin_Continue;
}