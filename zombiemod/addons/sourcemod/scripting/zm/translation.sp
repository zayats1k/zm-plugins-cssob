void TranslationOnInit()
{
	LoadTranslations("zombiemod.phrases");
	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");
	
	static char path[PLATFORM_LINE_LENGTH];
	BuildPath(Path_SM, path, sizeof(path), "translations");
	DirectoryListing directory = OpenDirectory(path);
	
	if (directory == null)
	{
		LogError("Config Validation Error opening folder: \"%s\"", path);
		return;
	}
	
	FileType type; int format;
	while (directory.GetNext(path, sizeof(path), type)) 
	{
		if (type == FileType_File) 
		{
			if (!strncmp(path, "zombiemod_", 9, false))
			{
				format = FindCharInString(path, '.');

				if (format != -1) 
				{
					if (!strcmp(path[format], ".phrases.txt", false))
					{
						LoadTranslations(path);
					}
				}
			}
		}
	}
	delete directory;
}

stock bool TranslationIsPhraseExists(char[] phrase)
{
	StringToLower(phrase); 
	return TranslationPhraseExists(phrase);
}

stock void TranslationPrintToChat(int client, any ...)
{
	if (!IsFakeClient(client))
	{
		static char buffer[SMALL_LINE_LENGTH], translation[PLATFORM_LINE_LENGTH];
		sCvarList.CHAT_PREFIX.GetString(buffer, sizeof(buffer));
		TranslationPluginFormatString(-1, -1, buffer, sizeof(buffer));
	
		SetGlobalTransTarget(client);
		VFormat(translation, sizeof(translation), "%t", 2);
		TranslationPluginFormatString(client, -1, translation, sizeof(translation));

		PrintToChat(client, "\x01%s %s", buffer, translation);
	}
}

stock void TranslationPrintToChatAll(any ...)
{
	static char buffer[SMALL_LINE_LENGTH], translation[PLATFORM_LINE_LENGTH];
	sCvarList.CHAT_PREFIX.GetString(buffer, sizeof(buffer));
	TranslationPluginFormatString(-1, -1, buffer, sizeof(buffer));
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && !IsFakeClient(i))
		{
			SetGlobalTransTarget(i);
			VFormat(translation, sizeof(translation), "%t", 1);
			TranslationPluginFormatString(-1, -1, translation, sizeof(translation));
			PrintToChat(i, "\x01%s %s", buffer, translation);
		}
	}
}

stock void TranslationPrintHudText(Handle sync, int client, float position[2], float holdTime, int color1[4], int color2[4], int effect=0, float fxTime=6.0, float fadeIn=0.1, float fadeOut=0.2, const char[] name, any ...)
{
	if (!IsFakeClient(client) && sForwardData._OnHudText(client, name) == Plugin_Continue)
	{
		if (color2[0] || color2[1] || color2[2] || color2[3])
			SetHudTextParamsEx(position[0], position[1], holdTime, color1, color2, effect, fxTime, fadeIn, fadeOut);
		else SetHudTextParams(position[0], position[1], holdTime, color1[0], color1[1], color1[2], color1[3], effect, fxTime, fadeIn, fadeOut);
	
		SetGlobalTransTarget(client);
		
		static char translation[CHAT_LINE_LENGTH];
		VFormat(translation, CHAT_LINE_LENGTH, "%t", 12);
	
		ShowSyncHudText(client, sync, translation);
	}
}

stock void TranslationPrintHudTextAll(Handle sync, float position[2], float holdTime, int color1[4], int color2[4], int effect=0, float fxTime=6.0, float fadeIn=0.1, float fadeOut=0.2, const char[] name, any ...)
{
	static char translation[CHAT_LINE_LENGTH];
	if (color2[0] || color2[1] || color2[2] || color2[3])
		SetHudTextParamsEx(position[0], position[1], holdTime, color1, color2, effect, fxTime, fadeIn, fadeOut);
	else SetHudTextParams(position[0], position[1], holdTime, color1[0], color1[1], color1[2], color1[3], effect, fxTime, fadeIn, fadeOut);

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && !IsFakeClient(i) && sForwardData._OnHudText(i, name) == Plugin_Continue)
		{
			SetGlobalTransTarget(i);
			VFormat(translation, CHAT_LINE_LENGTH, "%t", 11);
			ShowSyncHudText(i, sync, translation);
		}
	}
}

stock void TranslationPrintCenterText(int client, any ...)
{
	SetGlobalTransTarget(client);
	
	static char translation[CHAT_LINE_LENGTH];
	VFormat(translation, sizeof(translation), "%t", 2);
	
	PrintCenterText(client, translation);
}

stock void TranslationPrintCenterTextAll(any ...)
{
	static char translation[CHAT_LINE_LENGTH];

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && !IsFakeClient(i))
		{
			if (GetClientTeam(i) == CS_TEAM_NONE)
			{
				continue;
			}
			
			SetGlobalTransTarget(i);
			VFormat(translation, sizeof(translation), "%t", 2);
			PrintCenterText(i, translation);
		}
	}
}

stock void TranslationPluginFormatString(int client, int target, char[] text, int maxlen)
{
	ReplaceString(text, maxlen, "\\n", "\n");
	ReplaceString(text, maxlen, "#", "\x07");
	ReplaceString(text, maxlen, "{default}", "\x01");
	
	if (client != -1)
	{
		char buffer[64];
		if (StrContains(text, "{name}") != -1)
		{
			GetClientName(client, buffer, sizeof(buffer));
			ReplaceString(text, maxlen, "{name}", buffer);
		}
	}
	
	if (target != -1)
	{
		char buffer[64];
		if (StrContains(text, "{target}") != -1)
		{
			GetClientName(target, buffer, sizeof(buffer));
			ReplaceString(text, maxlen, "{target}", buffer);
		}
	}
}