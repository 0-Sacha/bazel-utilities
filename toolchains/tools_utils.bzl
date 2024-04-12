"""Tools Utils
"""

load("@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl", "tool_path")

def compiler_get_tool_name(compiler, tool_type, default, fallbacks = []):
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
        compiler: The ctx compiler dict
        tool_type: The tool type 
        default: The default tool name (default are gcc names)
        fallbacks: The fallback type if the first one is not found

    Returns:
        The full tool name
    """
    base_name = compiler.get("base_name", "")
    if tool_type in compiler:
        return base_name + compiler.get(tool_type)
    for tool_fallback in fallbacks:
        if tool_fallback in compiler:
            return base_name + compiler.get(tool_fallback)
    return base_name + compiler.get(default, default)

def _get_tool_file(toolchain_bins, tool_name):
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
        # buildifier: disable=print
        print("Tool NOT Found : '{}' in {} !!".format(tool_name, toolchain_bins))
        return None
    
    if len(matchs) > 1:
        # buildifier: disable=print
        print("Warrning: multiple Tool Found for {} !!. Keeping first one : {}".format(tool_name, matchs[0]))
    return matchs[0]

def get_tool_path(toolchain_bins, tool_name):
    """Tool Path

    This function return the tool path

    Args:
        toolchain_bins: The ctx toolchain_bins
        tool_name: The full tool name 

    Returns:
        The tool path
    """
    path = _get_tool_file(toolchain_bins, tool_name)
    if path == None:
        return None
    path = path.path
    if path.startswith("external/"):
        bindir_index = path.find('/', len("external/"))
        if bindir_index != -1:
            path = path[bindir_index + 1:]
    return path

def register_tools(tools):
    """Tool Path List

    This function return the list of tool path from an tools list.
    Tools supported names:
        - "cpp": "/usr/bin/cpp",
        - "cc": "/usr/bin/gcc",
        - "ar": "/usr/bin/ar",
        - "ld": "/usr/bin/ld",
        - "gcov": "/usr/bin/gcov",
        - "nm": "/usr/bin/nm",
        - "objcopy": "/usr/bin/objcopy",
        - "objdump": "/usr/bin/objdump",
        - "strip": "/usr/bin/strip",
        - "dwp": "/usr/bin/dwp",

    Args:
        tools: The ctx tool list
    Returns:
        The list of tool_path
    """
    return [
        tool_path(name = name, path = path)
        for name, path in tools.items()
    ]
