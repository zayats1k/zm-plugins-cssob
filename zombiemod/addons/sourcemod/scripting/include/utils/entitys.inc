#define IsValidEntityf(%0) (IsValidEntity(%0) && %0 != 0 && %0 != INVALID_ENT_REFERENCE)

#define EF_NODRAW 32

#define IS_COLLISION(%0) (%0 != 1 && %0 != 2 && %0 != 3 && %0 != 10 \
&& %0 != 11 && %0 != 12 && %0 != 14 && %0 != 16 && %0 != 17)

stock int CS_WeaponMaxClip1[34] = 
{
    0, 13, 20, 10, 0, 7, 0, 30, 30, 0, 30, 20, 25, 30, 35, 25,
	12, 10, 30, 100, 8, 30, 30, 20, 0, 7, 30, 30, 0, 50, 0, 0,
	0, 0 //CSGO Test
};

stock int CS_WeaponMaxAmmo[34] = {
    0, 52, 120, 90, 0, 32, 0, 100, 90, 0, 120, 100, 100, 90, 90, 90,
	100, 30, 120, 200, 32, 90, 120, 90, 0, 35, 90, 90, 0, 100, 0, 0,
	0, 0 //CSGO Test
};


enum SolidFlags_t
{
	FSOLID_CUSTOMRAYTEST		= 0x0001,	// Ignore solid type + always call into the entity for ray tests
	FSOLID_CUSTOMBOXTEST		= 0x0002,	// Ignore solid type + always call into the entity for swept box tests
	FSOLID_NOT_SOLID			= 0x0004,	// Are we currently not solid?
	FSOLID_TRIGGER				= 0x0008,	// This is something may be collideable but fires touch functions
											// even when it's not collideable (when the FSOLID_NOT_SOLID flag is set)
	FSOLID_NOT_STANDABLE		= 0x0010,	// You can't stand on this
	FSOLID_VOLUME_CONTENTS		= 0x0020,	// Contains volumetric contents (like water)
	FSOLID_FORCE_WORLD_ALIGNED	= 0x0040,	// Forces the collision rep to be world-aligned even if it's SOLID_BSP or SOLID_VPHYSICS
	FSOLID_USE_TRIGGER_BOUNDS	= 0x0080,	// Uses a special trigger bounds separate from the normal OBB
	FSOLID_ROOT_PARENT_ALIGNED	= 0x0100,	// Collisions are defined in root parent's local coordinate space
	FSOLID_TRIGGER_TOUCH_DEBRIS	= 0x0200,	// This trigger will touch debris objects

	FSOLID_MAX_BITS	= 10
};

enum SolidType_t
{
	SOLID_NONE			= 0,	// no solid model
	SOLID_BSP			= 1,	// a BSP tree
	SOLID_BBOX			= 2,	// an AABB
	SOLID_OBB			= 3,	// an OBB (not implemented yet)
	SOLID_OBB_YAW		= 4,	// an OBB, constrained so that it can only yaw
	SOLID_CUSTOM		= 5,	// Always call into the entity for tests
	SOLID_VPHYSICS		= 6,	// solid vphysics object, get vcollide from the model and collide with that
	SOLID_LAST,
};

enum Collision_Group_t
{
	COLLISION_GROUP_NONE  = 0,
	COLLISION_GROUP_DEBRIS,			// Collides with nothing but world and static stuff
	COLLISION_GROUP_DEBRIS_TRIGGER, // Same as debris, but hits triggers
	COLLISION_GROUP_INTERACTIVE_DEBRIS,	// Collides with everything except other interactive debris or debris
	COLLISION_GROUP_INTERACTIVE,	// Collides with everything except interactive debris or debris
	COLLISION_GROUP_PLAYER,
	COLLISION_GROUP_BREAKABLE_GLASS,
	COLLISION_GROUP_VEHICLE,
	COLLISION_GROUP_PLAYER_MOVEMENT,  // For HL2, same as Collision_Group_Player, for
										// TF2, this filters out other players and CBaseObjects
	COLLISION_GROUP_NPC,			// Generic NPC group
	COLLISION_GROUP_IN_VEHICLE,		// for any entity inside a vehicle
	COLLISION_GROUP_WEAPON,			// for any weapons that need collision detection
	COLLISION_GROUP_VEHICLE_CLIP,	// vehicle clip brush to restrict vehicle movement
	COLLISION_GROUP_PROJECTILE,		// Projectiles!
	COLLISION_GROUP_DOOR_BLOCKER,	// Blocks entities not permitted to get near moving doors
	COLLISION_GROUP_PASSABLE_DOOR,	// Doors that the player shouldn't collide with
	COLLISION_GROUP_DISSOLVING,		// Things that are dissolving are in this group
	COLLISION_GROUP_PUSHAWAY,		// Nonsolid on client and server, pushaway in player code

