"""cc_toolchain rule

According to:
https://bazel.build/docs/cc-toolchain-config-reference
"""

load("@bazel_tools//tools/build_defs/cc:action_names.bzl", "ACTION_NAMES")
load(
    "@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl",
    "feature",
    "flag_group",
    "flag_set",
    "action_config",
    "tool",
)
load("@bazel_utilities//toolchains:action_names.bzl",
    "ACTIONS_COMPILE_ALL",
    "ACTIONS_COMPILE_CPP",
    "ACTIONS_COMPILE_C",
    "ACTIONS_COMPILE_CXX",
    "ACTIONS_LINK",
    "ACTIONS_LINK_LTO",
    "ACTIONS_LINK_ALL",
    "ACTIONS_COV_ALL",
    "ACTIONS_COV_COMPILE",
    "ACTIONS_COV_LINK",
)
# load("@bazel_utilities//toolchains:toolchain_config_feature_legacy.bzl", "features_module_maps", "features_legacy")
load("@bazel_utilities//toolchains:tools_utils.bzl", "compiler_get_tool_name", "get_tool_path", "register_tools")
load("@bazel_utilities//toolchains:unpack.bzl", "unpack_flags_pack", "unpack_artifacts_patterns_pack")

ACTIONS_FEATURES_LUT_COMPILE = {
    "!compile_all": ACTIONS_COMPILE_ALL,
    "copts": ACTIONS_COMPILE_ALL,
    "cppcopts": ACTIONS_COMPILE_CPP,
    "conlycopts": ACTIONS_COMPILE_C,
    "cxxcopts": ACTIONS_COMPILE_CXX,
}

ACTIONS_FEATURES_LUT_LINK = {
    "!link_all": ACTIONS_LINK_ALL,
    "linkopts": ACTIONS_LINK_ALL,
    "linkw/ltoopts": ACTIONS_LINK,
    "ltoopts": ACTIONS_LINK_LTO,
}

ACTIONS_FEATURES_LUT_COV = {
    "cov": ACTIONS_COV_ALL,
    "ccov": ACTIONS_COV_COMPILE,
    "lcov": ACTIONS_COV_LINK
}

def feature_simple_add(name, actions, flags, enabled = True, provides = []):
    """Feature
    
    This function return the feature build only from an flag list

    Args:
        name: feature name
        actions: actions list of the feature
        flags: flags list of the feature
        enabled: If the feature is enable by default or not
        provides: provides list of the feature
      
    Returns:
        The feature
    """
    if len(flags) > 0:
        return feature(
            name = name,
            enabled = enabled,
            provides = provides,
            flag_sets = [
                flag_set(
                    actions = actions,
                    flag_groups = [
                        flag_group(
                            flags = flags
                        )
                    ]
                )
            ]
        )
    return None

def feature_simple_flags(name, flags_unpacked, actions_lut, enabled = True, provides = []):
    """Feature Flags
    
    This function return the feature build from the unpacked flags list 

    Args:
        name: feature name
        flags_unpacked: unpacked flags in the ctx 
        actions_lut: The actions lookup table to see which actions to activate
        enabled: If the feature is enable by default or not
        provides: provides list of the feature
      
    Returns:
        The feature
    """
    flag_sets = []
    for flag_data in flags_unpacked:
        if len(flag_data["flags"]) > 0 and flag_data["type"] in actions_lut:
            flag_sets.append(
                flag_set(
                    actions = actions_lut[flag_data["type"]],
                    flag_groups = [ flag_group( flags = flag_data["flags"]) ],
                    with_features = flag_data["with_features"]
                )
            )
    _feature = feature(
        name = name,
        provides = provides,
        enabled = enabled,
        flag_sets = flag_sets,
    )
    return _feature

def feature_flags_unpacked_compile(flags_unpacked):
    """default_compile_flags

    Args:
        flags_unpacked: unpacked flags in the ctx 
    Returns:
        The feature
    """
    return feature_simple_flags("default_compile_flags", flags_unpacked, ACTIONS_FEATURES_LUT_COMPILE)

def feature_flags_unpacked_link(flags_unpacked):
    """default_link_flags
    
    Args:
        flags_unpacked: unpacked flags in the ctx 
    Returns:
        The feature
    """
    return feature_simple_flags("default_link_flags", flags_unpacked, ACTIONS_FEATURES_LUT_LINK)

def feature_flags_unpacked_coverage(flags_unpacked):
    """coverage
    
    Args:
        flags_unpacked: unpacked flags in the ctx 
    Returns:
        The feature
    """
    return feature_simple_flags("coverage", flags_unpacked, ACTIONS_FEATURES_LUT_COV, provides = ["profile"])

