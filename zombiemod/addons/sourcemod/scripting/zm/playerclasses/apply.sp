void ApplyOnClientSpawn(int client)
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		if (sServerData.RoundNew) 
		{
			ToolsGetOrigin(client, sClientData[client].TeleSpawn);
		
			sClientData[client].TeleTimes = 0;
			sClientData[client].RespawnTimes = 0;
			sClientData[client].Respawn = CS_TEAM_CT;
			sClientData[client].KilledByWorld = false;
		}
		
		sClientData[client].SpawnTime = GetGameTime();
		
		switch (sClientData[client].Respawn)
		{
			case CS_TEAM_T: 
			{
				ApplyOnClientUpdate(client, -1, ModesGetTypeZombie(sServerData.RoundMode), false);
			}
			case CS_TEAM_CT: 
			{
				ApplyOnClientUpdate(client, -1, ModesGetTypeHuman(sServerData.RoundMode), false);
			}
		}
	}
}

bool ApplyOnClientUpdate(int client, int attacker = 0, int type = -2, bool escape = true)
{
	if (sServerData.MapLoaded == false)
	{
		return false;
	}

	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		if (type == -2) type = sServerData.Zombie;
		else if (type == -3) type = sServerData.Human;
		
		if (type == sServerData.Human)
		{
			sClientData[client].Class = sClientData[client].HumanClassNext; HumanValidateClass(client);
			sClientData[client].Zombie = false;
			sClientData[client].Custom = false;
		}
		else if (type == sServerData.Zombie)
		{
			sClientData[client].Class = sClientData[client].ZombieClassNext; ZombieValidateClass(client);
			sClientData[client].Zombie = true;
			sClientData[client].Custom = false;
		}
		else
		{
			int id = ClassTypeToRandomClassIndex(type);
			if (id == -1)
			{
				static char sType[SMALL_LINE_LENGTH];
				sServerData.Types.GetString(id, sType, sizeof(sType));
				
				LogError("[Classes] [Config Validation] Couldn't cache class type: \"%s\"", sType);
				return false;
			}
			
			sClientData[client].Class = id;
			sClientData[client].Zombie = ClassIsZombie(sClientData[client].Class);
			sClientData[client].Custom = true;
		}
		
		sClientData[client].ResetTimers();
		ClientCommand(client, "r_screenoverlay \"\"");
		UTIL_ExtinguishEntity(client, true);
		
		static char model[PLATFORM_LINE_LENGTH];
		if (sClientData[client].Skin != -1 && !sClientData[client].Zombie && !sClientData[client].Custom)
		{
			SkinsGetModel(sClientData[client].Skin, model, sizeof(model));
		}
		else
		{
			ClassGetModel(sClientData[client].Class, model, sizeof(model));
		}
		
		switch(sForwardData._OnClientModel(client, model))
		{
			case Plugin_Continue:
			{
				if (hasLength(model))
				{
					SetEntityModel(client, model);
				}
				else
				{
					CS_UpdateClientModel(client);
				}
			}
		}
		
		if (WeaponsRemoveAll(client, true)) // attacker > 0
		{
			static int weaponname[SMALL_LINE_LENGTH];
			ClassGetWeapon(sClientData[client].Class, weaponname, sizeof(weaponname));
			for (int i = 0; i < sizeof(weaponname); i++)
			{
				WeaponsGive(client, weaponname[i]);
			}
		}
		
		int knife = GetPlayerWeaponSlot(client, 2);
		if (knife != -1) 
		{
			if (sClientData[client].Zombie)
			{
				UTIL_SetRenderColor(knife, 3, 1);
				UTIL_AddEffect(knife, EF_NODRAW);
			}
			else
			{
				UTIL_SetRenderColor(knife, 3, 255);
			}
		}
		
		if (sCvarList.NOBLOCK.BoolValue == false)
		{
			if (ToolsGetCollisionGroup(client) != COLLISION_GROUP_PLAYER)
			{
				ToolsSetCollisionGroup(client, COLLISION_GROUP_PLAYER);
			}
		}
		else ToolsSetCollisionGroup(client, COLLISION_GROUP_DEBRIS_TRIGGER);
		
		SetEntityMoveType(client, MOVETYPE_WALK);
		SetEntityRenderMode(client, RENDER_NORMAL);
		SetEntityRenderColor(client, 255, 255, 255, 255);
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
		ToolsSetScale(client, ClassGetScale(sClientData[client].Class));
		ToolsSetArmor(client, (ToolsGetArmor(client) < ClassGetArmor(sClientData[client].Class)) ? ClassGetArmor(sClientData[client].Class):ToolsGetArmor(client));
		ToolsSetHealth(client, ClassGetHealth(sClientData[client].Class), true);
		ToolsSetGravity(client, ClassGetGravity(sClientData[client].Class));
		
		if (sCvarList.CLASSES_OLD_SPEED.BoolValue == true)
		{
			ToolsSetSpeed(client, ClassGetSpeed(sClientData[client].Class));
		}
		
		if (IsValidClient(attacker)) 
		{
			CreatePlayerDeath(GetClientUserId(client), GetClientUserId(attacker), "weapon_claws");
			
			// VEffectsOnClientInfected(client, attacker);
			
			ToolsSetScore(attacker, true, ToolsGetScore(attacker, true) + 1);
			ToolsSetScore(client, false, ToolsGetScore(client, false) + 1);
		}
		else if (!attacker)
		{
			if (ModesIsEscape(sServerData.RoundMode) && escape)
			{
				SpawnTeleportToRespawn(client);
			}
		}
		
		AccountOnClientSpawn(client);
		MarketOnClientUpdate(client);
		HealOnClientUpdate(client);
		// SoundsOnClientUpdate(client);
		
		SDKUnhook(client, SDKHook_SetTransmit, Hook_SetTransmit_invis);
		RequestFrame(Frame_WeaponsOnClientUpdate, GetClientUserId(client));
		
		if (!sClientData[client].Zombie)
		{
			VEffectsOnClientHumanized(client);
		}
		
		if (IsFakeClient(client))
		{
			CostumesOnFakeClientThink(client);
		}
		
		if (!sServerData.RoundNew)
		{
			sClientData[client].PlayerSpotted = false;
			sClientData[client].PlayerSpott = false;
		
			if (sClientData[client].Zombie)
			{
				CS_SwitchTeam(client, CS_TEAM_T);
				
				SoundsOnClientInfected(client, attacker);
				VEffectsOnClientInfected(client, attacker);
				
				sClientData[client].WeaponsTimer = CreateTimer(2.0, Timer_GiveWeapons, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
			else
			{
				CS_SwitchTeam(client, CS_TEAM_CT);
			}
			
			ZombieModTerminateRound();
		}
		else
		{
			sClientData[client].PlayerSpotted = true;
			sClientData[client].PlayerSpott = true;
		}
		
		sForwardData._OnClientUpdated(client, attacker);
		return true;
	}
	return false;
}

public Action Timer_GiveWeapons(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	
	if (IsValidClient(client) && IsPlayerAlive(client) && sClientData[client].Zombie)
	{
		if (GetPlayerWeaponSlot(client, 2) == -1)
		{
			int weaponname[SMALL_LINE_LENGTH]; char classname[64];
			ClassGetWeapon(sClientData[client].Class, weaponname, sizeof(weaponname));
			
			for (int i = 0; i < sizeof(weaponname); i++)
			{
				if (weaponname[i] != -1)   
				{
					WeaponsGetName(weaponname[i], classname, sizeof(classname));
					GivePlayerItem(client, classname);
					
					int knife = GetPlayerWeaponSlot(client, 2);
					if (knife != -1)
					{
						UTIL_SetRenderColor(knife, 3, 1);
						UTIL_AddEffect(knife, EF_NODRAW);
					}
					
					sClientData[client].WeaponsTimer = null;
					return Plugin_Stop;
				}
			}
		}
		return Plugin_Continue;
	}
	
	sClientData[client].WeaponsTimer = null;
	return Plugin_Stop;
}