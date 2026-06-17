{lib, ...}: let
  dataDir = "/var/lib/supabase-postgres/data";
in {
  services.postgresql.enable = lib.mkForce false;

  systemd.tmpfiles.rules = [
    "d /var/lib/supabase-postgres 0755 root root -"
    "d ${dataDir} 0750 root root -"
  ];

  # Container DB (when this module is active): psql -h 127.0.0.1 -p 5432 -U postgres -d postgres; password comes from POSTGRES_PASSWORD below.
  virtualisation.oci-containers.containers.postgresql = {
    image = "supabase/postgres:17.6.1.084";
    autoStart = true;
    ports = [
      "127.0.0.1:5432:5432"
    ];
    volumes = [
      "${dataDir}:/var/lib/postgresql/data"
    ];
    environment = {
      POSTGRES_USER = "postgres";
      POSTGRES_PASSWORD = "postgres";
      POSTGRES_DB = "postgres";
      PGDATA = "/var/lib/postgresql/data";
    };
    cmd = [
      "postgres"
      "-c"
      "config_file=/etc/postgresql/postgresql.conf"
      "-c"
      "log_min_messages=fatal"
    ];
  };
}
