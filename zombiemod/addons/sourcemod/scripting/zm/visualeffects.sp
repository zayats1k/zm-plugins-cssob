void VEffectsOnInit()
{
	AddTempEntHook("EffectDispatch", Hook_EffectDispatch);
}

void VEffectsOnCvarInit()
{
	HookConVarChange(sCvarList.VEFFECTS_LIGHTSTYLE, OnCvarHookLightStyle);
	HookConVarChange(sCvarList.VEFFECTS_SUN_DISABLE, OnCvarHookSunDisable);
}

void VEffectsOnLoad()
{
	LightStyleOnLoad();
	SunOnLoad();
}

void VEffectsOnClientInfected(int client, int attacker)
{
	PlayerVEffectsOnClientInfected(client, attacker);    
}

void VEffectsOnClientHumanized(int client)
{
	RequestFrame(Frame_PlayerVEffectsOnClientHumanized, GetClientUserId(client));
}

public void Frame_PlayerVEffectsOnClientHumanized(int userid) 
{
	int client = GetClientOfUserId(userid);
	
	if (client)
	{
		PlayerVEffectsOnClientHumanized(client);
	}
}

void VEffectsFadeClientScreenAll(ConVar colors, ConVar duration, ConVar HoldTime)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			VEffectsFadeClientScreen(i, colors, duration, HoldTime);
		}
	}
}

void VEffectsFadeClientScreen(int client, ConVar colors, ConVar duration, ConVar HoldTime)
{
	static int color[4];
	if (GetConVarColor(colors, color))
	{
		UTIL_ScreenFade(client, duration.FloatValue, HoldTime.FloatValue, FFADE_IN, color);
	}
}

///
public void OnCvarHookLightStyle(ConVar conVar, char[] oldValue, char[] newValue)
{
	LightStyleOnLoad();
}

void LightStyleOnLoad()
{
	static char name[4];
	sCvarList.VEFFECTS_LIGHTSTYLE.GetString(name, sizeof(name));
	
	if (name[0])
	{
		int iLight = -1;
		while ((iLight = FindEntityByClassname(iLight, "env_cascade_light")) != -1) 
		{ 
			AcceptEntityInput(iLight, "Kill");
		}
		
		SetLightStyle(0, name);
	}
	else SetLightStyle(0, "n");
}

// 
public void OnCvarHookSunDisable(ConVar conVar, char[] oldValue, char[] newValue)
{
	SunOnLoad();
}

void SunOnLoad()
{
	bool disable = !sCvarList.VEFFECTS_SUN_DISABLE.BoolValue;

	int sun = -1; 
	while ((sun = FindEntityByClassname(sun, "env_sun")) != -1)
	{
		if (disable)
		{
			AcceptEntityInput(sun, "TurnOn");
			return;
		}
		
		AcceptEntityInput(sun, "TurnOff");
	}
}

//
public Action Hook_EffectDispatch(const char[] te_name, const int[] Players, int numClients, float delay)
{
	char EffectName[32];
	TE_GetEffectName(TE_ReadNum("m_iEffectName"), EffectName, sizeof(EffectName));
	
	if (strcmp(EffectName, "csblood") == 0)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

stock int TE_GetEffectName(int stringidx, char[] str, int maxlength)
{
	static int tableidx = INVALID_STRING_TABLE;
	
	if (tableidx == INVALID_STRING_TABLE)
	{
		tableidx = FindStringTable("EffectDispatch");
	}
	return ReadStringTable(tableidx, stringidx, str, maxlength);
}