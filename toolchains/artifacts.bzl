"""unpack functions

This file define all unpack function that need to be used when using template
"""

load(
    "@rules_cc//cc:cc_toolchain_config_lib.bzl",
    "artifact_name_pattern"
)

def artifacts_patterns_unpack(artifacts_patterns_packed):
    """Unpack artifacts_patterns
    
    This function unpack artifacts_patterns

    Args:
        artifacts_patterns_packed: packed artifacts_patterns from the ctx
      
    Returns:
        The list of all artifact_name_pattern
    """
    patterns = []
    for artifacts_pattern in artifacts_patterns_packed:
        unpacked = artifacts_pattern.split('/')
        if len(unpacked) != 3:
            # buildifier: disable=print
            print("Unvalid artifacts_pattern pack: {}".format(artifacts_pattern))
        patterns.append(
            artifact_name_pattern(
                category_name = unpacked[0],
                prefix = unpacked[1],
                extension = unpacked[2]
            )
        )
    return patterns
