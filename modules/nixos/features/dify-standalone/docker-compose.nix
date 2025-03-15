# Auto-generated using compose2nix v0.3.1.
{
  pkgs,
  lib,
  ...
}: {
  # Containers
  virtualisation.oci-containers.containers."dify-api" = {
    image = "langgenius/dify-api:1.0.1";
    environment = {
      "ACCESS_TOKEN_EXPIRE_MINUTES" = "60";
      "ALIYUN_OSS_ACCESS_KEY" = "your-access-key";
      "ALIYUN_OSS_AUTH_VERSION" = "v4";
      "ALIYUN_OSS_BUCKET_NAME" = "your-bucket-name";
      "ALIYUN_OSS_ENDPOINT" = "https://oss-ap-southeast-1-internal.aliyuncs.com";
      "ALIYUN_OSS_PATH" = "your-path";
      "ALIYUN_OSS_REGION" = "ap-southeast-1";
      "ALIYUN_OSS_SECRET_KEY" = "your-secret-key";
      "ANALYTICDB_ACCOUNT" = "testaccount";
      "ANALYTICDB_HOST" = "gp-test.aliyuncs.com";
      "ANALYTICDB_INSTANCE_ID" = "gp-ab123456";
      "ANALYTICDB_KEY_ID" = "your-ak";
      "ANALYTICDB_KEY_SECRET" = "your-sk";
      "ANALYTICDB_MAX_CONNECTION" = "5";
      "ANALYTICDB_MIN_CONNECTION" = "1";
      "ANALYTICDB_NAMESPACE" = "dify";
      "ANALYTICDB_NAMESPACE_PASSWORD" = "difypassword";
      "ANALYTICDB_PASSWORD" = "testpassword";
      "ANALYTICDB_PORT" = "5432";
      "ANALYTICDB_REGION_ID" = "cn-hangzhou";
      "API_SENTRY_DSN" = "";
      "API_SENTRY_PROFILES_SAMPLE_RATE" = "1.0";
      "API_SENTRY_TRACES_SAMPLE_RATE" = "1.0";
      "API_TOOL_DEFAULT_CONNECT_TIMEOUT" = "10";
      "API_TOOL_DEFAULT_READ_TIMEOUT" = "60";
      "APP_API_URL" = "";
      "APP_MAX_ACTIVE_REQUESTS" = "0";
      "APP_MAX_EXECUTION_TIME" = "1200";
      "APP_WEB_URL" = "";
      "AZURE_BLOB_ACCOUNT_KEY" = "difyai";
      "AZURE_BLOB_ACCOUNT_NAME" = "difyai";
      "AZURE_BLOB_ACCOUNT_URL" = "https:// <your_account_name >.blob.core.windows.net";
      "AZURE_BLOB_CONTAINER_NAME" = "difyai-container";
      "BAIDU_OBS_ACCESS_KEY" = "your-access-key";
      "BAIDU_OBS_BUCKET_NAME" = "your-bucket-name";
      "BAIDU_OBS_ENDPOINT" = "your-server-url";
      "BAIDU_OBS_SECRET_KEY" = "your-secret-key";
      "BAIDU_VECTOR_DB_ACCOUNT" = "root";
      "BAIDU_VECTOR_DB_API_KEY" = "dify";
      "BAIDU_VECTOR_DB_CONNECTION_TIMEOUT_MS" = "30000";
      "BAIDU_VECTOR_DB_DATABASE" = "dify";
      "BAIDU_VECTOR_DB_ENDPOINT" = "http://127.0.0.1:5287";
      "BAIDU_VECTOR_DB_REPLICAS" = "3";
      "BAIDU_VECTOR_DB_SHARD" = "1";
      "BROKER_USE_SSL" = "false";
      "CELERY_AUTO_SCALE" = "false";
      "CELERY_BROKER_URL" = "redis://:difyai123456@redis:6379/1";
      "CELERY_MAX_WORKERS" = "";
      "CELERY_MIN_WORKERS" = "";
      "CELERY_SENTINEL_MASTER_NAME" = "";
      "CELERY_SENTINEL_SOCKET_TIMEOUT" = "0.1";
      "CELERY_USE_SENTINEL" = "false";
      "CELERY_WORKER_AMOUNT" = "";
      "CELERY_WORKER_CLASS" = "";
      "CERTBOT_DOMAIN" = "your_domain.com";
      "CERTBOT_EMAIL" = "your_email@example.com";
      "CERTBOT_OPTIONS" = "";
      "CHECK_UPDATE_URL" = "https://updates.dify.ai";
      "CHROMA_AUTH_CREDENTIALS" = "";
      "CHROMA_AUTH_PROVIDER" = "chromadb.auth.token_authn.TokenAuthClientProvider";
      "CHROMA_DATABASE" = "default_database";
      "CHROMA_HOST" = "127.0.0.1";
      "CHROMA_IS_PERSISTENT" = "TRUE";
      "CHROMA_PORT" = "8000";
      "CHROMA_SERVER_AUTHN_CREDENTIALS" = "difyai123456";
      "CHROMA_SERVER_AUTHN_PROVIDER" = "chromadb.auth.token_authn.TokenAuthenticationServerProvider";
      "CHROMA_TENANT" = "default_tenant";
      "CODE_EXECUTION_API_KEY" = "dify-sandbox";
      "CODE_EXECUTION_CONNECT_TIMEOUT" = "10";
      "CODE_EXECUTION_ENDPOINT" = "http://sandbox:8194";
      "CODE_EXECUTION_READ_TIMEOUT" = "60";
      "CODE_EXECUTION_WRITE_TIMEOUT" = "10";
      "CODE_GENERATION_MAX_TOKENS" = "1024";
      "CODE_MAX_DEPTH" = "5";
      "CODE_MAX_NUMBER" = "9223372036854775807";
      "CODE_MAX_NUMBER_ARRAY_LENGTH" = "1000";
      "CODE_MAX_OBJECT_ARRAY_LENGTH" = "30";
      "CODE_MAX_PRECISION" = "20";
      "CODE_MAX_STRING_ARRAY_LENGTH" = "30";
      "CODE_MAX_STRING_LENGTH" = "80000";
      "CODE_MIN_NUMBER" = "-9223372036854775808";
      "CONSOLE_API_URL" = "";
      "CONSOLE_CORS_ALLOW_ORIGINS" = "*";
      "CONSOLE_WEB_URL" = "";
      "COUCHBASE_BUCKET_NAME" = "Embeddings";
      "COUCHBASE_CONNECTION_STRING" = "couchbase://couchbase-server";
      "COUCHBASE_PASSWORD" = "password";
      "COUCHBASE_SCOPE_NAME" = "_default";
      "COUCHBASE_USER" = "Administrator";
      "CREATE_TIDB_SERVICE_JOB_ENABLED" = "false";
      "CSP_WHITELIST" = "";
      "DB_DATABASE" = "dify";
      "DB_HOST" = "db";
      "DB_PASSWORD" = "difyai123456";
      "DB_PLUGIN_DATABASE" = "dify_plugin";
      "DB_PORT" = "5432";
      "DB_USERNAME" = "postgres";
      "DEBUG" = "false";
      "DEPLOY_ENV" = "PRODUCTION";
      "DIFY_BIND_ADDRESS" = "0.0.0.0";
      "DIFY_PORT" = "5001";
      "ELASTICSEARCH_HOST" = "0.0.0.0";
      "ELASTICSEARCH_PASSWORD" = "elastic";
      "ELASTICSEARCH_PORT" = "9200";
      "ELASTICSEARCH_USERNAME" = "elastic";
      "ENDPOINT_URL_TEMPLATE" = "http://localhost/e/{hook_id}";
      "ETCD_AUTO_COMPACTION_MODE" = "revision";
      "ETCD_AUTO_COMPACTION_RETENTION" = "1000";
      "ETCD_ENDPOINTS" = "etcd:2379";
      "ETCD_QUOTA_BACKEND_BYTES" = "4294967296";
      "ETCD_SNAPSHOT_COUNT" = "50000";
      "ETL_TYPE" = "dify";
      "EXPOSE_NGINX_PORT" = "8080";
      "EXPOSE_NGINX_SSL_PORT" = "8443";
      "EXPOSE_PLUGIN_DAEMON_PORT" = "5002";
      "EXPOSE_PLUGIN_DEBUGGING_HOST" = "localhost";
      "EXPOSE_PLUGIN_DEBUGGING_PORT" = "5003";
      "FILES_ACCESS_TIMEOUT" = "300";
      "FILES_URL" = "";
      "FLASK_DEBUG" = "false";
      "FORCE_VERIFYING_SIGNATURE" = "true";
      "GOOGLE_STORAGE_BUCKET_NAME" = "your-bucket-name";
      "GOOGLE_STORAGE_SERVICE_ACCOUNT_JSON_BASE64" = "";
      "GUNICORN_TIMEOUT" = "360";
      "HTTP_REQUEST_NODE_MAX_BINARY_SIZE" = "10485760";
      "HTTP_REQUEST_NODE_MAX_TEXT_SIZE" = "1048576";
      "HTTP_REQUEST_NODE_SSL_VERIFY" = "True";
      "HUAWEI_OBS_ACCESS_KEY" = "your-access-key";
      "HUAWEI_OBS_BUCKET_NAME" = "your-bucket-name";
      "HUAWEI_OBS_SECRET_KEY" = "your-secret-key";
      "HUAWEI_OBS_SERVER" = "your-server-url";
      "INDEXING_MAX_SEGMENTATION_TOKENS_LENGTH" = "4000";
      "INIT_PASSWORD" = "";
      "INNER_API_KEY_FOR_PLUGIN" = "QaHbTe77CtuXmsfyhR7+vRjI/+XbV1AaFy691iy+kGDv2Jvy0/eAh8Y1";
      "INVITE_EXPIRY_HOURS" = "72";
      "KIBANA_PORT" = "5601";
      "LINDORM_PASSWORD" = "lindorm";
      "LINDORM_URL" = "http://lindorm:30070";
      "LINDORM_USERNAME" = "lindorm";
      "LOG_DATEFORMAT" = "%Y-%m-%d %H:%M:%S";
      "LOG_FILE" = "/app/logs/server.log";
      "LOG_FILE_BACKUP_COUNT" = "5";
      "LOG_FILE_MAX_SIZE" = "20";
      "LOG_LEVEL" = "INFO";
      "LOG_TZ" = "UTC";
      "LOOP_NODE_MAX_COUNT" = "100";
      "MAIL_DEFAULT_SEND_FROM" = "";
      "MAIL_TYPE" = "resend";
      "MARKETPLACE_API_URL" = "https://marketplace.dify.ai";
      "MARKETPLACE_ENABLED" = "true";
      "MAX_SUBMIT_COUNT" = "100";
      "MAX_TOOLS_NUM" = "10";
      "MAX_VARIABLE_SIZE" = "204800";
      "MIGRATION_ENABLED" = "true";
      "MILVUS_AUTHORIZATION_ENABLED" = "true";
      "MILVUS_ENABLE_HYBRID_SEARCH" = "False";
      "MILVUS_PASSWORD" = "";
      "MILVUS_TOKEN" = "";
      "MILVUS_URI" = "http://host.docker.internal:19530";
      "MILVUS_USER" = "";
      "MINIO_ACCESS_KEY" = "minioadmin";
      "MINIO_ADDRESS" = "minio:9000";
      "MINIO_SECRET_KEY" = "minioadmin";
      "MODE" = "api";
      "MULTIMODAL_SEND_FORMAT" = "base64";
      "MYSCALE_DATABASE" = "dify";
      "MYSCALE_FTS_PARAMS" = "";
      "MYSCALE_HOST" = "myscale";
      "MYSCALE_PASSWORD" = "";
      "MYSCALE_PORT" = "8123";
      "MYSCALE_USER" = "default";
      "NGINX_CLIENT_MAX_BODY_SIZE" = "15M";
      "NGINX_ENABLE_CERTBOT_CHALLENGE" = "false";
      "NGINX_HTTPS_ENABLED" = "false";
      "NGINX_KEEPALIVE_TIMEOUT" = "65";
      "NGINX_PORT" = "80";
      "NGINX_PROXY_READ_TIMEOUT" = "3600s";
      "NGINX_PROXY_SEND_TIMEOUT" = "3600s";
      "NGINX_SERVER_NAME" = "_";
      "NGINX_SSL_CERT_FILENAME" = "dify.crt";
      "NGINX_SSL_CERT_KEY_FILENAME" = "dify.key";
      "NGINX_SSL_PORT" = "443";
      "NGINX_SSL_PROTOCOLS" = "TLSv1.1 TLSv1.2 TLSv1.3";
      "NGINX_WORKER_PROCESSES" = "auto";
      "NOTION_CLIENT_ID" = "";
      "NOTION_CLIENT_SECRET" = "";
      "NOTION_INTEGRATION_TYPE" = "public";
      "NOTION_INTERNAL_SECRET" = "";
      "OCEANBASE_CLUSTER_NAME" = "difyai";
      "OCEANBASE_MEMORY_LIMIT" = "6G";
      "OCEANBASE_VECTOR_DATABASE" = "test";
      "OCEANBASE_VECTOR_HOST" = "oceanbase";
      "OCEANBASE_VECTOR_PASSWORD" = "difyai123456";
      "OCEANBASE_VECTOR_PORT" = "2881";
      "OCEANBASE_VECTOR_USER" = "root@test";
      "OCI_ACCESS_KEY" = "your-access-key";
      "OCI_BUCKET_NAME" = "your-bucket-name";
      "OCI_ENDPOINT" = "https://your-object-storage-namespace.compat.objectstorage.us-ashburn-1.oraclecloud.com";
      "OCI_REGION" = "us-ashburn-1";
      "OCI_SECRET_KEY" = "your-secret-key";
      "OPENAI_API_BASE" = "https://api.openai.com/v1";
      "OPENDAL_FS_ROOT" = "storage";
      "OPENDAL_SCHEME" = "fs";
      "OPENSEARCH_BOOTSTRAP_MEMORY_LOCK" = "true";
      "OPENSEARCH_DISCOVERY_TYPE" = "single-node";
      "OPENSEARCH_HOST" = "opensearch";
      "OPENSEARCH_INITIAL_ADMIN_PASSWORD" = "Qazwsxedc!@#123";
      "OPENSEARCH_JAVA_OPTS_MAX" = "1024m";
      "OPENSEARCH_JAVA_OPTS_MIN" = "512m";
      "OPENSEARCH_MEMLOCK_HARD" = "-1";
      "OPENSEARCH_MEMLOCK_SOFT" = "-1";
      "OPENSEARCH_NOFILE_HARD" = "65536";
      "OPENSEARCH_NOFILE_SOFT" = "65536";
      "OPENSEARCH_PASSWORD" = "admin";
      "OPENSEARCH_PORT" = "9200";
      "OPENSEARCH_SECURE" = "true";
      "OPENSEARCH_USER" = "admin";
      "ORACLE_CHARACTERSET" = "AL32UTF8";
      "ORACLE_CONFIG_DIR" = "/app/api/storage/wallet";
      "ORACLE_DSN" = "oracle:1521/FREEPDB1";
      "ORACLE_IS_AUTONOMOUS" = "false";
      "ORACLE_PASSWORD" = "dify";
      "ORACLE_PWD" = "Dify123456";
      "ORACLE_USER" = "dify";
      "ORACLE_WALLET_LOCATION" = "/app/api/storage/wallet";
      "ORACLE_WALLET_PASSWORD" = "dify";
      "PGDATA" = "/var/lib/postgresql/data/pgdata";
      "PGUSER" = "postgres";
      "PGVECTOR_DATABASE" = "dify";
      "PGVECTOR_HOST" = "pgvector";
      "PGVECTOR_MAX_CONNECTION" = "5";
      "PGVECTOR_MIN_CONNECTION" = "1";
      "PGVECTOR_PASSWORD" = "difyai123456";
      "PGVECTOR_PGDATA" = "/var/lib/postgresql/data/pgdata";
      "PGVECTOR_PGUSER" = "postgres";
      "PGVECTOR_PG_BIGM" = "false";
      "PGVECTOR_PG_BIGM_VERSION" = "1.2-20240606";
      "PGVECTOR_PORT" = "5432";
      "PGVECTOR_POSTGRES_DB" = "dify";
      "PGVECTOR_POSTGRES_PASSWORD" = "difyai123456";
      "PGVECTOR_USER" = "postgres";
      "PGVECTO_RS_DATABASE" = "dify";
      "PGVECTO_RS_HOST" = "pgvecto-rs";
      "PGVECTO_RS_PASSWORD" = "difyai123456";
      "PGVECTO_RS_PORT" = "5432";
      "PGVECTO_RS_USER" = "postgres";
      "PIP_MIRROR_URL" = "";
      "PLUGIN_DAEMON_KEY" = "lYkiYYT6owG+71oLerGzA7GXCgOT++6ovaezWAjpCjf+Sjc3ZtU+qUEi";
      "PLUGIN_DAEMON_PORT" = "5002";
      "PLUGIN_DAEMON_URL" = "http://plugin_daemon:5002";
      "PLUGIN_DEBUGGING_HOST" = "0.0.0.0";
      "PLUGIN_DEBUGGING_PORT" = "5003";
      "PLUGIN_DIFY_INNER_API_KEY" = "QaHbTe77CtuXmsfyhR7+vRjI/+XbV1AaFy691iy+kGDv2Jvy0/eAh8Y1";
      "PLUGIN_DIFY_INNER_API_URL" = "http://api:5001";
      "PLUGIN_MAX_EXECUTION_TIMEOUT" = "600";
      "PLUGIN_MAX_PACKAGE_SIZE" = "52428800";
      "PLUGIN_PPROF_ENABLED" = "false";
      "PLUGIN_PYTHON_ENV_INIT_TIMEOUT" = "120";
      "PLUGIN_REMOTE_INSTALL_HOST" = "localhost";
      "PLUGIN_REMOTE_INSTALL_PORT" = "5003";
      "POSITION_PROVIDER_EXCLUDES" = "";
      "POSITION_PROVIDER_INCLUDES" = "";
      "POSITION_PROVIDER_PINS" = "";
      "POSITION_TOOL_EXCLUDES" = "";
      "POSITION_TOOL_INCLUDES" = "";
      "POSITION_TOOL_PINS" = "";
      "POSTGRES_DB" = "dify";
      "POSTGRES_EFFECTIVE_CACHE_SIZE" = "4096MB";
      "POSTGRES_MAINTENANCE_WORK_MEM" = "64MB";
      "POSTGRES_MAX_CONNECTIONS" = "100";
      "POSTGRES_PASSWORD" = "difyai123456";
      "POSTGRES_SHARED_BUFFERS" = "128MB";
      "POSTGRES_WORK_MEM" = "4MB";
      "PROMPT_GENERATION_MAX_TOKENS" = "512";
      "QDRANT_API_KEY" = "difyai123456";
      "QDRANT_CLIENT_TIMEOUT" = "20";
      "QDRANT_GRPC_ENABLED" = "false";
      "QDRANT_GRPC_PORT" = "6334";
      "QDRANT_URL" = "http://qdrant:6333";
      "REDIS_CLUSTERS" = "";
      "REDIS_CLUSTERS_PASSWORD" = "";
      "REDIS_DB" = "0";
      "REDIS_HOST" = "redis";
      "REDIS_PASSWORD" = "difyai123456";
      "REDIS_PORT" = "6379";
      "REDIS_SENTINELS" = "";
      "REDIS_SENTINEL_PASSWORD" = "";
      "REDIS_SENTINEL_SERVICE_NAME" = "";
      "REDIS_SENTINEL_SOCKET_TIMEOUT" = "0.1";
      "REDIS_SENTINEL_USERNAME" = "";
      "REDIS_USERNAME" = "";
      "REDIS_USE_CLUSTERS" = "false";
      "REDIS_USE_SENTINEL" = "false";
      "REDIS_USE_SSL" = "false";
      "REFRESH_TOKEN_EXPIRE_DAYS" = "30";
      "RELYT_DATABASE" = "postgres";
      "RELYT_HOST" = "db";
      "RELYT_PASSWORD" = "difyai123456";
      "RELYT_PORT" = "5432";
      "RELYT_USER" = "postgres";
      "RESEND_API_KEY" = "your-resend-api-key";
      "RESEND_API_URL" = "https://api.resend.com";
      "RESET_PASSWORD_TOKEN_EXPIRY_MINUTES" = "5";
      "S3_ACCESS_KEY" = "";
      "S3_BUCKET_NAME" = "difyai";
      "S3_ENDPOINT" = "";
      "S3_REGION" = "us-east-1";
      "S3_SECRET_KEY" = "";
      "S3_USE_AWS_MANAGED_IAM" = "false";
      "SANDBOX_API_KEY" = "dify-sandbox";
      "SANDBOX_ENABLE_NETWORK" = "true";
      "SANDBOX_GIN_MODE" = "release";
      "SANDBOX_HTTPS_PROXY" = "http://ssrf_proxy:3128";
      "SANDBOX_HTTP_PROXY" = "http://ssrf_proxy:3128";
      "SANDBOX_PORT" = "8194";
      "SANDBOX_WORKER_TIMEOUT" = "15";
      "SCARF_NO_ANALYTICS" = "true";
      "SECRET_KEY" = "sk-9f73s3ljTXVcMT3Blb3ljTqtsKiGHXVcMT3BlbkFJLK7U";
      "SENTRY_DSN" = "";
      "SENTRY_PROFILES_SAMPLE_RATE" = "1.0";
      "SENTRY_TRACES_SAMPLE_RATE" = "1.0";
      "SERVER_WORKER_AMOUNT" = "1";
      "SERVER_WORKER_CLASS" = "gevent";
      "SERVER_WORKER_CONNECTIONS" = "10";
      "SERVICE_API_URL" = "";
      "SMTP_OPPORTUNISTIC_TLS" = "false";
      "SMTP_PASSWORD" = "";
      "SMTP_PORT" = "465";
      "SMTP_SERVER" = "";
      "SMTP_USERNAME" = "";
      "SMTP_USE_TLS" = "true";
      "SQLALCHEMY_ECHO" = "false";
      "SQLALCHEMY_POOL_RECYCLE" = "3600";
      "SQLALCHEMY_POOL_SIZE" = "30";
      "SSRF_COREDUMP_DIR" = "/var/spool/squid";
      "SSRF_DEFAULT_CONNECT_TIME_OUT" = "5";
      "SSRF_DEFAULT_READ_TIME_OUT" = "5";
      "SSRF_DEFAULT_TIME_OUT" = "5";
      "SSRF_DEFAULT_WRITE_TIME_OUT" = "5";
      "SSRF_HTTP_PORT" = "3128";
      "SSRF_PROXY_HTTPS_URL" = "http://ssrf_proxy:3128";
      "SSRF_PROXY_HTTP_URL" = "http://ssrf_proxy:3128";
      "SSRF_REVERSE_PROXY_PORT" = "8194";
      "SSRF_SANDBOX_HOST" = "sandbox";
      "STORAGE_TYPE" = "opendal";
      "SUPABASE_API_KEY" = "your-access-key";
      "SUPABASE_BUCKET_NAME" = "your-bucket-name";
      "SUPABASE_URL" = "your-server-url";
      "TEMPLATE_TRANSFORM_MAX_LENGTH" = "80000";
      "TENCENT_COS_BUCKET_NAME" = "your-bucket-name";
      "TENCENT_COS_REGION" = "your-region";
      "TENCENT_COS_SCHEME" = "your-scheme";
      "TENCENT_COS_SECRET_ID" = "your-secret-id";
      "TENCENT_COS_SECRET_KEY" = "your-secret-key";
      "TENCENT_VECTOR_DB_API_KEY" = "dify";
      "TENCENT_VECTOR_DB_DATABASE" = "dify";
      "TENCENT_VECTOR_DB_REPLICAS" = "2";
      "TENCENT_VECTOR_DB_SHARD" = "1";
      "TENCENT_VECTOR_DB_TIMEOUT" = "30";
      "TENCENT_VECTOR_DB_URL" = "http://127.0.0.1";
      "TENCENT_VECTOR_DB_USERNAME" = "dify";
      "TEXT_GENERATION_TIMEOUT_MS" = "60000";
      "TIDB_API_URL" = "http://127.0.0.1";
      "TIDB_IAM_API_URL" = "http://127.0.0.1";
      "TIDB_ON_QDRANT_API_KEY" = "dify";
      "TIDB_ON_QDRANT_CLIENT_TIMEOUT" = "20";
      "TIDB_ON_QDRANT_GRPC_ENABLED" = "false";
      "TIDB_ON_QDRANT_GRPC_PORT" = "6334";
      "TIDB_ON_QDRANT_URL" = "http://127.0.0.1";
      "TIDB_PRIVATE_KEY" = "dify";
      "TIDB_PROJECT_ID" = "dify";
      "TIDB_PUBLIC_KEY" = "dify";
      "TIDB_REGION" = "regions/aws-us-east-1";
      "TIDB_SPEND_LIMIT" = "100";
      "TIDB_VECTOR_DATABASE" = "dify";
      "TIDB_VECTOR_HOST" = "tidb";
      "TIDB_VECTOR_PASSWORD" = "";
      "TIDB_VECTOR_PORT" = "4000";
      "TIDB_VECTOR_USER" = "";
      "TOP_K_MAX_VALUE" = "10";
      "UNSTRUCTURED_API_KEY" = "";
      "UNSTRUCTURED_API_URL" = "";
      "UPLOAD_AUDIO_FILE_SIZE_LIMIT" = "50";
      "UPLOAD_FILE_BATCH_LIMIT" = "5";
      "UPLOAD_FILE_SIZE_LIMIT" = "15";
      "UPLOAD_IMAGE_FILE_SIZE_LIMIT" = "10";
      "UPLOAD_VIDEO_FILE_SIZE_LIMIT" = "100";
      "UPSTASH_VECTOR_TOKEN" = "dify";
      "UPSTASH_VECTOR_URL" = "https://xxx-vector.upstash.io";
      "VECTOR_STORE" = "weaviate";
      "VIKINGDB_ACCESS_KEY" = "your-ak";
      "VIKINGDB_CONNECTION_TIMEOUT" = "30";
      "VIKINGDB_HOST" = "api-vikingdb.xxx.volces.com";
      "VIKINGDB_REGION" = "cn-shanghai";
      "VIKINGDB_SCHEMA" = "http";
      "VIKINGDB_SECRET_KEY" = "your-sk";
      "VIKINGDB_SOCKET_TIMEOUT" = "30";
      "VOLCENGINE_TOS_ACCESS_KEY" = "your-access-key";
      "VOLCENGINE_TOS_BUCKET_NAME" = "your-bucket-name";
      "VOLCENGINE_TOS_ENDPOINT" = "your-server-url";
      "VOLCENGINE_TOS_REGION" = "your-region";
      "VOLCENGINE_TOS_SECRET_KEY" = "your-secret-key";
      "WEAVIATE_API_KEY" = "WVF5YThaHlkYwhGUSmCRgsX3tD5ngdN8pkih";
      "WEAVIATE_AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED" = "true";
      "WEAVIATE_AUTHENTICATION_APIKEY_ALLOWED_KEYS" = "WVF5YThaHlkYwhGUSmCRgsX3tD5ngdN8pkih";
      "WEAVIATE_AUTHENTICATION_APIKEY_ENABLED" = "true";
      "WEAVIATE_AUTHENTICATION_APIKEY_USERS" = "hello@dify.ai";
      "WEAVIATE_AUTHORIZATION_ADMINLIST_ENABLED" = "true";
      "WEAVIATE_AUTHORIZATION_ADMINLIST_USERS" = "hello@dify.ai";
      "WEAVIATE_CLUSTER_HOSTNAME" = "node1";
      "WEAVIATE_DEFAULT_VECTORIZER_MODULE" = "none";
      "WEAVIATE_ENDPOINT" = "http://weaviate:8080";
      "WEAVIATE_PERSISTENCE_DATA_PATH" = "/var/lib/weaviate";
      "WEAVIATE_QUERY_DEFAULTS_LIMIT" = "25";
      "WEB_API_CORS_ALLOW_ORIGINS" = "*";
      "WEB_SENTRY_DSN" = "";
      "WORKFLOW_CALL_MAX_DEPTH" = "5";
      "WORKFLOW_FILE_UPLOAD_LIMIT" = "10";
      "WORKFLOW_MAX_EXECUTION_STEPS" = "500";
      "WORKFLOW_MAX_EXECUTION_TIME" = "1200";
      "WORKFLOW_PARALLEL_DEPTH_LIMIT" = "3";
    };
    environmentFiles = [
      "/home/zshen/personal/nix-config/modules/nixos/features/dify/.env"
    ];
    volumes = [
      "/home/zshen/personal/nix-config/modules/nixos/features/dify/volumes/app/storage:/app/api/storage:rw"
    ];
    dependsOn = [
      "dify-db"
      "dify-redis"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=api"
      "--network=dify_default"
      "--network=dify_ssrf_proxy_network"
    ];
  };
  systemd.services."podman-dify-api" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
    };
    after = [
      "podman-network-dify_default.service"
      "podman-network-dify_ssrf_proxy_network.service"
    ];
    requires = [
      "podman-network-dify_default.service"
      "podman-network-dify_ssrf_proxy_network.service"
    ];
    partOf = [
      "podman-compose-dify-root.target"
    ];
    wantedBy = [
      "podman-compose-dify-root.target"
    ];
  };
  virtualisation.oci-containers.containers."dify-db" = {
    image = "postgres:15-alpine";
    environment = {
      "PGDATA" = "/var/lib/postgresql/data/pgdata";
      "PGUSER" = "postgres";
      "POSTGRES_DB" = "dify";
      "POSTGRES_PASSWORD" = "difyai123456";
    };
    environmentFiles = [
      "/home/zshen/personal/nix-config/modules/nixos/features/dify/.env"
    ];
    volumes = [
      "/home/zshen/personal/nix-config/modules/nixos/features/dify/volumes/db/data:/var/lib/postgresql/data:rw"
    ];
    cmd = ["postgres" "-c" "max_connections=100" "-c" "shared_buffers=128MB" "-c" "work_mem=4MB" "-c" "maintenance_work_mem=64MB" "-c" "effective_cache_size=4096MB"];
    log-driver = "journald";
    extraOptions = [
      "--health-cmd=[\"pg_isready\"]"
      "--health-interval=1s"
      "--health-retries=30"
      "--health-timeout=3s"
      "--network-alias=db"
      "--network=dify_default"
    ];
  };
  systemd.services."podman-dify-db" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
    };
    after = [
      "podman-network-dify_default.service"
    ];
    requires = [
      "podman-network-dify_default.service"
    ];
    partOf = [
      "podman-compose-dify-root.target"
    ];
    wantedBy = [
      "podman-compose-dify-root.target"
    ];
  };
  virtualisation.oci-containers.containers."dify-nginx" = {
    image = "nginx:latest";
    environment = {
      "CERTBOT_DOMAIN" = "your_domain.com";
      "NGINX_CLIENT_MAX_BODY_SIZE" = "15M";
      "NGINX_ENABLE_CERTBOT_CHALLENGE" = "false";
      "NGINX_HTTPS_ENABLED" = "false";
      "NGINX_KEEPALIVE_TIMEOUT" = "65";
      "NGINX_PORT" = "80";
      "NGINX_PROXY_READ_TIMEOUT" = "3600s";
      "NGINX_PROXY_SEND_TIMEOUT" = "3600s";
      "NGINX_SERVER_NAME" = "_";
      "NGINX_SSL_CERT_FILENAME" = "dify.crt";
      "NGINX_SSL_CERT_KEY_FILENAME" = "dify.key";
      "NGINX_SSL_PORT" = "443";
      "NGINX_SSL_PROTOCOLS" = "TLSv1.1 TLSv1.2 TLSv1.3";
      "NGINX_WORKER_PROCESSES" = "auto";
    };
    environmentFiles = [
      "/home/zshen/personal/nix-config/modules/nixos/features/dify/.env"
    ];
    volumes = [
      "/home/zshen/personal/nix-config/modules/nixos/features/dify/nginx/conf.d:/etc/nginx/conf.d:rw"
      "/home/zshen/personal/nix-config/modules/nixos/features/dify/nginx/docker-entrypoint.sh:/docker-entrypoint-mount.sh:rw"
      "/home/zshen/personal/nix-config/modules/nixos/features/dify/nginx/https.conf.template:/etc/nginx/https.conf.template:rw"
      "/home/zshen/personal/nix-config/modules/nixos/features/dify/nginx/nginx.conf.template:/etc/nginx/nginx.conf.template:rw"
      "/home/zshen/personal/nix-config/modules/nixos/features/dify/nginx/proxy.conf.template:/etc/nginx/proxy.conf.template:rw"
      "/home/zshen/personal/nix-config/modules/nixos/features/dify/nginx/ssl:/etc/ssl:rw"
      "/home/zshen/personal/nix-config/modules/nixos/features/dify/volumes/certbot/conf:/etc/letsencrypt:rw"
      "/home/zshen/personal/nix-config/modules/nixos/features/dify/volumes/certbot/conf/live:/etc/letsencrypt/live:rw"
      "/home/zshen/personal/nix-config/modules/nixos/features/dify/volumes/certbot/www:/var/www/html:rw"
    ];
    ports = [
      "8080:80/tcp"
      "8443:443/tcp"
    ];
    dependsOn = [
      "dify-api"
      "dify-web"
    ];
    log-driver = "journald";
    extraOptions = [
      "--entrypoint=[\"sh\", \"-c\", \"cp /docker-entrypoint-mount.sh /docker-entrypoint.sh && sed -i 's/$//' /docker-entrypoint.sh && chmod +x /docker-entrypoint.sh && /docker-entrypoint.sh\"]"
      "--network-alias=nginx"
      "--network=dify_default"
    ];
  };
  systemd.services."podman-dify-nginx" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
    };
    after = [
      "podman-network-dify_default.service"
    ];
    requires = [
      "podman-network-dify_default.service"
    ];
    partOf = [
      "podman-compose-dify-root.target"
    ];
    wantedBy = [
      "podman-compose-dify-root.target"
    ];
  };
  virtualisation.oci-containers.containers."dify-plugin_daemon" = {
    image = "langgenius/dify-plugin-daemon:0.0.4-local";
    environment = {
      "ACCESS_TOKEN_EXPIRE_MINUTES" = "60";
      "ALIYUN_OSS_ACCESS_KEY" = "your-access-key";
      "ALIYUN_OSS_AUTH_VERSION" = "v4";
      "ALIYUN_OSS_BUCKET_NAME" = "your-bucket-name";
      "ALIYUN_OSS_ENDPOINT" = "https://oss-ap-southeast-1-internal.aliyuncs.com";
      "ALIYUN_OSS_PATH" = "your-path";
      "ALIYUN_OSS_REGION" = "ap-southeast-1";
      "ALIYUN_OSS_SECRET_KEY" = "your-secret-key";
      "ANALYTICDB_ACCOUNT" = "testaccount";
      "ANALYTICDB_HOST" = "gp-test.aliyuncs.com";
      "ANALYTICDB_INSTANCE_ID" = "gp-ab123456";
      "ANALYTICDB_KEY_ID" = "your-ak";
      "ANALYTICDB_KEY_SECRET" = "your-sk";
      "ANALYTICDB_MAX_CONNECTION" = "5";
      "ANALYTICDB_MIN_CONNECTION" = "1";
      "ANALYTICDB_NAMESPACE" = "dify";
      "ANALYTICDB_NAMESPACE_PASSWORD" = "difypassword";
      "ANALYTICDB_PASSWORD" = "testpassword";
      "ANALYTICDB_PORT" = "5432";
      "ANALYTICDB_REGION_ID" = "cn-hangzhou";
      "API_SENTRY_DSN" = "";
      "API_SENTRY_PROFILES_SAMPLE_RATE" = "1.0";
      "API_SENTRY_TRACES_SAMPLE_RATE" = "1.0";
      "API_TOOL_DEFAULT_CONNECT_TIMEOUT" = "10";
      "API_TOOL_DEFAULT_READ_TIMEOUT" = "60";
      "APP_API_URL" = "";
      "APP_MAX_ACTIVE_REQUESTS" = "0";
      "APP_MAX_EXECUTION_TIME" = "1200";
      "APP_WEB_URL" = "";
      "AZURE_BLOB_ACCOUNT_KEY" = "difyai";
      "AZURE_BLOB_ACCOUNT_NAME" = "difyai";
      "AZURE_BLOB_ACCOUNT_URL" = "https:// <your_account_name >.blob.core.windows.net";
      "AZURE_BLOB_CONTAINER_NAME" = "difyai-container";
      "BAIDU_OBS_ACCESS_KEY" = "your-access-key";
      "BAIDU_OBS_BUCKET_NAME" = "your-bucket-name";
      "BAIDU_OBS_ENDPOINT" = "your-server-url";
      "BAIDU_OBS_SECRET_KEY" = "your-secret-key";
      "BAIDU_VECTOR_DB_ACCOUNT" = "root";
      "BAIDU_VECTOR_DB_API_KEY" = "dify";
      "BAIDU_VECTOR_DB_CONNECTION_TIMEOUT_MS" = "30000";
      "BAIDU_VECTOR_DB_DATABASE" = "dify";
      "BAIDU_VECTOR_DB_ENDPOINT" = "http://127.0.0.1:5287";
      "BAIDU_VECTOR_DB_REPLICAS" = "3";
      "BAIDU_VECTOR_DB_SHARD" = "1";
      "BROKER_USE_SSL" = "false";
      "CELERY_AUTO_SCALE" = "false";
      "CELERY_BROKER_URL" = "redis://:difyai123456@redis:6379/1";
      "CELERY_MAX_WORKERS" = "";
      "CELERY_MIN_WORKERS" = "";
      "CELERY_SENTINEL_MASTER_NAME" = "";
      "CELERY_SENTINEL_SOCKET_TIMEOUT" = "0.1";
      "CELERY_USE_SENTINEL" = "false";
      "CELERY_WORKER_AMOUNT" = "";
      "CELERY_WORKER_CLASS" = "";
      "CERTBOT_DOMAIN" = "your_domain.com";
      "CERTBOT_EMAIL" = "your_email@example.com";
      "CERTBOT_OPTIONS" = "";
      "CHECK_UPDATE_URL" = "https://updates.dify.ai";
      "CHROMA_AUTH_CREDENTIALS" = "";
      "CHROMA_AUTH_PROVIDER" = "chromadb.auth.token_authn.TokenAuthClientProvider";
      "CHROMA_DATABASE" = "default_database";
      "CHROMA_HOST" = "127.0.0.1";
      "CHROMA_IS_PERSISTENT" = "TRUE";
      "CHROMA_PORT" = "8000";
      "CHROMA_SERVER_AUTHN_CREDENTIALS" = "difyai123456";
      "CHROMA_SERVER_AUTHN_PROVIDER" = "chromadb.auth.token_authn.TokenAuthenticationServerProvider";
      "CHROMA_TENANT" = "default_tenant";
      "CODE_EXECUTION_API_KEY" = "dify-sandbox";
      "CODE_EXECUTION_CONNECT_TIMEOUT" = "10";
      "CODE_EXECUTION_ENDPOINT" = "http://sandbox:8194";
      "CODE_EXECUTION_READ_TIMEOUT" = "60";
      "CODE_EXECUTION_WRITE_TIMEOUT" = "10";
      "CODE_GENERATION_MAX_TOKENS" = "1024";
      "CODE_MAX_DEPTH" = "5";
      "CODE_MAX_NUMBER" = "9223372036854775807";
      "CODE_MAX_NUMBER_ARRAY_LENGTH" = "1000";
      "CODE_MAX_OBJECT_ARRAY_LENGTH" = "30";
      "CODE_MAX_PRECISION" = "20";
      "CODE_MAX_STRING_ARRAY_LENGTH" = "30";
      "CODE_MAX_STRING_LENGTH" = "80000";
      "CODE_MIN_NUMBER" = "-9223372036854775808";
      "CONSOLE_API_URL" = "";
      "CONSOLE_CORS_ALLOW_ORIGINS" = "*";
      "CONSOLE_WEB_URL" = "";
      "COUCHBASE_BUCKET_NAME" = "Embeddings";
      "COUCHBASE_CONNECTION_STRING" = "couchbase://couchbase-server";
      "COUCHBASE_PASSWORD" = "password";
      "COUCHBASE_SCOPE_NAME" = "_default";
      "COUCHBASE_USER" = "Administrator";
      "CREATE_TIDB_SERVICE_JOB_ENABLED" = "false";
      "CSP_WHITELIST" = "";
      "DB_DATABASE" = "dify_plugin";
      "DB_HOST" = "db";
      "DB_PASSWORD" = "difyai123456";
      "DB_PLUGIN_DATABASE" = "dify_plugin";
      "DB_PORT" = "5432";
      "DB_USERNAME" = "postgres";
      "DEBUG" = "false";
      "DEPLOY_ENV" = "PRODUCTION";
      "DIFY_BIND_ADDRESS" = "0.0.0.0";
      "DIFY_INNER_API_KEY" = "QaHbTe77CtuXmsfyhR7+vRjI/+XbV1AaFy691iy+kGDv2Jvy0/eAh8Y1";
      "DIFY_INNER_API_URL" = "http://api:5001";
      "DIFY_PORT" = "5001";
      "ELASTICSEARCH_HOST" = "0.0.0.0";
      "ELASTICSEARCH_PASSWORD" = "elastic";
      "ELASTICSEARCH_PORT" = "9200";
      "ELASTICSEARCH_USERNAME" = "elastic";
      "ENDPOINT_URL_TEMPLATE" = "http://localhost/e/{hook_id}";
      "ETCD_AUTO_COMPACTION_MODE" = "revision";
      "ETCD_AUTO_COMPACTION_RETENTION" = "1000";
      "ETCD_ENDPOINTS" = "etcd:2379";
      "ETCD_QUOTA_BACKEND_BYTES" = "4294967296";
      "ETCD_SNAPSHOT_COUNT" = "50000";
      "ETL_TYPE" = "dify";
      "EXPOSE_NGINX_PORT" = "8080";
      "EXPOSE_NGINX_SSL_PORT" = "8443";
      "EXPOSE_PLUGIN_DAEMON_PORT" = "5002";
      "EXPOSE_PLUGIN_DEBUGGING_HOST" = "localhost";
      "EXPOSE_PLUGIN_DEBUGGING_PORT" = "5003";
      "FILES_ACCESS_TIMEOUT" = "300";
      "FILES_URL" = "";
      "FLASK_DEBUG" = "false";
      "FORCE_VERIFYING_SIGNATURE" = "true";
      "GOOGLE_STORAGE_BUCKET_NAME" = "your-bucket-name";
      "GOOGLE_STORAGE_SERVICE_ACCOUNT_JSON_BASE64" = "";
      "GUNICORN_TIMEOUT" = "360";
      "HTTP_REQUEST_NODE_MAX_BINARY_SIZE" = "10485760";
      "HTTP_REQUEST_NODE_MAX_TEXT_SIZE" = "1048576";
      "HTTP_REQUEST_NODE_SSL_VERIFY" = "True";
      "HUAWEI_OBS_ACCESS_KEY" = "your-access-key";
      "HUAWEI_OBS_BUCKET_NAME" = "your-bucket-name";
      "HUAWEI_OBS_SECRET_KEY" = "your-secret-key";
      "HUAWEI_OBS_SERVER" = "your-server-url";
      "INDEXING_MAX_SEGMENTATION_TOKENS_LENGTH" = "4000";
      "INIT_PASSWORD" = "";
      "INVITE_EXPIRY_HOURS" = "72";
      "KIBANA_PORT" = "5601";
      "LINDORM_PASSWORD" = "lindorm";
      "LINDORM_URL" = "http://lindorm:30070";
      "LINDORM_USERNAME" = "lindorm";
      "LOG_DATEFORMAT" = "%Y-%m-%d %H:%M:%S";
      "LOG_FILE" = "/app/logs/server.log";
      "LOG_FILE_BACKUP_COUNT" = "5";
      "LOG_FILE_MAX_SIZE" = "20";
      "LOG_LEVEL" = "INFO";
      "LOG_TZ" = "UTC";
      "LOOP_NODE_MAX_COUNT" = "100";
      "MAIL_DEFAULT_SEND_FROM" = "";
      "MAIL_TYPE" = "resend";
      "MARKETPLACE_API_URL" = "https://marketplace.dify.ai";
      "MARKETPLACE_ENABLED" = "true";
      "MAX_PLUGIN_PACKAGE_SIZE" = "52428800";
      "MAX_SUBMIT_COUNT" = "100";
      "MAX_TOOLS_NUM" = "10";
      "MAX_VARIABLE_SIZE" = "204800";
      "MIGRATION_ENABLED" = "true";
      "MILVUS_AUTHORIZATION_ENABLED" = "true";
      "MILVUS_ENABLE_HYBRID_SEARCH" = "False";
      "MILVUS_PASSWORD" = "";
      "MILVUS_TOKEN" = "";
      "MILVUS_URI" = "http://host.docker.internal:19530";
      "MILVUS_USER" = "";
      "MINIO_ACCESS_KEY" = "minioadmin";
      "MINIO_ADDRESS" = "minio:9000";
      "MINIO_SECRET_KEY" = "minioadmin";
      "MULTIMODAL_SEND_FORMAT" = "base64";
      "MYSCALE_DATABASE" = "dify";
      "MYSCALE_FTS_PARAMS" = "";
      "MYSCALE_HOST" = "myscale";
      "MYSCALE_PASSWORD" = "";
      "MYSCALE_PORT" = "8123";
      "MYSCALE_USER" = "default";
      "NGINX_CLIENT_MAX_BODY_SIZE" = "15M";
      "NGINX_ENABLE_CERTBOT_CHALLENGE" = "false";
      "NGINX_HTTPS_ENABLED" = "false";
      "NGINX_KEEPALIVE_TIMEOUT" = "65";
      "NGINX_PORT" = "80";
      "NGINX_PROXY_READ_TIMEOUT" = "3600s";
      "NGINX_PROXY_SEND_TIMEOUT" = "3600s";
      "NGINX_SERVER_NAME" = "_";
      "NGINX_SSL_CERT_FILENAME" = "dify.crt";
      "NGINX_SSL_CERT_KEY_FILENAME" = "dify.key";
      "NGINX_SSL_PORT" = "443";
      "NGINX_SSL_PROTOCOLS" = "TLSv1.1 TLSv1.2 TLSv1.3";
      "NGINX_WORKER_PROCESSES" = "auto";
      "NOTION_CLIENT_ID" = "";
      "NOTION_CLIENT_SECRET" = "";
      "NOTION_INTEGRATION_TYPE" = "public";
      "NOTION_INTERNAL_SECRET" = "";
      "OCEANBASE_CLUSTER_NAME" = "difyai";
      "OCEANBASE_MEMORY_LIMIT" = "6G";
      "OCEANBASE_VECTOR_DATABASE" = "test";
      "OCEANBASE_VECTOR_HOST" = "oceanbase";
      "OCEANBASE_VECTOR_PASSWORD" = "difyai123456";
      "OCEANBASE_VECTOR_PORT" = "2881";
      "OCEANBASE_VECTOR_USER" = "root@test";
      "OCI_ACCESS_KEY" = "your-access-key";
      "OCI_BUCKET_NAME" = "your-bucket-name";
      "OCI_ENDPOINT" = "https://your-object-storage-namespace.compat.objectstorage.us-ashburn-1.oraclecloud.com";
      "OCI_REGION" = "us-ashburn-1";
      "OCI_SECRET_KEY" = "your-secret-key";
      "OPENAI_API_BASE" = "https://api.openai.com/v1";
      "OPENDAL_FS_ROOT" = "storage";
      "OPENDAL_SCHEME" = "fs";
      "OPENSEARCH_BOOTSTRAP_MEMORY_LOCK" = "true";
      "OPENSEARCH_DISCOVERY_TYPE" = "single-node";
      "OPENSEARCH_HOST" = "opensearch";
      "OPENSEARCH_INITIAL_ADMIN_PASSWORD" = "Qazwsxedc!@#123";
      "OPENSEARCH_JAVA_OPTS_MAX" = "1024m";
      "OPENSEARCH_JAVA_OPTS_MIN" = "512m";
      "OPENSEARCH_MEMLOCK_HARD" = "-1";
      "OPENSEARCH_MEMLOCK_SOFT" = "-1";
      "OPENSEARCH_NOFILE_HARD" = "65536";
      "OPENSEARCH_NOFILE_SOFT" = "65536";
      "OPENSEARCH_PASSWORD" = "admin";
      "OPENSEARCH_PORT" = "9200";
      "OPENSEARCH_SECURE" = "true";
      "OPENSEARCH_USER" = "admin";
      "ORACLE_CHARACTERSET" = "AL32UTF8";
      "ORACLE_CONFIG_DIR" = "/app/api/storage/wallet";
      "ORACLE_DSN" = "oracle:1521/FREEPDB1";
      "ORACLE_IS_AUTONOMOUS" = "false";
      "ORACLE_PASSWORD" = "dify";
      "ORACLE_PWD" = "Dify123456";
      "ORACLE_USER" = "dify";
      "ORACLE_WALLET_LOCATION" = "/app/api/storage/wallet";
      "ORACLE_WALLET_PASSWORD" = "dify";
      "PGDATA" = "/var/lib/postgresql/data/pgdata";
      "PGUSER" = "postgres";
      "PGVECTOR_DATABASE" = "dify";
      "PGVECTOR_HOST" = "pgvector";
      "PGVECTOR_MAX_CONNECTION" = "5";
      "PGVECTOR_MIN_CONNECTION" = "1";
      "PGVECTOR_PASSWORD" = "difyai123456";
      "PGVECTOR_PGDATA" = "/var/lib/postgresql/data/pgdata";
      "PGVECTOR_PGUSER" = "postgres";
      "PGVECTOR_PG_BIGM" = "false";
      "PGVECTOR_PG_BIGM_VERSION" = "1.2-20240606";
      "PGVECTOR_PORT" = "5432";
      "PGVECTOR_POSTGRES_DB" = "dify";
      "PGVECTOR_POSTGRES_PASSWORD" = "difyai123456";
      "PGVECTOR_USER" = "postgres";
      "PGVECTO_RS_DATABASE" = "dify";
      "PGVECTO_RS_HOST" = "pgvecto-rs";
      "PGVECTO_RS_PASSWORD" = "difyai123456";
      "PGVECTO_RS_PORT" = "5432";
      "PGVECTO_RS_USER" = "postgres";
      "PIP_MIRROR_URL" = "";
      "PLUGIN_DAEMON_KEY" = "lYkiYYT6owG+71oLerGzA7GXCgOT++6ovaezWAjpCjf+Sjc3ZtU+qUEi";
      "PLUGIN_DAEMON_PORT" = "5002";
      "PLUGIN_DAEMON_URL" = "http://plugin_daemon:5002";
      "PLUGIN_DEBUGGING_HOST" = "0.0.0.0";
      "PLUGIN_DEBUGGING_PORT" = "5003";
      "PLUGIN_DIFY_INNER_API_KEY" = "QaHbTe77CtuXmsfyhR7+vRjI/+XbV1AaFy691iy+kGDv2Jvy0/eAh8Y1";
      "PLUGIN_DIFY_INNER_API_URL" = "http://api:5001";
      "PLUGIN_MAX_EXECUTION_TIMEOUT" = "600";
      "PLUGIN_MAX_PACKAGE_SIZE" = "52428800";
      "PLUGIN_PPROF_ENABLED" = "false";
      "PLUGIN_PYTHON_ENV_INIT_TIMEOUT" = "120";
      "PLUGIN_REMOTE_INSTALLING_HOST" = "0.0.0.0";
      "PLUGIN_REMOTE_INSTALLING_PORT" = "5003";
      "PLUGIN_WORKING_PATH" = "/app/storage/cwd";
      "POSITION_PROVIDER_EXCLUDES" = "";
      "POSITION_PROVIDER_INCLUDES" = "";
      "POSITION_PROVIDER_PINS" = "";
      "POSITION_TOOL_EXCLUDES" = "";
      "POSITION_TOOL_INCLUDES" = "";
      "POSITION_TOOL_PINS" = "";
      "POSTGRES_DB" = "dify";
      "POSTGRES_EFFECTIVE_CACHE_SIZE" = "4096MB";
      "POSTGRES_MAINTENANCE_WORK_MEM" = "64MB";
      "POSTGRES_MAX_CONNECTIONS" = "100";
      "POSTGRES_PASSWORD" = "difyai123456";
      "POSTGRES_SHARED_BUFFERS" = "128MB";
      "POSTGRES_WORK_MEM" = "4MB";
      "PPROF_ENABLED" = "false";
      "PROMPT_GENERATION_MAX_TOKENS" = "512";
      "PYTHON_ENV_INIT_TIMEOUT" = "120";
      "QDRANT_API_KEY" = "difyai123456";
      "QDRANT_CLIENT_TIMEOUT" = "20";
      "QDRANT_GRPC_ENABLED" = "false";
      "QDRANT_GRPC_PORT" = "6334";
      "QDRANT_URL" = "http://qdrant:6333";
      "REDIS_CLUSTERS" = "";
      "REDIS_CLUSTERS_PASSWORD" = "";
      "REDIS_DB" = "0";
      "REDIS_HOST" = "redis";
      "REDIS_PASSWORD" = "difyai123456";
      "REDIS_PORT" = "6379";
      "REDIS_SENTINELS" = "";
      "REDIS_SENTINEL_PASSWORD" = "";
      "REDIS_SENTINEL_SERVICE_NAME" = "";
      "REDIS_SENTINEL_SOCKET_TIMEOUT" = "0.1";
      "REDIS_SENTINEL_USERNAME" = "";
      "REDIS_USERNAME" = "";
      "REDIS_USE_CLUSTERS" = "false";
      "REDIS_USE_SENTINEL" = "false";
      "REDIS_USE_SSL" = "false";
      "REFRESH_TOKEN_EXPIRE_DAYS" = "30";
      "RELYT_DATABASE" = "postgres";
      "RELYT_HOST" = "db";
      "RELYT_PASSWORD" = "difyai123456";
      "RELYT_PORT" = "5432";
      "RELYT_USER" = "postgres";
      "RESEND_API_KEY" = "your-resend-api-key";
      "RESEND_API_URL" = "https://api.resend.com";
      "RESET_PASSWORD_TOKEN_EXPIRY_MINUTES" = "5";
      "S3_ACCESS_KEY" = "";
      "S3_BUCKET_NAME" = "difyai";
      "S3_ENDPOINT" = "";
      "S3_REGION" = "us-east-1";
      "S3_SECRET_KEY" = "";
      "S3_USE_AWS_MANAGED_IAM" = "false";
      "SANDBOX_API_KEY" = "dify-sandbox";
      "SANDBOX_ENABLE_NETWORK" = "true";
      "SANDBOX_GIN_MODE" = "release";
      "SANDBOX_HTTPS_PROXY" = "http://ssrf_proxy:3128";
      "SANDBOX_HTTP_PROXY" = "http://ssrf_proxy:3128";
      "SANDBOX_PORT" = "8194";
      "SANDBOX_WORKER_TIMEOUT" = "15";
      "SCARF_NO_ANALYTICS" = "true";
      "SECRET_KEY" = "sk-9f73s3ljTXVcMT3Blb3ljTqtsKiGHXVcMT3BlbkFJLK7U";
      "SENTRY_DSN" = "";
      "SERVER_KEY" = "lYkiYYT6owG+71oLerGzA7GXCgOT++6ovaezWAjpCjf+Sjc3ZtU+qUEi";
      "SERVER_PORT" = "5002";
      "SERVER_WORKER_AMOUNT" = "1";
      "SERVER_WORKER_CLASS" = "gevent";
      "SERVER_WORKER_CONNECTIONS" = "10";
      "SERVICE_API_URL" = "";
      "SMTP_OPPORTUNISTIC_TLS" = "false";
      "SMTP_PASSWORD" = "";
      "SMTP_PORT" = "465";
      "SMTP_SERVER" = "";
      "SMTP_USERNAME" = "";
      "SMTP_USE_TLS" = "true";
      "SQLALCHEMY_ECHO" = "false";
      "SQLALCHEMY_POOL_RECYCLE" = "3600";
      "SQLALCHEMY_POOL_SIZE" = "30";
      "SSRF_COREDUMP_DIR" = "/var/spool/squid";
      "SSRF_DEFAULT_CONNECT_TIME_OUT" = "5";
      "SSRF_DEFAULT_READ_TIME_OUT" = "5";
      "SSRF_DEFAULT_TIME_OUT" = "5";
      "SSRF_DEFAULT_WRITE_TIME_OUT" = "5";
      "SSRF_HTTP_PORT" = "3128";
      "SSRF_PROXY_HTTPS_URL" = "http://ssrf_proxy:3128";
      "SSRF_PROXY_HTTP_URL" = "http://ssrf_proxy:3128";
      "SSRF_REVERSE_PROXY_PORT" = "8194";
      "SSRF_SANDBOX_HOST" = "sandbox";
      "STORAGE_TYPE" = "opendal";
      "SUPABASE_API_KEY" = "your-access-key";
      "SUPABASE_BUCKET_NAME" = "your-bucket-name";
      "SUPABASE_URL" = "your-server-url";
      "TEMPLATE_TRANSFORM_MAX_LENGTH" = "80000";
      "TENCENT_COS_BUCKET_NAME" = "your-bucket-name";
      "TENCENT_COS_REGION" = "your-region";
      "TENCENT_COS_SCHEME" = "your-scheme";
      "TENCENT_COS_SECRET_ID" = "your-secret-id";
      "TENCENT_COS_SECRET_KEY" = "your-secret-key";
      "TENCENT_VECTOR_DB_API_KEY" = "dify";
      "TENCENT_VECTOR_DB_DATABASE" = "dify";
      "TENCENT_VECTOR_DB_REPLICAS" = "2";
      "TENCENT_VECTOR_DB_SHARD" = "1";
      "TENCENT_VECTOR_DB_TIMEOUT" = "30";
      "TENCENT_VECTOR_DB_URL" = "http://127.0.0.1";
      "TENCENT_VECTOR_DB_USERNAME" = "dify";
      "TEXT_GENERATION_TIMEOUT_MS" = "60000";
      "TIDB_API_URL" = "http://127.0.0.1";
      "TIDB_IAM_API_URL" = "http://127.0.0.1";
      "TIDB_ON_QDRANT_API_KEY" = "dify";
      "TIDB_ON_QDRANT_CLIENT_TIMEOUT" = "20";
      "TIDB_ON_QDRANT_GRPC_ENABLED" = "false";
      "TIDB_ON_QDRANT_GRPC_PORT" = "6334";
      "TIDB_ON_QDRANT_URL" = "http://127.0.0.1";
      "TIDB_PRIVATE_KEY" = "dify";
      "TIDB_PROJECT_ID" = "dify";
      "TIDB_PUBLIC_KEY" = "dify";
      "TIDB_REGION" = "regions/aws-us-east-1";
      "TIDB_SPEND_LIMIT" = "100";
      "TIDB_VECTOR_DATABASE" = "dify";
      "TIDB_VECTOR_HOST" = "tidb";
      "TIDB_VECTOR_PASSWORD" = "";
      "TIDB_VECTOR_PORT" = "4000";
      "TIDB_VECTOR_USER" = "";
      "TOP_K_MAX_VALUE" = "10";
      "UNSTRUCTURED_API_KEY" = "";
      "UNSTRUCTURED_API_URL" = "";
      "UPLOAD_AUDIO_FILE_SIZE_LIMIT" = "50";
      "UPLOAD_FILE_BATCH_LIMIT" = "5";
      "UPLOAD_FILE_SIZE_LIMIT" = "15";
      "UPLOAD_IMAGE_FILE_SIZE_LIMIT" = "10";
      "UPLOAD_VIDEO_FILE_SIZE_LIMIT" = "100";
      "UPSTASH_VECTOR_TOKEN" = "dify";
      "UPSTASH_VECTOR_URL" = "https://xxx-vector.upstash.io";
      "VECTOR_STORE" = "weaviate";
      "VIKINGDB_ACCESS_KEY" = "your-ak";
      "VIKINGDB_CONNECTION_TIMEOUT" = "30";
      "VIKINGDB_HOST" = "api-vikingdb.xxx.volces.com";
      "VIKINGDB_REGION" = "cn-shanghai";
      "VIKINGDB_SCHEMA" = "http";
      "VIKINGDB_SECRET_KEY" = "your-sk";
      "VIKINGDB_SOCKET_TIMEOUT" = "30";
      "VOLCENGINE_TOS_ACCESS_KEY" = "your-access-key";
      "VOLCENGINE_TOS_BUCKET_NAME" = "your-bucket-name";
      "VOLCENGINE_TOS_ENDPOINT" = "your-server-url";
      "VOLCENGINE_TOS_REGION" = "your-region";
      "VOLCENGINE_TOS_SECRET_KEY" = "your-secret-key";
      "WEAVIATE_API_KEY" = "WVF5YThaHlkYwhGUSmCRgsX3tD5ngdN8pkih";
      "WEAVIATE_AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED" = "true";
      "WEAVIATE_AUTHENTICATION_APIKEY_ALLOWED_KEYS" = "WVF5YThaHlkYwhGUSmCRgsX3tD5ngdN8pkih";
      "WEAVIATE_AUTHENTICATION_APIKEY_ENABLED" = "true";
      "WEAVIATE_AUTHENTICATION_APIKEY_USERS" = "hello@dify.ai";
      "WEAVIATE_AUTHORIZATION_ADMINLIST_ENABLED" = "true";
      "WEAVIATE_AUTHORIZATION_ADMINLIST_USERS" = "hello@dify.ai";
      "WEAVIATE_CLUSTER_HOSTNAME" = "node1";
      "WEAVIATE_DEFAULT_VECTORIZER_MODULE" = "none";
      "WEAVIATE_ENDPOINT" = "http://weaviate:8080";
      "WEAVIATE_PERSISTENCE_DATA_PATH" = "/var/lib/weaviate";
      "WEAVIATE_QUERY_DEFAULTS_LIMIT" = "25";
      "WEB_API_CORS_ALLOW_ORIGINS" = "*";
      "WEB_SENTRY_DSN" = "";
      "WORKFLOW_CALL_MAX_DEPTH" = "5";
      "WORKFLOW_FILE_UPLOAD_LIMIT" = "10";
      "WORKFLOW_MAX_EXECUTION_STEPS" = "500";
      "WORKFLOW_MAX_EXECUTION_TIME" = "1200";
      "WORKFLOW_PARALLEL_DEPTH_LIMIT" = "3";
    };
    environmentFiles = [
      "/home/zshen/personal/nix-config/modules/nixos/features/dify/.env"
    ];
    volumes = [
      "/home/zshen/personal/nix-config/modules/nixos/features/dify/volumes/plugin_daemon:/app/storage:rw"
    ];
    ports = [
      "5003:5003/tcp"
    ];
    dependsOn = [
      "dify-db"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=plugin_daemon"
      "--network=dify_default"
    ];
  };
  systemd.services."podman-dify-plugin_daemon" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
    };
    after = [
      "podman-network-dify_default.service"
    ];
    requires = [
      "podman-network-dify_default.service"
    ];
    partOf = [
      "podman-compose-dify-root.target"
    ];
    wantedBy = [
      "podman-compose-dify-root.target"
    ];
  };
  virtualisation.oci-containers.containers."dify-redis" = {
    image = "redis:6-alpine";
    environment = {
      "REDISCLI_AUTH" = "difyai123456";
    };
    environmentFiles = [
      "/home/zshen/personal/nix-config/modules/nixos/features/dify/.env"
    ];
    volumes = [
      "/home/zshen/personal/nix-config/modules/nixos/features/dify/volumes/redis/data:/data:rw"
    ];
    cmd = ["redis-server" "--requirepass" "difyai123456"];
    log-driver = "journald";
    extraOptions = [
      "--health-cmd=[\"redis-cli\", \"ping\"]"
      "--network-alias=redis"
      "--network=dify_default"
    ];
  };
  systemd.services."podman-dify-redis" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
    };
    after = [
      "podman-network-dify_default.service"
    ];
    requires = [
      "podman-network-dify_default.service"
    ];
    partOf = [
      "podman-compose-dify-root.target"
    ];
    wantedBy = [
      "podman-compose-dify-root.target"
    ];
  };
  virtualisation.oci-containers.containers."dify-sandbox" = {
    image = "langgenius/dify-sandbox:0.2.10";
    environment = {
      "API_KEY" = "dify-sandbox";
      "ENABLE_NETWORK" = "true";
      "GIN_MODE" = "release";
      "HTTPS_PROXY" = "http://ssrf_proxy:3128";
      "HTTP_PROXY" = "http://ssrf_proxy:3128";
      "SANDBOX_PORT" = "8194";
      "WORKER_TIMEOUT" = "15";
    };
    environmentFiles = [
      "/home/zshen/personal/nix-config/modules/nixos/features/dify/.env"
    ];
    volumes = [
      "/home/zshen/personal/nix-config/modules/nixos/features/dify/volumes/sandbox/conf:/conf:rw"
      "/home/zshen/personal/nix-config/modules/nixos/features/dify/volumes/sandbox/dependencies:/dependencies:rw"
    ];
    log-driver = "journald";
    extraOptions = [
      "--health-cmd=[\"curl\", \"-f\", \"http://localhost:8194/health\"]"
      "--network-alias=sandbox"
      "--network=dify_ssrf_proxy_network"
    ];
  };
  systemd.services."podman-dify-sandbox" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
    };
    after = [
      "podman-network-dify_ssrf_proxy_network.service"
    ];
    requires = [
      "podman-network-dify_ssrf_proxy_network.service"
    ];
    partOf = [
      "podman-compose-dify-root.target"
    ];
    wantedBy = [
      "podman-compose-dify-root.target"
    ];
  };
  virtualisation.oci-containers.containers."dify-ssrf_proxy" = {
    image = "ubuntu/squid:latest";
    environment = {
      "COREDUMP_DIR" = "/var/spool/squid";
      "HTTP_PORT" = "3128";
      "REVERSE_PROXY_PORT" = "8194";
      "SANDBOX_HOST" = "sandbox";
      "SANDBOX_PORT" = "8194";
    };
    environmentFiles = [
      "/home/zshen/personal/nix-config/modules/nixos/features/dify/.env"
    ];
    volumes = [
      "/home/zshen/personal/nix-config/modules/nixos/features/dify/ssrf_proxy/docker-entrypoint.sh:/docker-entrypoint-mount.sh:rw"
      "/home/zshen/personal/nix-config/modules/nixos/features/dify/ssrf_proxy/squid.conf.template:/etc/squid/squid.conf.template:rw"
    ];
    log-driver = "journald";
    extraOptions = [
      "--entrypoint=[\"sh\", \"-c\", \"cp /docker-entrypoint-mount.sh /docker-entrypoint.sh && sed -i 's/$//' /docker-entrypoint.sh && chmod +x /docker-entrypoint.sh && /docker-entrypoint.sh\"]"
      "--network-alias=ssrf_proxy"
      "--network=dify_default"
      "--network=dify_ssrf_proxy_network"
    ];
  };
  systemd.services."podman-dify-ssrf_proxy" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
    };
    after = [
      "podman-network-dify_default.service"
      "podman-network-dify_ssrf_proxy_network.service"
    ];
    requires = [
      "podman-network-dify_default.service"
      "podman-network-dify_ssrf_proxy_network.service"
    ];
    partOf = [
      "podman-compose-dify-root.target"
    ];
    wantedBy = [
      "podman-compose-dify-root.target"
    ];
  };
  virtualisation.oci-containers.containers."dify-web" = {
    image = "langgenius/dify-web:1.0.1";
    environment = {
      "APP_API_URL" = "";
      "CONSOLE_API_URL" = "";
      "CSP_WHITELIST" = "";
      "INDEXING_MAX_SEGMENTATION_TOKENS_LENGTH" = "4000";
      "LOOP_NODE_MAX_COUNT" = "100";
      "MARKETPLACE_API_URL" = "https://marketplace.dify.ai";
      "MARKETPLACE_URL" = "https://marketplace.dify.ai";
      "MAX_TOOLS_NUM" = "10";
      "NEXT_TELEMETRY_DISABLED" = "0";
      "PM2_INSTANCES" = "2";
      "SENTRY_DSN" = "";
      "TEXT_GENERATION_TIMEOUT_MS" = "60000";
      "TOP_K_MAX_VALUE" = "10";
    };
    environmentFiles = [
      "/home/zshen/personal/nix-config/modules/nixos/features/dify/.env"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=web"
      "--network=dify_default"
    ];
  };
  systemd.services."podman-dify-web" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
    };
    after = [
      "podman-network-dify_default.service"
    ];
    requires = [
      "podman-network-dify_default.service"
    ];
    partOf = [
      "podman-compose-dify-root.target"
    ];
    wantedBy = [
      "podman-compose-dify-root.target"
    ];
  };
  virtualisation.oci-containers.containers."dify-worker" = {
    image = "langgenius/dify-api:1.0.1";
    environment = {
      "ACCESS_TOKEN_EXPIRE_MINUTES" = "60";
      "ALIYUN_OSS_ACCESS_KEY" = "your-access-key";
      "ALIYUN_OSS_AUTH_VERSION" = "v4";
      "ALIYUN_OSS_BUCKET_NAME" = "your-bucket-name";
      "ALIYUN_OSS_ENDPOINT" = "https://oss-ap-southeast-1-internal.aliyuncs.com";
      "ALIYUN_OSS_PATH" = "your-path";
      "ALIYUN_OSS_REGION" = "ap-southeast-1";
      "ALIYUN_OSS_SECRET_KEY" = "your-secret-key";
      "ANALYTICDB_ACCOUNT" = "testaccount";
      "ANALYTICDB_HOST" = "gp-test.aliyuncs.com";
      "ANALYTICDB_INSTANCE_ID" = "gp-ab123456";
      "ANALYTICDB_KEY_ID" = "your-ak";
      "ANALYTICDB_KEY_SECRET" = "your-sk";
      "ANALYTICDB_MAX_CONNECTION" = "5";
      "ANALYTICDB_MIN_CONNECTION" = "1";
      "ANALYTICDB_NAMESPACE" = "dify";
      "ANALYTICDB_NAMESPACE_PASSWORD" = "difypassword";
      "ANALYTICDB_PASSWORD" = "testpassword";
      "ANALYTICDB_PORT" = "5432";
      "ANALYTICDB_REGION_ID" = "cn-hangzhou";
      "API_SENTRY_DSN" = "";
      "API_SENTRY_PROFILES_SAMPLE_RATE" = "1.0";
      "API_SENTRY_TRACES_SAMPLE_RATE" = "1.0";
      "API_TOOL_DEFAULT_CONNECT_TIMEOUT" = "10";
      "API_TOOL_DEFAULT_READ_TIMEOUT" = "60";
      "APP_API_URL" = "";
      "APP_MAX_ACTIVE_REQUESTS" = "0";
      "APP_MAX_EXECUTION_TIME" = "1200";
      "APP_WEB_URL" = "";
      "AZURE_BLOB_ACCOUNT_KEY" = "difyai";
      "AZURE_BLOB_ACCOUNT_NAME" = "difyai";
      "AZURE_BLOB_ACCOUNT_URL" = "https:// <your_account_name >.blob.core.windows.net";
      "AZURE_BLOB_CONTAINER_NAME" = "difyai-container";
      "BAIDU_OBS_ACCESS_KEY" = "your-access-key";
      "BAIDU_OBS_BUCKET_NAME" = "your-bucket-name";
      "BAIDU_OBS_ENDPOINT" = "your-server-url";
      "BAIDU_OBS_SECRET_KEY" = "your-secret-key";
      "BAIDU_VECTOR_DB_ACCOUNT" = "root";
      "BAIDU_VECTOR_DB_API_KEY" = "dify";
      "BAIDU_VECTOR_DB_CONNECTION_TIMEOUT_MS" = "30000";
      "BAIDU_VECTOR_DB_DATABASE" = "dify";
      "BAIDU_VECTOR_DB_ENDPOINT" = "http://127.0.0.1:5287";
      "BAIDU_VECTOR_DB_REPLICAS" = "3";
      "BAIDU_VECTOR_DB_SHARD" = "1";
      "BROKER_USE_SSL" = "false";
      "CELERY_AUTO_SCALE" = "false";
      "CELERY_BROKER_URL" = "redis://:difyai123456@redis:6379/1";
      "CELERY_MAX_WORKERS" = "";
      "CELERY_MIN_WORKERS" = "";
      "CELERY_SENTINEL_MASTER_NAME" = "";
      "CELERY_SENTINEL_SOCKET_TIMEOUT" = "0.1";
      "CELERY_USE_SENTINEL" = "false";
      "CELERY_WORKER_AMOUNT" = "";
      "CELERY_WORKER_CLASS" = "";
      "CERTBOT_DOMAIN" = "your_domain.com";
      "CERTBOT_EMAIL" = "your_email@example.com";
      "CERTBOT_OPTIONS" = "";
      "CHECK_UPDATE_URL" = "https://updates.dify.ai";
      "CHROMA_AUTH_CREDENTIALS" = "";
      "CHROMA_AUTH_PROVIDER" = "chromadb.auth.token_authn.TokenAuthClientProvider";
      "CHROMA_DATABASE" = "default_database";
      "CHROMA_HOST" = "127.0.0.1";
      "CHROMA_IS_PERSISTENT" = "TRUE";
      "CHROMA_PORT" = "8000";
      "CHROMA_SERVER_AUTHN_CREDENTIALS" = "difyai123456";
      "CHROMA_SERVER_AUTHN_PROVIDER" = "chromadb.auth.token_authn.TokenAuthenticationServerProvider";
      "CHROMA_TENANT" = "default_tenant";
      "CODE_EXECUTION_API_KEY" = "dify-sandbox";
      "CODE_EXECUTION_CONNECT_TIMEOUT" = "10";
      "CODE_EXECUTION_ENDPOINT" = "http://sandbox:8194";
      "CODE_EXECUTION_READ_TIMEOUT" = "60";
      "CODE_EXECUTION_WRITE_TIMEOUT" = "10";
      "CODE_GENERATION_MAX_TOKENS" = "1024";
      "CODE_MAX_DEPTH" = "5";
      "CODE_MAX_NUMBER" = "9223372036854775807";
      "CODE_MAX_NUMBER_ARRAY_LENGTH" = "1000";
      "CODE_MAX_OBJECT_ARRAY_LENGTH" = "30";
      "CODE_MAX_PRECISION" = "20";
      "CODE_MAX_STRING_ARRAY_LENGTH" = "30";
      "CODE_MAX_STRING_LENGTH" = "80000";
      "CODE_MIN_NUMBER" = "-9223372036854775808";
      "CONSOLE_API_URL" = "";
      "CONSOLE_CORS_ALLOW_ORIGINS" = "*";
      "CONSOLE_WEB_URL" = "";
      "COUCHBASE_BUCKET_NAME" = "Embeddings";
      "COUCHBASE_CONNECTION_STRING" = "couchbase://couchbase-server";
      "COUCHBASE_PASSWORD" = "password";
      "COUCHBASE_SCOPE_NAME" = "_default";
      "COUCHBASE_USER" = "Administrator";
      "CREATE_TIDB_SERVICE_JOB_ENABLED" = "false";
      "CSP_WHITELIST" = "";
      "DB_DATABASE" = "dify";
      "DB_HOST" = "db";
      "DB_PASSWORD" = "difyai123456";
      "DB_PLUGIN_DATABASE" = "dify_plugin";
      "DB_PORT" = "5432";
      "DB_USERNAME" = "postgres";
      "DEBUG" = "false";
      "DEPLOY_ENV" = "PRODUCTION";
      "DIFY_BIND_ADDRESS" = "0.0.0.0";
      "DIFY_PORT" = "5001";
      "ELASTICSEARCH_HOST" = "0.0.0.0";
      "ELASTICSEARCH_PASSWORD" = "elastic";
      "ELASTICSEARCH_PORT" = "9200";
      "ELASTICSEARCH_USERNAME" = "elastic";
      "ENDPOINT_URL_TEMPLATE" = "http://localhost/e/{hook_id}";
      "ETCD_AUTO_COMPACTION_MODE" = "revision";
      "ETCD_AUTO_COMPACTION_RETENTION" = "1000";
      "ETCD_ENDPOINTS" = "etcd:2379";
      "ETCD_QUOTA_BACKEND_BYTES" = "4294967296";
      "ETCD_SNAPSHOT_COUNT" = "50000";
      "ETL_TYPE" = "dify";
      "EXPOSE_NGINX_PORT" = "8080";
      "EXPOSE_NGINX_SSL_PORT" = "8443";
      "EXPOSE_PLUGIN_DAEMON_PORT" = "5002";
      "EXPOSE_PLUGIN_DEBUGGING_HOST" = "localhost";
      "EXPOSE_PLUGIN_DEBUGGING_PORT" = "5003";
      "FILES_ACCESS_TIMEOUT" = "300";
      "FILES_URL" = "";
      "FLASK_DEBUG" = "false";
      "FORCE_VERIFYING_SIGNATURE" = "true";
      "GOOGLE_STORAGE_BUCKET_NAME" = "your-bucket-name";
      "GOOGLE_STORAGE_SERVICE_ACCOUNT_JSON_BASE64" = "";
      "GUNICORN_TIMEOUT" = "360";
      "HTTP_REQUEST_NODE_MAX_BINARY_SIZE" = "10485760";
      "HTTP_REQUEST_NODE_MAX_TEXT_SIZE" = "1048576";
      "HTTP_REQUEST_NODE_SSL_VERIFY" = "True";
      "HUAWEI_OBS_ACCESS_KEY" = "your-access-key";
      "HUAWEI_OBS_BUCKET_NAME" = "your-bucket-name";
      "HUAWEI_OBS_SECRET_KEY" = "your-secret-key";
      "HUAWEI_OBS_SERVER" = "your-server-url";
      "INDEXING_MAX_SEGMENTATION_TOKENS_LENGTH" = "4000";
      "INIT_PASSWORD" = "";
      "INNER_API_KEY_FOR_PLUGIN" = "QaHbTe77CtuXmsfyhR7+vRjI/+XbV1AaFy691iy+kGDv2Jvy0/eAh8Y1";
      "INVITE_EXPIRY_HOURS" = "72";
      "KIBANA_PORT" = "5601";
      "LINDORM_PASSWORD" = "lindorm";
      "LINDORM_URL" = "http://lindorm:30070";
      "LINDORM_USERNAME" = "lindorm";
      "LOG_DATEFORMAT" = "%Y-%m-%d %H:%M:%S";
      "LOG_FILE" = "/app/logs/server.log";
      "LOG_FILE_BACKUP_COUNT" = "5";
      "LOG_FILE_MAX_SIZE" = "20";
      "LOG_LEVEL" = "INFO";
      "LOG_TZ" = "UTC";
      "LOOP_NODE_MAX_COUNT" = "100";
      "MAIL_DEFAULT_SEND_FROM" = "";
      "MAIL_TYPE" = "resend";
      "MARKETPLACE_API_URL" = "https://marketplace.dify.ai";
      "MARKETPLACE_ENABLED" = "true";
      "MAX_SUBMIT_COUNT" = "100";
      "MAX_TOOLS_NUM" = "10";
      "MAX_VARIABLE_SIZE" = "204800";
      "MIGRATION_ENABLED" = "true";
      "MILVUS_AUTHORIZATION_ENABLED" = "true";
      "MILVUS_ENABLE_HYBRID_SEARCH" = "False";
      "MILVUS_PASSWORD" = "";
      "MILVUS_TOKEN" = "";
      "MILVUS_URI" = "http://host.docker.internal:19530";
      "MILVUS_USER" = "";
      "MINIO_ACCESS_KEY" = "minioadmin";
      "MINIO_ADDRESS" = "minio:9000";
      "MINIO_SECRET_KEY" = "minioadmin";
      "MODE" = "worker";
      "MULTIMODAL_SEND_FORMAT" = "base64";
      "MYSCALE_DATABASE" = "dify";
      "MYSCALE_FTS_PARAMS" = "";
      "MYSCALE_HOST" = "myscale";
      "MYSCALE_PASSWORD" = "";
      "MYSCALE_PORT" = "8123";
      "MYSCALE_USER" = "default";
      "NGINX_CLIENT_MAX_BODY_SIZE" = "15M";
      "NGINX_ENABLE_CERTBOT_CHALLENGE" = "false";
      "NGINX_HTTPS_ENABLED" = "false";
      "NGINX_KEEPALIVE_TIMEOUT" = "65";
      "NGINX_PORT" = "80";
      "NGINX_PROXY_READ_TIMEOUT" = "3600s";
      "NGINX_PROXY_SEND_TIMEOUT" = "3600s";
      "NGINX_SERVER_NAME" = "_";
      "NGINX_SSL_CERT_FILENAME" = "dify.crt";
      "NGINX_SSL_CERT_KEY_FILENAME" = "dify.key";
      "NGINX_SSL_PORT" = "443";
      "NGINX_SSL_PROTOCOLS" = "TLSv1.1 TLSv1.2 TLSv1.3";
      "NGINX_WORKER_PROCESSES" = "auto";
      "NOTION_CLIENT_ID" = "";
      "NOTION_CLIENT_SECRET" = "";
      "NOTION_INTEGRATION_TYPE" = "public";
      "NOTION_INTERNAL_SECRET" = "";
      "OCEANBASE_CLUSTER_NAME" = "difyai";
      "OCEANBASE_MEMORY_LIMIT" = "6G";
      "OCEANBASE_VECTOR_DATABASE" = "test";
      "OCEANBASE_VECTOR_HOST" = "oceanbase";
      "OCEANBASE_VECTOR_PASSWORD" = "difyai123456";
      "OCEANBASE_VECTOR_PORT" = "2881";
      "OCEANBASE_VECTOR_USER" = "root@test";
      "OCI_ACCESS_KEY" = "your-access-key";
      "OCI_BUCKET_NAME" = "your-bucket-name";
      "OCI_ENDPOINT" = "https://your-object-storage-namespace.compat.objectstorage.us-ashburn-1.oraclecloud.com";
      "OCI_REGION" = "us-ashburn-1";
      "OCI_SECRET_KEY" = "your-secret-key";
      "OPENAI_API_BASE" = "https://api.openai.com/v1";
      "OPENDAL_FS_ROOT" = "storage";
      "OPENDAL_SCHEME" = "fs";
      "OPENSEARCH_BOOTSTRAP_MEMORY_LOCK" = "true";
      "OPENSEARCH_DISCOVERY_TYPE" = "single-node";
      "OPENSEARCH_HOST" = "opensearch";
      "OPENSEARCH_INITIAL_ADMIN_PASSWORD" = "Qazwsxedc!@#123";
      "OPENSEARCH_JAVA_OPTS_MAX" = "1024m";
      "OPENSEARCH_JAVA_OPTS_MIN" = "512m";
      "OPENSEARCH_MEMLOCK_HARD" = "-1";
      "OPENSEARCH_MEMLOCK_SOFT" = "-1";
      "OPENSEARCH_NOFILE_HARD" = "65536";
      "OPENSEARCH_NOFILE_SOFT" = "65536";
      "OPENSEARCH_PASSWORD" = "admin";
      "OPENSEARCH_PORT" = "9200";
      "OPENSEARCH_SECURE" = "true";
      "OPENSEARCH_USER" = "admin";
      "ORACLE_CHARACTERSET" = "AL32UTF8";
      "ORACLE_CONFIG_DIR" = "/app/api/storage/wallet";
      "ORACLE_DSN" = "oracle:1521/FREEPDB1";
      "ORACLE_IS_AUTONOMOUS" = "false";
      "ORACLE_PASSWORD" = "dify";
      "ORACLE_PWD" = "Dify123456";
      "ORACLE_USER" = "dify";
      "ORACLE_WALLET_LOCATION" = "/app/api/storage/wallet";
      "ORACLE_WALLET_PASSWORD" = "dify";
      "PGDATA" = "/var/lib/postgresql/data/pgdata";
      "PGUSER" = "postgres";
      "PGVECTOR_DATABASE" = "dify";
      "PGVECTOR_HOST" = "pgvector";
      "PGVECTOR_MAX_CONNECTION" = "5";
      "PGVECTOR_MIN_CONNECTION" = "1";
      "PGVECTOR_PASSWORD" = "difyai123456";
      "PGVECTOR_PGDATA" = "/var/lib/postgresql/data/pgdata";
      "PGVECTOR_PGUSER" = "postgres";
      "PGVECTOR_PG_BIGM" = "false";
      "PGVECTOR_PG_BIGM_VERSION" = "1.2-20240606";
      "PGVECTOR_PORT" = "5432";
      "PGVECTOR_POSTGRES_DB" = "dify";
      "PGVECTOR_POSTGRES_PASSWORD" = "difyai123456";
      "PGVECTOR_USER" = "postgres";
      "PGVECTO_RS_DATABASE" = "dify";
      "PGVECTO_RS_HOST" = "pgvecto-rs";
      "PGVECTO_RS_PASSWORD" = "difyai123456";
      "PGVECTO_RS_PORT" = "5432";
      "PGVECTO_RS_USER" = "postgres";
      "PIP_MIRROR_URL" = "";
      "PLUGIN_DAEMON_KEY" = "lYkiYYT6owG+71oLerGzA7GXCgOT++6ovaezWAjpCjf+Sjc3ZtU+qUEi";
      "PLUGIN_DAEMON_PORT" = "5002";
      "PLUGIN_DAEMON_URL" = "http://plugin_daemon:5002";
      "PLUGIN_DEBUGGING_HOST" = "0.0.0.0";
      "PLUGIN_DEBUGGING_PORT" = "5003";
      "PLUGIN_DIFY_INNER_API_KEY" = "QaHbTe77CtuXmsfyhR7+vRjI/+XbV1AaFy691iy+kGDv2Jvy0/eAh8Y1";
      "PLUGIN_DIFY_INNER_API_URL" = "http://api:5001";
      "PLUGIN_MAX_EXECUTION_TIMEOUT" = "600";
      "PLUGIN_MAX_PACKAGE_SIZE" = "52428800";
      "PLUGIN_PPROF_ENABLED" = "false";
      "PLUGIN_PYTHON_ENV_INIT_TIMEOUT" = "120";
      "POSITION_PROVIDER_EXCLUDES" = "";
      "POSITION_PROVIDER_INCLUDES" = "";
      "POSITION_PROVIDER_PINS" = "";
      "POSITION_TOOL_EXCLUDES" = "";
      "POSITION_TOOL_INCLUDES" = "";
      "POSITION_TOOL_PINS" = "";
      "POSTGRES_DB" = "dify";
      "POSTGRES_EFFECTIVE_CACHE_SIZE" = "4096MB";
      "POSTGRES_MAINTENANCE_WORK_MEM" = "64MB";
      "POSTGRES_MAX_CONNECTIONS" = "100";
      "POSTGRES_PASSWORD" = "difyai123456";
      "POSTGRES_SHARED_BUFFERS" = "128MB";
      "POSTGRES_WORK_MEM" = "4MB";
      "PROMPT_GENERATION_MAX_TOKENS" = "512";
      "QDRANT_API_KEY" = "difyai123456";
      "QDRANT_CLIENT_TIMEOUT" = "20";
      "QDRANT_GRPC_ENABLED" = "false";
      "QDRANT_GRPC_PORT" = "6334";
      "QDRANT_URL" = "http://qdrant:6333";
      "REDIS_CLUSTERS" = "";
      "REDIS_CLUSTERS_PASSWORD" = "";
      "REDIS_DB" = "0";
      "REDIS_HOST" = "redis";
      "REDIS_PASSWORD" = "difyai123456";
      "REDIS_PORT" = "6379";
      "REDIS_SENTINELS" = "";
      "REDIS_SENTINEL_PASSWORD" = "";
      "REDIS_SENTINEL_SERVICE_NAME" = "";
      "REDIS_SENTINEL_SOCKET_TIMEOUT" = "0.1";
      "REDIS_SENTINEL_USERNAME" = "";
      "REDIS_USERNAME" = "";
      "REDIS_USE_CLUSTERS" = "false";
      "REDIS_USE_SENTINEL" = "false";
      "REDIS_USE_SSL" = "false";
      "REFRESH_TOKEN_EXPIRE_DAYS" = "30";
      "RELYT_DATABASE" = "postgres";
      "RELYT_HOST" = "db";
      "RELYT_PASSWORD" = "difyai123456";
      "RELYT_PORT" = "5432";
      "RELYT_USER" = "postgres";
      "RESEND_API_KEY" = "your-resend-api-key";
      "RESEND_API_URL" = "https://api.resend.com";
      "RESET_PASSWORD_TOKEN_EXPIRY_MINUTES" = "5";
      "S3_ACCESS_KEY" = "";
      "S3_BUCKET_NAME" = "difyai";
      "S3_ENDPOINT" = "";
      "S3_REGION" = "us-east-1";
      "S3_SECRET_KEY" = "";
      "S3_USE_AWS_MANAGED_IAM" = "false";
      "SANDBOX_API_KEY" = "dify-sandbox";
      "SANDBOX_ENABLE_NETWORK" = "true";
      "SANDBOX_GIN_MODE" = "release";
      "SANDBOX_HTTPS_PROXY" = "http://ssrf_proxy:3128";
      "SANDBOX_HTTP_PROXY" = "http://ssrf_proxy:3128";
      "SANDBOX_PORT" = "8194";
      "SANDBOX_WORKER_TIMEOUT" = "15";
      "SCARF_NO_ANALYTICS" = "true";
      "SECRET_KEY" = "sk-9f73s3ljTXVcMT3Blb3ljTqtsKiGHXVcMT3BlbkFJLK7U";
      "SENTRY_DSN" = "";
      "SENTRY_PROFILES_SAMPLE_RATE" = "1.0";
      "SENTRY_TRACES_SAMPLE_RATE" = "1.0";
      "SERVER_WORKER_AMOUNT" = "1";
      "SERVER_WORKER_CLASS" = "gevent";
      "SERVER_WORKER_CONNECTIONS" = "10";
      "SERVICE_API_URL" = "";
      "SMTP_OPPORTUNISTIC_TLS" = "false";
      "SMTP_PASSWORD" = "";
      "SMTP_PORT" = "465";
      "SMTP_SERVER" = "";
      "SMTP_USERNAME" = "";
      "SMTP_USE_TLS" = "true";
      "SQLALCHEMY_ECHO" = "false";
      "SQLALCHEMY_POOL_RECYCLE" = "3600";
      "SQLALCHEMY_POOL_SIZE" = "30";
      "SSRF_COREDUMP_DIR" = "/var/spool/squid";
      "SSRF_DEFAULT_CONNECT_TIME_OUT" = "5";
      "SSRF_DEFAULT_READ_TIME_OUT" = "5";
      "SSRF_DEFAULT_TIME_OUT" = "5";
      "SSRF_DEFAULT_WRITE_TIME_OUT" = "5";
      "SSRF_HTTP_PORT" = "3128";
      "SSRF_PROXY_HTTPS_URL" = "http://ssrf_proxy:3128";
      "SSRF_PROXY_HTTP_URL" = "http://ssrf_proxy:3128";
      "SSRF_REVERSE_PROXY_PORT" = "8194";
      "SSRF_SANDBOX_HOST" = "sandbox";
      "STORAGE_TYPE" = "opendal";
      "SUPABASE_API_KEY" = "your-access-key";
      "SUPABASE_BUCKET_NAME" = "your-bucket-name";
      "SUPABASE_URL" = "your-server-url";
      "TEMPLATE_TRANSFORM_MAX_LENGTH" = "80000";
      "TENCENT_COS_BUCKET_NAME" = "your-bucket-name";
      "TENCENT_COS_REGION" = "your-region";
      "TENCENT_COS_SCHEME" = "your-scheme";
      "TENCENT_COS_SECRET_ID" = "your-secret-id";
      "TENCENT_COS_SECRET_KEY" = "your-secret-key";
      "TENCENT_VECTOR_DB_API_KEY" = "dify";
      "TENCENT_VECTOR_DB_DATABASE" = "dify";
      "TENCENT_VECTOR_DB_REPLICAS" = "2";
      "TENCENT_VECTOR_DB_SHARD" = "1";
      "TENCENT_VECTOR_DB_TIMEOUT" = "30";
      "TENCENT_VECTOR_DB_URL" = "http://127.0.0.1";
      "TENCENT_VECTOR_DB_USERNAME" = "dify";
      "TEXT_GENERATION_TIMEOUT_MS" = "60000";
      "TIDB_API_URL" = "http://127.0.0.1";
      "TIDB_IAM_API_URL" = "http://127.0.0.1";
      "TIDB_ON_QDRANT_API_KEY" = "dify";
      "TIDB_ON_QDRANT_CLIENT_TIMEOUT" = "20";
      "TIDB_ON_QDRANT_GRPC_ENABLED" = "false";
      "TIDB_ON_QDRANT_GRPC_PORT" = "6334";
      "TIDB_ON_QDRANT_URL" = "http://127.0.0.1";
      "TIDB_PRIVATE_KEY" = "dify";
      "TIDB_PROJECT_ID" = "dify";
      "TIDB_PUBLIC_KEY" = "dify";
      "TIDB_REGION" = "regions/aws-us-east-1";
      "TIDB_SPEND_LIMIT" = "100";
      "TIDB_VECTOR_DATABASE" = "dify";
      "TIDB_VECTOR_HOST" = "tidb";
      "TIDB_VECTOR_PASSWORD" = "";
      "TIDB_VECTOR_PORT" = "4000";
      "TIDB_VECTOR_USER" = "";
      "TOP_K_MAX_VALUE" = "10";
      "UNSTRUCTURED_API_KEY" = "";
      "UNSTRUCTURED_API_URL" = "";
      "UPLOAD_AUDIO_FILE_SIZE_LIMIT" = "50";
      "UPLOAD_FILE_BATCH_LIMIT" = "5";
      "UPLOAD_FILE_SIZE_LIMIT" = "15";
      "UPLOAD_IMAGE_FILE_SIZE_LIMIT" = "10";
      "UPLOAD_VIDEO_FILE_SIZE_LIMIT" = "100";
      "UPSTASH_VECTOR_TOKEN" = "dify";
      "UPSTASH_VECTOR_URL" = "https://xxx-vector.upstash.io";
      "VECTOR_STORE" = "weaviate";
      "VIKINGDB_ACCESS_KEY" = "your-ak";
      "VIKINGDB_CONNECTION_TIMEOUT" = "30";
      "VIKINGDB_HOST" = "api-vikingdb.xxx.volces.com";
      "VIKINGDB_REGION" = "cn-shanghai";
      "VIKINGDB_SCHEMA" = "http";
      "VIKINGDB_SECRET_KEY" = "your-sk";
      "VIKINGDB_SOCKET_TIMEOUT" = "30";
      "VOLCENGINE_TOS_ACCESS_KEY" = "your-access-key";
      "VOLCENGINE_TOS_BUCKET_NAME" = "your-bucket-name";
      "VOLCENGINE_TOS_ENDPOINT" = "your-server-url";
      "VOLCENGINE_TOS_REGION" = "your-region";
      "VOLCENGINE_TOS_SECRET_KEY" = "your-secret-key";
      "WEAVIATE_API_KEY" = "WVF5YThaHlkYwhGUSmCRgsX3tD5ngdN8pkih";
      "WEAVIATE_AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED" = "true";
      "WEAVIATE_AUTHENTICATION_APIKEY_ALLOWED_KEYS" = "WVF5YThaHlkYwhGUSmCRgsX3tD5ngdN8pkih";
      "WEAVIATE_AUTHENTICATION_APIKEY_ENABLED" = "true";
      "WEAVIATE_AUTHENTICATION_APIKEY_USERS" = "hello@dify.ai";
      "WEAVIATE_AUTHORIZATION_ADMINLIST_ENABLED" = "true";
      "WEAVIATE_AUTHORIZATION_ADMINLIST_USERS" = "hello@dify.ai";
      "WEAVIATE_CLUSTER_HOSTNAME" = "node1";
      "WEAVIATE_DEFAULT_VECTORIZER_MODULE" = "none";
      "WEAVIATE_ENDPOINT" = "http://weaviate:8080";
      "WEAVIATE_PERSISTENCE_DATA_PATH" = "/var/lib/weaviate";
      "WEAVIATE_QUERY_DEFAULTS_LIMIT" = "25";
      "WEB_API_CORS_ALLOW_ORIGINS" = "*";
      "WEB_SENTRY_DSN" = "";
      "WORKFLOW_CALL_MAX_DEPTH" = "5";
      "WORKFLOW_FILE_UPLOAD_LIMIT" = "10";
      "WORKFLOW_MAX_EXECUTION_STEPS" = "500";
      "WORKFLOW_MAX_EXECUTION_TIME" = "1200";
      "WORKFLOW_PARALLEL_DEPTH_LIMIT" = "3";
    };
    environmentFiles = [
      "/home/zshen/personal/nix-config/modules/nixos/features/dify/.env"
    ];
    volumes = [
      "/home/zshen/personal/nix-config/modules/nixos/features/dify/volumes/app/storage:/app/api/storage:rw"
    ];
    dependsOn = [
      "dify-db"
      "dify-redis"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=worker"
      "--network=dify_default"
      "--network=dify_ssrf_proxy_network"
    ];
  };
  systemd.services."podman-dify-worker" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
    };
    after = [
      "podman-network-dify_default.service"
      "podman-network-dify_ssrf_proxy_network.service"
    ];
    requires = [
      "podman-network-dify_default.service"
      "podman-network-dify_ssrf_proxy_network.service"
    ];
    partOf = [
      "podman-compose-dify-root.target"
    ];
    wantedBy = [
      "podman-compose-dify-root.target"
    ];
  };

  # Networks
  systemd.services."podman-network-dify_default" = {
    path = [pkgs.podman];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "podman network rm -f dify_default";
    };
    script = ''
      podman network inspect dify_default || podman network create dify_default
    '';
    partOf = ["podman-compose-dify-root.target"];
    wantedBy = ["podman-compose-dify-root.target"];
  };
  systemd.services."podman-network-dify_ssrf_proxy_network" = {
    path = [pkgs.podman];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "podman network rm -f dify_ssrf_proxy_network";
    };
    script = ''
      podman network inspect dify_ssrf_proxy_network || podman network create dify_ssrf_proxy_network --driver=bridge --internal
    '';
    partOf = ["podman-compose-dify-root.target"];
    wantedBy = ["podman-compose-dify-root.target"];
  };

  # Root service
  # When started, this will automatically create all resources and start
  # the containers. When stopped, this will teardown all resources.
  systemd.targets."podman-compose-dify-root" = {
    unitConfig = {
      Description = "Root target generated by compose2nix.";
    };
    wantedBy = ["multi-user.target"];
  };
}
