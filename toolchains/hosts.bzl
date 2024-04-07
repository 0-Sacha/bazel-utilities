""

def get_host_infos_from_rctx(os_name, os_arch):
    ""
    host_os = "linux"
    host_arch = "x86_64"

    if "windows" in os_name:
        host_os = "windows"
    elif "mac" in os_name:
        host_os = "osx"

    if "amd64" in os_arch:
        host_arch = "x86_64"
    elif "aarch64":
        host_arch = "arm64"

    return host_os, host_arch, "{}_{}".format(host_os, host_arch)
