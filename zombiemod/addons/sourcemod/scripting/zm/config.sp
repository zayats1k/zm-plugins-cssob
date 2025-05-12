#define CONFIG_FILE_ALIAS_MAPS "maps"
#define CONFIG_FILE_ALIAS_CLASSES "classes"
#define CONFIG_FILE_ALIAS_MENUS "menus"
#define CONFIG_FILE_ALIAS_WEAPONS "weapons"
#define CONFIG_FILE_ALIAS_ADMINS "admins"
#define CONFIG_FILE_ALIAS_HUDS "huds"
#define CONFIG_FILE_ALIAS_SOUNDS "sounds"
#define CONFIG_FILE_ALIAS_GAMEMODES "gamemodes"
#define CONFIG_FILE_ALIAS_BLOCKCOMMANDS "blockcommands"
#define CONFIG_FILE_ALIAS_EXTRAITEMS "extraitems"
#define CONFIG_FILE_ALIAS_COSTUMES "costumes"
#define CONFIG_FILE_ALIAS_SKINS "skins"
#define CONFIG_FILE_ALIAS_DOWNLOADS "downloads"
#define CONFIG_PATH_DEFAULT "zombiemod"
#define PLUGIN_CONFIG "plugin." ... CONFIG_PATH_DEFAULT

enum ConfigStructure
{
	Structure_StringList,
	Structure_IntegerList,
	Structure_ArrayList,
	Structure_KeyValue
};

enum
{
	File_Invalid = -1,
	File_Classes,
	File_Menus,
	File_Weapons,
	File_Admins,
	File_Huds,
	File_Sounds,
	File_GameModes,
	File_BlockCommands,
	File_ExtraItems,
	File_Costumes,
	File_Skins,
	File_Downloads,
	File_Size
};

enum struct ConfigData
{
	bool Loaded;
	ConfigStructure Structure;      
	Function ReloadFunc;
	ArrayList Handler;
	char Path[PLATFORM_LINE_LENGTH];
	char Alias[NORMAL_LINE_LENGTH];
}
ConfigData sConfigData[File_Size]; 

enum ConfigKvAction
{
	KvAction_Create,
	KvAction_Delete,
	KvAction_Set,
	KvAction_Get
};

void ConfigOnInit()
{
	sServerData.Config = new GameData(PLUGIN_CONFIG);
	sServerData.SDKHooks = new GameData("sdkhooks.games");
	sServerData.SDKTools = new GameData("sdktools.games");
	
	if (sServerData.Config == null)
	{
		LogError("[GameData] Config Validation Error opening config: \"%s\"", PLUGIN_CONFIG);
		return;
	}
	
	sServerData.Configs = new StringMap();
}

void ConfigOnCacheData()
{
	sServerData.Configs.Clear();

	static char path[PLATFORM_LINE_LENGTH], sFile[PLATFORM_LINE_LENGTH], sName[PLATFORM_LINE_LENGTH];
	FileType hType; int iFormat;
	BuildPath(Path_SM, path, sizeof(path), "configs/%s/%s", CONFIG_PATH_DEFAULT, CONFIG_FILE_ALIAS_MAPS);
	DirectoryListing hDirectory = OpenDirectory(path);
	
	if (hDirectory == null)
	{
		return;
	}

	ArrayList hList = new ArrayList(PLATFORM_MAX_PATH);
	GetCurrentMap(sName, sizeof(sName));
	
	while (hDirectory.GetNext(path, sizeof(path), hType)) 
	{
		if (hType == FileType_Directory) 
		{
			if (!strncmp(sName, path, strlen(path), false))
			{
				hList.PushString(path);
			}
		}
	}
	
	delete hDirectory;
	SortADTArrayCustom(hList, view_as<SortFuncADTArray>(Sort_ByLength));
	
	int iSize = hList.Length;
	for (int i = 0; i < iSize; i++)
	{
		hList.GetString(i, path, sizeof(path));
		BuildPath(Path_SM, path, sizeof(path), "configs/%s/%s/%s", CONFIG_PATH_DEFAULT, CONFIG_FILE_ALIAS_MAPS, path);
		hDirectory = OpenDirectory(path);
		
		if (hDirectory == null)
		{
			LogError("Config Validation Error opening folder: \"%s\"", path);
			hList.Erase(i);
			iSize--; i--;
			continue;
		}
		while (hDirectory.GetNext(sFile, sizeof(sFile), hType)) 
		{
			if (hType == FileType_File) 
			{
				iFormat = FindCharInString(sFile, '.', true);
		
				if (iFormat != -1) 
				{
					if (!strcmp(sFile[iFormat], ".ini", false))
					{
						 // Format full path to config 
						FormatEx(sName, sizeof(sName), "%s/%s", path, sFile);
				
						sFile[iFormat] = NULL_STRING[0];
				
						sServerData.Configs.SetString(sFile, sName, true);
					}
				}
			}
		}
		delete hDirectory;
	}
	delete hList;
}

