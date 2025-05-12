void ZombieModInit()
{
	sServerData.Clients = new ArrayList();
	sServerData.LastZombies = new ArrayList();
	
	sServerData.SyncHudClass = CreateHudSynchronizer();
	sServerData.SyncHud = CreateHudSynchronizer();
	
	HookEvent("round_freeze_end", Event_RoundFreezeEnd);
	HookEvent("round_start", Event_RoundStartPre, EventHookMode_Pre);
	HookEvent("round_end", Event_RoundEndPre, EventHookMode_Pre);
	HookEvent("player_team", Event_PlayerTeamPre, EventHookMode_Pre);
	HookEvent("cs_win_panel_round", Event_CsWinPanelRound, EventHookMode_Pre);

	AddCommandListener(Command_Console, "say");

	sCvarList.WARMUP_TIME.AddChangeHook(Hook_OnWarmup);
}

void ZombieModOnLoad()
{		
	sForwardData._OnEngineExecute();

	PrecacheSound(SOUND_BUTTON_CMD_ERROR, true);
	PrecacheSound(SOUND_BUTTON_MENU_ERROR, true);
	// PrecacheSound(SOUND_NULL, true);
	
	sServerData.Warmup = false;
	sServerData.MapLoaded = true;
	sServerData.RoundModeCount = 0;
	sServerData.RoundStart = false;
	sServerData.BlockRespawn = false;
	sServerData.GetRoundTime = 0.0;
	
	Timer_RoundPrestart(null);
}

public void Hook_OnWarmup(ConVar convar, const char[] oldValue, const char[] newValue)
{
	ZombieModOnWarmup();
}

void ZombieModOnConfigsExecuted()
{
	ZombieModOnWarmup();
}

