"""
This file define a rule to execute clang_tidy

Inspired by: https://github.com/erenon/bazel_clang_tidy
"""

load("@bazel_tools//tools/build_defs/cc:action_names.bzl", "ACTION_NAMES")
load("@bazel_utilities//tools:utils.bzl", "toolchain_flags", "rule_files", "file_extention_match", "C_ALLOWED_FILES_EXT", "CC_HEADER")

def _execute_clang_tidy(ctx,
        file,
        compilation_context,
        flags
    ):

    local_run = len(ctx.files._clang_tidy_executable) == 0

    report_file = ctx.actions.declare_file("clang_tidy/" + file.path + ".yaml")
    
    args = ctx.actions.args()

    # clang-tidy args
    args.add("--config-file", ctx.file._clang_tidy_config.path)
    if ctx.attr.report_to_file:
        args.add("--export-fixes", report_file.path)
    args.add(file.path)

    args.add("--checks={}".format(",".join(TIDY_FORCE_FLAGS)))
    args.add("--warnings-as-errors={}".format(",".join(TIDY_FORCE_FLAGS)))

    if ctx.attr.system_header_errors:
        args.add("-system-headers")

    # compiler args
    args.add("--")
    args.add_all(flags)

    args.add_all(compilation_context.defines.to_list(), before_each = "-D")
    args.add_all(compilation_context.local_defines.to_list(), before_each = "-D")
    args.add_all(compilation_context.includes.to_list(), before_each = "-I")
    args.add_all(compilation_context.framework_includes.to_list(), before_each = "-F")
    args.add_all(compilation_context.quote_includes.to_list(), before_each = "-iquote")
    args.add_all(compilation_context.system_includes.to_list(), before_each = "-isystem")

    ctx.actions.run_shell(
        mnemonic = "ClangTidy",
        inputs = [ ctx.file._clang_tidy_config ],
        outputs = [ report_file ],
        tools = [] if local_run else [ ctx.files._clang_tidy_executable[0] ],
        arguments = [args],
        command = "touch {report_path} && {clang_tidy} $@".format(
            report_path = report_file.path,
            clang_tidy = "clang-tidy" if local_run else ctx.files._clang_tidy_executable[0],
        ),
    )

    return [ report_file ]

def _safe_flags(flags):
    # Some flags might be used by GCC, but not understood by Clang.
    # Remove them here, to allow users to run clang_tidy, without having
    # a clang toolchain configured (that would produce a good command line with --compiler clang)
    return [flag for flag in flags if flag not in COMPILER_FILTER_FLAGS]

def _compile_commands_impl(target, ctx):
    # Ignore if it's not a C/C++ target
    if not CcInfo in target:
        return []

    # Ignore external targets
    if target.label.workspace_root.startswith("external"):
        return []

    files = rule_files(ctx.rule)
    compilation_context = target[CcInfo].compilation_context
    rule_copts = ctx.rule.attr.copts if hasattr(ctx.rule.attr, "copts") else []
    copts = _safe_flags(toolchain_flags(ctx, ACTION_NAMES.c_compile) + rule_copts) + [ "-xc" ]
    cxxopts = _safe_flags(toolchain_flags(ctx, ACTION_NAMES.cpp_compile) + rule_copts) + [ "-xc++" ]

    report_files = []
    for file in files:
        if ctx.attr.skip_headers and file_extention_match(file, CC_HEADER):
            continue
        report_files += _execute_clang_tidy(
            ctx = ctx,
            file = file,
            compilation_context = compilation_context,
            flags = cxxopts
        )

    return [
        OutputGroupInfo(report = depset(direct = report_files)),
    ]

compile_commands = aspect(
    implementation = _compile_commands_impl,
    attrs = {
        "report_to_file": attr.bool(default = False),
        "enable_error": attr.bool(default = False),
        "system_header_errors": attr.bool(default = False),

        "skip_headers": attr.bool(default = False),

        "_clang_tidy_executable": attr.label(default = Label("@bazel_utilities//tools:clang_tidy_executable")),
        "_clang_tidy_config": attr.label(allow_single_file = True, default = Label("@bazel_utilities//tools:clang_tidy_config")),
    },
    fragments = ["cpp"], # ctx.fragments.cpp. [copts, cxxopts, ...]
    toolchains = ["@bazel_tools//tools/cpp:toolchain_type"],
)
