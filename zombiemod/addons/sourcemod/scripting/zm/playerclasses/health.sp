void HealOnClientUpdate(int client)
{
	float interval = ClassGetRegenInterval(sClientData[client].Class);
	if (!interval || !ClassGetRegenHealth(sClientData[client].Class))
	{
		return;
	}
	
	if (!ModesIsRegen(sServerData.RoundMode))
	{
		return;
	}
	
	delete sClientData[client].HealTimer;
	sClientData[client].HealTimer = CreateTimer(interval, Timer_HealnClientRegen, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_HealnClientRegen(Handle hTimer, int userid)
{
	int client = GetClientOfUserId(userid);

	if (client && !IsFakeClient(client))
	{
		if (GetGameTime() > sClientData[client].HealCounter)
		{
			int hp = ToolsGetHealth(client);
			
			if (hp < ClassGetHealth(sClientData[client].Class))
			{
				int regen = hp + ClassGetRegenHealth(sClientData[client].Class);
				
				if (regen > ClassGetHealth(sClientData[client].Class))
				{
					regen = ClassGetHealth(sClientData[client].Class);
				}
				
				ToolsSetHealth(client, regen);
			}
		}
		return Plugin_Continue;
	}

	sClientData[client].HealTimer = null;
	return Plugin_Stop;
}