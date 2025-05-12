enum struct SoundData
{
	int Count;
	int AmbientRoundStart;
}
SoundData sSoundData;

void PlayerSoundsOnOnLoad()
{
	static char buffer[SMALL_LINE_LENGTH];
	sCvarList.SEFFECTS_ROUND_COUNT.GetString(buffer, sizeof(buffer));
	sSoundData.Count = SoundsKeyToIndex(buffer);
	
	sCvarList.SEFFECTS_ROUND_START_AMBIENT.GetString(buffer, sizeof(buffer));
	sSoundData.AmbientRoundStart = SoundsKeyToIndex(buffer);
}

void PlayerSoundsOnInit()
{
	// 
}

void PlayerSoundsOnCvarInit()
{
	HookConVarChange(sCvarList.SEFFECTS_ROUND_COUNT, Hook_OnCvarSounds);
	HookConVarChange(sCvarList.SEFFECTS_ROUND_START_AMBIENT, Hook_OnCvarSounds);
}

bool PlayerSoundsOnCounter()
{
	return SEffectsEmitToAll(sSoundData.Count, sServerData.RoundCount, SOUND_FROM_PLAYER, SNDCHAN_STATIC) != 0.0;
}

void PlayerSoundsOnClientKills(int attacker)
{
	if (IsValidClient(attacker) && IsPlayerAlive(attacker))
	{
		static float kills[MAXPLAYERS+1];
		if (sClientData[attacker].Skin != -1 && !sClientData[attacker].Zombie)
			SEffectsEmitToAllNoRep(kills[attacker], SkinsGetSoundKillsID(sClientData[attacker].Skin), _, attacker, SNDCHAN_STATIC);
		else SEffectsEmitToAllNoRep(kills[attacker], ClassGetSoundKillsID(sClientData[attacker].Class), _, attacker, SNDCHAN_STATIC);
	}
}

void PlayerSoundsOnClientDeath(int client)
{
	if (sClientData[client].Skin != -1 && !sClientData[client].Zombie)
		SEffectsEmitToAll(SkinsGetSoundDeathID(sClientData[client].Skin), _, client, SNDCHAN_STATIC);
	else SEffectsEmitToAll(ClassGetSoundDeathID(sClientData[client].Class), _, client, SNDCHAN_STATIC);
}

void PlayerSoundsOnGameModeStart()
{
	SEffectsEmitToAll(ModesGetSoundStartID(sServerData.RoundMode), _, SOUND_FROM_PLAYER, SNDCHAN_STATIC);
	HudsPrintHudTextAll(sServerData.SyncHud, ModesGetHudStartID(sServerData.RoundMode));
}

void PlayerSoundsOnClientHurt(int client, bool burning)
{
	if (burning)
	{
		static float burn[MAXPLAYERS+1];
		SEffectsEmitToAllNoRep(burn[client], ClassGetSoundBurnID(sClientData[client].Class), _, client, SNDCHAN_WEAPON);
		return;
	}
	
	static float groan[MAXPLAYERS+1];
	if (sClientData[client].Skin != -1 && !sClientData[client].Zombie)
		SEffectsEmitToAllNoRep(groan[client], SkinsGetSoundHurtID(sClientData[client].Skin), _, client, SNDCHAN_BODY);
	else SEffectsEmitToAllNoRep(groan[client], ClassGetSoundHurtID(sClientData[client].Class), _, client, SNDCHAN_BODY);
}

void PlayerSoundsOnClientInfected(int client, int attacker)
{
	if (attacker < 1)
	{
		SEffectsEmitToAll(ClassGetSoundRespawnID(sClientData[client].Class), _, client, SNDCHAN_STATIC);
	}
	else
	{
		SEffectsEmitToAll(ClassGetSoundInfectID(sClientData[client].Class), _, client, SNDCHAN_STATIC);
	}
	
	if (sServerData.RoundStart && attacker == -1)
	{
		static float comeback;
		SEffectsEmitToAllNoRep(comeback, ModesGetSoundComebackID(sServerData.RoundMode), _, SOUND_FROM_PLAYER, SNDCHAN_STATIC, true, false);
	}
}

bool PlayerSoundsOnClientShoot(int client, int id)
{
	return SEffectsEmitToAll(WeaponsGetSoundID(id), _, client, SNDCHAN_WEAPON) != 0.0;
}

