""

load("@bazel_skylib//rules:copy_file.bzl", "copy_file")

#########################
######### Flags #########
#########################

VSCodeFlagsInfo = provider("", fields = {
    'includes': "",
    'defines': "",
    'flags': "",
})

def _impl_vscode_flags(target, ctx):
    includes = []
    defines = []
    flags = []

    if hasattr(ctx.rule.attr, 'includes'):
        includes += ctx.rule.attr.includes
    if hasattr(ctx.rule.attr, 'defines'):
        defines += ctx.rule.attr.defines

    if hasattr(ctx.rule.attr, 'copts'):
        flags += ctx.rule.attr.copts
    if hasattr(ctx.rule.attr, 'conlyopts'):
        flags += ctx.rule.attr.conlyopts
    if hasattr(ctx.rule.attr, 'cxxopts'):
        flags += ctx.rule.attr.cxxopts
    if hasattr(ctx.rule.attr, 'linkopts'):
        flags += ctx.rule.attr.linkopts

    if hasattr(ctx.rule.attr, 'deps'):
        for dep in ctx.rule.attr.deps:
            includes += dep[VSCodeFlagsInfo].includes
            defines += dep[VSCodeFlagsInfo].defines
            flags += dep[VSCodeFlagsInfo].flags

    return [
        VSCodeFlagsInfo(
            includes = includes,
            defines = defines,
            flags = flags,
        )
    ]

vscode_flags = aspect(
    implementation = _impl_vscode_flags,
    fragments = [],
    attr_aspects = [ "deps" ],
    provides = [VSCodeFlagsInfo]
)

def _options_includes(flag):
    return "includes", flag[2:]

def _options_define(flag):
    return "defines", flag[2:]

def _options_link(flag):
    return "compiler_args", flag

def _options_standard(flag):
    option = flag[5:]
    if '++' in option:
        return "cpp_standard", option
    else:
        return "c_standard", option

def _options_others(flag):
    return "compiler_args", flag

_flag_options = {
    "-I": _options_includes,
    "-D": _options_define,
    "-L": _options_link,
    "-l": _options_link,
    "-std=": _options_standard,
}

def _get_final_flags(target, cpp_fragments):
    context = {}
    context["includes"] = target[VSCodeFlagsInfo].includes
    context["defines"] = target[VSCodeFlagsInfo].defines
    context["compiler_args"] = []
    context["cpp_standard"] = [ "c++20" ]
    context["c_standard"] = [ "c17" ]

    flags = target[VSCodeFlagsInfo].flags + cpp_fragments.copts + cpp_fragments.conlyopts + cpp_fragments.cxxopts + cpp_fragments.linkopts
    for flag in flags:
        matched = False
        for option, callback in _flag_options.items():
            if flag.startswith(option):
                idx, values = callback(flag)
                context[idx].append(values)
                matched = True
                break
        if not matched:
            idx, values = _options_others(flag)
            context[idx].append(values)

    return context


###########################
######### Configs #########
###########################

VSCodeConfigInfo = provider("", fields = {
    "name": "",

    "includes": "",
    "defines": "",
    "cpp_standard": "",
    "c_standard": "",

    "intelli_sense_mode": "",
    "compiler_path": "",
    "compiler_args": "",
})

def _impl_vscode_config(ctx):
    context = _get_final_flags(ctx.attr.target, ctx.fragments.cpp)
    return [
        VSCodeConfigInfo(
            name = ctx.label.name,

            includes = context["includes"],
            defines = context["defines"],
            cpp_standard = context["cpp_standard"][-1],
            c_standard = context["c_standard"][-1],

            compiler_path = ctx.file.compiler.path,
            compiler_args = context["compiler_args"] + ctx.attr.compiler_args,
            intelli_sense_mode = ctx.attr.intelli_sense_mode,
        ),
    ]

vscode_config = rule(
    implementation = _impl_vscode_config,
    attrs = {
        'target' : attr.label(aspects = [vscode_flags]),
        'compiler': attr.label(mandatory = True, allow_single_file = True),
        'compiler_args': attr.string_list(default = []),
        'intelli_sense_mode': attr.string(default = "gcc-x64"),
    },
    fragments = [ "cpp", "platform" ],
    provides = [VSCodeConfigInfo]
)


VSCodeConfigJsonInfo = provider("", fields = {
    "path": "",
})

