void SpawnOnInit()
{
	AddCommandListener(Command_JoinTeam, "jointeam");
	AddCommandListener(Command_JoinClass, "joinclass");
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_team", Event_PlayerTeam);
	
	sServerData.Spawns = new ArrayList(3);
}

void SpawnOnLoad()
{
	sServerData.Spawns.Clear();
	
	SpawnOnCacheData("info_player_terrorist");
	SpawnOnCacheData("info_player_counterterrorist");
}

void SpawnOnCacheData(const char[] classname)
{
	int entity;
	while ((entity = FindEntityByClassname(entity, classname)) != -1)
	{
		static float position[3];
		ToolsGetOrigin(entity, position); 
		sServerData.Spawns.PushArray(position, sizeof(position));
		
		// PrintToServer("[%s] %f, %f, %f", classname, position[0], position[1], position[2]);
	}
}

public Action Command_JoinTeam(int client, const char[] c, int a)
{
	if (!sCvarList.INFECTION_COUNTDOWN_TIME.IntValue) {
		return Plugin_Continue;
	}

	if (IsValidClient(client))
	{
		static char arg[2];
		GetCmdArg(1, arg, sizeof(arg));
		
		if (IsPlayerAlive(client) || StringToInt(arg) != CS_TEAM_SPECTATOR)
		{
			if (GetClientTeam(client) <= CS_TEAM_SPECTATOR)
			{
				int team = (sCvarList.WARMUP_TEAM.BoolValue ? CS_TEAM_CT : (client & 1) ? CS_TEAM_T:CS_TEAM_CT);
			
				CS_SwitchTeam(client, team);
				CS_UpdateClientModel(client);
				sForwardData._OnClientJoinTeamed(client, team);
				
				if (GetPlayersCount() == 2 && !sServerData.Warmup)
				{
					ZombieModOnGameStart();
					return Plugin_Handled;
				}
				
				DeathOnClientRespawn(client, sServerData.RoundStart ? 1:2);
				return Plugin_Handled;
			}
			
			TranslationPrintToChat(client, "block jointeam");
			sForwardData._OnClientJoinTeamed(client, -1);
			
			ClientCommand(client, "play buttons/button11.wav");
			return Plugin_Handled;
		}
		
		ChangeClientTeam(client, CS_TEAM_SPECTATOR);
		sForwardData._OnClientJoinTeamed(client, 1);
		
		delete sClientData[client].RespawnTimer;
		WeaponsOnClientSpawn(client);
		CostumesOnClientSpawn(client);
	}
	return Plugin_Handled;
}

public Action Command_JoinClass(int client, const char[] c, int a)
{
	if (!sCvarList.INFECTION_COUNTDOWN_TIME.IntValue) {
		return Plugin_Continue;
	}
	
	// if (IsValidClient(client)) //  && !IsFakeClient(client)
	// {
	// 	if (sServerData.RoundStart)
	// 	{
	// 		CS_SwitchTeam(client, sCvarList.WARMUP_TEAM.BoolValue ? CS_TEAM_CT : (client & 1) ? CS_TEAM_T:CS_TEAM_CT);
	// 		CS_UpdateClientModel(client);
	// 		DeathOnClientRespawn(client, 2);
	// 	}
	// 	
	// 	ZombieModTerminateRound();
	// 	return Plugin_Handled;
	// }
	
	return Plugin_Handled;
}

