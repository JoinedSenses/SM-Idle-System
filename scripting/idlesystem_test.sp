#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <color_literals>
#undef REQUIRE_PLUGIN
#include <idlesystem>

#define TAG "\x01[\x0769cfbcIdleSys\x01] \x07b3e3e3"

public void OnPluginStart() {
	RegAdminCmd("sm_idletest", cmdIdleTest, ADMFLAG_ROOT);

	RegConsoleCmd("sm_activity", cmdActivity);

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

	ReplyToCommand(client, "%N is %sidle with an idle time of %i seconds"
		, target
		, IdleSys_IsClientIdle(target) ? "" : "not "
		, IdleSys_GetIdleTime(target)
	);
	return Plugin_Handled;
}

public Action cmdActivity(int client, int args) {
	if (client) {
		if (GetCmdReplySource() == SM_REPLY_TO_CHAT) {
			PrintColoredChat(client, TAG ... "Check console for output.");
		}

		PrintToConsole(client, "--------------------------------------------------------------------");
		PrintToConsole(client, " Idx|  ID  |               Name               | Status | Idle Time |");
		PrintToConsole(client, "--------------------------------------------------------------------");

		for (int i = 1; i <= MaxClients; ++i) {
			if (IsClientInGame(i) && !IsFakeClient(i)) {
				if (IdleSys_IsClientIdle(i)) {
					PrintToConsole(
						  client
						, " %02i | %04i | %32N |  Idle  |   %05i   |"
						, i, GetClientUserId(i), i, IdleSys_GetIdleTime(i)
					);
				}
				else {
					PrintToConsole(
						  client
						, " %02i | %04i | %32N | Active |           |"
						, i, GetClientUserId(i), i
					);
				}
			}
		}

		PrintToConsole(client, "--------------------------------------------------------------------");
	}
	else {
		ReplyToCommand(client, " Idx|  ID  |               Name               | Status | Idle Time |");
		for (int i = 1; i <= MaxClients; ++i) {
			if (IsClientInGame(i) && !IsFakeClient(i)) {
				if (IdleSys_IsClientIdle(i)) {
					ReplyToCommand(
						  client
						, " %02i | %04i | %32N |  Idle  |   %5i   |"
						, i, GetClientUserId(i), i, IdleSys_GetIdleTime(i)
					);
				}
				else {
					ReplyToCommand(
						  client
						, " %02i | %04i | %32N | Active |           |"
						, i, GetClientUserId(i), i
					);
				}
			}
		}
	}

	return Plugin_Handled;
}

// public void IdleSys_OnClientIdle(int client) {
// 	PrintColoredChat(client, TAG ... "You have been marked as idle.");
// }

// public void IdleSys_OnClientReturn(int client) {
// 	PrintColoredChat(client, TAG ... "You are no longer marked as idle.");
// }

