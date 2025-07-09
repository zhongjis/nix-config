local config = {
  cmd = { os.getenv("JDTLS_PATH") },
  root_dir = vim.fs.dirname(
    vim.fs.find({ "gradlew", ".git", "mvnw" }, { upward = true })[1]
  ),
}
require("jdtls").start_or_attach(config)
