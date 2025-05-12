static const char TextMsgArray[][] =
{
	"#C4_Plant_At_Bomb_Spot",
	"#Got_bomb"
};

static const char HintTextArray[][] =
{
	"#Hint_out_of_ammo",
	"#Hint_you_have_the_bomb",
	"#Hint_spotted_a_friend",
	"#Hint_spotted_an_enemy",
	"#Hint_win_round_by_killing_enemy",
	"#Hint_press_buy_to_purchase",
	"#Spec_Duck"
};

void BlockCommandsOnInit()
{
	HookUserMessage(GetUserMessageId("TextMsg"), Hook_TextMsg, true);
	HookUserMessage(GetUserMessageId("HintText"), Hook_HintText, true);
}

void BlockCommandsOnLoad()
{
	ConfigRegisterConfig(File_BlockCommands, Structure_StringList, CONFIG_FILE_ALIAS_BLOCKCOMMANDS);
	
	static char buffer[PLATFORM_LINE_LENGTH];
	if (!ConfigGetFullPath(CONFIG_FILE_ALIAS_BLOCKCOMMANDS, buffer, sizeof(buffer)))
	{
		LogError("[BlockCommands] [Config Validation] Missing blockcommands config file: %s", buffer);
		return;
	}
	
	ConfigSetConfigPath(File_BlockCommands, buffer);
	
	if (!ConfigLoadConfig(File_BlockCommands, sServerData.BlockCommands, PLATFORM_LINE_LENGTH))
	{
		LogError("[BlockCommands] [Config Validation] Unexpected error encountered loading: %s", buffer);
		return;
	}

	if (sServerData.BlockCommands == null)
	{
		LogError("[BlockCommands] [Config Validation] Invalid Handle 0 (error: 4)");
		LogError("[BlockCommands] [Config Validation] server restart");
		return;
	}

	BlockCommandsOnCacheData();

	ConfigSetConfigLoaded(File_BlockCommands, true);
	ConfigSetConfigReloadFunc(File_BlockCommands, GetFunctionByName(GetMyHandle(), "BlockCommandsOnConfigReload"));
	ConfigSetConfigHandle(File_BlockCommands, sServerData.BlockCommands);
}

void BlockCommandsOnCacheData()
{
	static char buffer[PLATFORM_LINE_LENGTH];
	ConfigGetConfigPath(File_BlockCommands, buffer, sizeof(buffer));
	
	int cmds = sServerData.BlockCommands.Length;
	if (!cmds)
	{
		LogError("[BlockCommands] [Config Validation] No usable data found in blockcommands config file: \"%s\"", buffer);
		return;
	}
	
	static char exp[10][35];
	for (int i = 0; i < cmds; i++)
	{
		sServerData.BlockCommands.GetString(i, buffer, sizeof(buffer));
		for (int c = 0; c < ExplodeString(buffer, " ", exp, sizeof(exp), sizeof(exp[])); c++)
		{
			AddCommandListener(command_blocked, exp[c]);
		}
	}
}

public void BlockCommandsOnConfigReload()
{
	BlockCommandsOnLoad();
}

public Action command_blocked(int client, const char[] command, int argc)
{
	return (client == 0) ? Plugin_Continue:Plugin_Stop;
}

public Action Hook_TextMsg(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
	if (reliable)
	{
		char buffer[PLATFORM_MAX_PATH];
		msg.ReadString(buffer, sizeof(buffer));
		// PrintToServer("[Hook_TextMsg] [%s]", buffer);
		
		for (int i = 0; i < sizeof(TextMsgArray); i++)
		{
			if (StrContains(buffer, TextMsgArray[i], false) != -1)
			{
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue; 
}

public Action Hook_HintText(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
	char buffer[PLATFORM_MAX_PATH];
	msg.ReadString(buffer, sizeof(buffer));
	// PrintToServer("[Hook_HintText] [%s]", buffer);
	
	for (int i = 0; i < sizeof(HintTextArray); i++)
	{
		if (!strcmp(buffer, HintTextArray[i], false))
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}