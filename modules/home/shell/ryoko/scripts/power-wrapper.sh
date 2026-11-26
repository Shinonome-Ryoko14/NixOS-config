# ryoko-lock / ryoko-suspend / ryoko-reboot / ryoko-shutdown wrapper.
# The action is derived from the command name installed by the ryoko buildEnv.

action=$(basename "$0")
action=${action#ryoko-}
exec ryoko-power "$action" "$@"
