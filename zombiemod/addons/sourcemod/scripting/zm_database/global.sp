enum struct ServerData
{
	Database Database;
	ArrayList ArrayLevels;
	ArrayList ArrayReward;
	Handle SyncHudAmmo;
	
	int CntPeople;
	bool TimeStart;
	
	void Clear()
	{
		delete this.Database;
		delete this.ArrayLevels;
		delete this.ArrayReward;
		delete this.SyncHudAmmo;
		
		this.CntPeople = 0;
		this.TimeStart = false;
	}
}
ServerData sServerData;

enum struct ClientData
{
	bool Loaded;
	int AccountID;
	
	int HudAmmo;
	float HudGameTime;
	float DamageLost;
	
	int RankPlace;
	int Level;
	int Exp;
	int AmmoPacks;
	int Kills;
	int Deaths;
	int Infects;
	int Infected;
	int boss;
	int bosskills;
	int Time;
	int PlayTime;
	
	void Clear()
	{
		this.Loaded = false;
		this.AccountID = 0;
		
		this.HudAmmo = 0;
		this.HudGameTime = 0.0;
		this.DamageLost = 0.0;
		
		this.RankPlace = 0;
		this.Level = 1;
		this.Exp = 0;
		this.AmmoPacks = 0;
		this.Kills = 0;
		this.Deaths = 0;
		this.Infects = 0;
		this.Infected = 0;
		this.boss = 0;
		this.bosskills = 0;
		this.Time = 0;
		this.PlayTime = 0;
	}
}
ClientData sClientData[MAXPLAYERS+1];

enum struct LevelData
{
	int level;
	char params[264];
	char chat_player[264];
	char chat_all[264];
}