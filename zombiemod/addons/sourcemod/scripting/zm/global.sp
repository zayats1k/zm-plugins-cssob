enum struct ServerData
{
	bool Late;
	
	GameData Config;
	GameData SDKHooks;
	GameData SDKTools;

	Cookie ClassCookieHuman;
	Cookie ClassCookieZombie;
	Cookie CookieCostume;
	Cookie CookieWeapons;
	
	StringMap Configs;
	ArrayList Sections;
	ArrayList Types;
	ArrayList Clients;
	ArrayList LastZombies;
	ArrayList Classes;
	ArrayList Menus;
	ArrayList Weapons;
	ArrayList Costumes;
	ArrayList Admins;
	ArrayList Huds;
	ArrayList Sounds;
	ArrayList GameModes;
	ArrayList BlockCommands;
	ArrayList ExtraItems;
	ArrayList Skins;
	ArrayList Downloads;
	ArrayList Spawns;
	
	Handle RoundTime;
	Handle CounterTimer;
	Handle RoundPrestart;
	Handle SyncHudClass;
	Handle SyncHud;
	
	bool RoundNew;
	bool RoundEnd;
	bool RoundStart;
	bool MapLoaded;
	bool Warmup;
	bool BlockRespawn;
	
	int RoundMode;
	int RoundModeCount;
	int Zombie;
	int Human;
	int RoundCount;
	int WarmupTime;
	
	int PlayerManager;
	
	float GetRoundTime;
	
	void PurgeTimers()
	{
		this.RoundTime = null;
		this.CounterTimer = null;
		this.RoundPrestart = null;
	}
}
ServerData sServerData;

enum struct ClientData
{
	Handle RespawnTimer;
	Handle AmbientTimer;
	Handle CounterTimer;
	Handle HealTimer;
	Handle TeleTimer;
	Handle WeaponsTimer;
	
	ArrayList ShoppingCart;
	ArrayList DefaultCart;
	
	bool Zombie;
	bool Custom;
	bool RunCmd;
	bool KilledByWorld;
	
	float HealCounter;
	float SpawnTime;
	float DeathTime;
	int Class;
	int HumanClassNext;
	int ZombieClassNext;
	int Skin;
	
	int Costume;
	int AttachmentCostume;
	
	int Respawn;
	int RespawnTimer2;
	int RespawnTimes;
	
	int TeleTimes;
	int TeleCounter;
	float TeleOrigin[3];
	float TeleSpawn[3];
	
	bool PlayerSpotted;
	bool PlayerSpott;
	
	bool PickWeaponRound[10];
	bool PickWeapon[10];
	
	// new weapons
	int AddonEntity[3];
	int PrevAddonBits;
	int PrevWeapon;
	bool IsCustom;
	bool SpawnCheck;
	bool RightHand;
	float NextCycle;
	float NextSequence;
	float PrevCycle;
	float fNextRightHand;
	int ViewModel[2];
	int PrevSeq;
	
	void ResetVars()
	{
		delete this.ShoppingCart;
		delete this.DefaultCart;
		
		for (int x = 0; x < 10; x++) {
			this.PickWeaponRound[x] = false;
			this.PickWeapon[x] = false;
		}
		
		this.Zombie = false;
		this.Custom = false;
		this.RunCmd = false;
		this.KilledByWorld = false;
		this.PlayerSpotted = false;
		this.PlayerSpott = false;
		this.HealCounter = 0.0;
		this.SpawnTime = 0.0;
		this.DeathTime = 0.0;
		this.Class = 0;
		this.HumanClassNext = 0;
		this.ZombieClassNext = 0;
		this.Skin = -1;
		this.Costume = -1;
		this.AttachmentCostume = -1;
		this.Respawn = CS_TEAM_CT;
		this.RespawnTimer2 = 0;
		// this.RespawnTimes = 0;
		this.TeleTimes = 0;
		this.TeleCounter = 0;
		this.TeleOrigin = NULL_VECTOR;
		this.TeleSpawn = NULL_VECTOR;
		
		this.AddonEntity[0] = 0;
		this.AddonEntity[1] = 0;
		this.AddonEntity[2] = 0;
		this.PrevAddonBits = 0;
		this.PrevWeapon = -1;
		this.IsCustom = false;
		this.SpawnCheck = false;
		this.RightHand = false;
		this.NextCycle = 0.0;
		this.NextSequence = 0.0;
		this.PrevCycle = 0.0;
		this.fNextRightHand = 0.0;
		this.ViewModel[0] = 0;
		this.ViewModel[1] = 0;
		this.PrevSeq = 0;
	}
	void ResetTimers()
	{
		delete this.RespawnTimer;
		delete this.AmbientTimer;
		delete this.HealTimer;
		delete this.TeleTimer;
		delete this.WeaponsTimer;
	}
	void PurgeTimers()
	{
		this.RespawnTimer = null;
		this.AmbientTimer = null;
		this.HealTimer = null;
		this.TeleTimer = null;
		this.WeaponsTimer = null;
	}
}
ClientData sClientData[MAXPLAYERS+1];