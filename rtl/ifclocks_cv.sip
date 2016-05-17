set_global_assignment -entity "ifclocks_cv" -library "lib_ifclocks_cv" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "ifclocks_cv" -library "lib_ifclocks_cv" -name IP_TOOL_VERSION "16.0"
set_global_assignment -entity "ifclocks_cv" -library "lib_ifclocks_cv" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_ifclocks_cv" -name SPD_FILE [file join $::quartus(sip_path) "ifclocks_cv.spd"]

set_global_assignment -library "lib_ifclocks_cv" -name MISC_FILE [file join $::quartus(sip_path) "ifclocks_cv_sim/ifclocks_cv.vo"]
