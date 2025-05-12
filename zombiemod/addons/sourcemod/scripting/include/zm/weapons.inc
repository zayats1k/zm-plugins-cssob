#if defined _weaponlist_included
 #endinput
#endif
#define _weaponlist_included

// #if !defined _WeaponAttachmentAPI_included
//  #include <WeaponAttachmentAPI> // https://github.com/MitchDizzle/WeaponAttachmentAPI/tree/master
// #endif

enum
{
	ANIM_IDLE,
	ANIM_SHOOT1,
	ANIM_SHOOT2,
	ANIM_RELOAD,
	ANIM_DRAW,
	ANIM_ATTACK_START,
	ANIM_ATTACK_END
};

enum
{
	PLAYERANIMEVENT_FIRE_GUN_PRIMARY=0,
	PLAYERANIMEVENT_FIRE_GUN_SECONDARY,
	PLAYERANIMEVENT_THROW_GRENADE,
	PLAYERANIMEVENT_JUMP,
	PLAYERANIMEVENT_RELOAD,
	PLAYERANIMEVENT_RELOAD_START,
	PLAYERANIMEVENT_RELOAD_LOOP,
	PLAYERANIMEVENT_RELOAD_END,
	PLAYERANIMEVENT_COUNT
};

native int ZM_SpawnWeapon(const char[] weaponname, const char[] targetname, const float origin[3] = NULL_VECTOR, const float angles[3] = NULL_VECTOR);
native bool ZM_FireBullets(int client, int weaponID, int mode, int seed, float angle[2]={0.0,0.0}, float spread, float inaccuracy);
native int ZM_GetClientViewModel(int client, bool custom);
native bool ZM_GetFRightHand(int client);
native void ZM_WeaponAttachRemoveAddons(int client);
native void ZM_SendWeaponAnim(int weapon, Activity anim);

forward void ZM_OnWeaponAnimationEvent(int client, int weapon, int sequence, float fCycle, float fPrevCycle, int id);
forward void ZM_OnWeaponDeploy(int client, int weapon, int id);
forward void ZM_OnWeaponBullet(int client, int weapon, const float bullet[3], int id);
forward void ZM_OnWeaponCreated(int client, int weapon, int id);
forward void ZM_OnWeaponHolster(int client, int weapon, int id);
forward void ZM_OnWeaponDrop(int client, int weapon, int id);
forward void ZM_OnWeaponDrop2(int weapon, int id);
forward Action ZM_OnWeaponRunCmd(int client, int& buttons, int LastButtons, int weapon, int id);

native int ZM_GetWeaponNameID(const char[] name, bool noprefix = false);
native int ZM_GetNumberWeapon();
native void ZM_GetWeaponName(int id, char[] name, int maxlenght = 32);
native void ZM_GetWeaponEntity(int id, char[] entity, int maxlenght = 32);
native float ZM_GetWeaponDamage(int id);
native float ZM_GetWeaponKnockBack(int id);
native float ZM_GetWeaponSpeed(int id);
native int ZM_GetWeaponClip(int id);
native int ZM_GetWeaponAmmo(int id);
native void ZM_GetWeaponModelView(int id, char[] model, int maxlenght = 256);
native int ZM_GetWeaponModelViewID(int id);
native void ZM_GetWeaponModelWorld(int id, char[] model, int maxlenght = 256);
native int ZM_GetWeaponModelWorldID(int id);

stock bool ZM_InRangeSound(float f1, float fPre, float fPost)
{
	if(fPre <= f1 && f1 < fPost)
		return true;
	return false;
}

stock void ZM_SetWeaponAnimation(int client, int sequence)
{
	int view = ZM_GetClientViewModel(client, false);

	if (view != -1)
	{
		SetEntPropFloat(view, Prop_Data, "m_flCycle", 0.0);
		SetEntProp(view, Prop_Send, "m_nSequence", sequence);
	}
}

stock int ZM_GetWeaponAnimation(int client)
{
	int view = ZM_GetClientViewModel(client, false);

	if (view != -1)
	{
		return GetEntProp(view, Prop_Send, "m_nSequence");
	}
	return -1;
}

stock bool ZM_IsPlayerHoldWeapon(int client, int &weapon, int id)
{
	if (!IsValidClient(client) || !IsPlayerAlive(client)) {
		return false;
	}

	weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (weapon == -1) {
		return false;
	}

	if (ZM_GetCustomID(weapon) != id) {
		return false;
	}
	return true;
}