public Action Hook_PlayerSoundsNormal(int clients[MAXPLAYERS], int& numClients, char sample[PLATFORM_MAX_PATH], int& entity, int& channel, float& volume, int& level, int& pitch, int& flags, char soundEntry[PLATFORM_MAX_PATH], int& seed)
{
	if (StrContains(sample, "player/kevlar", false) != -1)
	{
		return Plugin_Handled;
	}
	
	if (IsValidClient(entity))
	{
		if (StrContains(sample, "player/damage", false) != -1)
		{
			if (sClientData[entity].RespawnTimer != null)
			{
				return Plugin_Handled;
			}
		}
		
		if (StrContains(sample, "footsteps/", false) != -1 || StrContains(sample, "physics/", false) != -1)
		{
			if (sClientData[entity].RespawnTimer != null)
			{
				return Plugin_Handled;
			}
			
			switch(sForwardData._OnPlayFootStep(entity, sample, channel, level, flags, volume, pitch))
			{
				case Plugin_Continue:
				{
					EmitSoundToAll(sample, entity, channel, level, flags, volume, pitch);
				}
			}
			return Plugin_Changed;
		}
	}
	else if (IsValidEdict(entity))
	{
		static char classname[SMALL_LINE_LENGTH];
		GetEdictClassname(entity, classname, sizeof(classname));
		
		if (classname[0] == 'w' && classname[1] == 'e' && classname[6] == '_' && classname[7] == 'k') // weapon_knife
		{
			int index = WeaponsGetCustomID(entity);
			
			if (index != -1)
			{
				int sound = WeaponsGetSoundID(index);
				
				if (sound != -1 && !strncmp(sample, "weapons/knife/", 14, false))
				{
					if (!strncmp(sample[14], "knife_", 6, false))
					{
						if (sample[21] == 'l') /// knife_slashx
						{
							float oVolume; int oLevel; int oFlags; int oPitch;
							SoundsGetSound(sound, _, sample, oVolume, oLevel, oFlags, oPitch);
							
							int client = ToolsGetOwner(entity);
							if (IsClientInGame(client)) 
							{
								clients[numClients++] = client;
							}
							return Plugin_Changed; 
						}					
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

// public Action Hook_PlayerSoundsNormal(int clients[MAXPLAYERS], int& numClients, char sample[PLATFORM_MAX_PATH], int& entity, int& channel, float& volume, int& level, int& pitch, int& flags, char soundEntry[PLATFORM_MAX_PATH], int& seed)
// {
// 	if (IsValidEdict(entity))
// 	{
// 		static char classname[SMALL_LINE_LENGTH];
// 		GetEdictClassname(entity, classname, sizeof(classname));
// 		
// 		if (classname[0] == 'w' && classname[1] == 'e' && classname[6] == '_' && classname[7] == 'k') // weapon_knife
// 		{
// 			int index = WeaponsGetCustomID(entity);
// 			
// 			if (index != -1)
// 			{
// 				int sound = WeaponsGetSoundID(index);
// 				
// 				if (sound != -1 && !strncmp(sample, "weapons/knife/", 14, false) && strcmp(sample, "weapons/knife/knife_deploy1.wav", false))
// 				{
// 					int count = SoundsGetCount(sound);
// 					
// 					if (count != 8)
// 					{
// 						static char key[SMALL_LINE_LENGTH];
// 						SoundsGetKey(sound, key, sizeof(key));
// 					
// 						PrintToChatAll("Invalid amount of sounds \"%s\" for knife. Required (8), provided (%d)", key, count);
// 						LogError("[Sounds] [Sound Validation] Invalid amount of sounds \"%s\" for knife. Required (8), provided (%d)", key, count);
// 						return Plugin_Continue;
// 					}
// 
// 					if (!strncmp(sample[14], "knife_", 6, false))
// 					{
// 						int num = 0;
// 					
// 						if (sample[20] == 'h') // hit
// 						{
// 							if (sample[23] == 'w') /// knife_hitwallx
// 							{
// 								num = 4 + StringToInt(sample[27]);
// 							}
// 							else /// knife_hitx
// 							{
// 								num = StringToInt(sample[23]);
// 							}
// 						}
// 						else if (sample[21] == 'l') /// knife_slashx
// 						{
// 							num = 5 + StringToInt(sample[25]);
// 						}					
// 						else if (sample[21] == 't') /// knife_stab
// 						{
// 							num = 8;
// 						}
// 						
// 						float oVolume; int oLevel; int oFlags; int oPitch;
// 						if (SoundsGetSound(sound, num, sample, oVolume, oLevel, oFlags, oPitch))
// 						{
// 							int client = ToolsGetOwner(entity);
// 							if (IsClientInGame(client)) 
// 							{
// 								clients[numClients++] = client;
// 							}
// 							return Plugin_Changed; 
// 						}
// 					}
// 				}
// 			}
// 		}
// 	}
// 	return Plugin_Continue;
// }