#include <zombiemod>
#include <zm_settings>
#include <shop_system>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name = "[ZM] Zombie Class: Tank",
	author = "0kEmo",
	version = "3.0"
};

#define CLASS_TANK_COOLDOWN 35.0

static const char g_model[][] = {
	"models/zschool/rustambadr/normalhost/hand/hand_zombie_normalhost.dx80.vtx",
	"models/zschool/rustambadr/normalhost/hand/hand_zombie_normalhost.dx90.vtx",
	"models/zschool/rustambadr/normalhost/hand/hand_zombie_normalhost.mdl",
	"models/zschool/rustambadr/normalhost/hand/hand_zombie_normalhost.sw.vtx",
	"models/zschool/rustambadr/normalhost/hand/hand_zombie_normalhost.vvd",
	"models/zschool/rustambadr/normalhost/zombie_normalhost.dx80.vtx",
	"models/zschool/rustambadr/normalhost/zombie_normalhost.dx90.vtx",
	"models/zschool/rustambadr/normalhost/zombie_normalhost.mdl",
	"models/zschool/rustambadr/normalhost/zombie_normalhost.phy",
	"models/zschool/rustambadr/normalhost/zombie_normalhost.sw.vtx",
	"models/zschool/rustambadr/normalhost/zombie_normalhost.vvd",
	"materials/models/zschool/rustambadr/normalhost/hand/zombie_normalhost_hand.vmt",
	"materials/models/zschool/rustambadr/normalhost/zombie_normalhost_body.vmt",
	"materials/models/zschool/rustambadr/normalhost/zombie_normalhost_body.vtf",
	"materials/models/zschool/rustambadr/normalhost/zombie_normalhost_body_normal.vtf",
	"materials/models/zschool/rustambadr/normalhost/zombie_normalhost_hand.vmt",
	"materials/models/zschool/rustambadr/normalhost/zombie_normalhost_hand.vtf",
	"materials/models/zschool/rustambadr/normalhost/zombie_normalhost_hand_normal.vtf",
	"materials/models/zschool/rustambadr/normalhost/zombie_normalhost_sign.vmt",
	"materials/models/zschool/rustambadr/normalhost/zombie_normalhost_sign.vtf",
	"materials/models/zschool/rustambadr/normalhost/zombie_normalhost_sign_normal.vtf"
};

static const char g_LoopSounds[4][] = {
	"npc/zombie/moan_loop1.wav",
	"npc/zombie/moan_loop2.wav",
	"npc/zombie/moan_loop3.wav",
	"npc/zombie/moan_loop4.wav"
};

int m_Zombie;

enum struct ServerData
{
	int hActiveWeaponOffset;
	int OwnerEntityOffset;
	// int CollisionOffset;
	
	void Clear()
	{
		this.hActiveWeaponOffset = -1;
		this.OwnerEntityOffset = -1;
		// this.CollisionOffset = -1;
	}
}
ServerData sServerData;

enum struct ClientData
{
	Handle TimerHud;
	Handle TimerIgnite;
	
	bool ZombieClass;
	bool PlayerCanUse;
	
	int MoanSound;
	
	float Cooldown;
	float HudTimeLoad;
	float BotUse;
	
	void Clear()
	{
		this.ZombieClass = false;
		this.PlayerCanUse = false;
		this.MoanSound = 0;
		this.Cooldown = 0.0;
		this.HudTimeLoad = 0.0;
		this.BotUse = 0.0;
		
		if (this.TimerIgnite != null) {
			delete this.TimerIgnite;
		}
	}
	void StopSounds(int client)
	{
		for (int i = 0; i < sizeof(g_LoopSounds); i++)
		{
			StopSound(client, SNDCHAN_AUTO, g_LoopSounds[i]);
		}
	}
}
ClientData sClientData[MAXPLAYERS+1];			