def _impl_vscode_configs_json(ctx):
    c_cpp_properties_file = {
        "version": 4,
        "configurations": [ ]
    }

    config_template = {
        "name": "default",
        "includePath": [],
        "defines": [],
        "cppStandard": "c++20",
        "cStandard": "c17",
        "compilerPath": "gcc",
        "compilerArgs": [],
    }

    for _vscode_config in ctx.attr.configs:
        vscode_config = _vscode_config[VSCodeConfigInfo]
        toolchain_data = dict(config_template)

        toolchain_data["name"] = vscode_config.name
        
        toolchain_data["includePath"] = vscode_config.includes
        toolchain_data["defines"] = vscode_config.defines

        toolchain_data["cStandard"] = vscode_config.c_standard
        toolchain_data["cppStandard"] = vscode_config.cpp_standard
        if vscode_config.intelli_sense_mode != "":
            toolchain_data["intelliSenseMode"] = vscode_config.intelli_sense_mode
        toolchain_data["compilerPath"] = vscode_config.compiler_path
        toolchain_data["compilerArgs"] = vscode_config.compiler_args

        c_cpp_properties_file["configurations"].append(toolchain_data)

    ctx.actions.write(
        output = ctx.outputs.c_cpp_properties_json,
        content = json.encode_indent(c_cpp_properties_file, indent = '\t')
    )
    
    return [
        VSCodeConfigJsonInfo(
            path = ctx.outputs.c_cpp_properties_json
        )
    ]

vscode_configs_json = rule(
    implementation = _impl_vscode_configs_json,
    attrs = {
        'c_cpp_properties_json': attr.output(mandatory = True),
        'configs': attr.label_list(mandatory = True, providers = [VSCodeConfigInfo]),
    },
    fragments = [],
    provides = [VSCodeConfigJsonInfo]
)


#########################
######### Tasks #########
#########################

VSCodeTaskInfo = provider("", fields = {
    "label": "",
    "type": "",
    "command": "",
    "cwd": "",
    "is_default": "",
})

def _impl_vscode_task(ctx):
    command = "bazelisk {type} {verbose} -c {opt} {platform} {package}".format(
        type = ctx.attr.type,
        verbose = "-s" if ctx.attr.verbose else "",
        opt = ctx.attr.compilation_mode,
        # From fragments: platform = "--platforms=//{}:{}".format(ctx.fragments.platform.platform.package, ctx.fragments.platform.platform.name) if ctx.fragments.platform.platform != None else "",
        platform = "--platforms={}".format(ctx.attr.platform) if ctx.attr.platform != "" else "",
        package = "//{}:{}".format(ctx.attr.target.label.package, ctx.attr.target.label.name))

    return [
        VSCodeTaskInfo(
            label = ctx.label.name,
            type = ctx.attr.task_type,
            command = command,
            cwd = ctx.attr.cwd,
            is_default = ctx.attr.is_default,
        )
    ]

vscode_task = rule(
    implementation = _impl_vscode_task,
    attrs = {
        'target' : attr.label(mandatory = True),
        'type': attr.string(default = "build"),
        'verbose': attr.bool(default = False),
        'compilation_mode': attr.string(default = "fastbuild"),
        'platform': attr.string(default = ""),
        'task_type': attr.string(default = "shell"),
        'cwd': attr.string(default = "${workspaceFolder}"),
        'is_default': attr.bool(default = False),
    },
    fragments = [],
    provides = [VSCodeTaskInfo]
)


VSCodeTasksJsonInfo = provider("", fields = {
    "path": "",
})

def _impl_vscode_tasks_json(ctx):
    tasks_file = {
        "version": "2.0.0",
        "tasks": []
    }
    
    task_template = {
        "label": "",
        "type": "shell",
        "command": "",
        "options": {
            "cwd": "${workspaceFolder}"
        },
    }

    for _vscode_task in ctx.attr.tasks:
        vscode_task = _vscode_task[VSCodeTaskInfo]
        task_data = dict(task_template)
        
        task_data["label"] = vscode_task.label
        task_data["command"] = vscode_task.command
        task_data["type"] = vscode_task.type
        task_data["options"]["cwd"] = vscode_task.cwd
        if vscode_task.is_default == True:
            task_data["group"] = {
                "kind": "build",
                "isDefault": True
            }

        tasks_file["tasks"].append(task_data)
        
    ctx.actions.write(
        output = ctx.outputs.tasks_json,
        content = json.encode_indent(tasks_file, indent = '\t')
    )
    
    return [
        VSCodeTasksJsonInfo(
            path = ctx.outputs.tasks_json
        )
    ]

vscode_tasks_json = rule(
    implementation = _impl_vscode_tasks_json,
    attrs = {
        'tasks_json': attr.output(mandatory = True),
        'tasks': attr.label_list(mandatory = True, providers = [VSCodeTaskInfo]),
    },
    fragments = [],
    provides = [VSCodeTasksJsonInfo]
)


