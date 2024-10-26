"""cc_toolchain rule

According to:
https://bazel.build/docs/cc-toolchain-config-reference
"""

load("//toolchains:artifacts.bzl", "artifacts_patterns_unpack")
load("//toolchains:tools_utils.bzl",
    "link_actions_to_tool",
    "toolchain_tools_from_paths",
    "toolchain_tools_from_bins",
    "toolchain_path_from_bins",
    "toolchain_ctx_tool_paths",
)
# load("//toolchains:xflags.bzl", "xflags_unpack")

load("//toolchains/toolchains_features:toolchains_features.bzl", "TOOLCHAINS_FEATURES")

load("@rules_cc//cc:action_names.bzl", "ACTION_NAMES")
# load("//toolchains:actions_grp.bzl", "TOOLCHAIN_ACTIONS")

def toolchains_tools_actions_config(toolchain_tools):
    """Tools action config

    Args:
        toolchain_tools: The context toolchain's paths
    Returns:
        The list of all action_configs for this context
    """
    action_configs = []

    ########## Assembler actions ##########
    action_configs += link_actions_to_tool(
        toolchain_tools,
        "cxx",
        [ ACTION_NAMES.preprocess_assemble ],
        implies = [ "toolchain-assemble", "toolchain-assember-w-preprocess" ],
    )
    action_configs += link_actions_to_tool(
        toolchain_tools,
        "cxx",
        [ ACTION_NAMES.assemble ],
        implies = [ "toolchain-assemble" ],
    )

    ########## Compiler actions ##########
    # !NOT DONE: cc-flags-make-variable [ ACTION_NAMES.cc_flags_make_variable ]
    # !NOT DONE: c++-module-codegen [ ACTION_NAMES.cpp_module_codegen ]
    # !NOT DONE: c++-module-compile [ ACTION_NAMES.cpp_module_compile ]
    action_configs += link_actions_to_tool(
        toolchain_tools,
        "cxx",
        [ ACTION_NAMES.c_compile ],
        implies = [ "toolchain-compile", "toolchain-compile-c" ],
    )
    action_configs += link_actions_to_tool(
        toolchain_tools,
        "cxx",
        [ ACTION_NAMES.cpp_compile ],
        implies = [ "toolchain-compile", "toolchain-compile-cxx" ],
    )
    action_configs += link_actions_to_tool(
        toolchain_tools,
        "cxx",
        [ ACTION_NAMES.cpp_header_parsing ],
        implies = [ "toolchain-compile-header-parsing" ],
    )
    action_configs += link_actions_to_tool(
        toolchain_tools,
        "cxx",
        [ ACTION_NAMES.linkstamp_compile ],
        implies = [ "toolchain-compile", "toolchain-compile-cxx", "toolchain-compile-linkstamp"],
    )

    ########## Link actions ##########
    action_configs += link_actions_to_tool(
        toolchain_tools,
        "cxx",
        [
            ACTION_NAMES.cpp_link_dynamic_library,
            ACTION_NAMES.lto_index_for_dynamic_library,
        ],
        implies = [ "toolchain-link-dynamic-lib" ],
    )
    action_configs += link_actions_to_tool(
        toolchain_tools,
        "cxx",
        [
            ACTION_NAMES.cpp_link_nodeps_dynamic_library,
            ACTION_NAMES.lto_index_for_nodeps_dynamic_library,
        ],
        implies = [ "toolchain-link-dynamic-lib", "toolchain-link-nodeps" ],
    )
    action_configs += link_actions_to_tool(
        toolchain_tools,
        "cxx",
        [
            ACTION_NAMES.cpp_link_executable,
            ACTION_NAMES.lto_index_for_executable,
        ],
        implies = [ "toolchain-link-exe" ],
    )

    ########## AR actions ##########
    action_configs += link_actions_to_tool(
        toolchain_tools,
        "ar",
        [ ACTION_NAMES.cpp_link_static_library ],
        implies = [ "toolchain-archive-static-lib" ],
    )

    ########## LTO actions ##########
    action_configs += link_actions_to_tool(
        toolchain_tools,
        "cxx",
        [ ACTION_NAMES.lto_backend ],
        implies = [ "toolchain-lto-backend" ],
    )
    action_configs += link_actions_to_tool(
        toolchain_tools,
        "cxx",
        [
            ACTION_NAMES.lto_indexing,
            # TODO: add toolchain-lto-indexing to thoses actions
            # ACTION_NAMES.lto_index_for_executable,
            # ACTION_NAMES.lto_index_for_dynamic_library,
            # ACTION_NAMES.lto_index_for_nodeps_dynamic_library,
        ],
        implies = [ "toolchain-lto-indexing" ],
    )

    ########## Strip actions ##########
    action_configs += link_actions_to_tool(
        toolchain_tools,
        "strip",
        [ ACTION_NAMES.strip ],
        implies = [ "toolchain-strip" ],
    )

    ########## Cliff ##########
    action_configs += link_actions_to_tool(
        toolchain_tools,
        "cxx",
        [ ACTION_NAMES.clif_match ],
        implies = [ "toolchain-clif-match" ],
    )

    ########## ObjC / ObjC++ ##########
    # DISCARDED: objc-compile [ ACTION_NAMES.objc_compile ]
    # DISCARDED: objc++-compile [ ACTION_NAMES.objc_executable ]
    # DISCARDED: objc-executable [ ACTION_NAMES.objc_fully_link ]
    # DISCARDED: objc-fully-link [ ACTION_NAMES.objcpp_compile ]

    return action_configs

