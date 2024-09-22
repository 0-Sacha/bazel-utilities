"""Extras Filegroups

"""

def filegroup_translate_to_starlark(filegroups):
    """extras_filegroup_translate

    This macro translate the label list input to a starlark list with the correct form:
        - "@repo//package:name"

    Args:
        filegroups: Name of the repo that will be created
    
    Returns:
        The same list but as starlark list
    """
    starlark_filegroup = []
    for filegroup in filegroups:
        starlark_filegroup.append(
            "@{}//{}:{}".format(
                filegroup.repo_name,
                filegroup.package,
                filegroup.name,
            )
        )
    return starlark_filegroup