public void OnPluginStart()
{
	LoadTranslations("zm_class.phrases");

	sServerData.hActiveWeaponOffset = FindSendPropInfo("CCSPlayer", "m_hActiveWeapon");
	sServerData.OwnerEntityOffset = FindSendPropInfo("CBaseEntity", "m_hOwnerEntity");
	// sServerData.CollisionOffset = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
	
	HookEvent("player_death", Hook_PlayerDeath);
	
	AddNormalSoundHook(Hook_IgniteSound);
}

public void OnPluginEnd()
{
	sServerData.Clear();
	
	UnhookEvent("player_death", Hook_PlayerDeath);
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

	for (int i = 0; i < sizeof(g_LoopSounds); i++) {
		PrecacheSound(g_LoopSounds[i], true);
	}
}

public void OnMapEnd()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		sClientData[i].TimerIgnite = null;
	}
}

public void OnClientDisconnect_Post(int client)
{
	sClientData[client].Clear();
	
	SDKUnhook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
	SDKUnhook(client, SDKHook_OnTakeDamagePost, Hook_OnTakeDamagePost);
	SDKUnhook(client, SDKHook_PostThinkPost, Hook_PostThinkPost);
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
	m_Zombie = ZM_GetClassNameID("zombie_tank");
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3])
{
	if (IsValidClient(client) && IsPlayerAlive(client) && ZM_IsClientZombie(client) && sClientData[client].ZombieClass) 
	{
		if (sClientData[client].Cooldown <= 0.0)
		{
			if (GetEntityFlags(client) & FL_ONGROUND || GetEntityMoveType(client) == MOVETYPE_LADDER)
			{
				if (!sClientData[client].PlayerCanUse)
				{
					sClientData[client].HudTimeLoad = 0.0;
					sClientData[client].PlayerCanUse = true;
				}
			}
			else
			{
				if (sClientData[client].PlayerCanUse)
				{
					sClientData[client].HudTimeLoad = 0.0;
					sClientData[client].PlayerCanUse = false;
				}
			}
			
			if (IsFakeClient(client))
			{
				if (GetEntityFlags(client) & FL_ONGROUND)
				{
					float time = GetGameTime();
					
					if (sClientData[client].BotUse < time)
					{
						sClientData[client].BotUse = time + GetRandomFloat(2.0, 1.0);
						
						float origin[3]; bool use = false;
						for (int i = 1; i <= MaxClients; i++)
						{
							if (IsValidClient(i) && IsPlayerAlive(i) && ZM_IsClientHuman(i))
							{
								GetClientAbsOrigin(i, origin);
								
								if (IsTargetInSightRange(origin, client, 60.0, 500.0))
								{
									use = true;
								}
							}
						}
						
						if (use == true)
						{
							buttons |= IN_RELOAD;
						}
					}
				}
			}
			
			static int iOldButton[MAXPLAYERS+1];
			if (buttons & IN_RELOAD && !(iOldButton[client] & IN_RELOAD))
			{
				if (sClientData[client].Cooldown == RoundToFloor(-1.0))
				{
					return Plugin_Continue;
				}
				
				if (ZM_IsEndRound())
				{
					return Plugin_Continue;
				}
				
				if (IsFakeClient(client))
				{
					IgniteEntity(client, 5.0);
					
					delete sClientData[client].TimerIgnite;
					sClientData[client].TimerIgnite = CreateTimer(6.0, Timer_StopIgnite, GetClientUserId(client));
					
					SDKHook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
					SDKHook(client, SDKHook_OnTakeDamagePost, Hook_OnTakeDamagePost);
					
					sClientData[client].StopSounds(client);
					EmitSoundToAll(g_LoopSounds[sClientData[client].MoanSound], client);
					
					sClientData[client].MoanSound++;
					if (sClientData[client].MoanSound > 3) {
						sClientData[client].MoanSound = 0;
					}
					
					sClientData[client].Cooldown = -1.0;
					return Plugin_Continue;
				}
				
				if (sClientData[client].PlayerCanUse)
				{
					IgniteEntity(client, 5.0 + GetClientSkill(client, 1));
					
					delete sClientData[client].TimerIgnite;
					sClientData[client].TimerIgnite = CreateTimer(6.0 + GetClientSkill(client, 1), Timer_StopIgnite, GetClientUserId(client));
					
					SDKHook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
					SDKHook(client, SDKHook_OnTakeDamagePost, Hook_OnTakeDamagePost);
					
					int ClientWeapon = GetEntDataEnt2(client, sServerData.hActiveWeaponOffset);
					if (IsValidEdict(ClientWeapon)) {
						ZM_SendWeaponAnim(ClientWeapon, ACT_VM_DRAW);
					}
					
					sClientData[client].StopSounds(client);
					EmitSoundToAll(g_LoopSounds[sClientData[client].MoanSound], client);
					
					sClientData[client].MoanSound++;
					if (sClientData[client].MoanSound > 3) {
						sClientData[client].MoanSound = 0;
					}
					
					sClientData[client].HudTimeLoad = 0.0;
					sClientData[client].Cooldown = -1.0;
				}
			}
			iOldButton[client] = buttons;
		}
	}
	return Plugin_Continue;
}

