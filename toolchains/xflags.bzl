"""
"""

load("@rules_cc//cc:cc_toolchain_config_lib.bzl", "with_feature_set")
load("//toolchains:actions_grp.bzl", "CC_ACTIONS_GRP")

XFLAGS_ACTIONS = {
    # "cpp": CC_ACTIONS_GRP.cpp_actions,
    "compile": CC_ACTIONS_GRP.compile_actions,
    "conly": CC_ACTIONS_GRP.c_actions,
    "cxx": CC_ACTIONS_GRP.cxx_actions,
    "as": CC_ACTIONS_GRP.assembler_actions,
    "link": CC_ACTIONS_GRP.link_actions,
}

def xflags_unpack(xflags_packed):
    """Unpack XFlags
    
    TODO: use regex instead of raw parsing

    This function unpack the flags dict given as input.
    flags: [$#]?(%.*%)?{types}(/{features})?
        types:
            - cpp
            - compile
            - conly
            - cxx
            - as
            - link
        features:
            - dbg
            - opt
            - fastbuild
            - Any other custom feature

    [$#]?(%.*%)?{types}(/{features})?:

    - [$#]?: optional: pattern format
        Affect the given list:
        - '$' -> interpreted as json.
        - '#' -> interpreted as an list separated by ';'.
        None if it's only one flag
    
    - (%.*%)?: optional name
        A flag name between %

    - {types}: type or list of types:
        - '$' -> interpreted as json.
        - '#' -> interpreted as an list separated by ';'.
        None if it's only one type

    - {features}: a list of features:
        Block Separated by ;
        - \w+ -> a feature name that has to be present
        - !\w+ -> a feature name that must not be present
        - [(\w+)(!\w+)] -> a list of features, that need, at the same time, be present or not

    Args:
        xflags_packed: packed flags from the ctx
      
    Returns:
        an xflags
        The list of all flags, each flag is now an dict:
            - type
            - flags
            - with_features: the with_features list
    """
    xflags = []
    for pattern, flag_flags in xflags_packed.items():
        # filters name and json mode
        if pattern.startswith('$'):
            flag_flags = json.decode(flag_flags)
            flag_type = pattern[1:]
        elif pattern.startswith('#'):
            flag_flags = flag_flags.split(';')
            flag_type = pattern[1:]
        
        if pattern.startswith('%'):
            flag_type = pattern[pattern.find('%') + 1:]
        
        tf_pattern = pattern.split('/')
        flag_types = []
        if tf_pattern[0].startswith('$'):
            tf_pattern[0] = tf_pattern[0][1:]
            flag_types = json.decode(tf_pattern[0])
        elif tf_pattern[0].startswith('#'):
            tf_pattern[0] = tf_pattern[0][1:]
            flag_types = tf_pattern[0].split(';')
        else:
            flag_types.append(tf_pattern[0])

        # If there are any features declared
        with_features = []
        if len(tf_pattern) > 1:
            features_pattern = tf_pattern[1].split(';')
            for filter in features_pattern:
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
            xflags.append({
                "type": flag_type,
                "with_features": with_features,
                "flags": flag_flags
            })
    return xflags

def xflags_feature(name, xflags, actions_filter = XFLAGS_ACTIONS, enabled = True, provides = []):
    """Feature Flags
    
    This function return the feature build from the unpacked flags list 

    Args:
        name: feature name
        xflags: unpacked flags in the ctx 
        actions_filter: filter of actions
        enabled: If the feature is enable by default or not
        provides: provides list of the feature
      
    Returns:
        The feature
    """
    flag_sets = []
    for flag_data in xflags:
        if len(flag_data["flags"]) > 0 and flag_data["type"] in actions_filter:
            flag_sets.append(
                flag_set(
                    actions = XFLAGS_ACTIONS[flag_data["type"]],
                    flag_groups = [ flag_group(flags = flag_data["flags"]) ],
                    with_features = flag_data["with_features"]
                )
            )
    _feature = feature(
        name = name,
        provides = provides,
        enabled = enabled,
        flag_sets = flag_sets,
    )
    return _feature
