echo "exporting Prisma envs"
export PKG_CONFIG_PATH="@opensslDev@/lib/pkgconfig";
export PRISMA_SCHEMA_ENGINE_BINARY="@prismaEngines@/bin/schema-engine"
export PRISMA_QUERY_ENGINE_BINARY="@prismaEngines@/bin/query-engine"
export PRISMA_QUERY_ENGINE_LIBRARY="@prismaEngines@/lib/libquery_engine.node"
export PRISMA_FMT_BINARY="@prismaEngines@/bin/prisma-fmt"

export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true
export PLAYWRIGHT_HOST_PLATFORM_OVERRIDE="ubuntu-24.04"

@cleanupScript@ "@agentBrowserPath@"

echo "[[nextjs16]] shell activated!!!"
