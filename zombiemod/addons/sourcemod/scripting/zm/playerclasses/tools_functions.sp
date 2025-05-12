bool ToolsForceToRespawn(int client)
{
	if (IsValidClient(client) && !IsPlayerAlive(client))
	{
		int DeathMatch = ModesGetMatch(sServerData.RoundMode);
		
		if (DeathMatch != 4)
		{
			if (DeathMatch == 1 || (DeathMatch == 2 && UTIL_GetRandomInt(0, 1)) || (DeathMatch == 3 && GetHumans() < fnGetAlive() / 2))
			{
				sClientData[client].Respawn = CS_TEAM_CT;
			}
			else
			{
				sClientData[client].Respawn = CS_TEAM_T;
			}
		}
		else
		{
			if (sClientData[client].Zombie && !sClientData[client].KilledByWorld)
			{
				sClientData[client].Respawn = CS_TEAM_CT;
			}
			else
			{
				sClientData[client].Respawn = CS_TEAM_T;
				sClientData[client].KilledByWorld = false;
			}
		}
		
		CS_RespawnPlayer(client);
		return true;
	}
	return false;
}

void ToolsSetVelocity(int entity, float velocity[3], bool apply = true, bool stack = true)
{
	if (!apply)
	{
		ToolsGetVelocity(entity, velocity);
		return;
	}
	
	if (stack)
	{
		static float velocity2[3];
		ToolsGetVelocity(entity, velocity2);
		AddVectors(velocity2, velocity, velocity);
	}
	
	TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, velocity);
}

stock void ToolsSetRoundTime(float roundtime)
{
	if (sCvarList.ROUND_TIME.FloatValue == 1.0)
	{
		GameRules_SetProp("m_iRoundTime", roundtime);
		GameRules_SetPropFloat("m_fRoundStartTime", GetGameTime() - float(GameRules_GetProp("m_iRoundTime")) + roundtime);
		GameRules_SetProp("m_bFreezePeriod", 0, 1);
		sServerData.GetRoundTime = roundtime;
	}
}

void ToolsSetTeamScore(int team, int value)
{
	SetTeamScore(team, value);
	CS_SetTeamScore(team, value);
}

void ToolsSetScale(int entity, float scale)
{
	char str[10]; FloatToString(scale, str, sizeof(str));
	SetVariantString(str);
	AcceptEntityInput(entity, "SetModelScale");

	// SetEntPropFloat(entity, Prop_Send, "m_flModelScale", scale);
	// if (scale != 1.0)
	// {
	// 	SetEntPropFloat(entity, Prop_Send, "m_flStepSize", 18.0 * scale);
	// }
}

float ToolsGetScale(int entity)
{
	return GetEntPropFloat(entity, Prop_Send, "m_flModelScale");
}

void ToolsSetHealth(int entity, int health, bool set = false)
{
	SetEntProp(entity, Prop_Send, "m_iHealth", health);
	
	if (set) 
	{
		SetEntProp(entity, Prop_Data, "m_iMaxHealth", health);
	}
}

int ToolsGetHealth(int entity, bool max = false)
{
	return GetEntProp(entity, Prop_Data, max ? "m_iMaxHealth" : "m_iHealth");
}

void ToolsGetVelocity(int entity, float velocity[3])
{
	GetEntPropVector(entity, Prop_Data, "m_vecVelocity", velocity);
}

int ToolsGetActivator(int entity)
{
	return GetEntPropEnt(entity, Prop_Data, "m_pActivator");
}

int ToolsGetActiveWeapon(int entity)
{
	return GetEntPropEnt(entity, Prop_Send, "m_hActiveWeapon");
}

int ToolsGetHitGroup(int entity)
{
	return GetEntProp(entity, Prop_Data, "m_LastHitGroup");
}

void ToolsGetOrigin(int entity, float position[3])
{
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", position);
}

void ToolsGetAngles(int entity, float angle[3])
{
	GetEntPropVector(entity, Prop_Data, "m_angAbsRotation", angle);
}

int ToolsGetMyWeapons(int entity)
{
	return GetEntPropArraySize(entity, Prop_Data, "m_hMyWeapons");
}

int ToolsGetWeapon(int entity, int position)
{
	return GetEntPropEnt(entity, Prop_Data, "m_hMyWeapons", position);
}

int ToolsGetOwner(int entity)
{
	return GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
}

void ToolsSetOwner(int entity, int owner)
{
	SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", owner);
}

int ToolsGetScore(int entity, bool bScore = true)
{
	return GetEntProp(entity, Prop_Data, bScore ? "m_iFrags" : "m_iDeaths");
}

void ToolsSetScore(int entity, bool bScore = true, int iValue = 0)
{
	SetEntProp(entity, Prop_Data, bScore ? "m_iFrags" : "m_iDeaths", iValue);
}

int ToolsGetArmor(int entity)
{
	return GetEntProp(entity, Prop_Send, "m_ArmorValue");
}

void ToolsSetArmor(int entity, int armor)
{
	SetEntProp(entity, Prop_Send, "m_ArmorValue", armor);
}

void ToolsSetGravity(int entity, float value)
{
	SetEntPropFloat(entity, Prop_Data, "m_flGravity", value);
}

void ToolsSetDefuser(int entity, bool enable)
{
	SetEntProp(entity, Prop_Send, "m_bHasDefuser", enable);
}

void ToolsSetHelmet(int entity, bool enable)
{
	SetEntProp(entity, Prop_Send, "m_bHasHelmet", enable);
}

void ToolsSetSpeed(int entity, float speed)
{
	SetEntPropFloat(entity, Prop_Data, "m_flLaggedMovementValue", speed/300.0);
}

void ToolsSetCollisionGroup(int entity, Collision_Group_t collisiongroup)
{
	// SetEntProp(entity, Prop_Data, "m_CollisionGroup", collisiongroup);
	SetEntityCollisionGroup(entity, view_as<int>(collisiongroup));
	EntityCollisionRulesChanged(entity);
}

Collision_Group_t ToolsGetCollisionGroup(int entity)
{
	return view_as<Collision_Group_t>(GetEntProp(entity, Prop_Data, "m_CollisionGroup"));
}

// void ToolsSetlifeState(int entity, int value)
// {
// 	SetEntProp(entity, Prop_Send, "m_lifeState", value);
// }

// int ToolsGetlifeState(int entity)
// {
// 	return GetEntProp(entity, Prop_Send, "m_lifeState");
// }