public Action Timer_StopIgnite(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	sClientData[client].TimerIgnite = null;
	
	if (IsValidClient(client) && IsPlayerAlive(client) && ZM_IsClientZombie(client))
	{
		sClientData[client].Cooldown = CLASS_TANK_COOLDOWN;
		sClientData[client].HudTimeLoad = 0.0;
		sClientData[client].StopSounds(client);
		
		ZM_SetWeaponAnimation(client, 0);
		
		SDKUnhook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
		SDKUnhook(client, SDKHook_OnTakeDamagePost, Hook_OnTakeDamagePost);
	}
	return Plugin_Stop;
}

public Action Hook_OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	// PrintToChatAll("\x0700FFFF%d - %d - %d - %f - %d", victim, attacker, inflictor, damage, damagetype);
	
	if (IsValidClient(victim) && IsPlayerAlive(victim) && ZM_IsClientZombie(victim) && sClientData[victim].ZombieClass)
	{
		if (damagetype & (DMG_BURN | DMG_DIRECT))
		{
			SetEntProp(victim, Prop_Send, "m_ArmorValue", 1, 1);
		}
		
		if (damagetype == 4098 || damagetype == 1073745922)
		{
			if (IsValidClient(attacker) && IsPlayerAlive(attacker) && ZM_IsClientHuman(attacker))
			{
				damage *= 0.05;
				if (damage < 1.0) damage = GetRandomFloat(0.5, 4.0);
				damage *= GetClientSkill(victim, 0) + 1.0;
				
				int ent = CreateEntityByName("hegrenade_projectile");
				if (ent != -1)
				{
					float origin[3], pos[3]; char buffer[64];
					GetClientEyePosition(victim, pos);
					
					pos[0] += GetRandomFloat(-5.0, 5.0);
					pos[1] += GetRandomFloat(-5.0, 5.0);
					pos[2] += GetRandomFloat(-60.0, -30.0);
					
					Format(buffer, sizeof(buffer), "target_d_%d", ent); 
					DispatchKeyValue(ent, "targetname", buffer);     
					DispatchSpawn(ent);
					
					SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
					SetEntityRenderColor(ent, 255, 255, 255, 0);
				
					TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
					
					SetEntityMoveType(ent, MOVETYPE_NONE);
					SetEntProp(ent, Prop_Data, "m_takedamage", 0);
					SetEntProp(ent, Prop_Send, "m_nSolidType", 0);
					SetEntPropEnt(ent, Prop_Data, "m_pParent", attacker); 
					SetEntPropEnt(ent, Prop_Data, "m_hThrower", attacker);
					SetEntPropFloat(ent, Prop_Send, "m_flModelScale", 0.0001);
					// SetEntData(ent, sServerData.CollisionOffset, 2, 1, true);
					SetEntityCollisionGroup(ent, 2);
					
					int effect = CreateEntityByName("info_particle_system");
					if (effect != -1)
					{
						DispatchKeyValue(effect, "effect_name", (GetClientSkill(victim, 0) <= 0.1) ? "ra_return":"ra_return_damage");
						DispatchKeyValue(effect, "start_active", "1");
						
						char temp[64]; Format(temp, sizeof(temp), "damage_d_%d_%d", ent, GetRandomInt(1, 1000));
						DispatchKeyValue(effect, "targetname", temp);
						DispatchKeyValue(effect, "cpoint1", temp);
						DispatchKeyValue(effect, "cpoint2", buffer);
						
						GetClientEyePosition(attacker, origin); origin[2] -= 8.0;
						TeleportEntity(effect, origin, NULL_VECTOR, NULL_VECTOR);
						DispatchSpawn(effect);
						ActivateEntity(effect);
						
						UTIL_RemoveEntity(effect, 0.3);
					}
					
					UTIL_RemoveEntity(ent, 0.2);
				}
				
				UTIL_ScreenFade(attacker, 0.5, 0.1, FFADE_IN, {200, 0, 0, 50});
				UTIL_ScreenFade(victim, 0.5, 0.1, FFADE_IN, {200, 0, 0, 50});
				
				if (damage > 100.0 || !UTIL_DamageArmor(attacker, RoundToCeil(damage)))
				{
					SDKHooks_TakeDamage(attacker, victim, victim, damage, DMG_BULLET);
				}
			}
		}
	}
	return Plugin_Continue;
}

