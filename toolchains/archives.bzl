""

def gen_archives_registry(archives_version):
    archives_registry = {}
    for archive_version in archives_version:
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

