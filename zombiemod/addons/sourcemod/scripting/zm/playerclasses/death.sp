Handle hDHookCommitSuicide;

void DeathOnInit()
{
	HookEvent("player_death", Hook_PlayerDeathPost);
	
	int offset;
	fnInitGameConfOffset(sServerData.SDKTools, offset, "CommitSuicide");
	hDHookCommitSuicide = DHookCreate(offset, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, Hook_OnCommitSuicide);
	DHookAddParam(hDHookCommitSuicide, HookParamType_Bool);
	DHookAddParam(hDHookCommitSuicide, HookParamType_Bool);
}

void DeathOnClientInit(int client)
{
	if (hDHookCommitSuicide)
	{
		DHookEntity(hDHookCommitSuicide, true, client);
	}
}

public Action Hook_PlayerDeathPost(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	
	if (IsValidClient(client))
	{
		char weapon[64];
		event.GetString("weapon", weapon, sizeof(weapon));
		
		if (sServerData.RoundStart && !attacker && StrEqual(weapon, "trigger_hurt"))
		{
			float time = sCvarList.REPEATKILL.FloatValue;
			if (time > 0.0 && !sServerData.BlockRespawn)
			{
				float GameTime = GetGameTime();
				if (GameTime - sClientData[client].DeathTime - float(sCvarList.INFECTION_COUNTDOWN_TIME.IntValue) < time)
				{
					sServerData.BlockRespawn = true;
				}
				
				sClientData[client].DeathTime = GameTime;
			}
		}
		
		ExtinguishEntity(client);
		
		PlayerSoundsOnClientKills(attacker);
		DeathOnClientDeath(client, IsValidClient(attacker) ? attacker : 0);
	}
	return Plugin_Continue;
}

void DeathOnClientDeath(int client, int attacker = 0)
{
	sClientData[client].ResetTimers();
	
	WeaponsOnClientDeath(client);
	RagdollOnClientDeath(client);
	SoundsOnClientDeath(client);
	CostumesOnClientDeath(client);
	
	ClientCommand(client, "r_screenoverlay \"\"");
	
	if (sClientData[client].Zombie)
	{
		if (attacker == 0)
		{
			sClientData[client].KilledByWorld = true;
		}
	}
	
	if (!sServerData.RoundStart)
	{
		sClientData[client].RespawnTimer2 = -1;
	}
	
	DeathOnClientRespawn(client, sServerData.RoundStart ? 1:2);
	ZombieModTerminateRound();
}