public void Hook_OnTakeDamagePost(int victim, int attacker, int inflictor, float damage, int damagetype)
{
	SetEntPropFloat(victim, Prop_Send, "m_flVelocityModifier", 1.0);
}

public Action Hook_IgniteSound(int clients[64], int& numClients, char sample[PLATFORM_MAX_PATH], int& entity, int& channel, float& volume, int& level, int& pitch, int& flags)
{
	if (!(1 <= entity <= MaxClients)) return Plugin_Continue;
	if (IsValidClient(entity) && IsPlayerAlive(entity) && ZM_IsClientZombie(entity)	&& sClientData[entity].ZombieClass)
	{
		if (StrContains(sample, "physics/flesh/flesh_impact_bullet", true) == 0)
		{
			return Plugin_Handled;
		}
		
		if (StrContains(sample, "player/kevlar", true) == 0)
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public Action Hook_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (IsValidClient(client) && ZM_IsClientZombie(client) && sClientData[client].ZombieClass)
	{
		if (sClientData[client].ZombieClass)
		{
			sClientData[client].StopSounds(client);
			ClearSyncHud(client, ZM_GetHudSync());
			OnClientDisconnect_Post(client);
		}
	}
	return Plugin_Continue;
}

public void ZM_OnClientDamaged(int client, int attacker, int inflictor, float damage, int damagetype)
{
	if (IsValidClient(client) && IsPlayerAlive(client) && ZM_IsClientZombie(client) && sClientData[client].ZombieClass)
	{
		if (IsValidClient(attacker) && IsPlayerAlive(attacker))
		{
			if (damagetype & (DMG_BURN | DMG_DIRECT))
			{
				static char weaponname[64];
				int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				
				if (weapon != -1 && IsValidEdict(weapon) && GetEntityClassname(weapon, weaponname, sizeof(weaponname)))
				{
					if (strcmp(weaponname, "weapon_salamander") == 0)
					{
						return;
					}
					
					if (sClientData[client].Cooldown != RoundToFloor(-1.0))
					{
						SDKHook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
						SDKHook(client, SDKHook_OnTakeDamagePost, Hook_OnTakeDamagePost);
						
						delete sClientData[client].TimerIgnite;
						sClientData[client].TimerIgnite = CreateTimer(6.0 + GetClientSkill(client, 1), Timer_StopIgnite, GetClientUserId(client));
						IgniteEntity(client, 5.0 + GetClientSkill(client, 1));
						
						int ClientWeapon = GetEntDataEnt2(client, sServerData.hActiveWeaponOffset);
						if (IsValidEdict(ClientWeapon)) {
							ZM_SendWeaponAnim(ClientWeapon, ACT_VM_DRAW);
						}
						
						sClientData[client].StopSounds(client);
						EmitSoundToAll(g_LoopSounds[sClientData[client].MoanSound], client);
						
						sClientData[client].MoanSound++;
						if (sClientData[client].MoanSound > 3) {
							sClientData[client].MoanSound = 0;
						}
						
						sClientData[client].HudTimeLoad = 0.0;
						sClientData[client].Cooldown = -1.0;
					}
					
					UTIL_ScreenFade(attacker, 0.5, 0.1, FFADE_IN, {200, 0, 0, 50});
					UTIL_ScreenFade(client, 0.5, 0.1, FFADE_IN, {200, 0, 0, 50});
					
					if (!UTIL_DamageArmor(attacker, GetRandomInt(8, 15)))
					{
						SDKHooks_TakeDamage(attacker, client, client, GetRandomFloat(8.0, 15.0), DMG_BURN);
					}
				}
			}
		}
		else
		{
			if (damagetype & (DMG_BURN | DMG_DIRECT))
			{
				SetEntProp(client, Prop_Send, "m_ArmorValue", 1, 1);
			
				if (sClientData[client].Cooldown > 0.0)
				{
					sClientData[client].Cooldown = UTIL_Clamp(sClientData[client].Cooldown-1.0, 0.0, 9999.0);
				}
			}
		}
	}
}

public void ZM_OnClientUpdated(int client, int attacker)
{
	if (IsValidClient(client)) //  && !IsFakeClient(client)
	{
		if (sClientData[client].ZombieClass)
		{
			sClientData[client].StopSounds(client);
			ClearSyncHud(client, ZM_GetHudSync());
			OnClientDisconnect_Post(client);
		}
	
		if (ZM_GetClientClass(client) == m_Zombie)
		{
			sClientData[client].ZombieClass = true;
			sClientData[client].Cooldown = CLASS_TANK_COOLDOWN;
			sClientData[client].StopSounds(client);
			
			SDKUnhook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
			SDKUnhook(client, SDKHook_OnTakeDamagePost, Hook_OnTakeDamagePost);
			SDKHook(client, SDKHook_PostThinkPost, Hook_PostThinkPost);
		}
	}
}

public void Hook_PostThinkPost(int client)
{
	if (IsValidClient(client) && sClientData[client].ZombieClass)
	{
		if (!IsPlayerAlive(client) || !ZM_IsClientZombie(client) || ZM_IsEndRound())
		{
			sClientData[client].StopSounds(client);
			SDKUnhook(client, SDKHook_PostThinkPost, Hook_PostThinkPost);
			return;
		}
		
		float time = GetGameTime();
		if (sClientData[client].HudTimeLoad <= time)
		{
			int color[4];
			GetEntityRenderColor(client, color[0], color[1], color[2], color[3]);
		
			if (GetEntProp(client, Prop_Data, "m_nWaterLevel") > 1 || color[0] == 0 && color[1] == 128 && color[2] == 255 && color[3] == 255)
			{
				if (sClientData[client].Cooldown == RoundToFloor(-1.0))
				{
					sClientData[client].Cooldown = CLASS_TANK_COOLDOWN;
					sClientData[client].HudTimeLoad = 0.0;
					sClientData[client].StopSounds(client);
					
					ZM_SetWeaponAnimation(client, 0);
					UTIL_ExtinguishEntity(client, true);
					
					SDKUnhook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
					SDKUnhook(client, SDKHook_OnTakeDamagePost, Hook_OnTakeDamagePost);
					
					sClientData[client].HudTimeLoad = time + 1.0;
				}
				else
				{
					sClientData[client].Cooldown += 0.1;
					int r = RoundToCeil((255.0/CLASS_TANK_COOLDOWN) * sClientData[client].Cooldown);
					SetHudTextParams(-1.0, -0.20, 0.6, r, 255-r, 255, 255, 0, 1.0, 0.05, 0.5);
					PrintText(client, 1, ZM_GetHudSync(), "%T", "ZOMBIE_CLASS_TANK_HUD_COOLDOWN", client, sClientData[client].Cooldown);
					sClientData[client].HudTimeLoad = time + 0.5;
				}
				return;
			}
			
			if (sClientData[client].Cooldown == RoundToFloor(-1.0))
			{
				sClientData[client].HudTimeLoad = time + 1.0;
				SetHudTextParams(-1.0, -0.20, 1.1, 	255, 255, 255, 255, 0, 1.0, 0.05, 0.5);
				PrintText(client, 1, ZM_GetHudSync(), "%T", "ZOMBIE_CLASS_TANK_HUD_USESKILL", client); // ShowSyncHudText(client, ZM_GetHudSync(), "%t", "ZOMBIE_CLASS_TANK_HUD_USESKILL");
				return;
			}
		
			if (sClientData[client].Cooldown <= 0.0)
			{
				sClientData[client].HudTimeLoad = time + 1.0;
				SetHudTextParams(-1.0, -0.20, 1.1, 	255, 255, 255, 255, 0, 1.0, 0.05, 0.5);
				
				if (sClientData[client].PlayerCanUse)
				{
					PrintText(client, 1, ZM_GetHudSync(), "%T", "ZOMBIE_CLASS_TANK_HUD_BUTTON", client); // ShowSyncHudText(client, ZM_GetHudSync(), "%t", "ZOMBIE_CLASS_TANK_HUD_BUTTON");
				}
				else
				{
					PrintText(client, 1, ZM_GetHudSync(), "%T", "ZOMBIE_CLASS_TANK_HUD_NONE", client); // ShowSyncHudText(client, ZM_GetHudSync(), "%t", "ZOMBIE_CLASS_TANK_HUD_NONE");
				}
				return;
			}
			
			sClientData[client].HudTimeLoad = time + 0.2;
			int r = RoundToCeil((255.0/CLASS_TANK_COOLDOWN) * sClientData[client].Cooldown);
			SetHudTextParams(-1.0, -0.20, 0.3, r, 255-r, 255, 255, 0, 1.0, 0.05, 0.5);
			PrintText(client, 1, ZM_GetHudSync(), "%T", "ZOMBIE_CLASS_TANK_HUD_COOLDOWN", client, sClientData[client].Cooldown); // ShowSyncHudText(client, ZM_GetHudSync(), "%t", "ZOMBIE_CLASS_TANK_HUD_COOLDOWN", sClientData[client].Cooldown);
			
			sClientData[client].Cooldown -= 0.2;
		}
	}
}

public void HS_OnClientHudSettings(int client, int id, const char[] name)
{
	if (id != 1) return;
	if (IsValidClient(client) && sClientData[client].ZombieClass)
	{
		ClearSyncHud(client, ZM_GetHudSync());
		PrintHintText(client, "");
		
		sClientData[client].HudTimeLoad = 0.0;
	}
}

stock bool IsTargetInSightRange(float origin[3], int client, float angle = 90.0, float distance = 0.0)
{
	if (angle > 360.0)
	{
		angle = 360.0;
	}
	if (angle < 0.0)
	{
		return false;
	}
	
	float clientpos[3], anglevector[3], targetvector[3];
	float resultdistance;
	
	GetClientAbsOrigin(client, clientpos);
	GetClientEyeAngles(client, anglevector);
	
	// anglevector[0] = anglevector[2] = 0.0;
	GetAngleVectors(anglevector, anglevector, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(anglevector, anglevector);
	
	resultdistance = GetVectorDistance(clientpos, origin);
	
	// clientpos[2] = origin[2] = 0.0;
	MakeVectorFromPoints(clientpos, origin, targetvector);
	NormalizeVector(targetvector, targetvector);
	
	origin[2] += 30.0;
	if (!UTIL_IsAbleToSee2(origin, client, MASK_VISIBLE))
	{
		return false;
	}
	
	if (RadToDeg(ArcCosine(GetVectorDotProduct(targetvector, anglevector))) <= angle / 2)
	{
		if (distance > 0)
		{
			if (distance >= resultdistance)
			{
				return true;
			}
			else
			{
				return false;
			}
		}
		else
		{
			return true;
		}
	}
	return false;
}