void ZombieModOnWarmup()
{
	if (sServerData.Warmup) {
		return;
	}
	
	int warmuptime = sCvarList.WARMUP_TIME.IntValue;
	if (warmuptime > 1)
	{
		sServerData.Warmup = true;
		sServerData.WarmupTime = warmuptime;
		CreateTimer(1.0, Timer_OnWarmup, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

void ZombieModOnEntityCreated(int entity, const char[] classname)
{
	if (StrContains(classname, "_projectile") != -1)
	{
		if (sCvarList.NOBLOCK.BoolValue == false) {
			return;
		}
		
		ToolsSetCollisionGroup(entity, COLLISION_GROUP_DEBRIS_TRIGGER);
	}
}

public Action Event_RoundFreezeEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (!sServerData.Warmup)
	{
		float time = sCvarList.ROUND_TIME.FloatValue;
		
		if (time != 1.0)
		{
			sServerData.RoundTime = CreateTimer((time * 60.0), Timer_CheckRoundTimeExpired, _, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	return Plugin_Handled;
}

public Action Timer_OnWarmup(Handle timer)
{
	if (!sServerData.Warmup) {
		return Plugin_Stop;
	}

	if (sCvarList.WARMUP_RATIO.FloatValue > 0.0)
	{
		int ClientsConnected = GetClientCount(false); int ClientsInGame = GetClientCount(true);
		int ClientsNeeded = RoundToCeil(float(ClientsConnected) * sCvarList.WARMUP_RATIO.FloatValue);
		ClientsNeeded = ClientsNeeded > 2 ? ClientsNeeded : 2;

		if (ClientsInGame < ClientsNeeded)
		{
			sServerData.WarmupTime = sCvarList.WARMUP_TIME.IntValue;
			HudsPrintHudTextAll(sServerData.SyncHud, sHudData.Warmupwaiting, _, ClientsNeeded-ClientsInGame);
			return Plugin_Continue;
		}
	}

	if (sServerData.WarmupTime <= 0)
	{
		sServerData.Warmup = false;
		ZombieModOnGameStart();
		return Plugin_Stop;
	}
	
	HudsPrintHudTextAll(sServerData.SyncHud, sHudData.Warmuptimer, _, sServerData.WarmupTime);
	sServerData.WarmupTime--;
	return Plugin_Continue;
}

void ZombieModOnMapEnd()
{
	sServerData.MapLoaded = false;
	sServerData.PurgeTimers();
	
	for (int i = 1; i <= MaxClients; i++)
	{
		sClientData[i].PurgeTimers();
	}
}

void ZombieModOnClientInit(int client)
{
	SDKHook(client, SDKHook_PostThink, ZombieModPostThink);
}

void ZombieModOnClientDisconnectPost(int client)
{
	ZombieModTerminateRound();

	SDKUnhook(client, SDKHook_PostThink, ZombieModPostThink);
}

public void ZombieModPostThink(int client)
{
	if (IsValidClient(client) && IsPlayerAlive(client) && sClientData[client].Zombie)
	{
		int ground = GetEntPropEnt(client, Prop_Send, "m_hGroundEntity");
		if (IsValidClient(ground) && sClientData[ground].Zombie)
		{
			SetEntPropEnt(client, Prop_Send, "m_hGroundEntity", 0);
		}
	}
}

public Action Timer_RoundPrestart(Handle timer)
{
	sServerData.RoundPrestart = null;
	sServerData.RoundNew = true;
	sServerData.BlockRespawn = false;
	sServerData.RoundMode = -1;
	return Plugin_Stop;
}

public void Event_RoundStartPre(Event event, const char[] name, bool dontBroadcast)
{
	KillEntities();
	
	delete sServerData.RoundTime;
	sServerData.RoundEnd = false;
	sServerData.RoundStart = false;
	sServerData.RoundMode = -1;
	
	int count = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		sClientData[i].RespawnTimer2 = 0;
		sClientData[i].RespawnTimes = 0;
	
		if (IsValidClient(i))
		{
			if (GetClientTeam(i) <= CS_TEAM_SPECTATOR)
			{
				continue;
			}
			
			CS_SwitchTeam(i, sCvarList.WARMUP_TEAM.BoolValue ? CS_TEAM_CT : (count++ & 1) ? CS_TEAM_T:CS_TEAM_CT);
		}
	}
	
	if (sServerData.Warmup)
	{
		return;
	}
	
	if (sServerData.MapLoaded == false)
	{
		return;
	}
	
	delete sServerData.CounterTimer;
	sServerData.RoundCount = sCvarList.INFECTION_COUNTDOWN_TIME.IntValue;
	
	if (sServerData.RoundCount != 0)
	{
		ToolsSetRoundTime((GetPlayersCount() >= 1) ? float(sServerData.RoundCount) + 1.0:0.0);
		sServerData.CounterTimer = CreateTimer(1.0, Timer_Counter, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	
	CreateTimer(0.1, Timer_RoundStart, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_RoundStart(Handle timer)
{
	SoundsOnRoundStart();
	return Plugin_Stop;
}

public Action Event_RoundEndPre(Event event, const char[] name, bool dontBroadcast)
{
	// static const char sounds[][] = {"", "radio/rounddraw.wav", "radio/twin.wav", "radio/ctwin.wav"};
	// int winner = event.GetInt("winner");
	
	// for (int i = 1; i <= MaxClients; i++)
	// {
	// 	if (IsValidClient(i) && !IsFakeClient(i))
	// 	{
	// 		StopSound(i, SNDCHAN_STATIC, sounds[winner]);
	// 	}
	// }
	
	event.BroadcastDisabled = true;
	return Plugin_Changed;
}

public Action Event_CsWinPanelRound(Event event, const char[] name, bool dontBroadcast)
{
	if (!dontBroadcast)
	{
		event.BroadcastDisabled = true;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action Event_PlayerTeamPre(Event event, const char[] name, bool dontBroadcast)
{
	if (!dontBroadcast && !event.GetBool("silent"))
	{
		event.BroadcastDisabled = true;
	}
	return Plugin_Continue;
}

public Action Timer_Counter(Handle timer)
{
	if (sServerData.Warmup)
	{
		return Plugin_Continue;
	}

	if (fnGetAlive() >= 1)
	{
		if (sServerData.RoundCount <= 0)
		{
			sServerData.CounterTimer = null;
			
			ZombieModOnBegin();
			return Plugin_Stop;
		}
		
		HudsPrintHudTextAll(sServerData.SyncHud, sHudData.Countdown, _, sServerData.RoundCount);
		
		SoundsOnCounter();
		
		sServerData.RoundCount--;
	}
	return Plugin_Continue;
}

void ZombieModOnBegin(int mode = -1, int target = -1)
{
	sServerData.RoundNew = false;
	sServerData.RoundEnd = false;
	int alive = fnGetAlive();
	
	if (mode == -1)
	{
		static int defaultMode; 
		for (int i = 0; i < sServerData.GameModes.Length; i++)
		{
			if (i != 0 && UTIL_GetRandomInt(1, ModesGetChance(i)) == ModesGetChance(i) && alive > ModesGetMinPlayers(i))
			{
				if (sServerData.RoundModeCount >= 4)
				{
					sServerData.RoundModeCount = 0;
					mode = i;
				}
				else if (!ModesGetChance(i))
				{
					defaultMode = i;
				}
			}
			else if (!ModesGetChance(i))
			{
				defaultMode = i;
			}
		}
		
		if (mode == -1) mode = defaultMode;
	}

	sServerData.RoundMode = mode;
	
	int MaxZombies = RoundToNearest(float(alive) * ModesGetRatio(sServerData.RoundMode));
	if (MaxZombies == alive) MaxZombies--;
	else if (!MaxZombies) MaxZombies++;
	
	UpdateClienArray(target);
	
	int type = ModesGetTypeZombie(sServerData.RoundMode);
	for (int i = 0; i < MaxZombies; i++)
	{
		int client = sServerData.Clients.Get(i);
		
		ApplyOnClientUpdate(client, _, type);
		ToolsSetHealth(client, ToolsGetHealth(client) + (alive * ModesGetHealthZombie(sServerData.RoundMode)));
		sServerData.LastZombies.Push(GetClientUserId(client));
	}
	
	type = ModesGetTypeHuman(sServerData.RoundMode);
	
	if (type == sServerData.Human)
	{
		for (int i = MaxZombies; i < alive; i++) 
		{
			int client = sServerData.Clients.Get(i);
			
			CS_SwitchTeam(client, CS_TEAM_CT);
			ToolsSetHealth(client, ToolsGetHealth(client) + (alive * ModesGetHealthHuman(sServerData.RoundMode)));
		}
	}
	else
	{
		for (int i = MaxZombies; i < alive; i++)
		{
			int client = sServerData.Clients.Get(i);
		
			ApplyOnClientUpdate(client, _, type);
			
			ToolsSetHealth(client, ToolsGetHealth(client) + (alive * ModesGetHealthHuman(sServerData.RoundMode)));
		}
	}
	
	if (ModesKillProps(sServerData.RoundMode) == true)
	{
		KillProps();
	}
	
	if (sCvarList.ROUND_TIME.FloatValue == 1.0)
	{
		int roundtime = ModesGetRoundTime(sServerData.RoundMode);
		if (roundtime != 0)
		{
			ToolsSetRoundTime(roundtime * 60.0);
			sServerData.RoundTime = CreateTimer((roundtime * 60.0), Timer_CheckRoundTimeExpired, _, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			ToolsSetRoundTime(0.0);
		}
	}
	
	sServerData.RoundStart = true;
	sServerData.RoundModeCount++;
	
	if (sServerData.CounterTimer != null)
	{
		delete sServerData.CounterTimer;
	}
	
	AmbientGameSoundsStop();
	SoundsOnGameModeStart();
	GameModeHudsStart();
	
	sForwardData._OnGameModeStart(sServerData.RoundMode);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			// ClearSyncHud(i, sServerData.SyncHud);
			
			sClientData[i].PlayerSpotted = false;
			sClientData[i].PlayerSpott = false;
			
			if (!IsPlayerAlive(i) && GetClientTeam(i) > CS_TEAM_SPECTATOR)
			{
				DeathOnClientRespawn(i, 1);
			}
		}
	}
}

void UpdateClienArray(int target = -1)
{
	sServerData.Clients.Clear();
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i))
		{
			if (sServerData.LastZombies.FindValue(GetClientUserId(i)) == -1)
			{
				sServerData.Clients.Push(i);
			}
		}
	}
	ShuffleArray(sServerData.Clients);
	ShuffleArray(sServerData.LastZombies);
	for (int i = 0; i < sServerData.LastZombies.Length; i++)
	{
		int client = GetClientOfUserId(sServerData.LastZombies.Get(i));
		if (IsValidClient(client) && IsPlayerAlive(client))
		{
			sServerData.Clients.Push(client);
		}
	}
	sServerData.LastZombies.Clear();
	
	if (target != -1)
	{
		int client = sServerData.Clients.FindValue(target);
		if (client != -1)
		{
			sServerData.Clients.SwapAt(client, (ModesGetRatio(sServerData.RoundMode) < 0.5) ? 0 : sServerData.Clients.Length - 1);
		}
	}
}

void ShuffleArray(ArrayList al)
{
	int size = al.Length;
	int len = size - 1;
	for (int i = 0; i < size; i++)
	{
		al.SwapAt(i, UTIL_GetRandomInt(0, len));
	}
}

public Action Timer_CheckRoundTimeExpired(Handle timer)
{
	sServerData.RoundTime = null;
	
	if (fnGetAlive() >= 1)
	{
		sForwardData._OnCheckRoundTimeExpired();
	
		CS_TerminateRound(sCvarList.ROUND_RESTART_DELAY.FloatValue, CSRoundEnd_CTWin, false);
	}
	return Plugin_Stop;
}

public Action CS_OnTerminateRound(float& delay, CSRoundEndReason& reason)
{
	sServerData.GetRoundTime = 0.0;

	if (sServerData.Warmup)
	{
		return Plugin_Handled;
	}

	SoundsOnRoundEnd();
	
	// sServerData.RoundNew = false;
	sServerData.RoundEnd = true;
	sServerData.RoundStart = false;
	sServerData.BlockRespawn = false;
	
	delete sServerData.RoundTime;
	delete sServerData.CounterTimer;
	delete sServerData.RoundPrestart;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			if (ModesGetRespawn(sServerData.RoundMode) == 1)
			{
				if (IsPlayerAlive(i) && sClientData[i].RespawnTimer != null)
				{
					ApplyOnClientSpawn(i);
				}
			}
		
			sClientData[i].ResetTimers();
		}
	}
	
	if (delay < 0.1)
	{
		Timer_RoundPrestart(null);
		return Plugin_Continue;
	}
	
	sServerData.RoundPrestart = CreateTimer(delay - 0.3, Timer_RoundPrestart, _, TIMER_FLAG_NO_MAPCHANGE);
	
	switch(reason)
	{
		case CSRoundEnd_GameStart:
		{
			VEffectsFadeClientScreenAll(sCvarList.VEFFECTS_GAME_START_FADE_COLOR, sCvarList.VEFFECTS_GAME_START_FADE_DURATION, sCvarList.VEFFECTS_GAME_START_FADE_TIME);
			SEffectsEmitToAll(ModesGetSoundGameStartID(sServerData.RoundMode), _, SOUND_FROM_PLAYER, SNDCHAN_STATIC);
			HudsPrintHudTextAll(sServerData.SyncHud, ModesGetHudGameStartID(sServerData.RoundMode));
			
			reason = CSRoundEnd_GameStart;
		}
		case CSRoundEnd_Draw:
		{
			VEffectsFadeClientScreenAll(sCvarList.VEFFECTS_ROUND_END_DRAW_FADE_COLOR, sCvarList.VEFFECTS_ROUND_END_DRAW_FADE_DURATION, sCvarList.VEFFECTS_ROUND_END_DRAW_FADE_TIME);
			SEffectsEmitToAll(ModesGetSoundEndDrawID(sServerData.RoundMode), _, SOUND_FROM_PLAYER, SNDCHAN_STATIC);
			HudsPrintHudTextAll(sServerData.SyncHud, ModesGetHudEndDrawID(sServerData.RoundMode));
			
			reason = CSRoundEnd_Draw;
		}
		case CSRoundEnd_TerroristWin:
		{
			VEffectsFadeClientScreenAll(sCvarList.VEFFECTS_ROUND_END_ZOMBIE_FADE_COLOR, sCvarList.VEFFECTS_ROUND_END_ZOMBIE_FADE_DURATION, sCvarList.VEFFECTS_ROUND_END_ZOMBIE_FADE_TIME);
			SEffectsEmitToAll(ModesGetSoundEndZombieID(sServerData.RoundMode), _, SOUND_FROM_PLAYER, SNDCHAN_STATIC);  
			HudsPrintHudTextAll(sServerData.SyncHud, ModesGetHudEndZombieID(sServerData.RoundMode));
			
			ToolsSetTeamScore(CS_TEAM_T, GetTeamScore(CS_TEAM_T)+1);
			reason = CSRoundEnd_TerroristWin;
		}
		case CSRoundEnd_CTWin:
		{
			VEffectsFadeClientScreenAll(sCvarList.VEFFECTS_ROUND_END_HUMAN_FADE_COLOR, sCvarList.VEFFECTS_ROUND_END_HUMAN_FADE_DURATION, sCvarList.VEFFECTS_ROUND_END_HUMAN_FADE_TIME);
			SEffectsEmitToAll(ModesGetSoundEndHumanID(sServerData.RoundMode), _, SOUND_FROM_PLAYER, SNDCHAN_STATIC);
			HudsPrintHudTextAll(sServerData.SyncHud, ModesGetHudEndHumanID(sServerData.RoundMode));
			
			ToolsSetTeamScore(CS_TEAM_CT, GetTeamScore(CS_TEAM_CT)+1);
			reason = CSRoundEnd_CTWin;
		}
	}
	
	sForwardData._OnGameModeEnd(reason);
	return Plugin_Changed;
}

void KillEntities()
{
	static char classname[NORMAL_LINE_LENGTH];
	
	for (int i = MaxClients; i <= GetMaxEntities(); i++)
	{
		if (IsValidEdict(i))
		{
			GetEdictClassname(i, classname, sizeof(classname));
			
			if (StrContains(classname, "func_bomb_target|func_hostage_rescue|hostage_entity") > -1) // c4, func_buyzone
			{
				AcceptEntityInput(i, "Kill");
			}
		}
	}
}

void KillProps()
{
	static char classname[NORMAL_LINE_LENGTH];
	
	for (int i = MaxClients; i <= GetMaxEntities(); i++)
	{
		if (IsValidEdict(i) && IsPhysics(i))
		{
			GetEdictClassname(i, classname, sizeof(classname));
			
			if (StrContains(classname, "prop_physics") > -1) // prop_physics ...
			{
				AcceptEntityInput(i, "Kill");
			}
		}
	}
}

stock int IsPhysics(int client)
{
	if (GetFeatureStatus(FeatureType_Native, "Phys_IsPhysicsObject") == FeatureStatus_Available)
	{
		return (Phys_IsPhysicsObject(client) && Phys_IsMotionEnabled(client));
	}
	return true;
}

bool ZombieModTerminateRound()
{
	if (sServerData.RoundNew) // round humans
	{
		if (sServerData.Warmup)
		{
			return false;
		}
	
		if (fnGetAlive() < 2 && fnGetDead() != 0)
		{
			ToolsSetRoundTime(0.0);
			CS_TerminateRound(sCvarList.ROUND_RESTART_DELAY.FloatValue, CSRoundEnd_Draw, false);
		}
	}

	if (!sServerData.RoundStart)
	{
		return false;
	}
	
	int ih = GetHumans();
	int iz = GetZombies();

	if (iz && ih)
	{
		return false;
	}
	
	if (!iz && ih)
	{
		CS_TerminateRound(sCvarList.ROUND_RESTART_DELAY.FloatValue, CSRoundEnd_CTWin, false);
	}
	else if (iz && !ih)
	{
		CS_TerminateRound(sCvarList.ROUND_RESTART_DELAY.FloatValue, CSRoundEnd_TerroristWin, false);
	}
	else
	{
		CS_TerminateRound(sCvarList.ROUND_RESTART_DELAY.FloatValue, CSRoundEnd_Draw, false);
	}
	return true;
}

void ZombieModOnGameStart()
{
	if (sServerData.Warmup)
	{
		return;
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			ToolsSetScore(i, false, 0);
			ToolsSetScore(i, true, 0);
		}
	}
	
	ToolsSetTeamScore(CS_TEAM_T, 0);
	ToolsSetTeamScore(CS_TEAM_CT, 0);
	
	GameRules_SetPropFloat("m_flGameStartTime", GetGameTime());
	CS_TerminateRound(3.0, CSRoundEnd_GameStart, false);
}

public Action Command_Console(int client, const char[] command, int args)
{
	if (client == 0)
	{
		static char buffer[512], message[512];
		sCvarList.CHAT_CONSOLE.GetString(buffer, sizeof(buffer));
		
		if (buffer[0])
		{
			GetCmdArgString(message, sizeof(message));
			StripQuotes(message);
			TrimString(message);
			PrintToServer("Console: %s", message);
			
			TranslationPluginFormatString(-1, -1, buffer, sizeof(buffer));
			ReplaceString(buffer, sizeof(buffer), "{TEXT}", message);
			PrintToChatAll("%s", buffer);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

stock void AddConVarCommand(ConVar cv, ConCmd callback)
{
	char commands[BIG_LINE_LENGTH], ExplodeCmds[10][SMALL_LINE_LENGTH];
	
	cv.GetString(commands, sizeof(commands));
	ReplaceString(commands, sizeof(commands), " ", "");
	
	if (hasLength(commands))
	{
		for (int i = 0; i < ExplodeString(commands, ",", ExplodeCmds, sizeof(ExplodeCmds), sizeof(ExplodeCmds[])); i++)
		{
			if (GetCommandFlags(ExplodeCmds[i]) == INVALID_FCVAR_FLAGS)
			{
				RegConsoleCmd(ExplodeCmds[i], callback);
			}
		}
	}
}

stock void UnhookEvent2(const char[] name, EventHook CallBack, EventHookMode mode = EventHookMode_Post)
{
	HookEvent(name, CallBack, mode);
	UnhookEvent(name, CallBack, mode);
}

bool IsClientGroup(int client, int GroupFlags, const char[] group)
{
	if (hasLength(group))
	{
		if (!GroupFlags && GroupFlags & GetUserFlagBits(client))
		{
			return false;
		}
		
		if (GetFeatureStatus(FeatureType_Native, "VIP_IsClientVIP") == FeatureStatus_Available)
		{
			if (VIP_IsClientVIP(client))
			{
				bool IsVIP = false;
				
				char explode[3][SMALL_LINE_LENGTH], buffer[SMALL_LINE_LENGTH];
				for (int i = 0; i < ExplodeString(group, ", ", explode, sizeof(explode), sizeof(explode[])); i++)
				{
					VIP_GetClientGroup(client, buffer, sizeof(buffer));
					if (strcmp(buffer, explode[i]) == 0)
					{
						IsVIP = true;
					}
				}
				return IsVIP == false;
			}
		}
		return true;
	}
	return false;
}

stock int fnGetAlive()
{
	int alive = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i))
		{
			alive++;
		}
	}
	return alive;
}

stock int fnGetDead()
{
	int dead = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && GetClientTeam(i) > CS_TEAM_SPECTATOR && !IsPlayerAlive(i))
		{
			dead++;
		}
	}
	return dead;
}

stock int GetPlayersCount()
{
	int count = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && GetClientTeam(i) > CS_TEAM_SPECTATOR)
		{
			count++;
		}
	}
	return count;
}

