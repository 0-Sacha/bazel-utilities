""

VSCodeTaskInfo = provider("", fields = {
    'label': "",
    'type': "",
    'cmd': "",
    'cwd': "",
    'is_default': "",
})

def _impl_vscode_task(ctx):
    return [
        VSCodeTaskInfo(
            label = ctx.label.name,
            type = ctx.attr.type,
            cmd = ctx.attr.cmd,
            cwd = ctx.attr.cwd,
            is_default = ctx.attr.is_default,
        )
    ]

butils_vscode_task = rule(
    implementation = _impl_vscode_task,
    attrs = {
        'cmd': attr.string(mandatory = True),
        'cwd': attr.string(default = "${workspaceFolder}"),
        'type': attr.string(default = "shell"),
        'is_default': attr.bool(default = False),
    },
    provides = [VSCodeTaskInfo]
)

def vscode_task(
        name,
        compilation_mode = "dbg",
        cpu = "",
        platforms = "",
        verbose = False,
        cwd = "${workspaceFolder}",
        is_default = False,
        extras = []
    ):
    """Create a Setting for a Task on VSCode

    Args:
        name: name for the task
        compilation_mode: compilation_mode for the task
        cpu: cpu for the task
        platforms: platforms for the task
        verbose: verbose for the task
        cwd: cwd for the task
        is_default: is_default for the task
        extras: extras for the task
    """
    cmd = "bazelisk build "
    if verbose:
        cmd += "-s "
    if compilation_mode != "":
        cmd += "-c {} ".format(compilation_mode)
    if platforms != "":
        cmd += "--platforms=//:{} ".format(platforms)
    if cpu != "":
        cmd += "--cpu=//:{} ".format(cpu)
    for extra in extras:
        cmd += "{} ".format(extra)
    cmd += "{package_name}"
    butils_vscode_task(
        name = name,
        cmd = cmd,
        cwd = cwd,
        is_default = is_default,
    )


VSCodeLaunchInfo = provider("", fields = {
    'name': "",
    'type': "",
    'debugger_path': "",
    'extar': "",
    'cwd': "",
    'args': "",
    'pre_launch_task': "",
    'external_console': "",
})

def _impl_vscode_launch(ctx):
    return [
        VSCodeLaunchInfo(
            name = ctx.label.name,
            type = ctx.attr.type,
            debugger_path = ctx.file.debugger.path,
            extar = ctx.attr.extar,
            cwd = ctx.attr.cwd,
            args = ctx.attr.args,
            pre_launch_task = ctx.attr.pre_launch_task,
            external_console = ctx.attr.external_console,
        )
    ]

vscode_launch = rule(
    implementation = _impl_vscode_launch,
    attrs = {
        'type': attr.string(default = "cppdbg"),
        'debugger': attr.label(mandatory = True, allow_single_file = True),
        'extar': attr.int(default = 0),
        'cwd': attr.string(default = "${workspaceFolder}"),
        'args': attr.string_list(default = []),
        'pre_launch_task': attr.label(default = None, providers = [VSCodeTaskInfo]),
        'external_console': attr.bool(default = False),
    },
    provides = [VSCodeLaunchInfo]
)

VSCodeProjectInfo = provider("", fields = {
    'name': "",
    'elf_path': "",
    'includes': "",
    'defines': "",
    'task_configs': "",
    'launch_configs': "",

    'cpp_standard': "",
    'c_standard': "",
    'compiler_path': "",
    'compiler_args': "",
    'intelli_sense_mode': "",
})

def _impl_vscode_project(ctx):
    # buildifier: disable=print
    print(ctx.attr.project[CcInfo].compilation_context.defines)

    elf_path = ctx.attr.project[DebugPackageInfo].unstripped_file.path

    includes = ctx.attr.project[CcInfo].compilation_context.includes.to_list()
    includes += ctx.attr.project[CcInfo].compilation_context.external_includes.to_list()
    includes += ctx.attr.project[CcInfo].compilation_context.framework_includes.to_list()
    includes += ctx.attr.project[CcInfo].compilation_context.quote_includes.to_list()
    includes += ctx.attr.project[CcInfo].compilation_context.system_includes.to_list()
  
    defines = ctx.attr.project[CcInfo].compilation_context.defines.to_list()
    

    task_configs = ctx.attr.task_configs
    launch_configs = ctx.attr.launch_configs

    return [
        VSCodeProjectInfo(
            name = ctx.attr.project.label.name,
            elf_path = elf_path,
            includes = includes,
            defines = defines,
            task_configs = task_configs,
            launch_configs = launch_configs,
            cpp_standard = "c++20",
            c_standard = "c17",
            intelli_sense_mode = "",
            compiler_path = ctx.file.compiler.path,
            compiler_args = ctx.attr.compiler_args,
        ),
        ctx.attr.project[CcInfo],
        ctx.attr.project[OutputGroupInfo],
        ctx.attr.project[DebugPackageInfo],
    ]

vscode_project = rule(
    implementation = _impl_vscode_project,
    attrs = {
        'project': attr.label(providers = [CcInfo, OutputGroupInfo, DebugPackageInfo]),
        'task_configs': attr.label_list(providers = [VSCodeTaskInfo]),
        'launch_configs': attr.label_list(providers = [VSCodeLaunchInfo]),
        'compiler': attr.label(mandatory = True, allow_single_file = True),
        'compiler_args': attr.string_list(default = []),
    },
    provides = [VSCodeProjectInfo, CcInfo, OutputGroupInfo, DebugPackageInfo]
)