def _impl_cc_toolchain_config(ctx):
    toolchain_bins_defined = len(ctx.attr.toolchain_bins) > 0
    toolchain_paths_defined = len(ctx.attr.toolchain_paths) > 0

    if (toolchain_bins_defined and toolchain_paths_defined) or (toolchain_bins_defined == False and toolchain_paths_defined == False):
        fail("One and only one of 'toolchain_bins' and 'toolchain_paths' have to be set")

    if toolchain_paths_defined != False:
        toolchain_tools = toolchain_tools_from_paths(ctx.attr.toolchain_paths)
        toolchain_paths = ctx.attr.toolchain_paths
    else:
        toolchain_tools = toolchain_tools_from_bins(ctx.attr.toolchain_bins, ctx.files.toolchain_bins)
        toolchain_paths = toolchain_path_from_bins(ctx.attr.toolchain_bins, ctx.files.toolchain_bins)

    return cc_common.create_cc_toolchain_config_info(
        ctx = ctx,
        toolchain_identifier = ctx.attr.toolchain_identifier,

        compiler = ctx.attr.compiler_type,
 
        features = TOOLCHAINS_FEATURES[ctx.attr.compiler_type](ctx),
        action_configs = toolchains_tools_actions_config(toolchain_tools),
        tool_paths = toolchain_ctx_tool_paths(toolchain_paths),

        cxx_builtin_include_directories = ctx.attr.cxx_builtin_include_directories,

        artifact_name_patterns = artifacts_patterns_unpack(ctx.attr.artifacts_patterns_packed),

        # Deprecated, Need default value
        abi_version = ctx.attr.abi_version,
        abi_libc_version = ctx.attr.abi_libc_version,

        # Deprecated, Need default value
        target_cpu = "unknonwn",
        target_libc = "unknonwn",
        target_system_name = "unknonwn",
        host_system_name = "unknonwn",
    )

cc_toolchain_config = rule(
    implementation = _impl_cc_toolchain_config,
    attrs = {
        'toolchain_identifier': attr.string(mandatory = True),

        'compiler_type': attr.string(mandatory = True),

        'toolchain_bins': attr.label_keyed_string_dict(mandatory = False, allow_files = True),
        'toolchain_paths': attr.string_dict(mandatory = False),

        'cxx_builtin_include_directories': attr.string_list(default = []),

        'copts': attr.string_list(default = []),
        'conlyopts': attr.string_list(default = []),
        'cxxopts': attr.string_list(default = []),
        'linkopts': attr.string_list(default = []),
        'defines': attr.string_list(default = []),
        'includedirs': attr.string_list(default = []),
        'linkdirs': attr.string_list(default = []),
        'linklibs': attr.string_list(default = []),
        # dbg / opt
        'dbg_copts': attr.string_list(default = []),
        'dbg_linkopts': attr.string_list(default = []),
        'opt_copts': attr.string_list(default = []),
        'opt_linkopts': attr.string_list(default = []),

        'artifacts_patterns_packed' : attr.string_list(default = []),
        
        # TODO:
        'xflags_packed': attr.string_dict(default = {}),
        'enable_features': attr.string_list(default = []),
        'extras_features': attr.string_list(default = []),

        # Not really usefull
        'abi_version': attr.string(default = "local"),
        'abi_libc_version': attr.string(default = "local")
    },
    fragments = ["cpp"],
    provides = [CcToolchainConfigInfo],
)
