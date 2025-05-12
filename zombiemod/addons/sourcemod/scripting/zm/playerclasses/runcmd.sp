public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon)
{
	Action result; static int LastButtons[MAXPLAYERS+1]; 
	
	if (IsPlayerAlive(client))
	{
		if (ToolsGetScale(client) != 1.0)
		{
			buttons &= ~IN_DUCK;
		}
	
		int iButton = buttons;
		
		result = WeaponsOnRunCmd(client, buttons, LastButtons[client]);
		
		SpawnOnRunCmd(client, buttons, LastButtons[client], impulse);
		
		LastButtons[client] = iButton;
		return result;
	}
	return Plugin_Continue;
}