#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <idlesystem>

#define PLUGIN_NAME "IdleSystem Kick Handler"
#define PLUGIN_AUTHOR "JoinedSenses"
#define PLUGIN_DESCRIPTION "Handles kicks of idle players"
#define PLUGIN_VERSION "0.1.0"
#define PLUGIN_URL "htts://github.com/JoinedSenses"

public Plugin myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

bool g_bLate;
bool g_bEnabled;
bool g_bIdle[MAXPLAYERS+1];
int g_iCount;

ConVar g_cvarTime;
int g_iTime;

ConVar g_cvarMin;
int g_iMin;

ConVar g_cvarIgnore;
bool g_bIgnore;

Handle g_hTimer;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	g_bLate = late;
	return APLRes_Success;
}

public void OnPluginStart() {
	CreateConVar(
		"sm_newplugin_version",
		PLUGIN_VERSION,
		PLUGIN_DESCRIPTION,
		FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD
	).SetString(PLUGIN_VERSION);

	g_cvarTime = CreateConVar("sm_idlesys_kick_time", "300", "Time in seconds until idle player is kicked", FCVAR_NONE, true, 0.0);
	g_cvarMin = CreateConVar("sm_idlesys_kick_minplayers", "0", "Minimum players until kick is active", FCVAR_NONE, true, 0.0);
	g_cvarIgnore = CreateConVar("sm_idlesys_kick_ignore", "0", "Should admins be ignored?", FCVAR_NONE, true, 0.0, true, 1.0);

	g_cvarTime.AddChangeHook(cvarChanged_Time);
	g_cvarMin.AddChangeHook(cvarChanged_Min);
	g_cvarIgnore.AddChangeHook(cvarChanged_Ignore);

	AutoExecConfig();

	g_iTime = g_cvarTime.IntValue;
	g_iMin = g_cvarMin.IntValue;
	g_bIgnore = g_cvarIgnore.BoolValue;

	if (g_bLate) {
		g_bEnabled = LibraryExists("idlesystem");
		if (g_bEnabled) {
			CheckIdle();
		}
	}
}

public void OnLibraryAdded(const char[] name) {
	if (StrEqual(name, "idlesystem")) {
		g_bEnabled = true;
		CheckIdle();
	}
}

public void OnLibraryRemoved(const char[] name) {
	if (StrEqual(name, "idlesystem")) {
		g_bEnabled = false;
		delete g_hTimer;
	}
}

public void cvarChanged_Time(ConVar convar, const char[] oldValue, const char[] newValue) {
	g_iTime = StringToInt(newValue);
}

public void cvarChanged_Min(ConVar convar, const char[] oldValue, const char[] newValue) {
	g_iMin = StringToInt(newValue);

	if (g_hTimer) {
		if (g_iCount <  g_iMin) {
			CloseHandle(g_hTimer);
			g_hTimer = null;
		}
	}
	else {
		if (g_iCount >= g_iMin) {
			g_hTimer = CreateTimer(1.0, timerCheckPlayers, _, TIMER_REPEAT);
			TriggerTimer(g_hTimer);
		}
	}
}

public void cvarChanged_Ignore(ConVar convar, const char[] oldValue, const char[] newValue) {
	g_bIgnore = !!StringToInt(newValue);
}

public void IdleSys_OnClientIdle(int client) {
	g_bIdle[client] = true;
}

public void IdleSys_OnClientReturn(int client) {
	g_bIdle[client] = false;
}

public void OnClientPutInServer(int client) {
	if (!g_bEnabled || IsClientBot(client)) {
		return;
	}

	g_bIdle[client] = IdleSys_IsClientIdle(client);

	++g_iCount;

	if (!g_hTimer && g_iCount >= g_iMin) {
		g_hTimer = CreateTimer(1.0, timerCheckPlayers, _, TIMER_REPEAT);
		TriggerTimer(g_hTimer);
	}
}

public void OnClientDisconnect(int client) {
	if (!g_bEnabled || IsClientBot(client)) {
		return;
	}

	g_bIdle[client] = false;

	--g_iCount;

	if (g_hTimer && g_iCount < g_iMin) {
		CloseHandle(g_hTimer);
		g_hTimer = null;
	}
}

public Action timerCheckPlayers(Handle timer) {
	for (int i = 1; i <= MaxClients; ++i) {
		if (!g_bIdle[i]) {
			continue;
		}

		if (g_bIgnore && CheckCommandAccess(i, "sm_idlesys_kick_ignoreflag", ADMFLAG_ROOT)) {
			continue;
		}

		int idletime = IdleSys_GetIdleTime(i);
		int timeleft = g_iTime - idletime;

		switch (timeleft) {
			case 60, 30, 15, 10, 5, 4, 3, 2, 1: {
				PrintToChat(i, "\x01[\x05IdleSys\x01] Idle kick in \x05%i seconds", timeleft);
			}
			default: {
				if (timeleft <= 0) {
					KickClient(i, "IdleSys: Kicked for being idle (%i seconds)", idletime);
				}
			}
		}
	}
}

bool IsClientBot(int client) {
	return IsFakeClient(client) || IsClientSourceTV(client) || IsClientReplay(client);
}

void CheckIdle() {
	g_iCount = 0;

	for (int i = 1; i <= MaxClients; ++i) {
		if (IsClientInGame(i) && !IsClientBot(i)) {
			OnClientPutInServer(i);
		}
	}
}