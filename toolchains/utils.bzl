"""
"""

"Copied from rules_cc/cc/private/toolchain/lib_cc_configure.bzl"
def get_env_var(repo_ctx, name, default = None, enable_warning = True):
    """Find an environment variable in system path. Doesn't %-escape the value!

    Args:
      repo_ctx: The repository context.
      name: Name of the environment variable.
      default: Default value to be used when such environment variable is not present.
      enable_warning: Show warning if the variable is not present.
    Returns:
      value of the environment variable or default.
    """

    if name in repo_ctx.os.environ:
        return repo_ctx.os.environ[name]
    if default != None:
        if enable_warning:
            print("'%s' environment variable is not set, using '%s' as default" % (name, default)) # buidifier: disable=print
        return default
    return fail("'%s' environment variable is not set" % name)

def forward_envars(repo_ctx):
    envars = {}

    envars["BAZEL_USE_LLVM_NATIVE_COVERAGE"] = get_env_var(repo_ctx,
        "BAZEL_USE_LLVM_NATIVE_COVERAGE",
        default = "0",
        enable_warning = False
    )
    
    return envars
