stock bool UTIL_IsEntityOnground(int entity)
{
	static float start[3], end[3];

	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", start);
	end[0] = start[0]; end[1] = start[1];
	end[2] = start[2] - 12.0;

	Handle trace = TR_TraceRayFilterEx(start, end, MASK_SHOT, RayType_EndPoint, TraceEntityFilter100, entity);
	bool didHit = !TR_DidHit(trace);
	delete trace;
	
	return didHit;
}

stock bool UTIL_IsEntityOnground2(int entity)
{
	static float vEndPoint[3], normal[3], origin[3];
	
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
	
	vEndPoint[0] = 0.0 + origin[0];
	vEndPoint[1] = 0.0 + origin[1];
	vEndPoint[2] = -5.0 + origin[2];
	
	Handle trace = TR_TraceRayFilterEx(origin, vEndPoint, MASK_SOLID, RayType_EndPoint, TraceEntityFilter100, entity);
	
	if (!TR_DidHit())
	{
		TR_GetPlaneNormal(trace, normal);
		
		if (normal[2] <= 0.7)
		{
			delete trace;
			return true
		}
	}
	
	delete trace;
	return false;
}

stock bool UTIL_IsAbleToSee(float pos[3], float vec[3], float pos2 = 0.0, float vec2 = 0.0)
{
	pos[2] += pos2;
	vec[2] += vec2;
	
	TR_TraceRayFilter(pos, vec, MASK_SOLID, RayType_EndPoint, TraceEntityFilter101);
	return TR_DidHit();
}

stock bool UTIL_IsAbleToSee2(const float vecOrigin[3], int client, int flags = MASK_SOLID)
{
	float vecEyePos[3];
	GetClientEyePosition(client, vecEyePos);
	
	float mins[3], maxs[3];
	GetClientMins(client, mins);
	GetClientMaxs(client, maxs);
	
	if (IsRectangleVisible(vecEyePos, vecOrigin, mins, maxs, 0.0, flags)) // 1.30
	{
		return true;
	}

	if (IsRectangleVisible(vecEyePos, vecOrigin, mins, maxs, 0.65, flags)) // 0.65
	{
		return true;
	}
	
	return false;
}

stock bool IsRectangleVisible(const float start[3], const float end[3], const float mins[3], const float maxs[3], float scale = 1.0, int flags)
{
	float ZpozOffset = maxs[2], ZnegOffset = mins[2];
	float WideOffset = ((maxs[0] - mins[0]) + (maxs[1] - mins[1])) / 4.0;

	if (ZpozOffset == 0.0 && ZnegOffset == 0.0 && WideOffset == 0.0)
	{
		return IsPointVisible(start, end, flags);
	}

	ZpozOffset *= scale;
	ZnegOffset *= scale;
	WideOffset *= scale;
	
	float angles[3], fwd[3], right[3];
	SubtractVectors(start, end, fwd);
	NormalizeVector(fwd, fwd);

	GetVectorAngles(fwd, angles);
	GetAngleVectors(angles, fwd, right, NULL_VECTOR);

	float vRectangle[4][3], vTemp[3];
	if (FloatAbs(fwd[2]) <= 0.7071)
	{
		ScaleVector(right, WideOffset);
		
		// Corner 1, 2
		vTemp = end;
		vTemp[2] += ZpozOffset;
		AddVectors(vTemp, right, vRectangle[0]);
		SubtractVectors(vTemp, right, vRectangle[1]);
		
		// Corner 3, 4
		vTemp = end;
		vTemp[2] += ZnegOffset;
		AddVectors(vTemp, right, vRectangle[2]);
		SubtractVectors(vTemp, right, vRectangle[3]);
		
	}
	else if (fwd[2] > 0.0) // Player is below us.
	{
		fwd[2] = 0.0;
		NormalizeVector(fwd, fwd);
		
		ScaleVector(fwd, scale);
		ScaleVector(fwd, WideOffset);
		ScaleVector(right, WideOffset);
		
		// Corner 1
		vTemp = end;
		vTemp[2] += ZpozOffset;
		AddVectors(vTemp, right, vTemp);
		SubtractVectors(vTemp, fwd, vRectangle[0]);
		
		// Corner 2
		vTemp = end;
		vTemp[2] += ZpozOffset;
		SubtractVectors(vTemp, right, vTemp);
		SubtractVectors(vTemp, fwd, vRectangle[1]);
		
		// Corner 3
		vTemp = end;
		vTemp[2] += ZnegOffset;
		AddVectors(vTemp, right, vTemp);
		AddVectors(vTemp, fwd, vRectangle[2]);
		
		// Corner 4
		vTemp = end;
		vTemp[2] += ZnegOffset;
		SubtractVectors(vTemp, right, vTemp);
		AddVectors(vTemp, fwd, vRectangle[3]);
	}
	else // Player is above us.
	{
		fwd[2] = 0.0;
		NormalizeVector(fwd, fwd);
		
		ScaleVector(fwd, scale);
		ScaleVector(fwd, WideOffset);
		ScaleVector(right, WideOffset);

		// Corner 1
		vTemp = end;
		vTemp[2] += ZpozOffset;
		AddVectors(vTemp, right, vTemp);
		AddVectors(vTemp, fwd, vRectangle[0]);
		
		// Corner 2
		vTemp = end;
		vTemp[2] += ZpozOffset;
		SubtractVectors(vTemp, right, vTemp);
		AddVectors(vTemp, fwd, vRectangle[1]);
		
		// Corner 3
		vTemp = end;
		vTemp[2] += ZnegOffset;
		AddVectors(vTemp, right, vTemp);
		SubtractVectors(vTemp, fwd, vRectangle[2]);
		
		// Corner 4
		vTemp = end;
		vTemp[2] += ZnegOffset;
		SubtractVectors(vTemp, right, vTemp);
		SubtractVectors(vTemp, fwd, vRectangle[3]);
	}
	
	for (int i = 0; i < 4; i++)
	{
		if (IsPointVisible(start, vRectangle[i], flags))
		{
			return true;
		}
	}

	return false;
}

stock bool IsPointVisible(const float start[3], const float end[3], int flags)
{
	TR_TraceRayFilter(start, end, flags, RayType_EndPoint, TraceEntityFilter102);

	return TR_GetFraction() == 1.0;
}

////////////////////////////////////////////////////////////////////////////////////////
public bool TraceEntityFilter100(int entity, int contentsMask, int data)
{
   	return !(entity <= MaxClients || entity == data);
}

public bool TraceEntityFilter101(int entity, int contentsMask, int data)
{
	return !(entity != data);
}

public bool TraceEntityFilter102(int entity, int contentsMask)
{
	return (entity > MaxClients && !(0 < GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity") <= MaxClients));
}