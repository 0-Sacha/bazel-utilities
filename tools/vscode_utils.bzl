""

###########################
######### Configs #########
###########################

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
    fragments = [ "cpp", "platform" ],
    attr_aspects = [ "dep", "deps" ],
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

def _get_final_flags(target):
    context = {}
    context["includes"] = target[VSCodeFlagsInfo].includes
    context["defines"] = target[VSCodeFlagsInfo].defines
    context["compiler_args"] = []
    context["cpp_standard"] = "c++20"
    context["c_standard"] = "c17"

    for flag in target[VSCodeFlagsInfo].flags:
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

def _impl_vscode_config(target, ctx):
    config_template = {
        "name": "default",
        "includePath": [],
        "defines": [],
        "cppStandard": "c++20",
        "cStandard": "c17",
        "compilerPath": "gcc",
        "compilerArgs": [],
    }

    toolchain_data = dict(config_template)

    context_flags = _get_final_flags(ctx)

    toolchain_data["name"] = "{}_{}".format(ctx.label.name, target.label.name)
    
    toolchain_data["includePath"] = context_flags["includes"]
    toolchain_data["defines"] = context_flags["defines"]

    toolchain_data["cStandard"] = context_flags["c_standard"]
    toolchain_data["cppStandard"] = context_flags["cpp_standard"]
    if vscode_project.intelli_sense_mode != "":
        toolchain_data["intelliSenseMode"] = ctx.attr.intelli_sense_mode
    toolchain_data["compilerPath"] = ctx.attr.compiler.path
    toolchain_data["compilerArgs"] = context_flags["compiler_args"] + ctx.attr.compiler_args

    ctx.actions.write(
        output = ctx.outputs.config_json,
        content = json.encode_indent(toolchain_data, indent = '\t')
    )

vscode_config = aspect(
    implementation = _impl_vscode_config,
    attrs = {
        'config_json': attr.output(),
        'compiler': attr.label(mandatory = True, allow_single_file = True),
        'compiler_args': attr.string_list(default = []),
        'intelli_sense_mode': attr.string(default = "gcc-x64"),
    },
    attr_aspects = [ "dep", "deps" ],
    fragments = [ "cpp", "platform" ],
    provides = []
)


#########################
######### Tasks #########
#########################

def _impl_vscode_task(target, ctx):
    task_template = {
        "label": "",
        "type": "shell",
        "command": "",
        "options": {
            "cwd": "${workspaceFolder}"
        },
    }

    task_data = dict(task_template)
    
    task_data["label"] = "{}_{}".format(ctx.label.name, target.label.name)
    task_data["command"] = "bazelisk {type} {verbose} -c {opt} {platform} {package}".format(
        type = ctx.attr.type,
        verbose = "-s" if ctx.attr.verbose else "",
        opt = ctx.attr.compilation_mode
        platform = "--platforms=//{}:{}".format(ctx.fragments.platform.platform.package, ctx.fragments.platform.platform.name) if ctx.fragments.platform.platform != None else "",
        package = "//{}:{}".format(target.label.package, target.label.name))
    task_data["type"] = ctx.attr.task_type
    task_data["options"]["cwd"] = ctx.attr.cwd
    if ctx.attr.is_default == True:
        task_data["group"] = {
            "kind": "build",
            "isDefault": True
        }
    
    ctx.actions.write(
        output = ctx.outputs.tasks_json,
        content = json.encode_indent(task_data, indent = '\t')
    )

vscode_task = aspect(
    implementation = _impl_vscode_task,
    attrs = {
        'tasks_json': attr.output(),
        'type': attr.string(default = "build"),
        'verbose': attr.string(default = False),
        'compilation_mode': attr.bool(default = "fastbuild"),
        'task_type': attr.string(default = "shell"),
        'cwd': attr.string(default = "${workspaceFolder}"),
        'is_default': attr.bool(default = False),
    },
    attr_aspects = [],
    fragments = [ "cpp", "platform" ],
    provides = []
)


##########################
######### Launch #########
##########################

def _impl_vscode_launch(target, ctx):
    if hasattr(ctx.rule.attr, '_is_executable') == False or ctx.rule.attr._is_executable == False:
        # buildifier: disable=print
        print("The rule used for generating vscode tasks must be executable")

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

    launch_data = dict(launch_template)
    
    launch_data["name"] = "{}_{}".format(ctx.label.name, target.label.name)
    launch_data["program"] = target[DebugPackageInfo].unstripped_file.path
    launch_data["type"] = ctx.attr.launch_type
    launch_data["request"] = ctx.attr.launch_request
    launch_data["cwd"] = ctx.attr.cwd
    launch_data["miDebuggerPath"] = ctx.file.debugger.path
    launch_data["MIMode"] = ctx.attr.mimode
    if ctx.attr.extar != 0:
        launch_data["miDebuggerServerAddress"] = ":{}".format(vscode_launch.extar)
    launch_data["args"] = ctx.attr.args
    if ctx.attr.pre_launch_task != None:
        launch_data["preLaunchTask"] = ctx.attr.pre_launch_task[VSCodeTaskInfo].label.name
    launch_data["externalConsole"] = ctx.attr.external_console
    
    ctx.actions.write(
        output = ctx.outputs.launch_json,
        content = json.encode_indent(launch_data, indent = '\t')
    )

vscode_launch = aspect(
    implementation = _impl_vscode_launch,
    attrs = {
        'launch_json': attr.output(),
        'launch_type': attr.string(default = "cppdbg"),
        'launch_request': attr.string(default = "launch"),
        'cwd': attr.string(default = "${workspaceFolder}"),
        'debugger': attr.label(mandatory = True, allow_single_file = True),
        'mimode': attr.string(default = "gdb"),
        'extar': attr.int(default = 0),
        'args': attr.string_list(default = []),
        'pre_launch_task': attr.label(default = None, providers = [VSCodeTaskInfo]),
        'external_console': attr.bool(default = False),
    },
    attr_aspects = [],
    fragments = [ "cpp", "platform" ],
    provides = []
)
