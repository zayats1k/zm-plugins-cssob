enum struct ServerData
{
	bool RoundEnd;
	bool IsMapZm;
	
	void Clear()
	{
		this.RoundEnd = false;
		this.IsMapZm = false;
	}
}
ServerData sServerData;

enum struct ClientData
{
	int PriceUp[30];
	
	float ZombieSkills[2];
	
	void Clear()
	{
		this.ZombieSkills[0] = 0.0;
		this.ZombieSkills[1] = 0.0;
	}
}
ClientData sClientData[MAXPLAYERS+1];