stock void ZM_CreateWeaponKickBack(int client, float upBase, float lateralBase, float upMod, float lateralMod, float upMax, float lateralMax, int directionChange)
{
	static int iDirection; static int iShotsFired; static float vPunchAngle[3];
	GetEntPropVector(client, Prop_Send, "m_vecPunchAngle", vPunchAngle);

	if ((iShotsFired = GetEntProp(client, Prop_Send, "m_iShotsFired")) != 1)
	{
		upBase += iShotsFired * upMod;
		lateralBase += iShotsFired * lateralMod;
	}

	upMax *= -1.0;
	vPunchAngle[0] -= upBase;

	if (upMax >= vPunchAngle[0])
	{
		vPunchAngle[0] = upMax;
	}

	if ((iDirection = GetEntProp(client, Prop_Send, "m_iDirection")))
	{
		vPunchAngle[1] += lateralBase;

		if (lateralMax < vPunchAngle[1])
		{
			vPunchAngle[1] = lateralMax;
		}
	}
	else
	{
		lateralMax *=  -1.0;
		vPunchAngle[1] -= lateralBase;

		if (lateralMax > vPunchAngle[1])
		{
			vPunchAngle[1] = lateralMax;
		}
	}

	if (!GetRandomInt(0, directionChange))
	{
		SetEntProp(client, Prop_Send, "m_iDirection", !iDirection);
	}
	
	SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", vPunchAngle);
}

stock int ZM_CreateParticle(int parent = -1, const float vPosition[3] = NULL_VECTOR, const float vAngle[3] = NULL_VECTOR, const char[] sAttach = "", const char[] sEffect, float flDurationTime = 0.0)
{
	int entity = CreateEntityByName("info_particle_system");
	
	if (entity != -1)
	{
		DispatchKeyValueVector(entity, "origin", vPosition);
		DispatchKeyValueVector(entity, "angles", vAngle);
		DispatchKeyValue(entity, "start_active", "1");
		DispatchKeyValue(entity, "effect_name", sEffect);
		
		DispatchSpawn(entity);

		if (parent != -1)
		{
			SetVariantString("!activator");
			AcceptEntityInput(entity, "SetParent", parent, entity);
			SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", parent);
			
			if (strlen(sAttach))
			{ 
				SetVariantString(sAttach); 
				AcceptEntityInput(entity, "SetParentAttachment", parent, entity);
			}
		}
		
		ActivateEntity(entity);
		AcceptEntityInput(entity, "Start");
		
		if (flDurationTime > 0.0)
		{
			UTIL_RemoveEntity(entity, flDurationTime);
		}
	}
	
	return entity;
}

stock void ZM_CreateWeaponTracer(int client, int weapon, const char[] sAttach1, char[] sAttach2, const char[] sEffect, const float vBullet[3], float flDurationTime)
{
	if (!hasLength(sEffect)) {
		return;
	}
	
	int view = ZM_GetClientViewModel(client, false);
	if (view == -1) {    
		return;
	}

	static int entity[4];
	entity[0] = CreateEntityByName("info_particle_system");
	entity[1] = CreateEntityByName("info_particle_system");
	entity[2] = CreateEntityByName("info_particle_system");
	entity[3] = CreateEntityByName("info_particle_system");

	if (entity[3] != -1) /// Check the last entity ;)
	{
		float angle[3]; // , vEmpty[3]
		GetEntPropVector(client, Prop_Data, "m_angAbsRotation", angle);
		
		TeleportEntity(entity[1], vBullet, angle, NULL_VECTOR);
		TeleportEntity(entity[3], vBullet, angle, NULL_VECTOR);
		
		static char sClassname[SMALL_LINE_LENGTH];
		FormatEx(sClassname, sizeof(sClassname), "w_particle_%d", entity[0]);
		DispatchKeyValue(entity[0], "targetname", sClassname);
		DispatchKeyValue(entity[1], "effect_name", sEffect);
		DispatchKeyValue(entity[1], "cpoint1", sClassname);
		
		DispatchSpawn(entity[1]);
		
		SetEntPropEnt(entity[1], Prop_Data, "m_hOwnerEntity", client);
		
		FormatEx(sClassname, sizeof(sClassname), "w_particle_%d", entity[2]);
		DispatchKeyValue(entity[2], "targetname", sClassname);
		DispatchKeyValue(entity[3], "effect_name", sEffect);
		DispatchKeyValue(entity[3], "cpoint1", sClassname);
		
		DispatchSpawn(entity[3]);
		SetEntPropEnt(entity[3], Prop_Data, "m_hOwnerEntity", client);
		TeleportEntity(entity[2], NULL_VECTOR, angle, NULL_VECTOR);
		
		SetVariantString("!activator");
		AcceptEntityInput(entity[2], "SetParent", weapon, entity[2], 0);
		SetVariantString(sAttach2);
		AcceptEntityInput(entity[2], "SetParentAttachment", entity[2], entity[2], 0);
		
		// WA_GetAttachmentPos(client, sAttach2, vEmpty);
		// TeleportEntity(entity[2], vEmpty, NULL_VECTOR, NULL_VECTOR);

		// SetEdictFlags(entity[0], GetEdictFlags(entity[0]) & (~FL_EDICT_ALWAYS));
		// SetEdictFlags(entity[1], GetEdictFlags(entity[1]) & (~FL_EDICT_ALWAYS));
		// SetEdictFlags(entity[2], GetEdictFlags(entity[2]) & (~FL_EDICT_ALWAYS));
		// SetEdictFlags(entity[3], GetEdictFlags(entity[3]) & (~FL_EDICT_ALWAYS));

		SetVariantString("!activator");
		AcceptEntityInput(entity[0], "SetParent", view, entity[0], 0);
		SetVariantString(sAttach1);
		AcceptEntityInput(entity[0], "SetParentAttachment", entity[0], entity[0], 0);
		
		/*______________________________________________________________________________*/
		
		SetEdictFlags(entity[0], GetEdictFlags(entity[0]) & ~(FL_EDICT_ALWAYS|FL_EDICT_DONTSEND|FL_EDICT_PVSCHECK));
		SetEdictFlags(entity[1], GetEdictFlags(entity[1]) & ~(FL_EDICT_ALWAYS|FL_EDICT_DONTSEND|FL_EDICT_PVSCHECK));
		SetEdictFlags(entity[2], GetEdictFlags(entity[2]) & ~(FL_EDICT_ALWAYS|FL_EDICT_DONTSEND|FL_EDICT_PVSCHECK));
		SetEdictFlags(entity[3], GetEdictFlags(entity[3]) & ~(FL_EDICT_ALWAYS|FL_EDICT_DONTSEND|FL_EDICT_PVSCHECK));
		
		SDKHook(entity[1], SDKHook_SetTransmit, TracerClientTransmit);
		SDKHook(entity[3], SDKHook_SetTransmit, TracerViewerTransmit);

		ActivateEntity(entity[1]);
		AcceptEntityInput(entity[1], "Start");
		ActivateEntity(entity[3]);
		AcceptEntityInput(entity[3], "Start");

		UTIL_RemoveEntity(entity[1], flDurationTime);
		UTIL_RemoveEntity(entity[3], flDurationTime);
		UTIL_RemoveEntity(entity[0], flDurationTime);
		UTIL_RemoveEntity(entity[2], flDurationTime);
	}
}

