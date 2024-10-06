"""Host handlers

"""

def get_host_infos_from_rctx(os_name, os_arch):
    """Host OS, Arch, Name

    This function return the host os, arch and name according to the one used in archives registry

    Args:
        os_name: The rctx os_name
        os_arch: The rctx os_arch
    Returns:
        Host OS, Arch, Name
    """
    host_os = "linux"
    host_arch = "x86_64"

    if "windows" in os_name:
        host_os = "windows"
    elif "mac" in os_name:
        host_os = "darwin"

    if "amd64" in os_arch:
        host_arch = "x86_64"
    elif "aarch64":
        host_arch = "aarch64"

    return host_os, host_arch, "{}_{}".format(host_os, host_arch)

HOST_EXTENSION = {
    "windows": ".exe",
    "linux": "",
    "darwin": "",
}
