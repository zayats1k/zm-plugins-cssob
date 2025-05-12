float SEffectsEmitToAllNoRep(float &EmitTime, int key, int num = 0, int entity = SOUND_FROM_PLAYER, int channel = SNDCHAN_AUTO, bool human = true, bool zombie = true)
{
	static char sound[PLATFORM_LINE_LENGTH];
	float volume; int level; int flags; int pitch;
	float duration = SoundsGetSound(key, num, sound, volume, level, flags, pitch);
	
	if (duration)
	{
		float time = GetGameTime();

		if (time > EmitTime)
		{
			int[] clients = new int[MaxClients]; int count = 0;

			if (human && zombie)
			{
				for (int i = 1; i <= MaxClients; i++)
				{
					if (IsClientInGame(i))
					{
						clients[count++] = i;
					}
				}
			}
			else if (human)
			{
				for (int i = 1; i <= MaxClients; i++)
				{
					if (IsClientInGame(i) && !sClientData[i].Zombie)
					{
						clients[count++] = i;
					}
				}
			}
			else if (zombie)
			{
				for (int i = 1; i <= MaxClients; i++)
				{
					if (IsClientInGame(i) && sClientData[i].Zombie)
					{
						clients[count++] = i;
					}
				}
			}
			else
			{
				for (int i = 1; i <= MaxClients; i++)
				{
					if (IsClientInGame(i) && sClientData[i].Custom)
					{
						clients[count++] = i;
					}
				}
			}
			
			if (count)
			{
				EmitSound(clients, count, sound, entity, channel, level, flags, volume, pitch);
			}
		
			EmitTime = time + duration;
		}
		else
		{
			duration = 0.0;
		}
	}
	return duration;
}

float SEffectsEmitToAll(int key, int num = 0, int entity = SOUND_FROM_PLAYER, int channel = SNDCHAN_AUTO, bool human = true, bool zombie = true)
{
	static char sound[PLATFORM_LINE_LENGTH];
	float volume; int level; int flags; int pitch;
	float duration = SoundsGetSound(key, num, sound, volume, level, flags, pitch);
	
	if (duration)
	{
		int[] clients = new int[MaxClients]; int count = 0;

		if (human && zombie)
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i))
				{
					clients[count++] = i;
				}
			}
		}
		else if (human)
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && !sClientData[i].Zombie)
				{
					clients[count++] = i;
				}
			}
		}
		else if (zombie)
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && sClientData[i].Zombie)
				{
					clients[count++] = i;
				}
			}
		}
		else
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && sClientData[i].Custom)
				{
					clients[count++] = i;
				}
			}
		}
		
		if (count)
		{
			EmitSound(clients, count, sound, entity, channel, level, flags, volume, pitch);
		}
	}
	return duration;
}

// float SEffectsEmitToClient(int key, int num = 0, int client, int entity = SOUND_FROM_PLAYER, int channel = SNDCHAN_AUTO)
// {
// 	static char sound[PLATFORM_LINE_LENGTH];
// 	float volume; int level; int flags; int pitch;
// 	float duration = SoundsGetSound(key, num, sound, volume, level, flags, pitch);
// 	
// 	if (duration)
// 	{
// 		EmitSoundToClient(client, sound, entity, channel, level, flags, volume, pitch);
// 	}
// 	return duration;
// }

// float SEffectsEmitAmbient(int key, int num = 0, const float vPosition[3], int entity = SOUND_FROM_WORLD, float flDelay = 0.0)
// {
// 	static char sound[PLATFORM_LINE_LENGTH];
// 	float volume; int level; int flags; int pitch;
// 	float duration = SoundsGetSound(key, num, sound, volume, level, flags, pitch);
// 	
// 	if (duration)
// 	{
// 		EmitAmbientSound(sound, vPosition, entity, level, flags, volume, pitch, flDelay);
// 	}
// 	return duration;
// }

// bool SEffectsStopToAll(int key, int num = 0, int entity = SOUND_FROM_PLAYER, int channel = SNDCHAN_AUTO)
// {
// 	if (num == 0)
// 	{
// 		for (int i = 1; i <= SoundsGetCount(key); i++)
// 		{
// 			SEffectsStopToAll(key, i, entity, channel);
// 		}
// 		return true;
// 	}
// 	
// 	static char sound[PLATFORM_LINE_LENGTH];
// 	float volume; int level; int flags; int pitch;
// 
// 	if (SoundsGetSound(key, num, sound, volume, level, flags, pitch))
// 	{
// 		StopSound(entity, channel, sound);
// 		return true;
// 	}
// 	return false;
// }