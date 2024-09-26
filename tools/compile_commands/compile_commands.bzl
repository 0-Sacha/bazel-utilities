"""
This file define a rule to execute clang_tidy

Inspired by: https://github.com/erenon/bazel_clang_tidy

This version is currently manually reconstructing the commands lines.
For now: At first assume an easy case (Full C++ compilation and linking using linux arguments) and then need to be fixed with specific case 
Waitting to be able to generate the command line directly from the Aspect. If it is possible one day...
"""

load("@bazel_tools//tools/build_defs/cc:action_names.bzl", "ACTION_NAMES")
load(
    "@bazel_utilities//tools:utils.bzl",
    "toolchain_flags",
    "toolchain_tool",
    "rule_files",
    "linux_compiler_args_from_context",
    "linux_linker_args_from_context",
    "file_extention_match",
    "CC_HEADER",
    "C_ALLOWED_FILES_EXT"
)

def _get_object_file_name(file_name):
    if "." in file_name:
        base_name = file_name[:file_name.rfind(".")]
    else:
        base_name = file_name
    return base_name + ".o"

def _compile_commands_impl(target, ctx):
    # Ignore if it's not a C/C++ target
    if not CcInfo in target:
        print("Not a CC Target: ", target)
        return []
    print("Found CC Target: ", target)

    # Ignore external targets
    if target.label.workspace_root.startswith("external"):
        return []

    files = rule_files(ctx.rule)
    rule_copts = ctx.rule.attr.copts if hasattr(ctx.rule.attr, "copts") else []
    rule_linkopts = ctx.rule.attr.linkopts if hasattr(ctx.rule.attr, "linkopts") else []
    context_args = linux_compiler_args_from_context(target[CcInfo].compilation_context)
    context_args = linux_linker_args_from_context(target[CcInfo].linking_context)
    
    copts = toolchain_flags(ctx, ACTION_NAMES.c_compile)
    c_compiler = toolchain_tool(ctx, ACTION_NAMES.c_compile)

    cxxopts = toolchain_flags(ctx, ACTION_NAMES.cpp_compile)
    cpp_compiler = toolchain_tool(ctx, ACTION_NAMES.cpp_compile)

    compile_commands = []
    for file in files:
        if file_extention_match(file, CC_HEADER) and not ctx.attr.execute_headers:
            continue
        
        command = "{compiler} {fpath} -o {opath} {opts} {sopts}".format(
            compiler = c_compiler if file_extention_match(file, C_ALLOWED_FILES_EXT) else cpp_compiler,
            fpath = file.path,
            opath = _get_object_file_name(file.path),
            opts = " ".join(context_args + rule_copts),
            sopts = " ".join(copts if file_extention_match(file, C_ALLOWED_FILES_EXT) else cxxopts),
        )

        file_cmd = {}
        file_cmd["directory"] = ctx.bin_dir.path
        file_cmd["command"] = command
        file_cmd["file"] = file.path
        file_cmd["outputs"] = _get_object_file_name(file.path)
        compile_commands.append(file_cmd)

    # link_cmd = {}
    # link_cmd["directory"] = ctx.bin_dir.path
    # link_cmd["command"] = "{linker} {fpath} -o {opath} {opts} {sopts}".format(
    #     compiler = cpp_compiler,
    #     fpath = file.path,
    #     opath = _get_object_file_name(file.path),
    #     opts = " ".join(context_args + rule_linkopts),
    #     sopts = " ".join(copts if file_extention_match(file, C_ALLOWED_FILES_EXT) else cxxopts),
    # )
    # link_cmd["file"] = file.path
    # link_cmd["outputs"] = _get_object_file_name(file.path)
    # compile_commands.append(link_cmd)

    cc_file = ctx.actions.declare_file(target.label.name + ".compile_commands.json")
    ctx.actions.write(cc_file, json.encode_indent(compile_commands, indent="    "))

    return [
        OutputGroupInfo(report = depset(direct = [cc_file])),
    ]

compile_commands = aspect(
    implementation = _compile_commands_impl,
    attrs = {
        "execute_headers": attr.bool(default = False),
    },
    fragments = ["cpp"], # ctx.fragments.cpp. [copts, cxxopts, ...]
    attr_aspects = ['deps'],
    toolchains = ["@bazel_tools//tools/cpp:toolchain_type"],
)
