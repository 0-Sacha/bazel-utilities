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

    This function return the full tool name (including optionals prefix and extention) from its type and fallbacks
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

def toolchain_tool_path(toolchain_bins, tool_name):
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
            return file.path
    tool_name_woext = tool_name.split('.')[0]
    for file in toolchain_bins:
        file_woext = file.basename.split('.')[0]
        if file_woext == tool_name_woext:
            return file.path
        if file_woext.startswith(tool_name_woext):
            matchs.append(file)

    if len(matchs) == 0:
        fail("Tool NOT Found : '{}' in {} !!".format(tool_name, toolchain_bins))
    
    if len(matchs) > 1:
        print("Warrning: multiple Tool Found for {} !!. Keeping first one : {}".format(tool_name, matchs[0])) # buildifier: disable=print
    return matchs[0].path

def _get_path_fixed(path):
    path = path.replace("\\", "/")
    segments = path.split("/")
    if len(segments) < 4:
        return path
    if segments[0] == "external":
        return "/".join(segments[2:])
    return path

def link_actions_to_tool_bins(toolchain_bins, toolchain_bins_names, tool_type, action_names, **kwargs):
    """Create an list of action_config

    This function create an list of action_config

    Args:
        toolchain_bins: The rule context toolchain_bins
        toolchain_bins_names: dict of names of the toolchains binaries
        tool_type: The tool_type
        action_names: The list of all action_name that need to be created
        **kwargs: kwargs to be forwarded to action_config

    Returns:
        The list of all action_config that have been created
    """
    path = toolchain_tool_path(toolchain_bins, compiler_tool_name(toolchain_bins_names, tool_type))
    if path == None:
        fail("{} Resulted in an empty path".format(tool_type))
    action_configs = []
    for action_name in action_names:
        action_configs.append(
            action_config(
                action_name = action_name,
                tools = [ tool(path = _get_path_fixed(path)) ],
                **kwargs
            )
        )
    return action_configs

def link_actions_to_tool_paths(toolchain_paths, tool_type, action_names, **kwargs):
    """Create an list of action_config

    This function create an list of action_config

    Args:
        toolchain_paths: The rule context toolchain_paths dict
        tool_type: The tool_type
        action_names: The list of all action_name that need to be created
        **kwargs: kwargs to be forwarded to action_config

    Returns:
        The list of all action_config that have been created
    """
    path = toolchain_paths[tool_type]
    if path == None:
        fail("{} Resulted in an empty path".format(tool_type))
    action_configs = []
    for action_name in action_names:
        action_configs.append(
            action_config(
                action_name = action_name,
                tools = [ tool(path = _get_path_fixed(path)) ],
                **kwargs
            )
        )
    return action_configs

def toolchain_paths_from_bins(toolchain_bins, toolchain_bins_paths):
    """Create the toolchain's tools dict

    Args:
        toolchain_bins: The rule context toolchain_bins dict
        toolchain_bins_paths: The rule context toolchain_bins dict

    Returns:
        The toolchain's tools list
    """
    
    toolchain_paths = {}

    tool_index = 0

    for _, tool_type in toolchain_bins.items():
        if tool_type not in TOOLCHAIN_BIN_TYPE:
            print("Toolchain binaries: not supported tool_type: {}".format(tool_type)) # buildifier: disable=print
        
        if tool_type in toolchain_paths:
            print("Toolchain binaries: tool_type: {} already defined, Skipping".format(tool_type)) # buildifier: disable=print
            continue
        
        toolchain_paths[tool_type] = toolchain_bins_paths[tool_index].path

        tool_index += 1

    return toolchain_paths

def toolchain_paths_from_bins_grp(toolchain_bins, toolchain_bins_names):
    """Create the toolchain's tools dict

    Args:
        toolchain_bins: The rule context toolchain_bins
        toolchain_bins_names: dict of names of the toolchains binaries

    Returns:
        The toolchain's tools list
    """
    toolchain_paths = {}
    
    toolchain_paths["cpp"] =     toolchain_tool_path(toolchain_bins, compiler_tool_name(toolchain_bins_names, "cpp"))
    toolchain_paths["cc"] =      toolchain_tool_path(toolchain_bins, compiler_tool_name(toolchain_bins_names, "cc"))
    toolchain_paths["cxx"] =     toolchain_tool_path(toolchain_bins, compiler_tool_name(toolchain_bins_names, "cxx"))
    toolchain_paths["as"] =      toolchain_tool_path(toolchain_bins, compiler_tool_name(toolchain_bins_names, "as"))
    toolchain_paths["ar"] =      toolchain_tool_path(toolchain_bins, compiler_tool_name(toolchain_bins_names, "ar"))
    toolchain_paths["ld"] =      toolchain_tool_path(toolchain_bins, compiler_tool_name(toolchain_bins_names, "ld"))
    
    toolchain_paths["objcopy"] = toolchain_tool_path(toolchain_bins, compiler_tool_name(toolchain_bins_names, "objcopy"))
    toolchain_paths["strip"] =   toolchain_tool_path(toolchain_bins, compiler_tool_name(toolchain_bins_names, "strip"))
    
    toolchain_paths["cov"] =     toolchain_tool_path(toolchain_bins, compiler_tool_name(toolchain_bins_names, "cov"))
    
    toolchain_paths["size"] =    toolchain_tool_path(toolchain_bins, compiler_tool_name(toolchain_bins_names, "size"))
    toolchain_paths["nm"] =      toolchain_tool_path(toolchain_bins, compiler_tool_name(toolchain_bins_names, "nm"))
    toolchain_paths["objdump"] = toolchain_tool_path(toolchain_bins, compiler_tool_name(toolchain_bins_names, "objdump"))
    toolchain_paths["dwp"] =     toolchain_tool_path(toolchain_bins, compiler_tool_name(toolchain_bins_names, "dwp"))

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