	COLLISION_GROUP_NPC_ACTOR,		// Used so NPCs in scripts ignore the player.
	COLLISION_GROUP_NPC_SCRIPTED,	// USed for NPCs in scripts that should not collide with each other

	LAST_SHARED_COLLISION_GROUP
};

#define BEAM_STARTON (1<<0)
#define BEAM_TOGGLE (1<<1)
#define BEAM_RANDOMSTRIKE (1<<2)
#define BEAM_RING (1<<3)
#define BEAM_STARTSPARKS (1<<4)
#define BEAM_ENDSPARKS (1<<5)
#define BEAM_DECALEND (1<<6)
#define BEAM_SHADESTART (1<<7)
#define BEAM_SHADEEND (1<<8)
#define BEAM_TAPEROUT (1<<9)

stock bool UTIL_ExtinguishEntity(int entity, bool StopFire = false)
{
	int fire = GetEntPropEnt(entity, Prop_Data, "m_hEffectEntity");
	if (IsValidEdict(fire))
	{
		static char sClassname[SMALL_LINE_LENGTH];
		GetEdictClassname(fire, sClassname, sizeof(sClassname));
		
		if (!strcmp(sClassname, "entityflame", false))
		{
			if (StopFire == true)
			{
				SetEntPropFloat(fire, Prop_Data, "m_flLifetime", 0.0);
			}
			
			return true;
		}
	}
	return false;
}

stock int UTIL_CreateProjectile(const float vPosition[3], const float vAngle[3], int weaponID = -1, const char[] sModel = "")
{
	int entity = CreateEntityByName("hegrenade_projectile");

	if (entity != -1)
	{
		SetEntProp(entity, Prop_Data, "m_iMaxHealth", weaponID);
		SetEntProp(entity, Prop_Data, "m_nNextThinkTick", -1);
	
		DispatchSpawn(entity);
		
		TeleportEntity(entity, vPosition, vAngle, NULL_VECTOR);

		if (hasLength(sModel)) SetEntityModel(entity, sModel);
	}

	return entity;
}

stock int UTIL_CreateExplosion(const float vPosition[3], int team, int iFlags = 0, const char[] sSpriteName = "materials/sprites/xfireball3.vmt", float flDamage = 0.0, float flRadius = 0.0, int attacker = -1, int inflictor = -1, const char[] sIgnore = "")
{
	int entity = CreateEntityByName("env_explosion");

	if (entity != -1)
	{
		static char sFlags[SMALL_LINE_LENGTH];
		IntToString(iFlags, sFlags, sizeof(sFlags));
		
		DispatchKeyValueVector(entity, "origin", vPosition);
		DispatchKeyValue(entity, "spawnflags", sFlags);
		DispatchKeyValue(entity, "fireballsprite", sSpriteName);
		if (!(iFlags & (1<<0)))
		{
			IntToString(RoundToNearest(flDamage), sFlags, sizeof(sFlags));
			DispatchKeyValue(entity, "iMagnitude", sFlags);
			IntToString(RoundToNearest(flRadius), sFlags, sizeof(sFlags));
			DispatchKeyValue(entity, "iRadiusOverride", sFlags);
			if (hasLength(sIgnore)) DispatchKeyValue(entity, "ignoredEntity", sIgnore);
		}
		
		DispatchSpawn(entity);
		
		SetEntProp(entity, Prop_Data, "m_iTeamNum", team);
		
		if (attacker != -1)
		{
			SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", attacker);
		}
			
		if (inflictor != -1)
		{
			SetEntPropEnt(entity, Prop_Data, "m_hInflictor", inflictor);
		}
		
		AcceptEntityInput(entity, "Explode");
		AcceptEntityInput(entity, "Kill");
	}
	return entity;
}