def features_flags_legacy(copts, conlyopts, cxxopts, linkopts):
    """Features from legacy bazel opts: [ copts, conlyopts, cxxopts, linkopts ]
    
    Args:
        copts: copts
        conlyopts: conlyopts
        cxxopts: cxxopts
        linkopts: linkopts
    Returns:
        The list of all features that have been created
    """
    features = []
    if len(copts) > 0:
        features.append(
            feature_simple_add(
                name = "toolchain_copts",
                actions = ACTIONS_COMPILE_ALL,
                flags = copts
            )
        )
    if len(conlyopts) > 0:
        features.append(
            feature_simple_add(
                name = "toolchain_conlyopts",
                actions = ACTIONS_COMPILE_C,
                flags = conlyopts
            )
        )
    if len(cxxopts) > 0:
        features.append(
            feature_simple_add(
                name = "toolchain_cxxopts",
                actions = ACTIONS_COMPILE_CXX,
                flags = cxxopts
            )
        )
    if len(linkopts) > 0:
        features.append(
            feature_simple_add(
                name = "toolchain_linkopts",
                actions = ACTIONS_LINK_ALL,
                flags = linkopts
            )
        )
    return features

def features_flags(copts, conlyopts, cxxopts, linkopts, defines, includedirs, linkdirs):
    """Features for all bazel flags [ copts, conlyopts, cxxopts, linkopts, defines, includedirs, linkdirs ]
    
    Args:
        copts: copts
        conlyopts: conlyopts
        cxxopts: cxxopts
        linkopts: linkopts
        defines: defines
        includedirs: includedirs
        linkdirs: linkdirs
    Returns:
        The list of all features that have been created
    """
    features = []
    if len(copts) > 0:
        features.append(
            feature_simple_add(
                name = "toolchain_copts",
                actions = ACTIONS_COMPILE_ALL,
                flags = copts
            )
        )
    if len(conlyopts) > 0:
        features.append(
            feature_simple_add(
                name = "toolchain_conlyopts",
                actions = ACTIONS_COMPILE_C,
                flags = conlyopts
            )
        )
    if len(cxxopts) > 0:
        features.append(
            feature_simple_add(
                name = "toolchain_cxxopts",
                actions = ACTIONS_COMPILE_CXX,
                flags = cxxopts
            )
        )
    if len(linkopts) > 0:
        features.append(
            feature_simple_add(
                name = "toolchain_linkopts",
                actions = ACTIONS_LINK_ALL,
                flags = linkopts
            )
        )

    defines_opts = [ "-D{}".format(define) for define in defines ]
    includedirs_opts = [ "-I{}".format(includedir) for includedir in includedirs]
    linkdirs_opts = [ "-L{}".format(linkdir) for linkdir in linkdirs]
    if len(defines_opts) > 0:
        features.append(
            feature_simple_add(
                name = "toolchain_defines",
                actions = ACTIONS_COMPILE_ALL,
                flags = defines_opts
            )
        )
    if len(includedirs_opts) > 0:
        features.append(
            feature_simple_add(
                name = "toolchain_includedirs",
                actions = ACTIONS_COMPILE_ALL,
                flags = includedirs_opts
            )
        )
    if len(linkdirs_opts) > 0:
        features.append(
            feature_simple_add(
                name = "toolchain_linkdirs",
                actions = ACTIONS_LINK_ALL,
                flags = linkdirs_opts
            )
        )
    return features

def feature_link_libs(name, linklibs):
    """Feature Link Lib
    
    Args:
        name: Name of the feature
        linklibs: List of libs to link
    Returns:
        The feature
    """
    all_linklibs = [ "-l{}".format(linklib) for linklib in linklibs]
    return feature_simple_add(
        name = name,
        actions = ACTIONS_LINK_ALL,
        flags = all_linklibs
    )

def features_well_known(ctx):
    """Feature well_known
    
    Create all Well-Known Feature according to: https://bazel.build/docs/cc-toolchain-config-reference

    Args:
        ctx: The crule context
    Returns:
        All features that have been created
    """
    features = []
    if "supports_pic" in ctx.attr.enable_features:
        features.append(feature(name = "supports_pic", enabled = True))
    if "supports_dynamic_linker" in ctx.attr.enable_features:
        features.append(feature(name = "supports_dynamic_linker", enabled = True))
    if "supports_start_end_lib" in ctx.attr.enable_features:
        features.append(feature(name = "supports_start_end_lib", enabled = True))
    return features

def features_all(ctx):
    """Feature All

    Args:
        ctx: The crule context
    Returns:
        The list of all features that have been created
    """
    flags_unpacked = unpack_flags_pack(ctx.attr.flags)

    features = []
    features.append(feature(name = "dbg"))
    features.append(feature(name = "opt"))
    features.append(feature(name = "fastbuild"))

    for extra_feature in ctx.attr.extras_features:
        features.append(feature(name = extra_feature))

    if len(ctx.attr.toolchain_libs) > 0:
        features.append(feature_link_libs("toolchain_libs", ctx.attr.toolchain_libs))
    
    features += features_well_known(ctx)
    
    features += features_flags(
        ctx.attr.copts,
        ctx.attr.conlyopts,
        ctx.attr.cxxopts,
        ctx.attr.linkopts,
        ctx.attr.defines,
        ctx.attr.includedirs,
        ctx.attr.linkdirs
    )
    features.append(feature_flags_unpacked_compile(flags_unpacked))
    features.append(feature_flags_unpacked_link(flags_unpacked))
    features.append(feature_flags_unpacked_coverage(flags_unpacked))
    return features

