void CookiesInit()
{
    if (sServerData.ClassCookieHuman == null) {
        sServerData.ClassCookieHuman = new Cookie("humanclass", "The last human class selected.", CookieAccess_Private);
    }
    if (sServerData.ClassCookieZombie == null) {
        sServerData.ClassCookieZombie = new Cookie("zombieclass", "The last zombie class selected.", CookieAccess_Private);
    }
    if (sServerData.CookieCostume == null) {
        sServerData.CookieCostume = new Cookie("costume", "Costume", CookieAccess_Private);
    }
    if (sServerData.CookieWeapons == null) {
        sServerData.CookieWeapons = new Cookie("weapons", "Weapons", CookieAccess_Private);
    }
}

public void OnClientCookiesCached(int client)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		sClientData[client].HumanClassNext = CookiesGetInt(client, sCvarList.CLASSES_RANDOM_HUMAN.IntValue, sServerData.ClassCookieHuman);
		sClientData[client].ZombieClassNext = CookiesGetInt(client, sCvarList.CLASSES_RANDOM_ZOMBIE.IntValue, sServerData.ClassCookieZombie);
		
		char sColumn[SMALL_LINE_LENGTH];
		sServerData.CookieCostume.Get(client, sColumn, sizeof(sColumn));
		sClientData[client].Costume = CostumesNameToIndex(sColumn);
		
		
		Maket_OnClientCookiesCached(client);
	}
}

void CookiesSetInt(int client, int ClassRandom, Cookie cookie, int value)
{
	if (ClassRandom == 2)
	{
		char value2[16];
		IntToString(value, value2, sizeof(value2));
		cookie.Set(client, value2);
	}
}

int CookiesGetInt(int client, int ClassRandom, Cookie cookie)
{
	if (ClassRandom == 2)
	{
		char value[16]; value[0] = 0;
		cookie.Get(client, value, sizeof(value));
		return (StringToInt(value));
	}
	return 0;
}