##########################
######### Launch #########
##########################

VSCodeLaunchInfo = provider("", fields = {
    "name": "",
    "program": "",
    "launch_type": "",
    "launch_request": "",
    "cwd": "",
    "debugger_path": "",
    "extar": "",
    "args": "",
    "mimode": "",
    "pre_launch_task": "",
    "external_console": "",
})

def _impl_vscode_launch(ctx):
    return [
        VSCodeLaunchInfo(
            name = ctx.label.name,
            program = ctx.attr.target[DebugPackageInfo].unstripped_file.path,
            launch_type = ctx.attr.launch_type,
            launch_request = ctx.attr.launch_request,
            cwd = ctx.attr.cwd,
            debugger_path = ctx.file.debugger.path,
            extar = ctx.attr.extar,
            args = ctx.attr.args,
            mimode = ctx.attr.mimode,
            pre_launch_task = ctx.attr.pre_launch_task.label.name if ctx.attr.pre_launch_task != None else "",
            external_console = ctx.attr.external_console,
        )
    ]

vscode_launch = rule(
    implementation = _impl_vscode_launch,
    attrs = {
        'target' : attr.label(mandatory = True),
        'launch_type': attr.string(default = "cppdbg"),
        'launch_request': attr.string(default = "launch"),
        'cwd': attr.string(default = "${workspaceFolder}"),
        'debugger': attr.label(mandatory = True, allow_single_file = True),
        'extar': attr.int(default = 0),
        'args': attr.string_list(default = []),
        'mimode': attr.string(default = "gdb"),
        'pre_launch_task': attr.label(default = None, providers = [VSCodeTaskInfo]),
        'external_console': attr.bool(default = False),
    },
    fragments = [],
    provides = [VSCodeLaunchInfo]
)


VSCodeLaunchJsonInfo = provider("", fields = {
    "path": "",
})

def _impl_vscode_launch_json(ctx):
    launch_file = {
        "version": "0.2.0",
        "configurations": []
    }

    launch_template = {
        "name": "",
        "type": "",
        "program": "",
        "cwd": "${workspaceFolder}",
        "externalConsole": False,
        "miDebuggerPath": "",
        # "miDebuggerServerAddress": ":0",
        # "preLaunchTask": "",
        "request": "launch",
        "MIMode": "gdb",
    }

    for _vscode_launch in ctx.attr.launch:
        vscode_launch = _vscode_launch[VSCodeLaunchInfo]
        launch_data = dict(launch_template)
        
        launch_data["name"] = vscode_launch.name
        launch_data["program"] = vscode_launch.program
        launch_data["type"] = vscode_launch.launch_type
        launch_data["request"] = vscode_launch.launch_request
        launch_data["cwd"] = vscode_launch.cwd
        launch_data["miDebuggerPath"] = vscode_launch.debugger_path
        launch_data["MIMode"] = vscode_launch.mimode
        if vscode_launch.extar != 0:
            launch_data["miDebuggerServerAddress"] = ":{}".format(vscode_launch.extar)
        launch_data["args"] = vscode_launch.args
        if vscode_launch.pre_launch_task != None:
            launch_data["preLaunchTask"] = vscode_launch.pre_launch_task
        launch_data["externalConsole"] = vscode_launch.external_console
        
        launch_file["configurations"].append(launch_data)
    
    ctx.actions.write(
        output = ctx.outputs.launch_json,
        content = json.encode_indent(launch_file, indent = '\t')
    )

    return [
        VSCodeLaunchJsonInfo(
            path = ctx.outputs.launch_json
        )
    ]

vscode_launch_json = rule(
    implementation = _impl_vscode_launch_json,
    attrs = {
        'launch_json': attr.output(mandatory = True),
        'launch': attr.label_list(mandatory = True, providers = [VSCodeLaunchInfo]),
    },
    fragments = [],
    provides = [VSCodeLaunchJsonInfo]
)


#######################
######### All #########
#######################

def _impl_vscode_files(ctx):
    # buildifier: disable=print
    print(ctx.attr.configs[VSCodeConfigJsonInfo].path.path)
    pass

vscode_files = rule(
    implementation = _impl_vscode_files,
    attrs = {
        'configs': attr.label(mandatory = True, providers = [VSCodeConfigJsonInfo]),
        'tasks': attr.label(mandatory = True, providers = [VSCodeTasksJsonInfo]),
        'launch': attr.label(mandatory = True, providers = [VSCodeLaunchJsonInfo]),
    },
    fragments = [],
    provides = []
)