bool DeathOnClientRespawn(int client, int respawn = 0)
{
	switch (respawn)
	{
		case 0: // respawn = (0 - Respawn)
		{
			ToolsForceToRespawn(client); 
		}
		case 1: // respawn = (1 - Respawn Zombie)
		{
			if (!sServerData.RoundStart)
			{
				return false;
			}
			
			if (sClientData[client].RespawnTimes >= ModesGetAmount(sServerData.RoundMode))
			{
				return false;
			}
			
			if (ModesGetRespawn(sServerData.RoundMode) == 1)
			{
				sClientData[client].RespawnTimer2 = 1;
			}
			else
			{
				sClientData[client].RespawnTimer2 = ModesGetDelay(sServerData.RoundMode);
			}
			
			sClientData[client].RespawnTimes++;
			delete sClientData[client].RespawnTimer;
			sClientData[client].RespawnTimer = CreateTimer(1.0, Timer_OnClientRespawn, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			TriggerTimer(sClientData[client].RespawnTimer);
			
			sForwardData._OnClientRespawn(client, sClientData[client].RespawnTimer2);
		}
		case 2: // respawn = (2 - Respawn Human)
		{
			if (sServerData.RoundStart || sServerData.RoundEnd)
			{
				return false;
			}
			
			delete sClientData[client].RespawnTimer;
			
			if (sClientData[client].RespawnTimer2 == -1)
			{
				sClientData[client].RespawnTimer = CreateTimer(1.0, Timer_OnClientRespawn, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				TriggerTimer(sClientData[client].RespawnTimer);
				return false;
			}
			
			sClientData[client].RespawnTimer = CreateTimer(0.3, Timer_OnClientRespawnHuman, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
		case 3: // respawn = (3 - Respawn Gamemode)
		{
			if (!sServerData.RoundStart)
			{
				return false;
			}
			
			if (sClientData[client].RespawnTimes >= ModesGetAmount(sServerData.RoundMode))
			{
				return false;
			}
			
			if (IsFakeClient(client))
			{
				sClientData[client].RespawnTimer2 = UTIL_GetRandomInt(2, ModesGetDelay(sServerData.RoundMode));
			}
			else
			{
				sClientData[client].RespawnTimer2 = ModesGetDelay(sServerData.RoundMode);
			}
			
			sClientData[client].RespawnTimes++;
			delete sClientData[client].RespawnTimer;
			sClientData[client].RespawnTimer = CreateTimer(1.0, Timer_OnClientRespawnGamemode, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			TriggerTimer(sClientData[client].RespawnTimer);
		}
	}
	return true;
}

public Action Timer_OnClientRespawnHuman(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	sClientData[client].RespawnTimer = null;
	
	if (IsValidClient(client) && !IsPlayerAlive(client) && !sServerData.RoundStart)
	{
		DeathOnClientRespawn(client, 0);
	}
	return Plugin_Stop;
}

public Action Timer_OnClientRespawnGamemode(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);

	if (IsValidClient(client) && IsPlayerAlive(client) && !sServerData.RoundEnd)
	{
		if (sClientData[client].RespawnTimer2 <= 0)
		{
			sClientData[client].RespawnTimer = null;
		
			ClearSyncHud(client, sServerData.SyncHudClass);
			ClientCommand(client, "r_screenoverlay \"\"");
			SDKUnhook(client, SDKHook_SetTransmit, Hook_SetTransmit_invis);
			
			if (ToolsGetCollisionGroup(client) != COLLISION_GROUP_PLAYER)
			{
				ToolsSetCollisionGroup(client, COLLISION_GROUP_PLAYER);
			}
			
			ApplyOnClientSpawn(client);
			return Plugin_Stop;
		}
		
		ClientCommand(client, "r_screenoverlay \"debug/yuv\"");
		
		if (AntiStickIsStuck(client))
		{
			HudsPrintHudText(sServerData.SyncHudClass, client, sHudData.RespawnStuck, _, sClientData[client].RespawnTimer2);
			return Plugin_Continue;
		}
		
		HudsPrintHudText(sServerData.SyncHudClass, client, sHudData.RespawnButton, _, sClientData[client].RespawnTimer2);
		sClientData[client].RespawnTimer2--;
		return Plugin_Continue;
	}
	
	sClientData[client].RespawnTimer = null;
	return Plugin_Stop;
}

public Action Timer_OnClientRespawn(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	
	if (IsValidClient(client) && !IsPlayerAlive(client) && !sServerData.RoundEnd)
	{
		if (!sServerData.RoundStart)
		{
			HudsPrintHudText(sServerData.SyncHudClass, client, sHudData.RespawnDeath);
			return Plugin_Continue;
		}
		
		if (sServerData.BlockRespawn)
		{
			sClientData[client].RespawnTimer = null;
			return Plugin_Stop;
		}
		
		if (sClientData[client].RespawnTimer2 <= 0)
		{
			sClientData[client].RespawnTimer = null;
			DeathOnClientRespawn(client, 0);
			return Plugin_Stop;
		}
		
		if (ModesGetRespawn(sServerData.RoundMode) != 1)
		{
			HudsPrintHudText(sServerData.SyncHudClass, client, sHudData.Respawn, _, sClientData[client].RespawnTimer2);
		}
		
		sClientData[client].RespawnTimer2--;
		return Plugin_Continue;
	}
	
	sClientData[client].RespawnTimer = null;
	return Plugin_Stop;
}

public MRESReturn Hook_OnCommitSuicide(int client)
{
	DeathOnClientDeath(client);
	return MRES_Handled;
}