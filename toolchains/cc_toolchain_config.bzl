# Copyright 2019 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""A Starlark cc_toolchain configuration rule"""

"""
https://bazel.build/docs/cc-toolchain-config-reference
"""

load("@bazel_tools//tools/build_defs/cc:action_names.bzl", "ACTION_NAMES")
load(
    "@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl",
    "feature",
    "flag_group",
    "flag_set",
    "with_feature_set",
    "artifact_name_pattern"
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
load("@bazel_utilities//toolchains:config.bzl", "add_action_configs", "register_tools")
load("@bazel_utilities//toolchains:toolchain_config_feature_legacy.bzl", "features_module_maps", "features_legacy")

ACTIONS_FEATURES_LUT_COMPILE = {
    "copts": ACTIONS_COMPILE_ALL,
    "cppcopts": ACTIONS_COMPILE_CPP,
    "conlycopts": ACTIONS_COMPILE_C,
    "cxxcopts": ACTIONS_COMPILE_CXX,
}

ACTIONS_FEATURES_LUT_LINK = {
    "linkopts": ACTIONS_LINK + ACTIONS_LINK_LTO
}

ACTIONS_FEATURES_LUT_COV = {
    "cov": ACTIONS_COV_ALL,
    "ccov": ACTIONS_COV_COMPILE,
    "lcov": ACTIONS_COV_LINK
}

def flags_unpack(flags_packed):
    ""
    flags_unpacked = []
    for flag_type, flag_flags in flags_packed.items():
        # filters name and json mode
        if flag_type.startswith('$'):
            flag_flags = json.decode(flag_flags)
            flag_type = flag_type[1:]
        elif flag_type.startswith('#'):
            flag_flags = flag_flags.split(';')
            flag_type = flag_type[1:]
        
        if flag_type.startswith('%'):
            flag_type = flag_type[flag_type.find('%') + 1:]
        
        patterns = flag_type.split('/')
        flag_types = []
        if patterns[0].startswith('$'):
            patterns[0] = patterns[0][1:]
            flag_types = json.decode(patterns[0])
        elif patterns[0].startswith('#'):
            patterns[0] = patterns[0][1:]
            flag_types = patterns[0].split(';')
        else:
            flag_types.append(patterns[0])

        with_features = []
        if len(patterns) > 1:
            features_filters = patterns[1].split(';')
            for filter in features_filters:
                if filter.startswith('[') == False:
                    if filter.startswith('!'):
                        with_features.append(with_feature_set(not_features = [filter]))
                    else:
                        with_features.append(with_feature_set(features = [filter]))
                else:
                    filters = json.decode(filter)
                    f_with = []
                    f_without = []
                    for subfilter in filters:
                        if subfilter.startswith('!'):
                            f_without.append(subfilter)
                        else:
                            f_with.append(subfilter)
                    with_features.append(with_feature_set(features = f_with, not_features = f_without))

        for flag_type in flag_types:
            flags_unpacked.append({
                "type": flag_type,
                "with_features": with_features,
                "flags": flag_flags
            })
    return flags_unpacked

def feature_common_flags(name, flags_unpacked, actions_lut, enabled = True, provides = []):
    ""
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

def feature_default_compile_flags(flags_unpacked):
    return feature_common_flags("default_compile_flags", flags_unpacked, ACTIONS_FEATURES_LUT_COMPILE)

def feature_default_link_flags(flags_unpacked):
    return feature_common_flags("default_link_flags", flags_unpacked, ACTIONS_FEATURES_LUT_LINK)

def feature_coverage(flags_unpacked):
    return feature_common_flags("coverage", flags_unpacked, ACTIONS_FEATURES_LUT_COV, provides = ["profile"])

def feature_common_add(name, actions, flags, enabled = True):
    if len(flags) > 0:
        return feature(
            name = name,
            enabled = enabled,
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

def features_DIL(preprocessor_defines, include_directories, lib_directories):
    ""
    features = []
    all_defines = [ "-D{}".format(define) for define in preprocessor_defines ]
    all_includedirs = [ "-I{}".format(includedir) for includedir in include_directories]
    all_linkdirs = [ "-L{}".format(linkdir) for linkdir in lib_directories]
    if len(all_defines) > 0:
        features.append(
            feature_common_add(
                name = "toolchain_config_defines",
                actions = ACTIONS_COMPILE_ALL,
                flags = all_defines
            )
        )
    if len(all_includedirs) > 0:
        features.append(
            feature_common_add(
                name = "toolchain_config_link",
                actions = ACTIONS_COMPILE_ALL,
                flags = all_includedirs
            )
        )
    if len(all_linkdirs) > 0:
        features.append(
            feature_common_add(
                name = "toolchain_config_link",
                actions = ACTIONS_LINK_ALL,
                flags = all_linkdirs
            )
        )
    return features

def feature_link_libs(name, linklibs):
    all_linklibs = [ "-l{}".format(linklib) for linklib in linklibs]
    return feature_common_add(
        name = name,
        actions = ACTIONS_LINK_ALL,
        flags = all_linklibs
    )

def features_well_known(ctx):
    ""
    features = []
    features.append(feature(name = "supports_pic", enabled = True))
    features.append(feature(name = "supports_dynamic_linker", enabled = True))
    if "supports_start_end_lib" in ctx.attr.enable_features:
        features.append(feature(name = "supports_start_end_lib", enabled = True))
    return features

def features_all(ctx):
    ""
    features = []
    features.append(feature(name = "dbg"))
    features.append(feature(name = "opt"))
    features.append(feature(name = "fastbuild"))

    for extra_feature in ctx.attr.extras_features:
        features.append(feature(name = extra_feature))

    flags_unpacked = flags_unpack(ctx.attr.flags)
    features.append(feature_default_compile_flags(flags_unpacked))
    features.append(feature_default_link_flags(flags_unpacked))
    features.append(feature_coverage(flags_unpacked))

    if len(ctx.attr.toolchain_libs) > 0:
        features.append(feature_link_libs("toolchain_libs", ctx.attr.toolchain_libs))
    
    features += features_well_known(ctx)
    
    features += features_DIL(
        ctx.attr.preprocessor_defines,
        ctx.attr.include_directories + (ctx.attr.cxx_builtin_include_directories if ctx.attr.include_directories_use_builtin else []),
        ctx.attr.lib_directories
    )
    return features

def action_configs_all(ctx):
    ""
    action_configs = []
    action_configs += add_action_configs(
        ctx.files.toolchain_bins,
        ctx.attr.compiler.get("cpp", ctx.attr.compiler.get("cxx", "g++")),
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
        ctx.attr.compiler.get("cc", "gcc"),
        [
            ACTION_NAMES.c_compile,
            ACTION_NAMES.cc_flags_make_variable,
            ACTION_NAMES.preprocess_assemble,
        ]
    )
    action_configs += add_action_configs(
        ctx.files.toolchain_bins,
        ctx.attr.compiler.get("cxx", "g++"),
        [
            ACTION_NAMES.cpp_link_executable,
            ACTION_NAMES.cpp_link_dynamic_library,
            ACTION_NAMES.cpp_link_nodeps_dynamic_library,
        ]
    )
    action_configs += add_action_configs(
        ctx.files.toolchain_bins,
        ctx.attr.compiler.get("ar", "ar"),
        [
            ACTION_NAMES.cpp_link_static_library
        ],
        implies = [ "archiver_flags", "linker_param_file" ]
    )
    action_configs += add_action_configs(
        ctx.files.toolchain_bins,
        ctx.attr.compiler.get("cov", "gcov"),
        [
            ACTION_NAMES.llvm_cov
        ]
    )
    action_configs += add_action_configs(
        ctx.files.toolchain_bins,
        ctx.attr.compiler.get("strip", "strip"),
        [
            ACTION_NAMES.strip
        ]
    )
    return action_configs

def get_artifacts_patterns(artifacts_patterns_packed):
    ""
    artifacts_patterns_categories = artifacts_patterns_packed.split(',')
    patterns = []
    for category in artifacts_patterns_categories:
        unpacked = category.split('/')
        patterns.append(
            artifact_name_pattern(
                category_name = unpacked[0],
                prefix = unpacked[1],
                extension = unpacked[2]
            )
        )
    return patterns

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

        artifact_name_patterns = get_artifacts_patterns(ctx.attr.artifacts_patterns_packed),

        tool_paths = register_tools(ctx.attr.tools)
    )

"""
flags: {type} | {type}/{feature}
    type:
        - cpp_copts
        - conly_copts
        - cxx_copts
        - link_copts
    feature:
        - dbg
        - opt
        - fastbuild

tools:
    - "ar": "/usr/bin/ar",
    - "ld": "/usr/bin/ld",
    - "cpp": "/usr/bin/cpp",
    - "cc": "/usr/bin/gcc",
    - "dwp": "/usr/bin/dwp",
    - "gcov": "/usr/bin/gcov",
    - "nm": "/usr/bin/nm",
    - "objcopy": "/usr/bin/objcopy",
    - "objdump": "/usr/bin/objdump",
    - "strip": "/usr/bin/strip",

extras_features:
    - supports_start_end_lib
"""
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
        'flags': attr.string_dict(),
        'cxx_builtin_include_directories': attr.string_list(),

        'preprocessor_defines': attr.string_list(default = []),
        'include_directories': attr.string_list(default = []),
        'include_directories_use_builtin': attr.bool(default = False),
        'lib_directories': attr.string_list(default = []),

        'artifacts_patterns_packed' : attr.string(default = ""),
        
        'tools': attr.string_dict(default = {}), 

        'toolchain_libs': attr.string_list(default = []),

        'abi_version': attr.string(default = "local"),
        'abi_libc_version': attr.string(default = "local"),
        'target_libc': attr.string(default = "local"),

        'enable_features': attr.string_list(default = [])
    },
    provides = [CcToolchainConfigInfo],
)