public Action TracerClientTransmit(int entity, int client) 
{
	if (GetEdictFlags(entity) & FL_EDICT_ALWAYS)
	{
		SetEdictFlags(entity, (GetEdictFlags(entity) ^ FL_EDICT_ALWAYS));
	}
	
	int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	
	if (owner == client || (GetEntProp(client, Prop_Data, "m_iObserverMode") == 4 && owner == GetEntPropEnt(client, Prop_Data, "m_hObserverTarget")))
	{
		return Plugin_Continue;
	}
	
	return Plugin_Handled;
}

public Action TracerViewerTransmit(int entity, int client) 
{
	if (GetEdictFlags(entity) & FL_EDICT_ALWAYS)
	{
		SetEdictFlags(entity, (GetEdictFlags(entity) ^ FL_EDICT_ALWAYS));
	}
	
	int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	
	if (owner == client || (GetEntProp(client, Prop_Data, "m_iObserverMode") == 4 && owner == GetEntPropEnt(client, Prop_Data, "m_hObserverTarget")))
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

stock int ZM_CreateProjectile(const float vPosition[3], const float vAngle[3], const char[] sModel = "")
{
	int entity = CreateEntityByName("hegrenade_projectile");

	if (entity != -1)
	{
		SetEntProp(entity, Prop_Data, "m_nNextThinkTick", -1);
		DispatchSpawn(entity);
		TeleportEntity(entity, vPosition, vAngle, NULL_VECTOR);
		if (hasLength(sModel)) SetEntityModel(entity, sModel);
	}
	return entity;
}

stock void ZM_GetPlayerEyePosition(int client, float flForward = 0.0, float flRight = 0.0, float flVertical = 0.0, float vOutput[3])
{
	static float vPosition[3]; static float vAngle[3]; static float vForward[3]; static float vRight[3];  static float vVertical[3]; 

	GetClientEyePosition(client, vPosition);
	GetClientEyeAngles(client, vAngle);

	GetAngleVectors(vAngle, vForward, vRight, vVertical);

	vOutput[0] = vPosition[0] + (vForward[0] * flForward) + (vRight[0] * flRight) + (vVertical[0] * flVertical);
	vOutput[1] = vPosition[1] + (vForward[1] * flForward) + (vRight[1] * flRight) + (vVertical[1] * flVertical);
	vOutput[2] = vPosition[2] + (vForward[2] * flForward) + (vRight[2] * flRight) + (vVertical[2] * flVertical);
}

stock void ZM_SetPlayerAnimation(int client, int event, int data = 0)
{
	TE_Start("PlayerAnimEvent");
	TE_WriteNum("m_hPlayer", ZM_GetWeaponAnimOwner(client));
	TE_WriteNum("m_iEvent", event);
	TE_WriteNum("m_nData", data);
	TE_SendToAll();
}

stock int ZM_GetWeaponAnimOwner(int client)
{
	if (!IsClientInGame(client)) return 0;
	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (!IsValidEntity(weapon)) return 0;
	return GetEntProp(weapon, Prop_Send, "m_hOwnerEntity");
}

stock void ZM_EventWeaponReload(int client)
{
	Event event = CreateEvent("weapon_reload");
	event.SetInt("userid", GetClientUserId(client));
	event.Fire();
}

stock int ZM_GetCustomID(int entity)
{
	return GetEntProp(entity, Prop_Data, "m_iMaxHealth");
}