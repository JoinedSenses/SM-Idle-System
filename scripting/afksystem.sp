#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <afksystem>

#define PLUGIN_VERSION "0.0.1"

public Plugin myinfo = {
	name = "AFK System",
	author = "JoinedSenses",
	description = "Simple AFK system for keeping track of idle players.",
	version = PLUGIN_VERSION,
	url = "https://GitHub.com/JoinedSenses"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	
}

public void OnPluginStart() {

}