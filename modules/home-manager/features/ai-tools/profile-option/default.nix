# TODO: Full profile-based routing logic will be added when Task 1 completes
# Task 4: This placeholder allows testing the routing system
# Task 1 (ai-tools-profile-module-creation) will enhance with filtering by profile
{lib, ...}: {
  options.myHomeManager = {
    aiProfile = lib.mkOption {
      type = lib.types.enum ["personal" "work"];
      default = "personal";
      description = "AI tools profile selection (personal or work)";
    };
  };

  config = {
    # TODO: Profile-based filtering will be added in Task 1
    # For now, this is a simple placeholder to allow eval to work
  };
}
