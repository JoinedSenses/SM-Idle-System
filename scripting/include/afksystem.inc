#if defined _afksystem_included_
  #endinput
#endif
#define _afksystem_included_

public SharedPlugin __pl_afksystem = {
	name = "afksystem",
	file = "afksystem.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_afksystem_SetNTVOptional() {
}
#endif