stock int Sort_ByLength(int iIndex1, int iIndex2, ArrayList hList, Handle hCustom)
{
	static char buffer1[PLATFORM_LINE_LENGTH], buffer2[PLATFORM_LINE_LENGTH];
	hList.GetString(iIndex1, buffer1, sizeof(buffer1));
	hList.GetString(iIndex2, buffer2, sizeof(buffer2));
	int len1 = strlen(buffer1); int len2 = strlen(buffer2); 
	if (len1 < len2) return -1;
	else if (len1 > len2) return 1;
	return 0;
}

void ConfigOnLoad(const char[] name = "")
{
	char mapconfig[PLATFORM_MAX_PATH], path[PLATFORM_MAX_PATH];
	sCvarList.MAP_CONFIG_PATH.GetString(path, sizeof(path));
	
	GetCurrentMap(mapconfig, sizeof(mapconfig));
	Format(mapconfig, sizeof(mapconfig), "%s%s%s.cfg", path, mapconfig, name);
	Format(path, sizeof(path), "cfg/%s", mapconfig);
	
	if (FileExists(path))
	{
		ServerCommand("exec %s", mapconfig);
	}
}

stock void ConfigRegisterConfig(int iFile, ConfigStructure iStructure, const char[] sAlias = "")
{
	sConfigData[iFile].Loaded = false;
	sConfigData[iFile].Structure = iStructure;
	sConfigData[iFile].Handler = null;
	sConfigData[iFile].ReloadFunc = INVALID_FUNCTION;
	strcopy(sConfigData[iFile].Path, PLATFORM_LINE_LENGTH, "");
	strcopy(sConfigData[iFile].Alias, NORMAL_LINE_LENGTH, sAlias);
}

stock void ConfigSetConfigLoaded(int iConfig, bool bLoaded)
{
	sConfigData[iConfig].Loaded = bLoaded;
}

stock void ConfigSetConfigStructure(int iConfig, ConfigStructure iStructure)
{
	sConfigData[iConfig].Structure = iStructure;
}

stock void ConfigSetConfigReloadFunc(int iConfig, Function iReloadfunc)
{
	sConfigData[iConfig].ReloadFunc = iReloadfunc;
}

stock void ConfigSetConfigHandle(int iConfig, ArrayList iFile)
{
	sConfigData[iConfig].Handler = iFile;
}

stock void ConfigSetConfigPath(int iConfig, const char[] sPath)
{
	strcopy(sConfigData[iConfig].Path, PLATFORM_LINE_LENGTH, sPath);
}

stock void ConfigSetConfigAlias(int iConfig, const char[] sAlias)
{
	strcopy(sConfigData[iConfig].Alias, NORMAL_LINE_LENGTH, sAlias);
}

stock bool ConfigIsConfigLoaded(int iConfig)
{
	return sConfigData[iConfig].Loaded;
}

stock ConfigStructure ConfigGetConfigStructure(int iConfig)
{
	return sConfigData[iConfig].Structure;
}

stock Function ConfigGetConfigReloadFunc(int iConfig)
{
	return sConfigData[iConfig].ReloadFunc;
}

stock ArrayList ConfigGetConfigHandle(int iConfig)
{
	return sConfigData[iConfig].Handler;
}

stock void ConfigGetConfigPath(int iConfig, char[] sPath, int iMaxLen)
{
	strcopy(sPath, iMaxLen, sConfigData[iConfig].Path);
}

stock void ConfigGetConfigAlias(int iConfig, char[] sAlias, int iMaxLen)
{
	strcopy(sAlias, iMaxLen, sConfigData[iConfig].Alias);
}

