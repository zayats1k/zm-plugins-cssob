#define ANTISTICK_DEFAULT_HULL_WIDTH 32.0

void AntiStickOnInit()
{
	RegConsoleCmd("zstuck", Command_Stuck);
}

void AntiStickClientInit(int client)
{
	SDKHook(client, SDKHook_StartTouch, AntiStickStartTouch);
}

void AntiStickOnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_StartTouch, AntiStickStartTouch);
}

public Action Command_Stuck(int client, int args)
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		if (!AntiStickIsClientStuck(client))
		{
			// TranslationPrintToChat(client, "block unstucking prop");
			EmitSoundToClient(client, SOUND_BUTTON_CMD_ERROR, SOUND_FROM_PLAYER, SNDCHAN_ITEM, SNDLEVEL_WHISPER);  
			return Plugin_Handled;
		}
		
		SpawnTeleportToRespawn(client);
	}
	return Plugin_Handled;
}

public void AntiStickStartTouch(int client, int entity)
{
	if (!IsValidClient(client))
	{
		return;
	}
	
	if (client == entity)
	{
		return;
	}
	
	if (!IsValidClient(entity))
	{
		return;
	}
	
	if (sClientData[client].RespawnTimer != null)
	{
		return;
	}
	
	if (!AntiStickIsModelBoxColliding(client, entity))
	{
		return;
	}
	
	if (ToolsGetCollisionGroup(client) != COLLISION_GROUP_PUSHAWAY)
	{
		ToolsSetCollisionGroup(client, COLLISION_GROUP_PUSHAWAY);
		CreateTimer(0.0, AntiStickSolidifyTimer, client, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	}
}

public Action AntiStickSolidifyTimer(Handle timer, int client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
	{
		return Plugin_Stop;
	}
	
	if (ToolsGetCollisionGroup(client) == COLLISION_GROUP_PLAYER)
	{
		return Plugin_Stop;
	}
	
	if (AntiStickIsStuck(client))
	{
		return Plugin_Continue;
	}
	
	ToolsSetCollisionGroup(client, COLLISION_GROUP_PLAYER);
	return Plugin_Stop;
}

stock void AntiStickBuildModelBox(int client, float boundaries[8][3], float width)
{
	float clientloc[3], twistang[3], cornerang[3], sideloc[3];
	float finalloc[4][3];
	
	GetClientAbsOrigin(client, clientloc);
	twistang[1] = 90.0; cornerang[1] = 0.0;
	
	for (int x = 0; x < 4; x++)
	{
		AntiStickJumpToPoint(clientloc, twistang, width / 2, sideloc);
		AntiStickJumpToPoint(sideloc, cornerang, width / 2, finalloc[x]);
		
		twistang[1] += 90.0;
		cornerang[1] += 90.0;
		
		if (twistang[1] > 180.0) {
			twistang[1] -= 360.0;
		}
		
		if (cornerang[1] > 180.0) {
			cornerang[1] -= 360.0;
		}
	}
	
	boundaries[0][0] = finalloc[3][0];
	boundaries[0][1] = finalloc[3][1];
	boundaries[1][0] = finalloc[0][0];
	boundaries[1][1] = finalloc[0][1];
	boundaries[2][0] = finalloc[3][0];
	boundaries[2][1] = finalloc[3][1];
	boundaries[3][0] = finalloc[0][0];
	boundaries[3][1] = finalloc[0][1];
	boundaries[4][0] = finalloc[2][0];
	boundaries[4][1] = finalloc[2][1];
	boundaries[5][0] = finalloc[1][0];
	boundaries[5][1] = finalloc[1][1];
	boundaries[6][0] = finalloc[2][0];
	boundaries[6][1] = finalloc[2][1];
	boundaries[7][0] = finalloc[1][0];
	boundaries[7][1] = finalloc[1][1];
	
	float eyeloc[3]; GetClientEyePosition(client, eyeloc);
	boundaries[0][2] = eyeloc[2];
	boundaries[1][2] = eyeloc[2];
	boundaries[2][2] = clientloc[2] + 15.0;
	boundaries[3][2] = clientloc[2] + 15.0;
	boundaries[4][2] = eyeloc[2];
	boundaries[5][2] = eyeloc[2];
	boundaries[6][2] = clientloc[2] + 15.0;
	boundaries[7][2] = clientloc[2] + 15.0;
}

stock void AntiStickJumpToPoint(const float vec[3], const float ang[3], float distance, float result[3])
{
	float viewvec[3];
	GetAngleVectors(ang, viewvec, NULL_VECTOR, NULL_VECTOR);
	
	NormalizeVector(viewvec, viewvec);
	ScaleVector(viewvec, distance);
	AddVectors(vec, viewvec, result);
}

stock float AntiStickGetBoxMaxBoundary(int axis, float boundaries[8][3], bool min = false)
{
	float outlier = boundaries[0][axis];
	
	for (int x = 1; x < sizeof(boundaries); x++)
	{
		if (!min && boundaries[x][axis] > outlier)
		{
			outlier = boundaries[x][axis];
		}
		else if (min && boundaries[x][axis] < outlier)
		{
			outlier = boundaries[x][axis];
		}
	}
	return outlier;
}

bool AntiStickIsStuck(int client)
{
	for (int x = 1; x <= MaxClients; x++)
	{
		if (!IsClientConnected(x) || !IsClientInGame(x) || !IsPlayerAlive(x))
		{
			continue;
		}
		
		if (client == x)
		{
			continue;
		}
		
		if (AntiStickIsModelBoxColliding(client, x))
		{
			return true;
		}
	}
	return false;
}

stock bool AntiStickIsModelBoxColliding(int client1, int client2)
{
	float client1modelbox[8][3];
	float client2modelbox[8][3];
	
	AntiStickBuildModelBox(client1, client1modelbox, ANTISTICK_DEFAULT_HULL_WIDTH);
	AntiStickBuildModelBox(client2, client2modelbox, ANTISTICK_DEFAULT_HULL_WIDTH);
	
	float max1x = AntiStickGetBoxMaxBoundary(0, client1modelbox);
	float max2x = AntiStickGetBoxMaxBoundary(0, client2modelbox);
	float min1x = AntiStickGetBoxMaxBoundary(0, client1modelbox, true);
	float min2x = AntiStickGetBoxMaxBoundary(0, client2modelbox, true);
	
	if (max1x < min2x || min1x > max2x)
	{
		return false;
	}
	
	float max1y = AntiStickGetBoxMaxBoundary(1, client1modelbox);
	float max2y = AntiStickGetBoxMaxBoundary(1, client2modelbox);
	float min1y = AntiStickGetBoxMaxBoundary(1, client1modelbox, true);
	float min2y = AntiStickGetBoxMaxBoundary(1, client2modelbox, true);
	
	if (max1y < min2y || min1y > max2y) {
		return false;
	}
	
	float max1z = AntiStickGetBoxMaxBoundary(2, client1modelbox);
	float max2z = AntiStickGetBoxMaxBoundary(2, client2modelbox);
	float min1z = AntiStickGetBoxMaxBoundary(2, client1modelbox, true);
	float min2z = AntiStickGetBoxMaxBoundary(2, client2modelbox, true);
	
	if (max1z < min2z || min1z > max2z) {
		return false;
	}
	return true;
}

bool AntiStickIsClientStuck(int client)
{
	static float origin[3], maxs[3], mins[3];
	GetClientAbsOrigin(client, origin);
	GetClientMins(client, mins);
	GetClientMaxs(client, maxs);
	TR_TraceHullFilter(origin, origin, mins, maxs, MASK_SOLID, AntiStickFilter, client);

	if (TR_DidHit())
	{
		int victim = TR_GetEntityIndex();
		if (victim > 0)
		{
			// static char classname[64];
			// GetEntityClassname(victim, classname, sizeof(classname))
			// PrintToChatAll("[5] %s - %d", classname, ToolsGetCollisionGroup(victim));
		
			switch (ToolsGetCollisionGroup(victim))
			{
				case COLLISION_GROUP_DEBRIS, COLLISION_GROUP_DEBRIS_TRIGGER, COLLISION_GROUP_INTERACTIVE_DEBRIS,
				COLLISION_GROUP_IN_VEHICLE, COLLISION_GROUP_WEAPON, COLLISION_GROUP_VEHICLE_CLIP, COLLISION_GROUP_DISSOLVING,
				COLLISION_GROUP_PUSHAWAY: return false;
			}
			
			if (ToolsGetOwner(victim) == client)
			{
				return false;
			}
		}
		return true;
	}
	return false;
}

public bool AntiStickFilter(int entity, int contentsMask, int client) 
{
	return (entity != client);
}