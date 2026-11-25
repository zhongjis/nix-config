# Input: live settings object. $managed[0]: Nix-managed settings.
# Managed keys win; permission lists become the union of both sides.
$managed[0] as $m
| (. * ($m | del(.permissions)))
| if $m.permissions then
    .permissions = (
      (.permissions // {}) as $live
      | reduce ($m.permissions | keys[]) as $k ($live;
          .[$k] = ((($live[$k]) // []) + $m.permissions[$k] | unique))
    )
  else . end
