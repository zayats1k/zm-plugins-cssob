#include <zombiemod>
#include <zm_player_animation>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name = "[ZM] Weapon awp_buff",
	author = "0kEmo",
	version = "1.0"
};

static const char g_model[][] = {
	"models/zombiecity/weapons/awp_buff/v_awp_buff.dx80.vtx",
	"models/zombiecity/weapons/awp_buff/v_awp_buff.dx90.vtx",
	"models/zombiecity/weapons/awp_buff/v_awp_buff.mdl",
	"models/zombiecity/weapons/awp_buff/v_awp_buff.sw.vtx",
	"models/zombiecity/weapons/awp_buff/v_awp_buff.vvd",
	"models/zombiecity/weapons/awp_buff/w_awp_buff.dx80.vtx",
	"models/zombiecity/weapons/awp_buff/w_awp_buff.dx90.vtx",
	"models/zombiecity/weapons/awp_buff/w_awp_buff.mdl",
	"models/zombiecity/weapons/awp_buff/w_awp_buff.phy",
	"models/zombiecity/weapons/awp_buff/w_awp_buff.sw.vtx",
	"models/zombiecity/weapons/awp_buff/w_awp_buff.vvd",
	"materials/models/weapons/v_models/awp_buff/awpbuff1.vmt",
	"materials/models/weapons/v_models/awp_buff/awpbuff1.vtf",
	"materials/models/weapons/v_models/awp_buff/awpbuff1_ref.vtf",
	"materials/models/weapons/v_models/awp_buff/awpbuff2.vmt",
	"materials/models/weapons/v_models/awp_buff/awpbuff2.vtf",
	"materials/models/weapons/v_models/awp_buff/awpbuff2_ref.vtf",
	"materials/models/weapons/v_models/awp_buff/awpfx01.vmt",
	"materials/models/weapons/v_models/awp_buff/awpfx01.vtf",
	"materials/models/weapons/v_models/awp_buff/awpfx02.vmt",
	"materials/models/weapons/v_models/awp_buff/awpfx02.vtf",
	"materials/models/weapons/w_models/awp_buff/awp_buff_p.vmt",
	"materials/models/weapons/w_models/awp_buff/awp_buff_p.vtf"
};

float m_flStartCharge[MAXPLAYERS+1];
int m_Weapon;
int m_fov[MAXPLAYERS+1];
int m_flProgressBarStartTimeOffset, m_iProgressBarDurationOffset;

public void OnPluginStart()
{
	m_flProgressBarStartTimeOffset = FindSendPropInfo("CCSPlayer", "m_flProgressBarStartTime");
	m_iProgressBarDurationOffset = FindSendPropInfo("CCSPlayer", "m_iProgressBarDuration");
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
	m_Weapon = ZM_GetWeaponNameID("weapon_awp_buff");
}

public void ZM_OnClientValidateDamage(int client, int& attacker, int& inflicter, float& damage, int& damagetype)
{
	if (IsValidClient(attacker) && IsPlayerAlive(attacker) && ZM_IsClientHuman(attacker) && m_fov[attacker] == 1)
	{
		int weapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
		if (weapon != -1 && GetEntProp(weapon, Prop_Data, "m_iMaxHealth") == m_Weapon)
		{
			if (IsValidClient(client) && IsPlayerAlive(client) && ZM_IsClientZombie(client))
			{
				float time = GetGameTime();
				
				if (m_flStartCharge[attacker] > time - 4.0)
				{
					damage += ((time - m_flStartCharge[attacker]) * 60.0) + 60.0;
				}
				else if (m_flStartCharge[attacker] <= time - 4.0)
				{
					damage += 370.0;
				}
			}
		}
	}
}

public void OnPlayerSequencePre(int client, int entity, const char[] anim)
{
	if (IsValidClient(client))
	{
		if (m_fov[client] == 1)
		{
			SetProgressBar(client, 0.0, 0, 1);
			m_flStartCharge[client] = 0.0;
			m_fov[client] = 0;
		}
	}
}

public void ZM_OnWeaponDeploy(int client, int weapon, int id)
{
	if (id == m_Weapon)
	{
		OnPlayerSequencePre(client, 0, "");
	}
}

public void ZM_OnWeaponHolster(int client, int weapon, int id)
{
	if (id == m_Weapon)
	{
		OnPlayerSequencePre(client, 0, "");
	}
}

public void ZM_OnWeaponDrop(int client, int weapon, int id)
{
	if (id == m_Weapon)
	{
		OnPlayerSequencePre(client, 0, "");
	}
}

public Action ZM_OnWeaponRunCmd(int client, int& buttons, int LastButtons, int weapon, int id)
{
	if (id == m_Weapon)
	{
		float time = GetGameTime();
		
		if (GetEntProp(client, Prop_Send, "m_iObserverMode") == 0)
		{
			if (GetEntPropFloat(weapon, Prop_Data, "m_flNextSecondaryAttack") + 0.15 > time)
			{
				int fov = GetEntProp(client, Prop_Data, "m_iFOV");
				
				if (fov != 90 && fov != 0)
				{
					if (m_fov[client] != 1)
					{
						SetProgressBar(client, GetGameTime(), 4, 4);
						m_flStartCharge[client] = time;
						m_fov[client] = 1;
					}
				}
				else OnPlayerSequencePre(client, 0, "");
			}
		}
		else OnPlayerSequencePre(client, 0, "");
	}
	return Plugin_Continue;
}

stock void SetProgressBar(int client, float time, int interval, int size)
{
	SetEntDataFloat(client, m_flProgressBarStartTimeOffset, time, true);
	SetEntData(client, m_iProgressBarDurationOffset, interval, size, true);
}