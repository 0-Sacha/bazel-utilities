"""
This file define a rule to execute clang_format
"""

load("@bazel_utilities//tools:utils.bzl", "rule_files")

def _execute_clang_format(ctx, file):
    local_run = len(ctx.files._clang_format_executable) == 0

    report_file = ctx.actions.declare_file("clang_format/" + file.path)
    
    args = ctx.actions.args()

    args.add("--style=file:{}".format(ctx.file._clang_format_config.path))
    args.add(file.path)

    ctx.actions.run_shell(
        mnemonic = "ClangFormat",
        inputs = [ ctx.file._clang_format_config ],
        outputs = [ report_file ],
        tools = [] if local_run else [ ctx.files._clang_format_executable[0] ],
        arguments = [args],
        command = "{clang_format} $@ > {report_path}".format(
            report_path = report_file.path,
            clang_format = "clang-format" if local_run else ctx.files._clang_format_executable[0],
        ),
    )

    diff_file = ctx.actions.declare_file("clang_format/" + file.path + ".diff")

    fmt = "diff {file} {report_path} | tee {diff_path}"
    if ctx.attr.enable_error == False:
        fmt += " ; exit 0"
    
    ctx.actions.run_shell(
        mnemonic = "ClangFormatDiff",
        inputs = [ report_file ],
        outputs = [ diff_file ],
        command = fmt.format(
            file = file.path,
            report_path = report_file.path,
            diff_path = diff_file.path
        ),
    )

    return [ report_file, diff_file ]

def _clang_format_impl(target, ctx):
    # Ignore if it's not a C/C++ target
    if not CcInfo in target:
        return []

    # Ignore external targets
    if target.label.workspace_root.startswith("external"):
        return []

    # Tag to disable aspect
    ignore_tags = [ "no-clang-format" ]
    for tag in ignore_tags:
        if tag in ctx.rule.attr.tags:
            return []

    files = rule_files(ctx.rule)

    reports = []
    for file in files:
        reports += _execute_clang_format(
            ctx = ctx,
            file = file,
        )

    exec_report = ctx.actions.declare_file("clang_format/" + ctx.label.name + ".exec_report.json")
    ctx.actions.write(output = exec_report, content = json.encode_indent([file.path for file in files], indent = "    "))
    reports.append(exec_report)

    return [
        OutputGroupInfo(report = depset(direct = reports)),
    ]

clang_format = aspect(
    implementation = _clang_format_impl,
    attrs = {
        "enable_error": attr.bool(default = False),

        "_clang_format_executable": attr.label(default = Label("@bazel_utilities//tools/clang_format:clang_format_executable")),
        "_clang_format_config": attr.label(allow_single_file = True, default = Label("@bazel_utilities//tools/clang_format:clang_format_config")),
    },
    fragments = ["cpp"],
    toolchains = ["@bazel_tools//tools/cpp:toolchain_type"],
)
