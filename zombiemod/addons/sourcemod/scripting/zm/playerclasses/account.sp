void AccountOnClientSpawn(int client)
{
	int cash = sCvarList.ACCOUNT_CASHFILL_VALUE.IntValue;
	if (cash > 0)
	{
		if (sClientData[client].Zombie)
		{
			return;
		}
	
		AccountSetClientCash(client, cash);
	}
}

void AccountOnClientHurt(int client, int attacker, float damage)
{
	if (sCvarList.ACCOUNT_CASHDMG.BoolValue)
	{
		if (!IsValidClient(attacker))
		{
			return;
		}
		
		if (client == attacker)
		{
			return;
		}
		
		if (sClientData[attacker].Zombie)
		{
			return;
		}
		
		int cash = AccountGetClientCash(attacker);
		
		if (cash >= 16000)
		{
			return;
		}
		
		AccountSetClientCash(attacker, cash + RoundFloat(damage));
	}
}

stock int AccountGetClientCash(int client)
{
    return GetEntData(client, Player_bAccount, 4);
}

stock void AccountSetClientCash(int client, int value)
{
	if (value < 0) {
		value = 0;
	}
	SetEntData(client, Player_bAccount, value, 4);
}
