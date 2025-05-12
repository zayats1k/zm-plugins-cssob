#define VEFFECTS_RAGDOLL_DISSOLVE_EFFECTLESS -2
#define VEFFECTS_RAGDOLL_DISSOLVE_RANDOM -1
#define VEFFECTS_RAGDOLL_DISSOLVE_ENERGY 0
#define VEFFECTS_RAGDOLL_DISSOLVE_ELECTRICALH 1
#define VEFFECTS_RAGDOLL_DISSOLVE_ELECTRICALL 2
#define VEFFECTS_RAGDOLL_DISSOLVE_CORE 3

void RagdollOnClientDeath(int client)
{
	int ragdoll = RagdollGetIndex(client);
	
	if (ragdoll != -1)
	{
		int DamageType = GetEntProp(client, Prop_Data, "m_bitsDamageType");
		if (DamageType == DMG_BURN || DamageType == (DMG_BURN|DMG_DIRECT) || GetEntityFlags(client) & FL_ONFIRE)
		{
			IgniteEntity(ragdoll, GetRandomFloat(8.0, 16.0), false, 5.0, false);
		}
		
		if (sCvarList.VEFFECTS_RAGDOLL_REMOVE.IntValue == 0)
		{
			return;
		}
		
		float delay = sCvarList.VEFFECTS_RAGDOLL_DELAY.FloatValue;
		if (!delay)
		{
			Timer_RagdollOnEntityRemove(null, EntIndexToEntRef(ragdoll));
			return;
		}
		
		CreateTimer(delay, Timer_RagdollOnEntityRemove, EntIndexToEntRef(ragdoll), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_RagdollOnEntityRemove(Handle timer, int ref)
{
	int ragdoll = EntRefToEntIndex(ref);

	if (ragdoll != -1)
	{
		static char classname[SMALL_LINE_LENGTH];
		GetEdictClassname(ragdoll, classname, sizeof(classname));

		if (!strcmp(classname, "cs_ragdoll", false))
		{
			int effect = sCvarList.VEFFECTS_RAGDOLL_DISSOLVE.IntValue;

			if (effect == VEFFECTS_RAGDOLL_DISSOLVE_EFFECTLESS)
			{
				AcceptEntityInput(ragdoll, "Kill");
				return Plugin_Stop;
			}

			if (effect == VEFFECTS_RAGDOLL_DISSOLVE_RANDOM)
			{
				effect = UTIL_GetRandomInt(VEFFECTS_RAGDOLL_DISSOLVE_ENERGY, VEFFECTS_RAGDOLL_DISSOLVE_CORE);
			}

			static char dissolve[SMALL_LINE_LENGTH];
			FormatEx(dissolve, sizeof(dissolve), "dissolve%d", ragdoll);
			DispatchKeyValue(ragdoll, "targetname", dissolve);

			int iDissolver = CreateEntityByName("env_entity_dissolver");
			
			if (iDissolver != -1)
			{
				DispatchKeyValue(iDissolver, "target", dissolve);

				FormatEx(dissolve, sizeof(dissolve), "%d", effect);
				DispatchKeyValue(iDissolver, "dissolvetype", dissolve);
				AcceptEntityInput(iDissolver, "Dissolve");
				AcceptEntityInput(iDissolver, "Kill");
			}
		}
	}
	return Plugin_Stop;
}

int RagdollGetIndex(int client)
{
	return GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
}