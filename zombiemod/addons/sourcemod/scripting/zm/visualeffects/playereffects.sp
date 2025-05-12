void PlayerVEffectsOnClientInfected(int client, int attacker)
{
	RequestFrame(Frame_zVEffectsFadeClientScreen, GetClientUserId(client));
	
	static char particle[SMALL_LINE_LENGTH], attachment[SMALL_LINE_LENGTH]; static float duration;
	particle = NULL_STRING;
	
	if (sServerData.RoundStart && attacker < 1)
	{
		duration = sCvarList.VEFFECTS_INFECT_DURATION.FloatValue;
		
		if (duration <= 0.0) {
			return;
		}
		
		sCvarList.VEFFECTS_INFECT_NAME.GetString(particle, sizeof(particle));
		sCvarList.VEFFECTS_INFECT_ATTACH.GetString(attachment, sizeof(attachment));
	}
	else
	{
		duration = ClassGetEffectTime(sClientData[client].Class);
		if (duration <= 0.0) {
			return;
		}
	
		ClassGetEffectName(sClientData[client].Class, particle, sizeof(particle)); 
		ClassGetEffectAttach(sClientData[client].Class, attachment, sizeof(attachment));
	}
	
	ParticlesCreate(client, attachment, particle, duration);
}

public void Frame_zVEffectsFadeClientScreen(int userid)
{
	int client = GetClientOfUserId(userid);
	
	if (sServerData.RoundEnd)
	{
		return;
	}
	
	if (client)
	{
		VEffectsFadeClientScreen(client, sCvarList.VEFFECTS_INFECT_FADE_COLOR, sCvarList.VEFFECTS_INFECT_FADE_DURATION, sCvarList.VEFFECTS_INFECT_FADE_TIME);
	}
}

void PlayerVEffectsOnClientHumanized(int client)
{
	RequestFrame(Timer_hVEffectsFadeClientScreen, GetClientUserId(client));
	
	static char particle[SMALL_LINE_LENGTH], attachment[SMALL_LINE_LENGTH]; static float duration;
	particle = NULL_STRING;
	
	if (!sServerData.RoundNew)
	{
		duration = ClassGetEffectTime(sClientData[client].Class);
		if (duration <= 0.0) {
			return;
		}
	
		ClassGetEffectName(sClientData[client].Class, particle, sizeof(particle)); 
		ClassGetEffectAttach(sClientData[client].Class, attachment, sizeof(attachment));
	}
	
	ParticlesCreate(client, attachment, particle, duration);
}

public void Timer_hVEffectsFadeClientScreen(int userid)
{
	int client = GetClientOfUserId(userid);
	
	if (sServerData.RoundEnd)
	{
		return;
	}
	
	if (client)
	{
		VEffectsFadeClientScreen(client, sCvarList.VEFFECTS_HUMANIZE_FADE_COLOR, sCvarList.VEFFECTS_HUMANIZE_FADE_DURATION, sCvarList.VEFFECTS_HUMANIZE_FADE_TIME);
	}
}

int ParticlesCreate(int parent, const char[] attach, const char[] effect, float durationTime)
{
	if (!hasLength(effect)) {
		return -1;
	}
	
	static float position[3], angle[3]; 
	if (!hasLength(attach)) { 
		ToolsGetOrigin(parent, position);
		ToolsGetAngles(parent, angle);
	}
	
	return UTIL_CreateParticle2(parent, position, angle, attach, effect, durationTime);
}