def add_action_configs(toolchain_bins, tool_name, action_names, implies = []):
    """Create an list of action_config

    This function create an list of action_config

    Args:
        toolchain_bins: The rule context toolchain_bins
        tool_name: The full tool_name including optionals prefix and extention
        action_names: The list of all action_name that need to be created
        implies: The implies list of the action_config

    Returns:
        The list of all action_config that have been created
    """
    if tool_name == "":
        return None
    action_configs = []
    for action_name in action_names:
        path = get_tool_path(toolchain_bins, tool_name)
        if path == None:
            continue
        action_configs.append(
            action_config(
                action_name = action_name,
                tools = [ tool(path = path) ],
                implies = implies
            )
        )
    return action_configs

def action_configs_all(ctx):
    """All action config

    Args:
        ctx: The rule context
    Returns:
        The list of all action_config that have been created
    """
    action_configs = []
    action_configs += add_action_configs(
        ctx.files.toolchain_bins,
        compiler_get_tool_name(ctx.attr.compiler, "cpp", "g++", ["cxx"]),
        [
            ACTION_NAMES.cpp_compile,
            ACTION_NAMES.cpp_header_parsing,
            ACTION_NAMES.cpp_module_codegen,
            ACTION_NAMES.cpp_module_compile,
            ACTION_NAMES.assemble,
        ]
    )
    action_configs += add_action_configs(
        ctx.files.toolchain_bins,
        compiler_get_tool_name(ctx.attr.compiler, "cc", "gcc"),
        [
            ACTION_NAMES.c_compile,
            ACTION_NAMES.cc_flags_make_variable,
            ACTION_NAMES.preprocess_assemble,
        ]
    )
    action_configs += add_action_configs(
        ctx.files.toolchain_bins,
        compiler_get_tool_name(ctx.attr.compiler, "cxx", "g++"),
        [
            ACTION_NAMES.cpp_link_executable,
            ACTION_NAMES.cpp_link_dynamic_library,
            ACTION_NAMES.cpp_link_nodeps_dynamic_library,
        ]
    )
    action_configs += add_action_configs(
        ctx.files.toolchain_bins,
        compiler_get_tool_name(ctx.attr.compiler, "ar", "ar"),
        [
            ACTION_NAMES.cpp_link_static_library
        ],
        implies = [ "archiver_flags", "linker_param_file" ]
    )
    action_configs += add_action_configs(
        ctx.files.toolchain_bins,
        compiler_get_tool_name(ctx.attr.compiler, "cov", "gcov"),
        [
            ACTION_NAMES.llvm_cov
        ]
    )
    action_configs += add_action_configs(
        ctx.files.toolchain_bins,
        compiler_get_tool_name(ctx.attr.compiler, "strip", "strip"),
        [
            ACTION_NAMES.strip
        ]
    )
    return action_configs

def _impl_cc_toolchain_config(ctx):
    return cc_common.create_cc_toolchain_config_info(
        ctx = ctx,
        toolchain_identifier = ctx.attr.toolchain_identifier,
        
        host_system_name = ctx.attr.host_name,
        target_system_name = ctx.attr.target_name,
        target_cpu = ctx.attr.target_cpu,

        features = features_all(ctx),
        action_configs = action_configs_all(ctx),

        compiler = ctx.attr.compiler.get("name", "gcc"),

        cxx_builtin_include_directories = ctx.attr.cxx_builtin_include_directories,

        abi_version = ctx.attr.abi_version,
        abi_libc_version = ctx.attr.abi_libc_version,
        target_libc = ctx.attr.target_libc,

        artifact_name_patterns = unpack_artifacts_patterns_pack(ctx.attr.artifacts_patterns_packed),

        tool_paths = register_tools(ctx.attr.tools)
    )

cc_toolchain_config = rule(
    implementation = _impl_cc_toolchain_config,
    attrs = {
        'toolchain_identifier': attr.string(mandatory = True),
        'host_name': attr.string(mandatory = True),
        'target_name': attr.string(mandatory = True),
        'target_cpu': attr.string(mandatory = True),

        'compiler': attr.string_dict(default = {}),
        'toolchain_bins': attr.label(mandatory = True, allow_files = True),
        'extras_features': attr.string_list(default = []),
        'cxx_builtin_include_directories': attr.string_list(default = []),

        'copts': attr.string_list(default = []),
        'conlyopts': attr.string_list(default = []),
        'cxxopts': attr.string_list(default = []),
        'linkopts': attr.string_list(default = []),
        'defines': attr.string_list(default = []),
        'includedirs': attr.string_list(default = []),
        'linkdirs': attr.string_list(default = []),
        
        'flags': attr.string_dict(),

        'artifacts_patterns_packed' : attr.string_list(default = []),
        
        'tools': attr.string_dict(default = {}), 

        'toolchain_libs': attr.string_list(default = []),

        'abi_version': attr.string(default = "local"),
        'abi_libc_version': attr.string(default = "local"),
        'target_libc': attr.string(default = "local"),

        'enable_features': attr.string_list(default = [])
    },
    provides = [CcToolchainConfigInfo],
)
