""

load("@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl", "tool", "tool_path", "action_config")

def _get_tool_file(toolchain_bins, tool_name, base_name = "", extention = ""):
    matchs = []
    tool_fullname = "{}{}{}".format(base_name, tool_name, extention)
    for file in toolchain_bins:
        if file.basename == tool_fullname:
            return file
    tool_fullname_woext = "{}{}.".format(base_name, tool_name)
    for file in toolchain_bins:
        if file.basename.startswith(tool_fullname_woext):
            matchs.append(file)

    if len(matchs) == 0:
        # buildifier: disable=print
        print("Tool NOT Found : '{}' in {} !!".format(tool_fullname, toolchain_bins))
        return None
    
    if len(matchs) > 1:
        # buildifier: disable=print
        print("Warrning: multiple Tool Found for {} !!. Keeping first one : {}".format(tool_name, matchs[0]))
    return matchs[0]


def get_tool_file(toolchain_bins, tool_name, base_name = "", extention = ""):
    ""
    path = _get_tool_file(toolchain_bins, tool_name, base_name, extention)
    if path == None:
        return None
    path = path.path
    if path.startswith("external/"):
        bindir_index = path.find('/', len("external/"))
        if bindir_index != -1:
            path = path[bindir_index + 1:]
    return path

def add_action_configs(toolchain_bins, tool_name, action_names, implies = [], tool_base_name = "", tool_extention = ""):
    ""
    if tool_name == "":
        return None
    action_configs = []
    for action_name in action_names:
        path = get_tool_file(toolchain_bins, tool_name, tool_base_name, tool_extention)
        if path == None:
            continue
        action_configs.append(
            action_config(
                action_name = action_name,
                tools = [ tool(path = path) ],
                implies = implies
            )
        )
    return action_configs

def register_tools(tools):
    return [
        tool_path(name = name, path = path)
        for name, path in tools.items()
    ]
