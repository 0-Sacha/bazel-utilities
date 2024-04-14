"""unpack functions

This file define all unpack function that need to be used when using template
"""

load(
    "@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl",
    "with_feature_set",
    "artifact_name_pattern"
)

def unpack_flags_pack(flags_packed):
    """Unpack Flags
    
    This function unpack the flags dict given as input.
    flags: {type} | {type}/{feature}
        type:
            - copts
            - cppcopts
            - conlycopts
            - cxxcopts

            - linkopts
            
            - cov
            - ccov
            - lcov

            - !compile_all override of copts
            - !link_all override of linkopts
        feature:
            - dbg
            - opt
            - fastbuild
            - Any other custom feature

    Args:
        flags_packed: packed flags from the ctx
      
    Returns:
        The list of all flags, each flag is now an dict:
            - type
            - flags
            - with_features: the with_features list
    """
    flags_unpacked = []
    for flag_type, flag_flags in flags_packed.items():
        # filters name and json mode
        if flag_type.startswith('$'):
            flag_flags = json.decode(flag_flags)
            flag_type = flag_type[1:]
        elif flag_type.startswith('#'):
            flag_flags = flag_flags.split(';')
            flag_type = flag_type[1:]
        
        if flag_type.startswith('%'):
            flag_type = flag_type[flag_type.find('%') + 1:]
        
        patterns = flag_type.split('/')
        flag_types = []
        if patterns[0].startswith('$'):
            patterns[0] = patterns[0][1:]
            flag_types = json.decode(patterns[0])
        elif patterns[0].startswith('#'):
            patterns[0] = patterns[0][1:]
            flag_types = patterns[0].split(';')
        else:
            flag_types.append(patterns[0])

        with_features = []
        if len(patterns) > 1:
            features_filters = patterns[1].split(';')
            for filter in features_filters:
                if filter.startswith('[') == False:
                    if filter.startswith('!'):
                        with_features.append(with_feature_set(not_features = [filter]))
                    else:
                        with_features.append(with_feature_set(features = [filter]))
                else:
                    filters = json.decode(filter)
                    f_with = []
                    f_without = []
                    for subfilter in filters:
                        if subfilter.startswith('!'):
                            f_without.append(subfilter)
                        else:
                            f_with.append(subfilter)
                    with_features.append(with_feature_set(features = f_with, not_features = f_without))

        for flag_type in flag_types:
            flags_unpacked.append({
                "type": flag_type,
                "with_features": with_features,
                "flags": flag_flags
            })
    return flags_unpacked

def flags_unpacked_from_kwargs(**kwargs):
    """Make flags_unpacked from kwargs
    
    Args:
        **kwargs: "type"=[flags]
    Returns:
        The list of all flags, each flag is now an dict:
            - type
            - flags
            - with_features: the with_features list
    """
    flags_unpacked = []
    for flag_type, flags in kwargs:
        flags_unpacked.append({
                "type": flag_type,
                "with_features": [],
                "flags": flags
            })
    return flags_unpacked

def flags_unpacked_DIL(defines, includedirs, linkdirs):
    """Make flags_unpacked from [ defines, includedirs, linkdirs ]
    
    Args:
        defines: preprocessor defines
        includedirs: include directories
        linkdirs: lib directories
    Returns:
        The list of all flags, each flag is now an dict:
            - type
            - flags
            - with_features: the with_features list
    """
    flags_unpacked = []
    flags_unpacked.append({
        "type": "!compile_all",
        "with_features": [],
        "flags": [ "-D{}".format(define) for define in defines ] + [ "-I{}".format(includedir) for includedir in includedirs]
    })
    flags_unpacked.append({
        "type": "!link_all",
        "with_features": [],
        "flags": [ "-L{}".format(linkdir) for linkdir in linkdirs]
    })
    return flags_unpacked

def unpack_artifacts_patterns_pack(artifacts_patterns_packed):
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
