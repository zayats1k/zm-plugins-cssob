#define HITGROUP_GENERIC 0
#define HITGROUP_HEAD 1
#define HITGROUP_CHEST 2
#define HITGROUP_STOMACH 3
#define HITGROUP_LEFTARM 4
#define HITGROUP_RIGHTARM 5
#define HITGROUP_LEFTLEG 6
#define HITGROUP_RIGHTLEG 7
#define HITGROUP_GEAR 8

void HitGroupsOnClientInit(int client)
{
	SDKHook(client, SDKHook_TraceAttack, Hook_TraceAttack);
	SDKHook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
}

void HitGroupsOnEntityCreated(int entity, const char[] classname)
{
	if (!strcmp(classname[6], "hurt", false))
	{
		SDKHook(entity, SDKHook_SpawnPost, Hook_OnHurtSpawn);
	}
}

public void Hook_OnHurtSpawn(int entity)
{
	WeaponsSetCustomID(entity, -1);
}

public Action Hook_TraceAttack(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& ammotype, int hitbox, int hitgroup)
{
	if (sServerData.RoundEnd == true)
	{
		return Plugin_Handled;
	}

	if (sClientData[victim].RespawnTimer != null)
	{
		return Plugin_Handled;
	}
	
	if (IsPlayerAlive(victim) && IsValidClient(attacker) && IsPlayerAlive(attacker))
	{
		if (sClientData[victim].Zombie == sClientData[attacker].Zombie)
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public Action Hook_OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	if (sServerData.RoundEnd == true)
	{
		return Plugin_Handled;
	}

	if (sClientData[victim].RespawnTimer != null)
	{
		return Plugin_Handled;
	}

	static char classname[SMALL_LINE_LENGTH]; classname[0] = NULL_STRING[0];
	if (IsValidEdict(inflictor))
	{
		GetEdictClassname(inflictor, classname, sizeof(classname));
		
		if (!strncmp(classname, "trigger", 7, false))
		{
			return Plugin_Continue;
		}
	}
	
	if (damagetype == DMG_BLAST || damagetype == (DMG_BLAST_SURFACE|DMG_BLAST))
	{
		if (IsValidClient(victim) && IsValidClient(attacker))
		{
			if (sClientData[victim].Zombie == sClientData[attacker].Zombie)
			{
				return Plugin_Handled;
			}
		
			// if (IsValidClient(victim) && IsPlayerAlive(victim) && GetClientTeam(victim) == GetEntProp(inflictor, Prop_Send, "m_iTeamNum"))
			// {
			// 	return Plugin_Handled;
			// }
			
			if (sClientData[attacker].Zombie && strcmp(classname, "hegrenade_projectile", false) == 0)
			{
				return Plugin_Handled;
			}
		}
	}
	
	if (damagetype == (DMG_BLAST_SURFACE|DMG_BLAST)) // ...?
	{
		sForwardData._OnClientDamaged(victim, attacker, inflictor, damage, damagetype);
		return Plugin_Continue;
	}

	if (!HitGroupsOnCalculateDamage(victim, attacker, inflictor, damage, damagetype, classname))
	{
		return Plugin_Handled;
	}
	return Plugin_Changed;
}

bool HitGroupsOnCalculateDamage(int client, int& attacker, int& inflictor, float& damage, int& damagetype, const char[] classname)
{
	if (!IsPlayerAlive(client))
	{
		return false;
	}
	float DamageRatio = 1.0;
	float OldDamage = damage;
	
	float KnockRatio = ClassGetKnockBack(sClientData[client].Class);
	int HitGroup = ToolsGetHitGroup(client);
	
	if (!HitGroupsHasBits(client, damagetype, HitGroup))
	{
		return false;
	}
	
	if (!strcmp(classname[6], "hurt", false))
	{
		attacker = ToolsGetActivator(inflictor);
		if (client == attacker)
		{
			return false;
		}
	}
	
	sForwardData._OnClientValidateDamage(client, attacker, inflictor, damage, damagetype);

	if (damage < 0.0)
	{
		return false;
	}
	
	if (IsValidClient(attacker))
	{
		if (!(client == attacker) && sClientData[client].Zombie == sClientData[attacker].Zombie)
		{
			return false;
		}
		
		int dealer = HitGroupsHasInfclictor(classname) ? inflictor : ToolsGetActiveWeapon(attacker);
		if (dealer != -1)
		{
			int index = WeaponsGetCustomID(dealer);
			if (index != -1)
			{
				KnockRatio *= WeaponsGetKnockBack(index);
				DamageRatio *= WeaponsGetDamage(index);
			}
		}
	}
	else attacker = 0; 
	
	damage *= DamageRatio;
	
	SoundsOnClientHurt(client, damagetype);
	
	if (ModesIsArmor(sServerData.RoundMode) == true && ClassIsArmor(sClientData[client].Class) == true)
	{
		if (RoundToFloor(OldDamage) != 195 && !(damagetype & DMG_CRUSH)) // xD
		{
			int armor = ToolsGetArmor(client);
			if (armor > 0 && !(damagetype & (DMG_DROWN | DMG_FALL | DMG_BURN | DMG_DIRECT)) && HitGroupsHasArmor(HitGroup))
			{
				float reduce = damage * 0.5;
				int hit = RoundToNearest((damage - reduce) * 0.5);
			
				if (hit > armor) {
					reduce = damage - armor;
					hit = armor;
				}
				else {   
					if (hit < 0) hit = 1;
				}
				
				damage = reduce; armor -= hit;
				ToolsSetArmor(client, armor);
				sForwardData._OnClientDamaged(client, attacker, inflictor, damage, damagetype);
				return false;
			}
		}
	}
	
	if (attacker > 0 && !(client == attacker))
	{
		KnockRatio *= damage;
		HitGroupsApplyKnock(client, attacker, inflictor, KnockRatio, damagetype, classname);
		
		AccountOnClientHurt(client, attacker, damage);
		
		if (damagetype & DMG_NEVERGIB)
		{
			if (sClientData[attacker].Zombie)
			{
				if (sClientData[client].Zombie)
				{
					return false;
				}
				
				int dealer = HitGroupsHasInfclictor(classname) ? inflictor : ToolsGetActiveWeapon(attacker);
				if (dealer != -1 && !IsFakeClient(client) && !IsFakeClient(attacker))
				{
					int index = WeaponsGetCustomID(dealer);
					if (index != -1)
					{
						if (ModesIsInfection(sServerData.RoundMode) != 2)
						{
							if (ModesIsInfection(sServerData.RoundMode) == 1)
							{
								ApplyOnClientUpdate(client, attacker, ModesGetTypeZombie(sServerData.RoundMode), false);
								return false;
							}
							
							if (WeaponsIsInfection(index) && GetHumans() > 1)
							{
								ApplyOnClientUpdate(client, attacker, ModesGetTypeZombie(sServerData.RoundMode), false);
								return false;
							}
						}
					}
				}
			}
		}
	}
	
	float countdown = ClassGetHealCountdown(sClientData[client].Class);
	if (countdown > 0.0)
	{
		sClientData[client].HealCounter = GetGameTime() + countdown;
	}
	
	sForwardData._OnClientDamaged(client, attacker, inflictor, damage, damagetype);
	return true;
}

bool HitGroupsHasArmor(int HitGroup)
{
	bool ApplyArmor;

	switch (HitGroup)
	{
		case HITGROUP_HEAD:
		{
			ApplyArmor = false;
		}
		
		case HITGROUP_GENERIC, HITGROUP_CHEST, HITGROUP_STOMACH, HITGROUP_LEFTARM, HITGROUP_RIGHTARM:
		{
			ApplyArmor = true;
		}
	}
	return ApplyArmor;
}

void HitGroupsApplyKnock(int client, int attacker, int& inflictor, float force, int& damagetype, const char[] classname)
{
	if (force <= 0.0) {
		return;
	}
	
	if (damagetype & (DMG_NEVERGIB|DMG_BLAST|DMG_BURN) && damagetype != (DMG_BLAST_SURFACE|DMG_BLAST))
	{
		static float position[3], angle[3], velocity[3], EndPosition[3];
		
		if (HitGroupsHasInfclictor(classname) || strcmp(classname[4], "explosion", false) == 0)
		{
			if (GetEntProp(inflictor, Prop_Data, "m_takedamage") != 0) {
				return;
			}
			
			GetClientAbsOrigin(client, EndPosition);
			ToolsGetOrigin(inflictor, position);
		}
		else
		{
			GetClientEyeAngles(attacker, angle);
			GetClientEyePosition(attacker, position);
			TR_TraceRayFilter(position, angle, MASK_ALL, RayType_Infinite, KnockbackTRFilter);
			TR_GetEndPosition(EndPosition);
		}
		
		MakeVectorFromPoints(position, EndPosition, velocity);
		NormalizeVector(velocity, velocity);
		ScaleVector(velocity, force);
		
		ToolsSetVelocity(client, velocity);
	}
}

public bool KnockbackTRFilter(int entity, int contentsMask)
{
	if (entity > 0 && entity < MAXPLAYERS)
	{
		return false;
	}
	return true;
}

bool HitGroupsHasBits(int client, int damagetype, int &HitGroup)
{
	if (damagetype & (DMG_BURN | DMG_DIRECT))
	{
		HitGroup = HITGROUP_CHEST;
	}
	else if (damagetype & DMG_FALL)
	{
		if (!ClassIsFall(sClientData[client].Class)) {
			return false;
		}
		HitGroup = UTIL_GetRandomInt(HITGROUP_LEFTLEG, HITGROUP_RIGHTLEG); 
	}
	else if (damagetype & DMG_BLAST)
	{
		HitGroup = HITGROUP_GENERIC; 
	}
	else if (damagetype & (DMG_NERVEGAS | DMG_DROWN))
	{
		HitGroup = HITGROUP_HEAD;
	}
	return true;
}

bool HitGroupsHasInfclictor(const char[] classname)
{
	int len = strlen(classname) - 11;
	if (len > 0) {
		return (!strncmp(classname[len], "_proj", 5, false));
	}
	return (!strcmp(classname[6], "hurt", false) || !strncmp(classname, "infe", 4, false));
}