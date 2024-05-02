"""Registry macro
"""

def gen_archives_registry(archives, mirroirs = {}):
    """Generate the toolchain registry
    
    This function generate the toolchain registry. An dict that link an version name to the data related to this version

    Args:
        archives: An list of archives data of all versions that this registry will define
        mirroirs: An optional dictionary of mirroirs
    Returns:
        The generated registry, which is:
            - A dictionary of mapping all toolchain that this registry provide; ex: 'MinGW' or 'arm-none-eabi'
                - A dictionary this specific toolchain has. Always their is the long name of each version,
                    if enabled, the short name and, if defined in one toolchain archive, the term latest
            Example of use: registry["arm-none-eabi"]["latest"]
    """
    registry = {}
    for archive in archives:
        if archive["toolchain"] not in registry:
            registry[archive["toolchain"]] = {}
        toolchain_registry = registry[archive["toolchain"]]

        archive_cpy = dict(archive)
        
        if "details" in archive_cpy:
            archive_cpy["details"] = dict(archive_cpy["details"])

        if "archives" in archive_cpy:
            archive_cpy["archives"] = dict(archive_cpy["archives"])
            for host_name, host_archive_data in archive_cpy["archives"].items():
                if archive["toolchain"] in mirroirs and archive["version"] in mirroirs[archive["toolchain"]]:
                    archive_cpy["archives"][host_name] = dict(mirroirs[archive["toolchain"]][archive["version"]])
                else:
                    archive_cpy["archives"][host_name] = dict(host_archive_data)

        toolchain_registry[archive["version"]] = archive
        if "version-short" in archive:
            toolchain_registry[archive["version-short"]] = archive
        if "latest" in archive and archive["latest"] == True:
            if "latest" in registry:
                print("Registry Already Has an latest flagged archive. Ignoring...") # buildifier: disable=print
            else:
                toolchain_registry["latest"] = archive
    return registry

def get_archive_from_registry(registry, toolchain, version):
    """Get the whole archive data from the specified registry according to the toolchain/version
    
    Args:
        registry: The registry
        toolchain: The toolchain in the registry; ex: 'MinGW' or 'arm-none-eabi'
        version: The version of the toolchain to download
    Returns:
        The whole archive
    """
    if toolchain not in registry:
        print("The provided registry doesn't support toolchain: {}".format(toolchain)) # buildifier: disable=print
        if version not in registry[toolchain]:
            print("{} toolchain doesn't define version: {}".format(toolchain, version)) # buildifier: disable=print
    return registry[toolchain][version]