stock bool ConfigLoadConfig(int iConfig, ArrayList &arrayConfig, int blockSize = NORMAL_LINE_LENGTH)
{
	if (arrayConfig == null)
	{
		arrayConfig = new ArrayList(blockSize);
	}
	
	static char sBuffer[PLATFORM_LINE_LENGTH];
	
	ConfigStructure iStructure = ConfigGetConfigStructure(iConfig);

	switch (iStructure)
	{
		case Structure_StringList:
		{
			File hFile;
			bool bSuccess = ConfigOpenConfigFile(iConfig, hFile);

			if (!bSuccess)
			{
				return false;
			}
			arrayConfig.Clear();

			while (hFile.ReadLine(sBuffer, sizeof(sBuffer)))
			{
				SplitString(sBuffer, "//", sBuffer, sizeof(sBuffer));

				TrimString(sBuffer);
				
				StripQuotes(sBuffer);

				if (!hasLength(sBuffer))
				{
					continue;
				}

				arrayConfig.PushString(sBuffer);
			}

			delete hFile;
			return true;
		}
		
		case Structure_IntegerList:
		{
			File hFile;
			bool bSuccess = ConfigOpenConfigFile(iConfig, hFile);

			if (!bSuccess)
			{
				return false;
			}

			arrayConfig.Clear();

			while (hFile.ReadLine(sBuffer, sizeof(sBuffer)))
			{
				SplitString(sBuffer, "//", sBuffer, sizeof(sBuffer));

				TrimString(sBuffer);
				
				StripQuotes(sBuffer);

				if (!hasLength(sBuffer))
				{
					continue;
				}

				arrayConfig.Push(StringToInt(sBuffer));
			}

			delete hFile;
			return true;
		}

		case Structure_ArrayList:
		{
			File hFile;
			bool bSuccess = ConfigOpenConfigFile(iConfig, hFile);
			
			if (!bSuccess)
			{
				return false;
			}
			
			ClearArrayList(arrayConfig);

			while (hFile.ReadLine(sBuffer, sizeof(sBuffer)))
			{
				SplitString(sBuffer, "//", sBuffer, sizeof(sBuffer));

				TrimString(sBuffer);

				if (!hasLength(sBuffer))
				{
					continue;
				}

				ArrayList arrayConfigEntry = new ArrayList(blockSize);

				arrayConfigEntry.PushString(sBuffer);

				arrayConfig.Push(arrayConfigEntry);
			}
			
			delete hFile;
			return true;
		}
		
		case Structure_KeyValue:
		{
			KeyValues hKeyvalue;
			bool bSuccess = ConfigOpenConfigFile(iConfig, hKeyvalue);
			
			if (!bSuccess)
			{
				return false;
			}
			
			ClearArrayList(arrayConfig);
			
			if (hKeyvalue.GotoFirstSubKey())
			{
				do
				{
					ArrayList arrayConfigEntry = new ArrayList(blockSize);
					
					hKeyvalue.GetSectionName(sBuffer, sizeof(sBuffer));

					StringToLower(sBuffer);

					arrayConfigEntry.PushString(sBuffer);
					
					arrayConfig.Push(arrayConfigEntry);
				} 
				while (hKeyvalue.GotoNextKey());
			}
			
			delete hKeyvalue;
			return true;
		}
	}

	return false;
}

stock bool ConfigReloadConfig(int iConfig)
{
	bool bLoaded = ConfigIsConfigLoaded(iConfig);
	if (!bLoaded)
	{
		return false;
	}
	
	Function iReloadfunc = ConfigGetConfigReloadFunc(iConfig);
	
	Call_StartFunction(GetMyHandle(), iReloadfunc);
	Call_Finish();
	return true;
}

stock bool ConfigOpenConfigFile(int iConfig, Handle &hConfig)
{
	ConfigStructure iStructure = ConfigGetConfigStructure(iConfig);
	
	static char sPath[PLATFORM_LINE_LENGTH];
	ConfigGetConfigPath(iConfig, sPath, sizeof(sPath));
	
	static char sAlias[NORMAL_LINE_LENGTH];
	ConfigGetConfigAlias(iConfig, sAlias, sizeof(sAlias));
	
	switch (iStructure)
	{
		case Structure_KeyValue:
		{
			hConfig = CreateKeyValues(sAlias);
			return FileToKeyValues(hConfig, sPath);
		}
		
		default:
		{
			hConfig = OpenFile(sPath, "r");
			
			if (hConfig == null)
			{
				return false;
			}
			
			return true;
		}
	}
}

stock bool ConfigGetFullPath(const char[] alias, char[] buffer, int maxlength)
{
	if (!sServerData.Configs.GetString(alias, buffer, maxlength))
	{
		BuildPath(Path_SM, buffer, maxlength, "configs/%s/%s.ini", CONFIG_PATH_DEFAULT, alias);
	}
	return FileExists(buffer);
}

stock bool ConfigSettingToBool(const char[] option)
{
	if (!strcmp(option, "yes", false) || !strcmp(option, "on", false) || !strcmp(option, "true", false) || !strcmp(option, "1", false)) {
		return true;
	}
	return false;
}

stock bool ConfigKvGetStringBool(KeyValues kv, const char[] key, const char[] defvalue = "on")
{
	static char value[NORMAL_LINE_LENGTH];
	kv.GetString(key, value, sizeof(value), defvalue);
	
	return ConfigSettingToBool(value);
}

stock int ConfigGetAdmFlags(const char[] sGroup)
{
	if (hasLength(sGroup))
	{
		GroupId nGroup = FindAdmGroup(sGroup);
		return nGroup != INVALID_GROUP_ID ? nGroup.GetFlags() : 0;
	}
	return 0;
}