"""Tools Utils
"""

load(
    "@rules_cc//cc:cc_toolchain_config_lib.bzl",
    "action_config",
    "tool_path",
    "tool"
)

TOOLCHAIN_BIN_TYPE = [
    "cpp",
    "cc",
    "cxx",
    "as",
    "ar",
    "ld",
    
    "objcopy",
    "strip",
    
    "cov",

    "size",
    "nm",
    "objdump",
    "dwp",

    "dbg",
]

def compiler_tool_name(toolchain_bins_names, tool_type, default = None, fallbacks = []):
    """Tool Name

    This function return the full tool name (including optionals prefix and extension) from its type and fallbacks
    Tool types:
        - cpp
        - cc
        - cxx
        - cov

        - ar
        - ld
        - nm
        - objcopy
        - objdump
        - strip
        - as
        - size

    Args:
        toolchain_bins_names: The ctx toolchain_bins_names dict
        tool_type: The tool type 
        default: The default tool name (default are gcc names)
        fallbacks: The fallback type if the first one is not found

    Returns:
        The full tool name
    """
    base_name = toolchain_bins_names.get("base_name", "")
    if tool_type in toolchain_bins_names:
        return base_name + toolchain_bins_names.get(tool_type)
    for tool_fallback in fallbacks:
        if tool_fallback in toolchain_bins_names:
            return base_name + toolchain_bins_names.get(tool_fallback)
    if default == None:
        fail("{} Not Found in the tools names dicts".format(tool_type))
    return base_name + toolchain_bins_names.get(default, default)

def toolchain_bins_get_tool(toolchain_bins, tool_name):
    """Tool Path

    This function return the tool path relative to the toolchain external/

    Args:
        toolchain_bins: The ctx toolchain_bins
        tool_name: The full tool name

    Returns:
        The tool path
    """
    matchs = []
    for file in toolchain_bins:
        if file.basename == tool_name:
            return file
    tool_name_woext = tool_name.split('.')[0]
    for file in toolchain_bins:
        file_woext = file.basename.split('.')[0]
        if file_woext == tool_name_woext:
            return file
        if file_woext.startswith(tool_name_woext):
            matchs.append(file)

    if len(matchs) == 0:
        fail("Tool NOT Found : '{}' in {} !!".format(tool_name, toolchain_bins))
    
    if len(matchs) > 1:
        print("Warrning: multiple Tool Found for {} !!. Keeping first one : {}".format(tool_name, matchs[0])) # buildifier: disable=print
    return matchs[0]

def _get_path_fixed(path):
    path = path.replace("\\", "/")
    segments = path.split("/")
    if len(segments) < 4:
        return path
    if segments[0] == "external":
        return "/".join(segments[2:])
    return path

def link_actions_to_tool(toolchain_tools, tool_type, action_names, **kwargs):
    """Create an list of action_config

    This function create an list of action_config

    Args:
        toolchain_tools: The toolchain_tools dict
        tool_type: The tool_type
        action_names: The list of all action_name that need to be created
        **kwargs: kwargs to be forwarded to action_config

    Returns:
        The list of all action_config that have been created
    """
    action_configs = []
    for action_name in action_names:
        action_configs.append(
            action_config(
                action_name = action_name,
                tools = [
                    toolchain_tools[tool_type]
                ],
                **kwargs
            )
        )
    return action_configs

def toolchain_tools_from_bins(toolchain_bins, toolchain_bins_paths):
    """Create the toolchain's tools dict

    Args:
        toolchain_bins: The rule context toolchain_bins dict
        toolchain_bins_paths: The rule context toolchain_bins dict

    Returns:
        The toolchain's tools list
    """
    toolchain_tools = {}

    tool_index = 0

    for _, tool_type in toolchain_bins.items():
        if tool_type not in TOOLCHAIN_BIN_TYPE:
            print("Toolchain binaries: not supported tool_type: {}".format(tool_type)) # buildifier: disable=print
        
        if tool_type in toolchain_tools:
            print("Toolchain binaries: tool_type: {} already defined, Ignoreping".format(tool_type)) # buildifier: disable=print
            continue
        
        toolchain_tools[tool_type] = struct(
            type_name = "tool",
            tool = toolchain_bins_paths[tool_index],
        )

        tool_index += 1

    return toolchain_tools

def toolchain_tools_from_paths(toolchain_paths):
    """Create the toolchain's tools dict

    Args:
        toolchain_paths: The rule context toolchain_paths dict

    Returns:
        The toolchain's tools list
    """
    toolchain_tools = {}

    for tool_type, tool_path in toolchain_paths.items():
        if tool_type not in TOOLCHAIN_BIN_TYPE:
            print("Toolchain binaries: not supported tool_type: {}".format(tool_type)) # buildifier: disable=print
        
        if tool_type in toolchain_tools:
            print("Toolchain binaries: tool_type: {} already defined, Ignoreping".format(tool_type)) # buildifier: disable=print
            continue
        
        toolchain_tools[tool_type] = tool(path = tool_path)

    return toolchain_tools

def toolchain_path_from_bins(toolchain_bins, toolchain_bins_paths):
    """Create the toolchain's tools dict

    Args:
        toolchain_bins: The rule context toolchain_bins dict
        toolchain_bins_paths: toolchain_bins_paths

    Returns:
        The toolchain's tools list
    """
    toolchain_paths = {}
    toolchain_tools = toolchain_tools_from_bins(toolchain_bins, toolchain_bins_paths)
    for tool_type, tool_data in toolchain_tools.items():
        toolchain_paths[tool_type] = _get_path_fixed(tool_data.tool.path)
    return toolchain_paths

def toolchain_ctx_tool_paths(toolchain_paths):
    """Create the toolchain's tools dict

    Args:
        toolchain_paths: The rule context toolchain_paths dict

    Returns:
        The toolchain's tool_paths list of tool_path
    """

    # Bazel Legacy toolchain's binaries
    tool_paths = [ tool_path(name = name, path = path) for name, path in toolchain_paths.items() ]
    tool_paths += [
        tool_path(name = "gcc", path = toolchain_paths["cc"]),
        tool_path(name = "gcov", path = toolchain_paths["cov"]),
    ]
    return tool_paths
