void DownloadsOnLoad()
{
	ConfigRegisterConfig(File_Downloads, Structure_StringList, CONFIG_FILE_ALIAS_DOWNLOADS);

	static char buffer[PLATFORM_LINE_LENGTH];
	if (!ConfigGetFullPath(CONFIG_FILE_ALIAS_DOWNLOADS, buffer, sizeof(buffer)))
	{
		LogError("[Downloads] [Config Validation] Missing downloads file: \"%s\"", buffer);
		return;
	}

	ConfigSetConfigPath(File_Downloads, buffer);
	if (!ConfigLoadConfig(File_Downloads, sServerData.Downloads, PLATFORM_LINE_LENGTH))
	{
		LogError("[Downloads] [Config Validation] Unexpected error encountered loading: %s", buffer);
		return;
	}
	
	DownloadsOnCacheData();
	
	ConfigSetConfigLoaded(File_Downloads, true);
	ConfigSetConfigReloadFunc(File_Downloads, GetFunctionByName(GetMyHandle(), "DownloadsOnConfigReload"));
	ConfigSetConfigHandle(File_Downloads, sServerData.Downloads);
}

void DownloadsOnCacheData()
{
	static char buffer[PLATFORM_LINE_LENGTH];
	ConfigGetConfigPath(File_Downloads, buffer, sizeof(buffer));
	
	// int iDownloadCount, iDownloadValidCount, iDownloadUnValidCount;
	
	int iDownloads = sServerData.Downloads.Length; // = iDownloadCount =
	if (!iDownloads)
	{
		// LogError("[Downloads] [Config Validation] No usable data found in downloads config file: \"%s\"", buffer);
		return;
	}

	for (int i = 0; i < iDownloads; i++)
	{
		sServerData.Downloads.GetString(i, buffer, sizeof(buffer));

		if (FileExists(buffer) || FileExists(buffer, true)) 
		{
			DownloadsOnPrecache(buffer);
			
			// if (DownloadsOnPrecache(buffer)) 
			// 	iDownloadValidCount++; 
			// else iDownloadUnValidCount++;
		}
		else
		{
			DirectoryListing directory = OpenDirectory(buffer);
			
			if (directory == null)
			{
				directory = OpenDirectory(buffer, true);
			}

			if (directory == null)
			{
				LogError("[Downloads] [Config Validation] Incorrect path \"%s\"", buffer);
				
				sServerData.Downloads.Erase(i);
				iDownloads--; i--;
				continue;
			}
	
			static char file[PLATFORM_LINE_LENGTH]; FileType type;
			
			while (directory.GetNext(file, sizeof(file), type)) 
			{
				if (type == FileType_File) 
				{
					Format(file, sizeof(file), "%s%s", buffer, file);
					DownloadsOnPrecache(file);
					
					// if (DownloadsOnPrecache(file))
					// 	iDownloadValidCount++;
					// else iDownloadUnValidCount++;
				}
			}
		
			delete directory;
		}
	}
	
	// LogMessage("[Downloads] [Config Validation] Total blocks: \"%d\" | Unsuccessful blocks: \"%d\" | Total: \"%d\" | Successful: \"%d\" | Unsuccessful: \"%d\"", iDownloadCount, iDownloadCount - iDownloads, iDownloadValidCount + iDownloadUnValidCount, iDownloadValidCount, iDownloadUnValidCount);
}

public void DownloadsOnConfigReload()
{
	DownloadsOnLoad();
}

bool DownloadsOnPrecache(const char[] path)
{
	int iFormat = FindCharInString(path, '.', true);
	
	if (iFormat == -1)
	{
		LogError("[Downloads] [Config Validation] Missing file format: %s", path);
		return false;
	}
	
	AddFileToDownloadsTable(path);
	
	if (!strcmp(path[iFormat], ".mp3", false) || !strcmp(path[iFormat], ".wav", false))
	{
		PrecacheSound(path[6], true);
	}
	else if (!strcmp(path[iFormat], ".mdl", false))
	{
		PrecacheModel(path, true);
	}
	return true;
}
