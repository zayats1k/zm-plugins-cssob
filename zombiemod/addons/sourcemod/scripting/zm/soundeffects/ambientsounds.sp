char m_Ambient[MAXPLAYERS+1][PLATFORM_MAX_PATH]; 
char m_AmbientGame[PLATFORM_MAX_PATH]; 

void AmbientSoundsOnGameModeStart()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			AmbientSoundsOnClientUpdate(i);
		}
	}
}

void AmbientOnMapEnd()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			AmbientSoundsOnClientDeath(i);
		}
	}
}

void AmbientSoundsOnClientDeath(int client)
{
	if (!IsFakeClient(client))
	{
		if (hasLength(m_Ambient[client])) {
			StopSound(client, SNDCHAN_STATIC, m_Ambient[client]);
			m_Ambient[client][0] = NULL_STRING[0];
		}
	}
}

void AmbientSoundsOnClientUpdate(int client)
{
	if (!IsFakeClient(client))
	{
		if (hasLength(m_Ambient[client])) {
			StopSound(client, SNDCHAN_STATIC, m_Ambient[client]);
			m_Ambient[client][0] = NULL_STRING[0];
		}
		
		if (!sServerData.RoundStart)
		{
			return;
		}
		
		float volume; int level; int flags; int pitch;
		float duration = SoundsGetSound(ModesGetSoundAmbientID(sServerData.RoundMode), _, m_Ambient[client], volume, level, flags, pitch);
		
		if (duration)
		{
			EmitSoundToClient(client, m_Ambient[client], SOUND_FROM_PLAYER, SNDCHAN_STATIC, level, flags, volume, pitch);
		
			delete sClientData[client].AmbientTimer;
			sClientData[client].AmbientTimer = CreateTimer(duration, Timer_AmbientSoundsRepeat, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action Timer_AmbientSoundsRepeat(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);

	sClientData[client].AmbientTimer = null;

	if (client && !IsFakeClient(client))
	{
		float volume; int level; int flags; int pitch;
		float duration = SoundsGetSound(ModesGetSoundAmbientID(sServerData.RoundMode), _, m_Ambient[client], volume, level, flags, pitch);
		
		if (duration)
		{
			EmitSoundToClient(client, m_Ambient[client], SOUND_FROM_PLAYER, SNDCHAN_STATIC, level, flags, volume, pitch);
			sClientData[client].AmbientTimer = CreateTimer(duration, Timer_AmbientSoundsRepeat, userid, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	return Plugin_Stop;
}

void AmbientGameSoundsStop()
{
	if (hasLength(m_AmbientGame))
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i))
			{
				StopSound(i, SNDCHAN_STATIC, m_AmbientGame);
			}
		}
		
		m_AmbientGame[0] = NULL_STRING[0];
	}
}

void AmbientGameSoundsRoundEnd()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			AmbientSoundsOnClientDeath(i);
		}
	}

	if (hasLength(m_AmbientGame))
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i))
			{
				StopSound(i, SNDCHAN_STATIC, m_AmbientGame);
			}
		}
		
		m_AmbientGame[0] = NULL_STRING[0];
	}
}

void AmbientGameSoundsRoundStart()
{
	AmbientGameSoundsRoundEnd();
	
	float volume; int level; int flags; int pitch;
	
	if (SoundsGetSound(sSoundData.AmbientRoundStart, _, m_AmbientGame, volume, level, flags, pitch))
	{
		EmitSoundToAll(m_AmbientGame, SOUND_FROM_PLAYER, SNDCHAN_STATIC, level, flags, volume, pitch);
	}
}