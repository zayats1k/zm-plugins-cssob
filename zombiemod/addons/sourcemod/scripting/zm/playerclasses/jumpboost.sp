void JumpBoostOnInit()
{
	bool JumpBoost = sCvarList.JUMPBOOST.BoolValue;
	if (!JumpBoost)
	{
		UnhookEvent2("player_jump", JumpBoostOnClientJump, EventHookMode_Post);
		return;
	}
	
	HookEvent("player_jump", JumpBoostOnClientJump, EventHookMode_Post);
}

// void JumpBoostOnClientInit(int client)
// {
// 	SDKHook(client, SDKHook_GroundEntChangedPost, JumpBoostOnClientEntChanged);
// }

void JumpBoostOnCvarInit()
{
	HookConVarChange(sCvarList.JUMPBOOST, JumpBoostOnCvarHook);
}

public void JumpBoostOnCvarHook(ConVar convar, char[] oldValue, char[] newValue)
{
	if (!strcmp(oldValue, newValue, false))
	{
		return;
	}
	
	JumpBoostOnInit();
}

// public void JumpBoostOnClientEntChanged(int client)
// {
// 	if (!(GetEntityFlags(client) & FL_ONGROUND))
// 	{
// 		return;
// 	}
// 	
// 	if (GetEntityMoveType(client) != MOVETYPE_LADDER)
// 	{
// 		ToolsSetGravity(client, ClassGetGravity(sClientData[client].Class));
// 	}
// }

public Action JumpBoostOnClientJump(Event event, char[] name, bool dontBroadcast) 
{
	if (!sCvarList.JUMPBOOST.BoolValue)
	{
		return Plugin_Continue;
	}

	int client = GetClientOfUserId(event.GetInt("userid"));
	CreateTimer(0.0, JumpBoostOnClientJumpPost, GetClientUserId(client));
	return Plugin_Continue;
}

public Action JumpBoostOnClientJumpPost(Handle timer, any userID)
{
	int client = GetClientOfUserId(userID);

	if (client)
	{
		static float vVelocity[3];
		ToolsGetVelocity(client, vVelocity);
		
		float flMaxBoost = sCvarList.JUMPBOOST_MAX.FloatValue;
		float flMaxBoost2 = flMaxBoost * flMaxBoost;
		float flMultiplier = sCvarList.JUMPBOOST_MULTIPLIER.FloatValue;
		
		if (GetVectorLength(vVelocity, true) < flMaxBoost2)
		{
			vVelocity[0] *= flMultiplier;
			vVelocity[1] *= flMultiplier;
		}
		
		vVelocity[2] *= flMultiplier;

		int weapon = ToolsGetActiveWeapon(client);
		
		if (weapon != -1)
		{
			int index = WeaponsGetCustomID(weapon);
			if (index != -1)
			{
				vVelocity[2] += WeaponsGetJump(index);
			}
		}

		ToolsSetVelocity(client, vVelocity, true, false);
	}
	return Plugin_Stop;
}