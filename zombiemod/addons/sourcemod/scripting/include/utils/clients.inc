#define EF_BONEMERGE (1 << 0)
#define EF_NOSHADOW (1 << 4)
#define EF_BONEMERGE_FASTCULL (1 << 7)
#define EF_NORECEIVESHADOW (1 << 6)
#define EF_PARENT_ANIMATES (1 << 9)

#define HIDEHUD_CROSSHAIR (1 << 8)

#define FFADE_IN 0x0001
#define FFADE_OUT 0x0002
#define FFADE_MODULATE 0x0004
#define FFADE_STAYOUT 0x0008
#define FFADE_PURGE 0x0010

stock bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

stock bool UTIL_ValidateClient(int client)
{
	if (client < 1 || client > MaxClients)
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client index %d is invalid", client);
		return false;
	}
	if (!IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_NOT_FOUND, "Client %d is not in game", client);
		return false;
	}
	return true;
}

stock void UTIL_ScreenFade(int client, float duration, float holdtime, int flags, const int color[4])
{
	Handle message = StartMessageOne("Fade", client);
	
	if (message != null)
	{
		if (GetUserMessageType() == UM_Protobuf)
		{
			Protobuf pb = UserMessageToProtobuf(message);
			pb.SetInt("duration", FixedUnsigned16(duration, 1 << 9));
			pb.SetInt("hold_time", FixedUnsigned16(holdtime, 1 << 9));
			pb.SetInt("flags", flags);
			pb.SetColor("clr", color);
		}
		else
		{
			BfWrite bf = UserMessageToBfWrite(message);
			bf.WriteShort(FixedUnsigned16(duration, 1 << 9));
			bf.WriteShort(FixedUnsigned16(holdtime, 1 << 9));
			bf.WriteShort(flags);		
			bf.WriteByte(color[0]);
			bf.WriteByte(color[1]);
			bf.WriteByte(color[2]);
			bf.WriteByte(color[3]);
		}
		
		EndMessage();
	}
}

stock int FixedUnsigned16(float value, int scale)
{
	int output = RoundToFloor(value * float(scale));
	if (output < 0) output = 0;
	if (output > 0xFFFF) output = 0xFFFF;
	return output;
}

stock void UTIL_ScreenShake(float center[3], float amplitude, float frequency, float duration, float radius, int command, bool airShake)
{
	for (int i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			if (!airShake && command == 0 && !(GetEntityFlags(i) & FL_ONGROUND))
			{
				continue;
			}

			float playerPos[3];
			GetClientAbsOrigin(i, playerPos);

			float localAmplitude = ComputeShakeAmplitude(center, playerPos, amplitude, radius);

			if (localAmplitude < 0.0) continue;

			if (localAmplitude > 0 || command == 0)
			{
				Handle msg = StartMessageOne("Shake", i, USERMSG_RELIABLE);
				if(msg != null)
				{
					BfWriteByte(msg, command);
					BfWriteFloat(msg, localAmplitude);
					BfWriteFloat(msg, frequency);
					BfWriteFloat(msg, duration);

					EndMessage();
				}
			}
		}
	}
}

stock void UTIL_SetClientOverlay(int client, const char[] overlay)
{
	int flags = GetCommandFlags("r_screenoverlay");
	SetCommandFlags("r_screenoverlay", flags &~ FCVAR_CHEAT); 
	ClientCommand(client, "r_screenoverlay \"%s\"", overlay);
	SetCommandFlags("r_screenoverlay", flags | FCVAR_CHEAT);
}

stock float ComputeShakeAmplitude(float center[3], float playerPos[3], float amplitude, float radius)
{
	if(radius <= 0.0) return amplitude;

	float localAmplitude = -1.0;
	float delta[3];
	SubtractVectors(center, playerPos, delta);
	float distance = GetVectorLength(delta);

	if(distance <= radius)
	{
		float perc = 1.0 - (distance / radius);
		localAmplitude = amplitude * perc;
	}

	return localAmplitude;
}

// https://forums.alliedmods.net/showthread.php?t=210080
stock bool UTIL_IsTargetInSightRange(float origin[3], int client, float angle = 90.0, float distance = 0.0)
{
	if (angle > 360.0) angle = 360.0;
	if (angle < 0.0) return false;
	
	float clientpos[3], anglevector[3], targetvector[3];
	float resultdistance;
	
	GetClientAbsOrigin(client, clientpos);
	GetClientEyeAngles(client, anglevector);
	
	// anglevector[0] = anglevector[2] = 0.0;
	GetAngleVectors(anglevector, anglevector, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(anglevector, anglevector);
	
	resultdistance = GetVectorDistance(clientpos, origin);
	
	clientpos[2] = origin[2] = 0.0;
	MakeVectorFromPoints(clientpos, origin, targetvector);
	NormalizeVector(targetvector, targetvector);
	
	if (RadToDeg(ArcCosine(GetVectorDotProduct(targetvector, anglevector))) <= angle / 2)
	{
		if (distance > 0)
		{
			if (distance >= resultdistance) return true;
			else return false;
		}
		else return true;
	}
	return false;
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

stock void UTIL_PrintToAdmins(int flags, char[] format, any ...)
{
	char buffer[255];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && UTIL_IsValidAdmin(i, flags))
		{
			SetGlobalTransTarget(i);
			VFormat(buffer, sizeof(buffer), format, 3);
			PrintToChat(i, "%s", buffer);
		}
	}
}

stock bool UTIL_IsValidAdmin(int client, int flags)
{
    int FlagBits = GetUserFlagBits(client);
    return (FlagBits & ADMFLAG_ROOT || (FlagBits & flags) == flags);
}

stock void UTIL_SetReserveAmmo(int client, int index, int Ammo)
{
	int m_iPrimaryAmmoType = -1;
	if ((m_iPrimaryAmmoType = GetEntProp(index, Prop_Send, "m_iPrimaryAmmoType")) != -1)
	{
		SetEntProp(client, Prop_Send, "m_iAmmo", Ammo, _, m_iPrimaryAmmoType);
	}
}

stock int UTIL_GetReserveAmmo(int client, int index)
{
	int m_iPrimaryAmmoType = -1;
	if ((m_iPrimaryAmmoType = GetEntProp(index, Prop_Send, "m_iPrimaryAmmoType")) != -1)
	{
		return GetEntProp(client, Prop_Send, "m_iAmmo", _, m_iPrimaryAmmoType);
	}
	return 0;
}

stock void UTIL_SetClientCam(int client, bool toggle)
{
	if (toggle)
	{
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", 0);
		SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
		SetEntProp(client, Prop_Send, "m_iFOV", 120);
		SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") | HIDEHUD_CROSSHAIR);
	}
	else
	{
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", client);
		SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
		SetEntProp(client, Prop_Send, "m_iFOV", 90);
		SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") & ~HIDEHUD_CROSSHAIR);
	}
}

stock bool UTIL_DamageArmor(int client, int count)
{
	int armor = GetClientArmor(client);

	if (armor > 0)
	{
		armor -= count;
		
		SetEntProp(client, Prop_Send, "m_ArmorValue", (armor < 0) ? 0:armor);
		return true;
	}
	return false;
}