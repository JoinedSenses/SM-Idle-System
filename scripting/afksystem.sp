#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <afksystem>

#define PLUGIN_VERSION "0.0.1"
#define PLUGIN_DESCRIPTION "Simple AFK system for keeping track of idle players."

public Plugin myinfo = {
	name = "AFK System",
	author = "JoinedSenses",
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "https://GitHub.com/JoinedSenses"
};

bool g_bLateLoad;
bool g_bIsClientIdle[MAXPLAYERS+1]; // Stores client idle state
int g_iIdleStartTime[MAXPLAYERS+1]; // Stores GetGameTime()

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	g_bLateLoad = late;
	
	RegPluginLibrary("afksystem");

	CreateNative("AFKS_IsClientIdle", Native_IsClientIdle);
	CreateNative("AFKS_GetIdleTime", Native_GetIdleTime);
}

public void OnPluginStart() {
	CreateConVar("sm_afksystem_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD).SetString(PLUGIN_VERSION);

	HookEvent("player_connect_client", eventPlayerConnect);
	HookEvent("player_spawn", eventPlayerSpawn);
	HookEvent("player_disconnect", eventPlayerDisconnect);

	if (g_bLateLoad) {

	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2]) {

	return Plugin_Continue;
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs) {

	return Plugin_Continue;
}

public void eventPlayerConnect(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
}

public void eventPlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
}

public void eventPlayerDisconnect(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
}

public any Native_IsClientIdle(Handle plugin, int numParams) {

}

public any Native_GetIdleTime(Handle plugin, int numParams) {

}