#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <afksystem>

public void OnPluginStart() {
	RegAdminCmd("sm_idletest", cmdIdleTest, ADMFLAG_ROOT);

	LoadTranslations("common.phrases");
}

public Action cmdIdleTest(int client, int args) {
	int target;

	if (!args) {
		if (!client) {
			ReplyToCommand(client, "Cannot target self as console. Use arg to target client");
			return Plugin_Handled;
		}

		target = client;
	}
	else {
		char arg[32];
		GetCmdArg(1, arg, sizeof arg);

		target = FindTarget(client, arg, false, false);

		if (target == -1) {
			return Plugin_Handled;
		}
	}

	ReplyToCommand(client, "%N is %sidle with an idle time of %i seconds", target, AFKS_IsClientIdle(target) ? "" : "not ", AFKS_GetIdleTime(target));
	return Plugin_Handled;
}

public void AFKS_OnClientIdle(int client) {
	PrintToChatAll("%N has become idle", client);
}

public void AFKS_OnClientReturn(int client) {
	PrintToChatAll("%N is no longer idle", client);
}