stock int GetHumans()
{
	int count = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i) && !sClientData[i].Zombie)
		{
			count++;
		}
	}
	return count;
}

stock int GetZombies()
{
	int count = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i) && sClientData[i].Zombie)
		{  
			count++;
		}
	}
	return count;
}

stock int GetRandomHuman()
{
	int count = 0;
	int[] clients = new int[MaxClients];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i) && !sClientData[i].Zombie)
		{
			clients[count++] = i;
		}
	}
	return (count) ? clients[UTIL_GetRandomInt(0, count-1)] : -1;
}

stock int GetRandomZombie()
{
	int count = 0;
	int[] clients = new int[MaxClients];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i) && sClientData[i].Zombie)
		{
			clients[count++] = i;
		}
	}
	return (count) ? clients[UTIL_GetRandomInt(0, count-1)] : -1;
}

stock void CreatePlayerDeath(int userid, int attacker, char[] weapon, bool headshot = false, bool penetrated = false, bool revenge = false, bool dominated = false, int assister = 0)
{
	Event event = CreateEvent("player_death");
	if (event != null)
	{
		event.SetInt("userid", userid);
		event.SetInt("attacker", attacker);
		event.SetInt("assister", assister);
		event.SetString("weapon", weapon);
		event.SetBool("headshot", headshot);
		event.SetBool("penetrated", penetrated);
		event.SetBool("revenge", revenge);
		event.SetBool("dominated", dominated);

		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i))
			{
				event.FireToClient(i);
			}
		}
		event.Cancel();
	}
}

public bool TraceEntityFilter(int entity, int contentsMask, int client) 
{
	return (entity != client);
}