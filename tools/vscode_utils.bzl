""

VSCodeConfigInfo = provider("", fields = {
    'name_prefix': "",
    'compiler_path': "",
    'compiler_args': "",
    'intelli_sense_mode': "",
})

def _impl_vscode_config(ctx):
    return [
        VSCodeConfigInfo(
            name = ctx.label.name,
            compiler_path = ctx.file.compiler.path,
            compiler_args = ctx.attr.compiler_args,
            intelli_sense_mode = "",
        ),
    ]

vscode_config = rule(
    implementation = _impl_vscode_config,
    attrs = {
        'compiler': attr.label(mandatory = True, allow_single_file = True),
        'compiler_args': attr.string_list(default = []),
        'intelli_sense_mode': attr.string(default = "gcc-x64"),
    },
    provides = [VSCodeConfigInfo]
)


VSCodeTaskInfo = provider("", fields = {
    'label_prefix': "",
    'type': "",
    'compilation_mode': "",
    'is_default': "",
    'verbose': "",
    'cwd': "",
    'task_type': "",
})

def _impl_vscode_task(ctx):
    return [
        VSCodeTaskInfo(
            label_prefix = ctx.label.name,
            type = ctx.attr.type,
            compilation_mode = ctx.attr.compilation_mode,
            is_default = ctx.attr.is_default,
            verbose = ctx.attr.verbose,
            cwd = ctx.attr.cwd,
            task_type = ctx.attr.type,
        )
    ]

vscode_task = rule(
    implementation = _impl_vscode_task,
    attrs = {
        'type': attr.string(default = "build"),
        'compilation_mode': attr.bool(default = "fastbuild"),
        'is_default': attr.bool(default = False),
        'verbose': attr.string(default = False),
        'cwd': attr.string(default = "${workspaceFolder}"),
        'task_type': attr.string(default = "shell"),
    },
    provides = [VSCodeTaskInfo]
)


VSCodeLaunchInfo = provider("", fields = {
    'name_prefix': "",
    'debugger_path': "",
    'launch_type': "",
    'launch_request': "",
    'mimode': "",
    'extar': "",
    'args': "",
    'pre_launch_task': "",
    'cwd': "",
    'external_console': "",
})

def _impl_vscode_launch(ctx):
    pre_launch_task = ""
    if ctx.attr.pre_launch_task != None:
        pre_launch_task = ctx.attr.pre_launch_task[VSCodeTaskInfo].label.name

    if hasattr(ctx.rule.attr, '_is_executable') == False or ctx.rule.attr._is_executable == False:
        # buildifier: disable=print
        print("The rule used for generating vscode tasks must be executable")

    return [
        VSCodeLaunchInfo(
            name_prefix = ctx.label.name,
            debugger_path = ctx.file.debugger.path,
            launch_type = ctx.attr.launch_type,
            launch_request = ctx.attr.launch_request,
            mimode = ctx.attr.mimode,
            extar = ctx.attr.extar,
            cwd = ctx.attr.cwd,
            args = ctx.attr.args,
            pre_launch_task = pre_launch_task,
            external_console = ctx.attr.external_console,
        )
    ]

vscode_launch = rule(
    implementation = _impl_vscode_launch,
    attrs = {
        'debugger': attr.label(mandatory = True, allow_single_file = True),
        'launch_type': attr.string(default = "cppdbg"),
        'launch_request': attr.string(default = "launch"),
        'mimode': attr.string(default = "gdb"),
        'extar': attr.int(default = 0),
        'args': attr.string_list(default = []),
        'pre_launch_task': attr.label(default = None, providers = [VSCodeTaskInfo]),
        'cwd': attr.string(default = "${workspaceFolder}"),
        'external_console': attr.bool(default = False),
    },
    provides = [VSCodeLaunchInfo]
)


VSCodeProjectInfo = provider("", fields = {
    'configs': "",
    'tasks': "",
    'launch': "",
})

def _impl_vscode_project(ctx):
    return [
        VSCodeProjectInfo(
            configs = ctx.attr.configs,
            tasks = ctx.attr.tasks,
            launch = ctx.attr.launch,
        ),
    ]

vscode_project = rule(
    implementation = _impl_vscode_project,
    attrs = {
        'dep': attr.label(mandatory = True),
        'configs': attr.label_list(mandatory = True, providers = [VSCodeConfigInfo]),
        'tasks': attr.label_list(default = [], providers = [VSCodeTaskInfo]),
        'launch': attr.label_list(default = [], providers = [VSCodeLaunchInfo]),
    },
    provides = [VSCodeProjectInfo]
)
