"""
Utils rules
"""

load("@bazel_tools//tools/build_defs/cc:action_names.bzl", "ACTION_NAMES")
load("@bazel_tools//tools/cpp:toolchain_utils.bzl", "find_cpp_toolchain")

# Inspired by: https://github.com/erenon/bazel_clang_tidy
def toolchain_flags(ctx, action_name = ACTION_NAMES.cpp_compile):
    """Return the flags associted to an action and the current C/C++ toolchain

    Args:
        ctx: ctx
        action_name: the action_name to execute from the toolchain
    Returns:
        List of toolchains flags
    """
    cc_toolchain = find_cpp_toolchain(ctx)
    feature_configuration = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
    )
    compile_variables = cc_common.create_compile_variables(
        feature_configuration = feature_configuration,
        cc_toolchain = cc_toolchain,
        user_compile_flags = ctx.fragments.cpp.cxxopts + ctx.fragments.cpp.copts,
    )
    flags = cc_common.get_memory_inefficient_command_line(
        feature_configuration = feature_configuration,
        action_name = action_name,
        variables = compile_variables,
    )
    return flags

C_ALLOWED_FILES_EXT = [
    ".c", ".C",
    ".h", ".H",
]
CXX_ALLOWED_FILES_EXT = [
    ".cc", ".cpp", ".cxx", ".c++",
    ".hh", ".hpp", ".hxx", ".inc", ".inl",
]
CC_ALLOWED_FILES = C_ALLOWED_FILES_EXT + CXX_ALLOWED_FILES_EXT

CC_HEADER = [
    ".h", ".H", ".hh", ".hpp", ".hxx", ".inc", ".inl"
]

def file_extention_match(file, allowed_files):
    """Returns True if the file type matches one of the permitted file extention
    
    Args:
        file: file
        allowed_files: list of all extentions allowed files
    Returns:
        True or False
    """
    for file_type in allowed_files:
        if file.basename.endswith(file_type):
            return True
    return False

def rule_files(rule, allowed_files = CC_ALLOWED_FILES):
    """Return all files in the given rule

    Args:
        rule: the ctx.rule member
        allowed_files: list of all extentions allowed files
    Returns:
        The list of all files
    """

    files = []
    if hasattr(rule.attr, "srcs"):
        for src in rule.attr.srcs:
            files += [file for file in src.files.to_list() if file.is_source and file_extention_match(file, allowed_files)]
    if hasattr(rule.attr, "hdrs"):
        for hdr in rule.attr.hdrs:
            files += [file for file in hdr.files.to_list() if file.is_source and file_extention_match(file, allowed_files)]
    return files