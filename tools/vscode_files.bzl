""

load(":vscode_utils.bzl", "VSCodeConfigInfo", "VSCodeTaskInfo", "VSCodeLaunchInfo", "VSCodeProjectInfo")

def _c_cpp_properties(target, ctx, context_flags):
    properties_file = {
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

    for _vscode_config in ctx.rule.attr.configs:
        vscode_config = _vscode_config[VSCodeConfigInfo]
        vscode_project = target[VSCodeProjectInfo]
        toolchain_data = dict(config_template)

        toolchain_data["name"] = "{}_{}".format(vscode_config.name_prefix, vscode_project.name)
        
        toolchain_data["includePath"] = context_flags["includes"]
        toolchain_data["defines"] = context_flags["defines"]

        toolchain_data["cStandard"] = context_flags["c_standard"]
        toolchain_data["cppStandard"] = context_flags["cpp_standard"]
        if vscode_project.intelli_sense_mode != "":
            toolchain_data["intelliSenseMode"] = vscode_config.intelli_sense_mode
        toolchain_data["compilerPath"] = vscode_config.compiler_path
        toolchain_data["compilerArgs"] = context_flags["compiler_args"] + vscode_project.compiler_args

        properties_file["configurations"].append(toolchain_data)

    return json.encode_indent(properties_file, indent = '\t')


def _tasks(target, ctx):
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

    for _vscode_task in ctx.rule.attr.tasks:
        vscode_project = target[VSCodeProjectInfo]
        vscode_task = _vscode_task[VSCodeTaskInfo]
        task_data = dict(task_template)
        
        task_data["label"] = "{}_{}".format(vscode_task.label_prefix, vscode_project.name)
        task_data["command"] = "bazelisk {type} {verbose} -c {opt} {platform} {package}".format(
            type = vscode_task.type,
            verbose = "-s" if vscode_task.verbose else "",
            opt = vscode_task.compilation_mode
            platform = "--platforms=//{}:{}".format(ctx.fragments.platform.platform.package, ctx.fragments.platform.platform.name) if ctx.fragments.platform.platform != None else "",
            package = "//{}:{}".format(ctx.rule.attr.dep.label.package, ctx.rule.attr.dep.label.name))
        task_data["type"] = vscode_task.task_type
        task_data["options"]["cwd"] = vscode_task.cwd
        if vscode_task.is_default == True:
            task_data["group"] = {
                "kind": "build",
                "isDefault": True
            }
        
        tasks_file["tasks"].append(task_data)

    return json.encode_indent(tasks_file, indent = '\t')


def _launch(target, ctx):
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

    for _vscode_launch in ctx.rule.attr.launch:
        vscode_project = target[VSCodeProjectInfo]
        vscode_launch = _vscode_launch[VSCodeLaunchInfo]
        launch_data = dict(launch_template)
        
        launch_data["name"] = "{}_{}".format(vscode_launch.label_prefix, vscode_project.name)
        launch_data["program"] = ctx.rule.attr.dep[DebugPackageInfo].unstripped_file.path
        launch_data["type"] = vscode_launch.launch_type
        launch_data["request"] = vscode_launch.launch_request
        launch_data["cwd"] = vscode_launch.cwd
        launch_data["externalConsole"] = vscode_launch.external_console
        launch_data["miDebuggerPath"] = vscode_launch.debugger_path
        launch_data["MIMode"] = vscode_launch.mimode
        if vscode_launch.extar != 0:
            launch_data["miDebuggerServerAddress"] = ":{}".format(vscode_launch.extar)
        if vscode_launch.pre_launch_task != None:
            launch_data["preLaunchTask"] = vscode_launch.pre_launch_task[VSCodeTaskInfo].label.name
        
        launch_file["configurations"].append(launch_data)

    return json.encode_indent(launch_file, indent = '\t')


VSCodeFlagsInfo = provider("", fields = {
    'includes': "",
    'defines': "",
    'flags': "",
})

def _vscode_project(target, ctx, context_flags):
    c_cpp_properties = ctx.actions.declare_file("generated.vscode/c_cpp_properties.json")
    launch = ctx.actions.declare_file("generated.vscode/launch.json")
    tasks = ctx.actions.declare_file("generated.vscode/tasks.json")
    ctx.actions.write(
        output = c_cpp_properties,
        content = _c_cpp_properties(target, ctx, context_flags)
    )
    ctx.actions.write(
        output = launch,
        content = _launch(target, ctx)
    )
    ctx.actions.write(
        output = tasks,
        content = _tasks(target, ctx)
    )
    return depset([
            c_cpp_properties,
            launch,
            tasks
        ])
    
def _get_flags(ctx):
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
    
    return includes, defines, flags


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

def _get_final_flags(ctx):
    context = {}
    context["includes"] = ctx.rule.attr.dep[VSCodeFlagsInfo].includes
    context["defines"] = ctx.rule.attr.dep[VSCodeFlagsInfo].defines
    context["compiler_args"] = []
    context["cpp_standard"] = "c++20"
    context["c_standard"] = "c17"

    for flag in ctx.rule.attr.dep[VSCodeFlagsInfo].flags:
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

def _impl_vscode_files(target, ctx):
    includes = []
    defines = []
    flags = []
    files = depset([])

    if ctx.rule.kind == "vscode_project":
        context_flags = _get_final_flags(ctx)
        files = _vscode_project(target, ctx, context_flags)
    else:
        _includes, _defines, _flags = _get_flags(ctx)
        includes = _includes
        defines = _defines
        flags = _flags

    return [
        VSCodeFlagsInfo(
            includes = includes,
            defines = defines,
            flags = flags,
        ),
        DefaultInfo(files = files)
    ]

vscode_files = aspect(
    implementation = _impl_vscode_files,
    fragments = [ "cpp", "platform" ],
    attr_aspects = [ "dep", "deps" ],
    provides = [VSCodeFlagsInfo]
)
