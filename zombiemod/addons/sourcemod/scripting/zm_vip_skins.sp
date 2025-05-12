#include <zombiemod>
#include <zm_vip_system>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name = "[ZM & VIP] Skins",
	author = "0kEmo",
	version = "1.0"
};

#define MODEL_VIP "models/zombiecity/humans/vip_zm/vip.mdl"
#define MODEL_SVIP "models/zombiecity/humans/supervip_zm/supervip.mdl"

// #define MODEL_VIP_MECHANIC "models/zombiecity/humans/vip_mechanic/mechanic.mdl"
// #define MODEL_VIP_LINOLN "models/zombiecity/humans/gamemode_survivor/lincoln.mdl"

// static const char g_vipmechanicmodel[][] =
// {
// 	"models/zombiecity/humans/vip_mechanic/mechanic.phy",
// 	"models/zombiecity/humans/vip_mechanic/mechanic.sw.vtx",
// 	"models/zombiecity/humans/vip_mechanic/mechanic.vvd",
// 	"models/zombiecity/humans/vip_mechanic/mechanic.dx80.vtx",
// 	"models/zombiecity/humans/vip_mechanic/mechanic.dx90.vtx",
// 	MODEL_VIP_MECHANIC,
// 	"materials/models/zombiecity/humans/vip_mechanic/mechanic_eyes.vtf",
// 	"materials/models/zombiecity/humans/vip_mechanic/mechanic_hair_color.vtf",
// 	"materials/models/zombiecity/humans/vip_mechanic/mechanic_head_color.vtf",
// 	"materials/models/zombiecity/humans/vip_mechanic/mechanic_head_normal.vtf",
// 	"materials/models/zombiecity/humans/vip_mechanic/mechanic_body_color.vmt",
// 	"materials/models/zombiecity/humans/vip_mechanic/mechanic_color_it.vmt",
// 	"materials/models/zombiecity/humans/vip_mechanic/mechanic_eyes.vmt",
// 	"materials/models/zombiecity/humans/vip_mechanic/mechanic_hair_color.vmt",
// 	"materials/models/zombiecity/humans/vip_mechanic/mechanic_head_color.vmt",
// 	"materials/models/zombiecity/humans/vip_mechanic/mechanic_body_color.vtf",
// 	"materials/models/zombiecity/humans/vip_mechanic/mechanic_body_normal.vtf"
// };

static const char g_vipmodel[][] =
{
	"models/zombiecity/humans/vip_zm/vip.dx80.vtx",
	"models/zombiecity/humans/vip_zm/vip.dx90.vtx",
	MODEL_VIP,
	"models/zombiecity/humans/vip_zm/vip.phy",
	"models/zombiecity/humans/vip_zm/vip.sw.vtx",
	"models/zombiecity/humans/vip_zm/vip.vvd",
	"materials/models/zombiecity/humans/vip_zm/ct_707.vmt",
	"materials/models/zombiecity/humans/vip_zm/ct_707.vtf",
	"materials/models/zombiecity/humans/vip_zm/ct_707_eyeball_l.vmt",
	"materials/models/zombiecity/humans/vip_zm/ct_707_eyeball_l.vtf",
	"materials/models/zombiecity/humans/vip_zm/ct_707_eyeball_r.vmt",
	"materials/models/zombiecity/humans/vip_zm/ct_707_eyeball_r.vtf",
	"materials/models/zombiecity/humans/vip_zm/ct_707_glass.vmt",
	"materials/models/zombiecity/humans/vip_zm/ct_707_glass.vtf",
	"materials/models/zombiecity/humans/vip_zm/ct_707_glass_normal.vtf",
	"materials/models/zombiecity/humans/vip_zm/ct_707_normal.vtf"
};

static const char g_svipmodel[][] =
{
	"models/zombiecity/humans/supervip_zm/supervip.dx80.vtx",
	"models/zombiecity/humans/supervip_zm/supervip.dx90.vtx",
	MODEL_SVIP,
	"models/zombiecity/humans/supervip_zm/supervip.phy",
	"models/zombiecity/humans/supervip_zm/supervip.sw.vtx",
	"models/zombiecity/humans/supervip_zm/supervip.vvd",
	"materials/models/zombiecity/humans/supervip_zm/ct_gign_eyeball_l.vmt",
	"materials/models/zombiecity/humans/supervip_zm/ct_gign_eyeball_l.vtf",
	"materials/models/zombiecity/humans/supervip_zm/ct_gign_eyeball_r.vmt",
	"materials/models/zombiecity/humans/supervip_zm/ct_gign_eyeball_r.vtf",
	"materials/models/zombiecity/humans/supervip_zm/ct_sas.vmt",
	"materials/models/zombiecity/humans/supervip_zm/ct_sas.vtf",
	"materials/models/zombiecity/humans/supervip_zm/ct_sas_maskglass.vmt",
	"materials/models/zombiecity/humans/supervip_zm/ct_sas_maskglass.vtf",
	"materials/models/zombiecity/humans/supervip_zm/ct_sas_maskglass_normal.vtf",
	"materials/models/zombiecity/humans/supervip_zm/ct_sas_normal.vtf"
};

int m_HumanSniper, m_HumanSurvivor;

public void OnMapStart()
{
	for (int i = 0; i < sizeof(g_vipmodel); i++) {
		AddFileToDownloadsTable(g_vipmodel[i]);
	}
	for (int i = 0; i < sizeof(g_svipmodel); i++) {
		AddFileToDownloadsTable(g_svipmodel[i]);
	}
	
	PrecacheModel(MODEL_VIP, true);
	PrecacheModel(MODEL_SVIP, true);
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
	m_HumanSniper = ZM_GetClassNameID("human_sniper");
	m_HumanSurvivor = ZM_GetClassNameID("human_survivor");
}

public Action ZM_OnClientModel(int client, const char[] model)
{
	if (IsValidClient(client) && ZM_IsClientHuman(client))
	{
		if (VIP_IsClientVIP(client))
		{
			int id = ZM_GetClientClass(client);
			if (id == m_HumanSniper || id == m_HumanSurvivor)
			{
				return Plugin_Continue;
			}
		
			if (ZM_GetClientSkin(client) != -1)
			{
				return Plugin_Continue;
			}
			
			static char group[SMALL_LINE_LENGTH];
			VIP_GetClientGroup(client, group, sizeof(group));
			if (strcmp(group, "VIP") == 0) // || strcmp(group, "SUPERVIP") == 0
			{
				SetEntityModel(client, MODEL_VIP);
				return Plugin_Handled;
			}
			else if (strcmp(group, "SUPERVIP") == 0)
			{
				SetEntityModel(client, MODEL_SVIP);
				return Plugin_Handled;
			}
			// else if (strcmp(group, "MAXIMUM") == 0)
			// {
			// 	SetEntityModel(client, MODEL_VIP_LINOLN);
			// 	return Plugin_Handled;
			// }
		}
	}
	return Plugin_Continue;
}