public Action Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	if (!sCvarList.INFECTION_COUNTDOWN_TIME.IntValue) {
		return Plugin_Continue;
	}

	int client = GetClientOfUserId(event.GetInt("userid"));

	if (IsValidClient(client) && !IsFakeClient(client) && event.GetInt("team") == CS_TEAM_NONE)
	{
		ShowVGUIPanel(client, "team", null, true);
	}
	return Plugin_Continue;
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (IsValidClient(client))
	{
		if (!sServerData.RoundEnd && ModesGetRespawn(sServerData.RoundMode) == 1)
		{
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.4);
			SetEntityRenderMode(client, RENDER_TRANSCOLOR);
			SetEntityRenderColor(client, 255, 255, 255, 0);
			SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit_invis);
			
			for (int i = 0; i < ToolsGetMyWeapons(client); i++) {
				int weapon = ToolsGetWeapon(client, i);
				if (weapon != -1) {
					RemovePlayerItem(client, weapon);
					AcceptEntityInput(weapon, "Kill");
				}
			}
			
			if (ToolsGetCollisionGroup(client) != COLLISION_GROUP_DEBRIS_TRIGGER)
			{
				ToolsSetCollisionGroup(client, COLLISION_GROUP_DEBRIS_TRIGGER);
			}
			
			// ClientCommand(client, "r_screenoverlay \"models/zschool/rustambadr/other/inv_event.vmt\"");
			// ClientCommand(client, "r_screenoverlay \"debug/yuv\"");
			sClientData[client].PlayerSpotted = true;
			
			DeathOnClientRespawn(client, 3);
		}
		else
		{
			switch(sForwardData._OnPlayerSpawn(client))
			{
				case Plugin_Continue:
				{
					ApplyOnClientSpawn(client);
				}
			}
		}
		
		SDKHook(client, SDKHook_WeaponCanUse, Hook_WeaponCanUse);
		CreateTimer(0.1, Timer_SpawnOnClientRespawn, GetClientUserId(client));
		
		WeaponsModOnClientSpawn(client);
	}
	return Plugin_Continue;
}

public Action Timer_SpawnOnClientRespawn(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		SetEntProp(client, Prop_Send, "m_fEffects", 0);
	}
	return Plugin_Stop;
}

public Action Hook_SetTransmit_invis(int entity, int client) 
{ 
	if (entity == client) {
		return Plugin_Continue;
	}
	
	if (IsValidClient(entity) && !IsPlayerAlive(entity)){
		SDKUnhook(entity, SDKHook_SetTransmit, Hook_SetTransmit_invis);
	}
	return Plugin_Handled;
}

void SpawnOnRunCmd(int client, int& buttons, int LastButtons, int& impulse)
{
	if (ModesGetRespawn(sServerData.RoundMode) == 0) {
		return;
	}

	if (IsValidClient(client) && !IsFakeClient(client) && IsPlayerAlive(client) && !AntiStickIsStuck(client) && sClientData[client].RespawnTimer != null)
	{
		if (sClientData[client].RespawnTimer2 > 0)
		{
			if (buttons & IN_USE && !(LastButtons & IN_USE))
			{
				ClearSyncHud(client, sServerData.SyncHudClass);
				ClientCommand(client, "r_screenoverlay \"\"");
				SDKUnhook(client, SDKHook_SetTransmit, Hook_SetTransmit_invis);
				
				ApplyOnClientSpawn(client);
				
				if (sClientData[client].RespawnTimer != null)
				{
					delete sClientData[client].RespawnTimer;
					sClientData[client].RespawnTimer = null;
				}
			}
		}
	}
}

void SpawnTeleportToRespawn(int client)
{
	static float position[3];
	
	if (sCvarList.TELEPORT_SPAWN_IOCATON.BoolValue == false)
	{
		float maxs[3], mins[3]; 
		GetClientMins(client, mins);
		GetClientMaxs(client, maxs);
		
		for (int i = 0; i < sServerData.Spawns.Length; i++)
		{
			sServerData.Spawns.GetArray(i, position, sizeof(position));
			TR_TraceHullFilter(position, position, mins, maxs, MASK_SOLID, TraceEntityFilter, client);
			
			if (!TR_DidHit())
			{
				TeleportEntity(client, position, NULL_VECTOR, NULL_VECTOR);
				return;
			}
		}
	}
	else TeleportEntity(client, sClientData[client].TeleSpawn, NULL_VECTOR, view_as<float>({0.0, 0.0, 0.0}));
}