stock int UTIL_CreateBeam(const float vStartPosition[3],const  float vEndPosition[3], const char[] sDamage = "0", const char[] sFrame = "0", const char[] sWidth = "4.0", const char[] sRenderFX = "0", const char[] sType = "3", const char[] sRate = "0", const char[] sDecalName = "Bigshot", const char[] sScroll = "35", const char[] sScale = "1.0", const char[] sTextureName = "materials/sprites/purplelaser1.vmt", const char[] sLife = "0", const char[] sStrike = "1", int iFlags = 0, const char[] sAmplitude = "0", const char[] sRadius = "256", const char[] sRenderAMT = "100", const char[] sColor, float flDelayTime, float flDurationTime, const char[] sName)
{
	int entity = CreateEntityByName("env_beam");

	if (entity != -1)
	{
		static char sClassname[SMALL_LINE_LENGTH];
		FormatEx(sClassname, sizeof(sClassname), "%s%i", sName, entity);

		static char sFlags[SMALL_LINE_LENGTH];
		IntToString(iFlags, sFlags, sizeof(sFlags));
		
		DispatchKeyValueVector(entity, "origin", vStartPosition);
		DispatchKeyValue(entity, "targetname", sClassname);
		DispatchKeyValue(entity, "damage", sDamage);
		DispatchKeyValue(entity, "framestart", sFrame);
		DispatchKeyValue(entity, "BoltWidth", sWidth);
		DispatchKeyValue(entity, "renderfx", sRenderFX);
		DispatchKeyValue(entity, "TouchType", sType);
		DispatchKeyValue(entity, "framerate", sRate);
		DispatchKeyValue(entity, "decalname", sDecalName);
		DispatchKeyValue(entity, "TextureScroll", sScroll);
		DispatchKeyValue(entity, "HDRColorScale", sScale);
		DispatchKeyValue(entity, "texture", sTextureName);
		DispatchKeyValue(entity, "life", sLife); 
		DispatchKeyValue(entity, "StrikeTime", sStrike); 
		DispatchKeyValue(entity, "LightningStart", sClassname);
		DispatchKeyValue(entity, "spawnflags", sFlags); 
		DispatchKeyValue(entity, "NoiseAmplitude", sAmplitude); 
		DispatchKeyValue(entity, "Radius", sRadius);
		DispatchKeyValue(entity, "renderamt", sRenderAMT);
		DispatchKeyValue(entity, "rendercolor", sColor);

		DispatchSpawn(entity);

		AcceptEntityInput(entity, "TurnOff");
		AcceptEntityInput(entity, "TurnOn");
		
		SetEntityModel(entity, sTextureName);
		
		float flWidth = StringToFloat(sWidth);
		SetEntPropFloat(entity, Prop_Data, "m_fWidth", flWidth);
		SetEntPropFloat(entity, Prop_Data, "m_fEndWidth", flWidth);
		SetEntPropVector(entity, Prop_Data, "m_vecEndPos", vEndPosition);

		if (flDurationTime > 0.0)
		{
			UTIL_RemoveEntity(entity, flDurationTime);
		}
		
		if (flDelayTime > 0.0)
		{
			FormatEx(sFlags, sizeof(sFlags), "OnUser2 !self:TurnOff::%f:1", flDelayTime - 0.001);
			
			SetVariantString(sFlags);
			AcceptEntityInput(entity, "AddOutput");
			
			FormatEx(sFlags, sizeof(sFlags), "OnUser3 !self:TurnOn::%f:1", flDelayTime);
			
			SetVariantString(sFlags);
			AcceptEntityInput(entity, "AddOutput");
			
			SetVariantString("OnTouchedByEntity !self:FireUser2::0.0:-1");
			AcceptEntityInput(entity, "AddOutput");
			SetVariantString("OnTouchedByEntity !self:FireUser3::0.0:-1");
			AcceptEntityInput(entity, "AddOutput");
		}
	}
	
	return entity;
}

