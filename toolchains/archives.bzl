"""Registry macro
"""

def gen_archives_registry(archives_data):
    """Generate the toolchain registry
    
    This function generate the toolchain registry. An dict that link an version name to the data related to this version

    Args:
        archives_data: An list of archives data of all versions that this registry will define
    Returns:
        The generated registry
    """
    archives_registry = {}
    for archive_version in archives_data:
        archives_registry[archive_version["version"]] = archive_version
        if "version-short" in archive_version:
            archives_registry[archive_version["version-short"]] = archive_version
        if "latest" in archive_version and archive_version["latest"] == True:
            if "latest" in archives_registry:
                # buildifier: disable=print
                print("Registry Already Has an latest flagged archive. Ignoring...")
            else:
                archives_registry["latest"] = archive_version
    return archives_registry

