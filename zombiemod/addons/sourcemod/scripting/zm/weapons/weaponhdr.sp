int WeaponHDRCreateViewModel(int client)
{
	int view;
	
	if ((view = CreateEntityByName("predicted_viewmodel")) == -1)
	{
		LogError("[Weapons] Failed to create \"predicted_viewmodel\" entity");
		return view;
	}

	SetEntPropEnt(view, Prop_Send, "m_hOwner", client);
	SetEntProp(view, Prop_Send, "m_nViewModelIndex", 1);

	DispatchSpawn(view);
	
	SetVariantString("!activator");
	AcceptEntityInput(view, "SetParent", client, view);
	
	WeaponHDRSetPlayerViewModel(client, 1, view);
	return view;
}

void WeaponHDRSwapViewModel(int client, int view1, int view2, int iD)
{
	int iModel;
	
	if (!iModel) 
	{
		iModel = WeaponsGetModelViewID(iD);
	}
	
	ToolsSetModelIndex(view2, iModel);
	
	WeaponHDRSetPlaybackRate(view2, WeaponHDRGetPlaybackRate(view1));

	WeaponHDRToggleViewModel(client, view2);

	WeaponHDRSetLastSequence(view1, -1);
	WeaponHDRSetLastSequenceParity(view1, -1);
}

void WeaponHDRToggleViewModel(int client, int view)
{
	SetEntPropEnt(view, Prop_Send, "m_hWeapon", sClientData[client].CustomWeapon);
}

int WeaponHDRGetPlayerViewModel(int client, int view)
{
	return GetEntDataEnt2(client, Player_hViewModel + (view * 4));
}

void WeaponHDRSetPlayerViewModel(int client, int view, int model)
{
	SetEntDataEnt2(client, Player_hViewModel + (view * 4), model, true);
}

void WeaponHDRSetSequence(int entity, int iSequence)
{
	SetEntProp(entity, Prop_Send, "m_nSequence", iSequence);
}

int WeaponHDRGetSequence(int entity)
{
	return GetEntProp(entity, Prop_Send, "m_nSequence");
}

void WeaponHDRSetLastSequence(int entity, int iSequence)
{
	SetEntProp(entity, Prop_Data, "m_iHealth", iSequence);
}

void WeaponHDRSetLastSequenceParity(int entity, int iSequenceParity)
{
	SetEntProp(entity, Prop_Data, "m_iMaxHealth", iSequenceParity);
}

void WeaponHDRSetPlaybackRate(int entity, float flRate)
{
	SetEntPropFloat(entity, Prop_Send, "m_flPlaybackRate", flRate);
}

float WeaponHDRGetPlaybackRate(int entity)
{
	return GetEntPropFloat(entity, Prop_Send, "m_flPlaybackRate");
}