#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <afksystem>

#define PLUGIN_VERSION "0.0.1"
#define PLUGIN_DESCRIPTION "Simple idle system for keeping track of afk players."
#define ALLOWED_IDLE_TIME 30 // Time player allowed to idle until marked as AFK

public Plugin myinfo = {
	name = "Idle System",
	author = "JoinedSenses",
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "https://GitHub.com/JoinedSenses"
};

bool g_bLateLoad;

bool g_bIsClientIdle[MAXPLAYERS+1]; // Stores client idle state
int g_iIdleStartTime[MAXPLAYERS+1]; // Stores GetGameTime()
int g_iButtons[MAXPLAYERS+1]; // Stores client buttons

Handle g_hTimer[MAXPLAYERS+1]; // Timer to keep track of clients

GlobalForward g_fwdOnClientIdle;
GlobalForward g_fwdOnClientReturn;

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
	CreateConVar("sm_idlesystem_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD).SetString(PLUGIN_VERSION);

	HookEvent("player_connect_client", eventPlayerConnect);
	HookEvent("player_disconnect", eventPlayerDisconnect);

	if (g_bLateLoad) {
		for (int i = 1; i <= MaxClients; ++i) {
			if (IsClientInGame(i) && !IsFakeClient(i) && !IsClientSourceTV(i) && !IsClientReplay(i)) {
				g_hTimer[i] = CreateTimer(1.0, timerCheckClient, GetClientUserId(i), TIMER_REPEAT);
			}
		}
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2]) {
	if (!client || !IsClientInGame(client) || IsFakeClient(client)) {
		return Plugin_Continue;
	} 

	if (g_iButtons[client] != buttons || mouse[0] || mouse[1]) {
		if (g_bIsClientIdle[client]) {
			g_iButtons[client] = buttons;

			SetClientReturn(client);

			return Plugin_Continue;
		}

		if (g_iIdleStartTime[client] != 0) {
			g_iIdleStartTime[client] = 0;
		}

		g_iButtons[client] = buttons;
	}
	else {
		if (g_iIdleStartTime[client] == 0) {
			g_iIdleStartTime[client] = RoundFloat(GetEngineTime());
		}
	}

	

	return Plugin_Continue;
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs) {
	if (!client) {
		return Plugin_Continue;
	}

	if (g_bIsClientIdle[client]) {
		SetClientReturn(client);
	}
	else if (g_iIdleStartTime[client] != 0) {
		g_iIdleStartTime[client] = 0;
	}

	return Plugin_Continue;
}

// ----------------------- Events

public void eventPlayerConnect(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));

	g_hTimer[client] = CreateTimer(1.0, timerCheckClient, GetClientUserId(client), TIMER_REPEAT);
}

public void eventPlayerDisconnect(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));

	delete g_hTimer[client];

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
		if (GetIdleTime(client) > ALLOWED_IDLE_TIME) {
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

// ----------------------- Natives

public any Native_IsClientIdle(Handle plugin, int numParams) {
	int client = GetNativeCell(1);

	if (client < 1 || client > MaxClients) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%i)", client);
	}

	if (!IsClientConnected(client) || IsClientSourceTV(client) || IsClientReplay(client)) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %i is not connected", client);
	}

	return g_bIsClientIdle[client];
}

public any Native_GetIdleTime(Handle plugin, int numParams) {
	int client = GetNativeCell(1);

	if (client < 1 || client > MaxClients) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%i)", client);
	}

	if (!IsClientConnected(client) || IsClientSourceTV(client) || IsClientReplay(client)) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %i is not connected", client);
	}

	return GetIdleTime(client);
}