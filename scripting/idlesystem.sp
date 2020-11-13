#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <idlesystem>

/* NOTE: Developed with only TF2 in mind */

#define PLUGIN_VERSION "0.1.0"
#define PLUGIN_DESCRIPTION "Simple system for keeping track of idle players."

public Plugin myinfo = {
	name = "Idle System",
	author = "JoinedSenses",
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "https://github.com/JoinedSenses"
};

// Stores plugin late load status
bool g_bLateLoad;

// Used to determine if client is initially connecting
bool g_bInitialConnect[MAXPLAYERS+1];
// Stores client idle state
bool g_bIsClientIdle[MAXPLAYERS+1];
// Stores GetEngineTime()
int g_iIdleStartTime[MAXPLAYERS+1];
// Stores client buttons
int g_iButtons[MAXPLAYERS+1];

GlobalForward g_fwdOnClientIdle;
GlobalForward g_fwdOnClientReturn;

ConVar g_cvarAllowedIdleTime;

// Time in seconds player allowed no input until marked as idle.
int g_iAllowedIdleTime; 

// ----------------------- SM Functions

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	g_bLateLoad = late;

	RegPluginLibrary("idlesystem");

	CreateNative("IdleSys_IsClientIdle", Native_IsClientIdle);
	CreateNative("IdleSys_GetIdleTime", Native_GetIdleTime);

	g_fwdOnClientIdle = new GlobalForward("IdleSys_OnClientIdle", ET_Ignore, Param_Cell);
	g_fwdOnClientReturn = new GlobalForward("IdleSys_OnClientReturn", ET_Ignore, Param_Cell);
}

public void OnPluginStart() {
	CreateConVar(
		"sm_idlesystem_version",
		PLUGIN_VERSION,
		PLUGIN_DESCRIPTION,
		FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD
	).SetString(PLUGIN_VERSION);

	g_cvarAllowedIdleTime = CreateConVar(
		"sm_idlesystem_allowed",
		"10",
		"Allowed time in seconds for no input change before client is considered idle.",
		FCVAR_NONE,
		true
	);

	g_cvarAllowedIdleTime.AddChangeHook(cvarChangedAllowedIdleTime);

	g_iAllowedIdleTime = g_cvarAllowedIdleTime.IntValue;

	AutoExecConfig();

	HookEvent("player_connect", eventPlayerConnect);
	HookEvent("player_disconnect", eventPlayerDisconnect);

	if (g_bLateLoad) {
		for (int i = 1; i <= MaxClients; ++i) {
			if (IsClientInGame(i) && !IsClientBot(i)) {
				CreateTimer(1.0, timerCheckClient, GetClientUserId(i), TIMER_REPEAT);
			}
		}
	}
}

public void cvarChangedAllowedIdleTime(ConVar convar, const char[] oldValue, const char[] newValue) {
	g_iAllowedIdleTime = StringToInt(newValue);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3],
int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2]) {
	if (!client || !IsClientInGame(client) || IsClientBot(client)) {
		return Plugin_Continue;
	}

	/* Maybe consider additional logic for time-outs or checking if cmdnum has not changed;
	 * however, also consider that cmdnum can potentially be manipulated by cheaters.
	 * For now, this logic is very simple: check for input changes. */

	if (g_iButtons[client] != buttons || mouse[0] || mouse[1]) {
		if (g_bIsClientIdle[client]) {
			g_iButtons[client] = buttons;

			SetClientReturn(client);

			return Plugin_Continue;
		}

		if (g_iIdleStartTime[client]) {
			g_iIdleStartTime[client] = 0;
		}

		g_iButtons[client] = buttons;
	}
	else { // input has not changed
		if (!g_iIdleStartTime[client]) {
			g_iIdleStartTime[client] = RoundFloat(GetEngineTime());
		}
	}

	return Plugin_Continue;
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs) {
	if (client) {
		if (g_bIsClientIdle[client]) {
			SetClientReturn(client);
		}
		else {
			g_iIdleStartTime[client] = 0;
		}
	}

	return Plugin_Continue;
}

// ----------------------- Events

public void eventPlayerConnect(Event event, const char[] name, bool dontBroadcast) {
	if (event.GetInt("bot")) {
		return;
	}

	g_bInitialConnect[event.GetInt("index")+1] = true;
}

public void OnClientPutInServer(int client) {
	if (g_bInitialConnect[client]) {
		CreateTimer(1.0, timerCheckClient, GetClientUserId(client), TIMER_REPEAT);
		g_bInitialConnect[client] = false;
	}
}

public void eventPlayerDisconnect(Event event, const char[] name, bool dontBroadcast) {
	if (event.GetBool("bot")) {
		return;
	}

	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!client || IsClientBot(client)) {
		return;
	}

	g_bIsClientIdle[client] = false;
	g_iIdleStartTime[client] = 0;
}

// ----------------------- Timer

public Action timerCheckClient(Handle timer, int userid) {
	int client = GetClientOfUserId(userid);
	if (!client) {
		return Plugin_Stop;
	}

	if (g_iIdleStartTime[client] && !g_bIsClientIdle[client]) {
		if (GetIdleTime(client) > g_iAllowedIdleTime) {
			SetClientIdle(client);
		}
	}

	return Plugin_Continue;
}

// ----------------------- Plugin Methods

void SetClientIdle(int client) {
	g_bIsClientIdle[client] = true;
	
	Call_StartForward(g_fwdOnClientIdle);
	Call_PushCell(client);
	Call_Finish();
}

void SetClientReturn(int client) {
	g_bIsClientIdle[client] = false;
	g_iIdleStartTime[client] = 0;

	Call_StartForward(g_fwdOnClientReturn);
	Call_PushCell(client);
	Call_Finish();
}

int GetIdleTime(int client) {
	if (g_iIdleStartTime[client]) {
		return RoundFloat(GetEngineTime()) - g_iIdleStartTime[client];
	}

	return 0;
}

bool IsClientBot(int client) {
	return IsFakeClient(client) || IsClientSourceTV(client) || IsClientReplay(client);
}

// ----------------------- Natives

public any Native_IsClientIdle(Handle plugin, int numParams) {
	int client = GetNativeCell(1);

	if (client < 1 || client > MaxClients) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%i)", client);
	}

	if (!IsClientConnected(client)) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %i is not connected", client);
	}

	if (IsClientBot(client)) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %i is not human", client);
	}

	return g_bIsClientIdle[client];
}

public any Native_GetIdleTime(Handle plugin, int numParams) {
	int client = GetNativeCell(1);

	if (client < 1 || client > MaxClients) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%i)", client);
	}

	if (!IsClientConnected(client)) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %i is not connected", client);
	}

	if (IsClientBot(client)) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %i is not human", client);
	}

	return GetIdleTime(client);
}