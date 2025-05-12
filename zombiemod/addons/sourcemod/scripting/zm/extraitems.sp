enum
{
	EXTRAITEMS_DATA_SECTION,
	EXTRAITEMS_DATA_NAME,
	EXTRAITEMS_DATA_WEAPON,
	EXTRAITEMS_DATA_PRICE,
	EXTRAITEMS_DATA_LEVEL,
	EXTRAITEMS_DATA_GROUP,
	EXTRAITEMS_DATA_GROUP_FLAGS,
	EXTRAITEMS_DATA_TYPES
};

void ExtraItemsOnLoad()
{
	ConfigRegisterConfig(File_ExtraItems, Structure_KeyValue, CONFIG_FILE_ALIAS_EXTRAITEMS);

	static char buffer[PLATFORM_LINE_LENGTH];
	if (!ConfigGetFullPath(CONFIG_FILE_ALIAS_EXTRAITEMS, buffer, sizeof(buffer)))
	{
		LogError("[ExtraItems] Config Validation Missing extraitems config file: \"%s\"", buffer);
		return;
	}

	ConfigSetConfigPath(File_ExtraItems, buffer);
	if (!ConfigLoadConfig(File_ExtraItems, sServerData.ExtraItems, SMALL_LINE_LENGTH))
	{
		LogError("[ExtraItems] Config Validation Unexpected error encountered loading: \"%s\"", buffer);
		return;
	}

	if (sServerData.ExtraItems == null)
	{
		LogError("[ExtraItems] [Config Validation] Invalid Handle 0 (error: 4)");
		LogError("[ExtraItems] [Config Validation] server restart");
		return;
	}

	ExtraItemsOnCacheData();

	ConfigSetConfigLoaded(File_ExtraItems, true);
	ConfigSetConfigReloadFunc(File_ExtraItems, GetFunctionByName(GetMyHandle(), "ExtraItemsOnConfigReload"));
	ConfigSetConfigHandle(File_ExtraItems, sServerData.ExtraItems);
}

void ExtraItemsOnCacheData()
{
	static char buffer[PLATFORM_LINE_LENGTH];
	ConfigGetConfigPath(File_ExtraItems, buffer, sizeof(buffer));

	KeyValues kv;
	if (!ConfigOpenConfigFile(File_ExtraItems, kv))
	{
		LogError("[ExtraItems] Config Validation Unexpected error caching data from extraitems config file: \"%s\"", buffer);
		return;
	}
	
	if (sServerData.Sections == null)
	{
		sServerData.Sections = new ArrayList(SMALL_LINE_LENGTH);
	}
	else
	{
		sServerData.Sections.Clear();
	}
	
	int size = sServerData.ExtraItems.Length;
	if (!size)
	{
		LogError("[ExtraItems] Config Validation No usable data found in extraitems config file: \"%s\"", buffer);
		return;
	}
	
	for (int i = 0; i < size; i++)
	{
		ArrayList array = sServerData.ExtraItems.Get(i);
		array.GetString(EXTRAITEMS_DATA_SECTION, buffer, sizeof(buffer));

		sServerData.Sections.PushString(buffer);
	}

	sServerData.ExtraItems.Clear();
	
	for (int i = 0; i < sServerData.Sections.Length; i++)
	{
		sServerData.Sections.GetString(i, buffer, sizeof(buffer));
		kv.Rewind();
		if (!kv.JumpToKey(buffer))
		{
			SetFailState("[ExtraItems] Config Validation Config Validation", "Couldn't cache extraitem data for: \"%s\" (check extraitems config)", buffer);
			continue;
		}

		if (!TranslationIsPhraseExists(buffer))
		{
			SetFailState("[ExtraItems] Config Validation Couldn't cache extraitem section: \"%s\" (check translation file)", buffer);
			continue;
		}

		if (kv.GotoFirstSubKey())
		{
			do
			{
				kv.GetSectionName(buffer, sizeof(buffer));
			
				if (!TranslationIsPhraseExists(buffer))
				{
					SetFailState("[ExtraItems] Config Validation Couldn't cache extraitem name: \"%s\" (check translation file)", buffer);
					continue;
				}
				
				ArrayList array = new ArrayList(SMALL_LINE_LENGTH);

				array.Push(i); // Index: 0
				array.PushString(buffer); // Index: 1
				array.Push(WeaponsEntityToIndex(buffer)); // Index: 2
				array.Push(kv.GetNum("price", 0)); // Index: 3
				array.Push(kv.GetNum("level", 0)); // Index: 4
				kv.GetString("group", buffer, sizeof(buffer), ""); 
				array.PushString(buffer); // Index: 5
				array.Push(ConfigGetAdmFlags(buffer)); // Index: 6
				kv.GetString("types", buffer, sizeof(buffer), ""); 
				array.Push(ClassTypeToIndex(buffer)); // Index: 7
				
				sServerData.ExtraItems.Push(array);
			}
			while (kv.GotoNextKey());
		}
	}

	delete kv;
}

public void ExtraItemsOnConfigReload()
{
	ExtraItemsOnLoad();
}

int ItemsGetSectionID(int id)
{
	ArrayList array = sServerData.ExtraItems.Get(id);
	return array.Get(EXTRAITEMS_DATA_SECTION);
}

void ItemsGetName(int id, char[] name, int maxLen)
{
	ArrayList array = sServerData.ExtraItems.Get(id);
	array.GetString(EXTRAITEMS_DATA_NAME, name, maxLen);
}

int ItemsGetWeaponID(int id)
{
	ArrayList array = sServerData.ExtraItems.Get(id);
	return array.Get(EXTRAITEMS_DATA_WEAPON);
}

int ItemsGetPrice(int id)
{
	ArrayList array = sServerData.ExtraItems.Get(id);
	return array.Get(EXTRAITEMS_DATA_PRICE);
}

int ItemsGetLevel(int id)
{
	ArrayList array = sServerData.ExtraItems.Get(id);
	return array.Get(EXTRAITEMS_DATA_LEVEL);
}

void ItemsGetGroup(int id, char[] group, int maxLen)
{
	ArrayList array = sServerData.ExtraItems.Get(id);
	array.GetString(EXTRAITEMS_DATA_GROUP, group, maxLen);
}

int ItemsGetGroupFlags(int id)
{
	ArrayList array = sServerData.ExtraItems.Get(id);
	return array.Get(EXTRAITEMS_DATA_GROUP_FLAGS);
}

int ItemsGetTypes(int id)
{
	ArrayList array = sServerData.ExtraItems.Get(id);
	return array.Get(EXTRAITEMS_DATA_TYPES);
}

// int ItemsNameToIndex(const char[] name)
// {
// 	static char ItemName[SMALL_LINE_LENGTH];
// 	for (int i = 0; i < sServerData.ExtraItems.Length; i++)
// 	{
// 		ItemsGetName(i, ItemName, sizeof(ItemName));
// 		
// 		if (!strcmp(name, ItemName, false)) {
// 			return i;
// 		}
// 	}
// 	
// 	return -1;
// }

bool ItemsHasAccessByType(int client, int id)
{
	return ClassHasTypeBits(ItemsGetTypes(id), ClassGetType(sClientData[client].Class));
}