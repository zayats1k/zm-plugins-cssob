#if defined _zm_player_animation_included
 #endinput
#endif
#define _zm_player_animation_included

#if !defined _dhooks_included
 #include <dhooks>
#endif

native int GetHandleAnimEvent();
native bool IsPlayerAnimation(int client, bool duck);
native int GetEntitySequence(int client);
native bool SetPlayerSequence(int client, const char[] anim, const char[] anim2 = "");
native void GetClientAnimationAngles(int client, float ang[3]);
native bool IsClientPlayerNone(int client);
native void SetVictimState(int client, int maxstate);
native bool IsVictimState(int client);

forward void OnPlayerSequence(int client, int entity);
forward void OnPlayerSequencePre(int client, int entity, const char[] anim);
forward void OnResetPlayerSequencePre(int client, bool player);
forward void OnResetPlayerSequence(int client, bool player);
forward Action OnAnimationDone(int client, int entity);
forward void OnClientBreakSkill(int client);

#if defined _dhooks_included
stock void OnHandleAnimEvent(int client, DHookCallback callback)
{
	static Handle hHook = null;
	if (hHook == null)
	{
		hHook = DHookCreate(GetHandleAnimEvent(), HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity);
		if (hHook == null) {
			return;
		}
		
		DHookAddParam(hHook, HookParamType_ObjectPtr, -1);
	}
	DHookEntity(hHook, false, GetEntitySequence(client), _, callback);
}
#endif

public SharedPlugin __pl_zm_player_animation = 
{
	name = "zm_player_animation",
	file = "zm_player_animation.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_zm_player_animation_SetNTVOptional()
{
	MarkNativeAsOptional("GetHandleAnimEvent");
	MarkNativeAsOptional("IsPlayerAnimation");
	MarkNativeAsOptional("GetEntitySequence");
	MarkNativeAsOptional("SetPlayerSequence");
	MarkNativeAsOptional("GetClientAnimationAngles");
}
#endif
