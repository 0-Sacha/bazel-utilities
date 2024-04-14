""

load(":vscode_utils.bzl", "VSCodeTaskInfo", "VSCodeLaunchInfo", "VSCodeProjectInfo")

def _c_cpp_properties(ctx):
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

    for vscode_project_info in ctx.attr.vscode_projects:
        vscode_project = vscode_project_info[VSCodeProjectInfo]
        toolchain_data = dict(config_template)

        toolchain_data["name"] = vscode_project.name
        toolchain_data["includePath"] = vscode_project.includes
        toolchain_data["defines"] = vscode_project.defines
        toolchain_data["cppStandard"] = vscode_project.cpp_standard
        toolchain_data["cStandard"] = vscode_project.c_standard
        if vscode_project.intelli_sense_mode != "":
            toolchain_data["intelliSenseMode"] = vscode_project.intelli_sense_mode
        toolchain_data["compilerPath"] = vscode_project.compiler_path
        toolchain_data["compilerArgs"] = vscode_project.compiler_args

        properties_file["configurations"].append(toolchain_data)

    return json.encode_indent(properties_file, indent = '\t')

def _launch(ctx):
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

    for vscode_project_info in ctx.attr.vscode_projects:
        for launch_info in vscode_project_info[VSCodeProjectInfo].launch_configs:
            launch_struct = launch_info[VSCodeLaunchInfo]
            launch_data = dict(launch_template)
            
            launch_data["name"] = launch_struct.name
            launch_data["type"] = launch_struct.type
            launch_data["program"] = vscode_project_info[VSCodeProjectInfo].elf_path
            launch_data["cwd"] = launch_struct.cwd
            launch_data["externalConsole"] = launch_struct.external_console
            launch_data["miDebuggerPath"] = launch_struct.debugger_path
            if launch_info.extar != 0:
                launch_data["miDebuggerServerAddress"] = ":{}".format(launch_info.extar)
            if launch_info.pre_launch_task != None:
                launch_data["preLaunchTask"] = launch_info.pre_launch_task[VSCodeTaskInfo].label.name
            
            launch_file["configurations"].append(launch_data)

    return json.encode_indent(launch_file, indent = '\t')

def _tasks(ctx):
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

    for vscode_project_info in ctx.attr.vscode_projects:
        for task_info in vscode_project_info[VSCodeProjectInfo].task_configs:
            task_struct = task_info[VSCodeLaunchInfo]
            task_data = dict(task_template)
            
            task_data["label"] = task_struct.label
            task_data["type"] = task_struct.type
            task_data["command"] = task_struct.cmd.format(vscode_project_info[VSCodeProjectInfo].label.name)
            task_data["options"]["cwd"] = task_struct.cwd
            if task_struct.is_default == True:
                task_data["group"] = {
                    "kind": "build",
                    "isDefault": True
                }
            
            tasks_file["tasks"].append(task_data)

    return json.encode_indent(tasks_file, indent = '\t')

def _impl_vscode_files(ctx):
    c_cpp_properties = ctx.actions.declare_file("generated.vscode/c_cpp_properties.json")
    launch = ctx.actions.declare_file("generated.vscode/launch.json")
    tasks = ctx.actions.declare_file("generated.vscode/tasks.json")

    ctx.actions.write(
        output = c_cpp_properties,
        content = _c_cpp_properties(ctx)
    )
    ctx.actions.write(
        output = launch,
        content = _launch(ctx)
    )
    ctx.actions.write(
        output = tasks,
        content = _tasks(ctx)
    )

    return [DefaultInfo(files = depset([
        c_cpp_properties,
        launch,
        tasks
    ]))]

vscode_files = rule(
    implementation = _impl_vscode_files,
    attrs = {
        'vscode_projects': attr.label_list(providers = [VSCodeProjectInfo]),
    },
    provides = [DefaultInfo]
)