stock int UTIL_CreateSmokestack(int client, float origin[3], const char[] smokeMaterial, const float baseSpread, const char[] speed, const char[] spreadSpeed, const float startSize, const char[] rate, const char[] jetLength, const float twist, const char[] rendercolor, const char[] renderAmt, const char[] angles)
{
	int env = CreateEntityByName("env_smokestack");
	if (env != -1)
	{
		DispatchKeyValueFloat(env, "BaseSpread", baseSpread);
		DispatchKeyValueFloat(env, "StartSize", startSize);
		DispatchKeyValueFloat(env, "Twist", twist);
		
		DispatchKeyValue(env, "smokeMaterial", smokeMaterial); 
		DispatchKeyValue(env, "speed", speed); 
		DispatchKeyValue(env, "spreadSpeed", spreadSpeed);
		DispatchKeyValue(env, "rate", rate); 
		DispatchKeyValue(env, "jetLength", jetLength); 
		DispatchKeyValue(env, "rendercolor", rendercolor);
		DispatchKeyValue(env, "renderAmt", renderAmt);
		DispatchKeyValue(env, "angles", angles); // ...
		TeleportEntity(env, origin, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(env);
		
		if (client)
		{
			SetVariantString("!activator");
			AcceptEntityInput(env, "SetParent", client, env);
		}
		
		AcceptEntityInput(env, "TurnOn");
	}
	return env;
}

stock int UTIL_CreateParticle(int entity = 0, const char[] name = "", const char[] effectname, const float origin[3], bool targetname = false)
{
	int effect = CreateEntityByName("info_particle_system");
	if (IsValidEdict(effect))
	{
		DispatchKeyValue(effect, "effect_name", effectname);
		DispatchKeyValue(effect, "start_active", "1");
		
		if (entity != 0)
		{
			char temp[64]; Format(temp, sizeof(temp), "%s%d", name, entity);
			if (targetname) DispatchKeyValue(effect, "targetname", temp);
			DispatchKeyValue(effect, "cpoint1", temp);
		}
		
		if (entity == -2)
		{
			char temp[64]; Format(temp, sizeof(temp), "%s%d", name, effect);
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

stock int UTIL_CreateParticle2(int parent = -1, const float position[3] = NULL_VECTOR, const float angle[3] = NULL_VECTOR, const char[] attach = "", const char[] effect, float durationTime = 0.0)
{
	int entity = CreateEntityByName("info_particle_system");
	
	if (entity != -1) {
		char temp[64];
		Format(temp, sizeof(temp), "zc_particle_%d", entity);
		DispatchKeyValue(entity, "targetname", temp);
		DispatchKeyValue(entity, "cpoint1", temp); // test
		
		DispatchKeyValueVector(entity, "origin", position);
		DispatchKeyValueVector(entity, "angles", angle);
		DispatchKeyValue(entity, "start_active", "1");
		DispatchKeyValue(entity, "effect_name", effect);
		
		DispatchSpawn(entity);

		if (parent != -1) {
			SetVariantString("!activator");
			AcceptEntityInput(entity, "SetParent", parent, entity);
			SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", parent);
			
			if (strlen(attach)) { 
				SetVariantString(attach); 
				AcceptEntityInput(entity, "SetParentAttachment", parent, entity);
			}
		}
		
		ActivateEntity(entity);
		AcceptEntityInput(entity, "Start");
		if (durationTime > 0.0) {
			UTIL_RemoveEntity(entity, durationTime);
		}
	}
	return entity;
}

stock int UTIL_CreatePhysExplosion(float origin[3], const float radius, const float magnitude)
{
	int phys = CreateEntityByName("env_physexplosion");
	if (phys != -1)
	{
		TeleportEntity(phys, origin, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(phys, "spawnflags", "1");
		DispatchKeyValueFloat(phys, "radius", radius);
		DispatchKeyValueFloat(phys, "magnitude", magnitude);
		DispatchSpawn(phys);
		ActivateEntity(phys);
		AcceptEntityInput(phys, "Explode");
		AcceptEntityInput(phys, "Kill");
		return phys;
	}
	return -1;
}

stock int UTIL_CreateTrigger(int entity, const char[] model, const float origin[3], const float mins[3], const float maxs[3])
{
	int trigger = CreateEntityByName("trigger_multiple");
	if (IsValidEdict(trigger))
	{
		DispatchKeyValueVector(trigger, "origin", origin);
		DispatchKeyValue(trigger, "wait", "0");
		DispatchKeyValue(trigger, "spawnflags", "64");
		DispatchSpawn(trigger);
		ActivateEntity(trigger);
		
		SetEntityModel(trigger, model);
		
		SetEntPropVector(trigger, Prop_Send, "m_vecMins", mins);
		SetEntPropVector(trigger, Prop_Send, "m_vecMaxs", maxs);
		
		SetEntProp(trigger, Prop_Data, "m_spawnflags", 64);
		SetEntProp(trigger, Prop_Send, "m_nSolidType", 2);
		
		if (entity != 0)
		{
			SetVariantString("!activator");
			AcceptEntityInput(trigger, "SetParent", entity, trigger);
		}
		return trigger;
	}
	return -1;
}

stock void UTIL_SetRenderColor(int entity, int color, int render)
{
	static int renderOffset;
	if (!renderOffset && (renderOffset = GetEntSendPropOffs(entity, "m_clrRender")) == -1)
	{
		return;
	}

	SetEntProp(entity, Prop_Send, "m_nRenderMode", RENDER_TRANSALPHA);
	SetEntData(entity, renderOffset + color, render, 1, true);
}

stock void UTIL_CreateShooter(int parent, const char[] sTextureName, const float Location[3] = NULL_VECTOR, const float vAngle[3] = NULL_VECTOR, float vGibAngle[3] = NULL_VECTOR, float iGibs, float flDelay, float flVelocity, float flVariance, float flLife)
{
	int entity = CreateEntityByName("env_shooter");

	if (entity != -1)
	{
		DispatchKeyValueVector(entity, "angles", vAngle);
		DispatchKeyValueVector(entity, "gibangles", vGibAngle);
		DispatchKeyValue(entity, "rendermode", "5");
		DispatchKeyValue(entity, "shootsounds", "-1");
		DispatchKeyValue(entity, "shootmodel", sTextureName);
		DispatchKeyValueFloat(entity, "m_iGibs", iGibs);
		DispatchKeyValueFloat(entity, "delay", flDelay);
		DispatchKeyValueFloat(entity, "m_flVelocity", flVelocity);
		DispatchKeyValueFloat(entity, "m_flVariance", flVariance);
		DispatchKeyValueFloat(entity, "m_flGibLife", flLife);

		DispatchSpawn(entity);
		SetVariantString("spawnflags 4");
		AcceptEntityInput(entity,"AddOutput");

		ActivateEntity(entity);
		AcceptEntityInput(entity, "Shoot", 0);

		TeleportEntity(entity, Location, NULL_VECTOR, NULL_VECTOR);
		
		// SetVariantString("!activator"); 
		// AcceptEntityInput(entity, "SetParent", parent, entity); 
		// SetVariantString(sAttach); 
		// AcceptEntityInput(entity, "SetParentAttachment", parent, entity);
		
		SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", parent);
		
		UTIL_RemoveEntity(entity, 1.0);
	}
}

stock int UTIL_GetRenderColor(int entity, int color)
{
	static int renderOffset;
	if (!renderOffset && (renderOffset = GetEntSendPropOffs(entity, "m_clrRender")) == -1)
	{
		return 255;
	}

	return GetEntData(entity, renderOffset + view_as<int>(color), 1);
}

stock void UTIL_RemoveEntity(int entity, float Lifetime)
{
	if (Lifetime > 0.0)
	{
		char temp[64];
		Format(temp, sizeof(temp), "OnUser1 !self:kill::%.1f:1", Lifetime);
		SetVariantString(temp);
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser1");
	}
}

stock void UTIL_SetEdictFlagsAlways(int ent)
{
	if (GetEdictFlags(ent) & FL_EDICT_ALWAYS)
	{
		SetEdictFlags(ent, (GetEdictFlags(ent) ^ FL_EDICT_ALWAYS));
	}
}

stock void UTIL_AddEffect(int entity, int effect)
{
	int effects = GetEntProp(entity, Prop_Send, "m_fEffects");
	if (effect & effects)
	{
		return;
	}
	effects = effect | effects;
	SetEntProp(entity, Prop_Send, "m_fEffects", effects);
}

stock void UTIL_RemoveEffect(int entity, int effect)
{
	int effects = GetEntProp(entity, Prop_Send, "m_fEffects");
	if (!(effect & effects))
	{
		return;
	}
	effects = ~effect & effects;
	SetEntProp(entity, Prop_Send, "m_fEffects", effects);
}

stock float UTIL_VectorNormalize(float a1[3])
{
	float flLength = GetVectorLength(a1, true) + 0.0000000001;
	float v4 = (1.0 / SquareRoot(flLength)); 
	float den = v4 * ((3.0 - ((v4 * v4) * flLength)) * 0.5);
	ScaleVector(a1, den);
	return den * flLength;
}

stock void TE_SetupWorldDecal(const float vecOrigin[3], int index)
{    
    TE_Start("World Decal");
    TE_WriteVector("m_vecOrigin", vecOrigin);
    TE_WriteNum("m_nIndex", index);
}