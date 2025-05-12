#define MAX_INTEGER 2147483647 // ...

stock int UTIL_CreateParticle(int entity = 0, const char[] name, const char[] effectname, const float origin[3], bool targetname = false)
{
	int effect = CreateEntityByName("info_particle_system");
	if (IsValidEdict(effect))
	{
		DispatchKeyValue(effect, "effect_name", effectname);
		DispatchKeyValue(effect, "start_active", "1");
		
		if (entity != 0)
		{
			char temp[64];
			Format(temp, sizeof(temp), "%s_%d", name, entity);
			if (targetname) DispatchKeyValue(effect, "targetname", temp);
			DispatchKeyValue(effect, "cpoint1", temp);
		}
		
		TeleportEntity(effect, origin, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(effect);
		ActivateEntity(effect);
		return effect;
	}
	return -1;
}

stock void UTIL_RemoveEntity(int ent, float Lifetime)
{
	if (Lifetime > 0.0)
	{
		char output[64];
		Format(output, sizeof(output), "OnUser1 !self:kill::%.1f:1", Lifetime);
		SetVariantString(output);
		AcceptEntityInput(ent, "AddOutput");
		AcceptEntityInput(ent, "FireUser1");
	}
}

stock void UTIL_CreateFade(int client, int duration, int holdtime, int flags, int color[4] = {0, 0, 0, 255})
{
	Handle message = StartMessageOne("Fade", client);
	
	if (message != null)
	{
		if (GetUserMessageType() == UM_Protobuf)
		{
			Protobuf pb = UserMessageToProtobuf(message);
			pb.SetInt("duration", duration);
			pb.SetInt("hold_time", holdtime);
			pb.SetInt("flags", flags);
			pb.SetColor("clr", color);
		}
		else
		{
			BfWrite bf = UserMessageToBfWrite(message);
			bf.WriteShort(duration);
			bf.WriteShort(holdtime);
			bf.WriteShort(flags);		
			bf.WriteByte(color[0]);
			bf.WriteByte(color[1]);
			bf.WriteByte(color[2]);
			bf.WriteByte(color[3]);
		}
		
		EndMessage();
	}
}

stock void UTIL_ShowHudTextAll(Handle sync = null, const char[] mag, any ...)
{
	char buffer[164];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			VFormat(buffer, sizeof(buffer), mag, 3);
			
			if (!sync) ShowHudText(i, -1, buffer);
			else ShowSyncHudText(i, sync, buffer);
		}
	}
}

stock void UTIL_SetWeaponAmmo(int client, int index, int Ammo)
{
	int m_iPrimaryAmmoType = -1;
	if ((m_iPrimaryAmmoType = GetEntProp(index, Prop_Send, "m_iPrimaryAmmoType")) != -1)
	{
		SetEntProp(client, Prop_Send, "m_iAmmo", Ammo, _, m_iPrimaryAmmoType);
	}
}

stock int UTIL_GetMax(int i1 = 0, int i2 = 0, int i3 = 0) 
{
	return (i1 >= i2 ? i2 : i1 && i1 < i3 ? i3 : i1);
}

stock int GetZombies()
{
	int count;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i) && ZR_IsClientZombie(i))
		{  
			count++;
		}
	}
	return count;
}