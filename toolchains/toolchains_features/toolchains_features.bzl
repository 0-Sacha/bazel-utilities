"""
"""

load("//toolchains/toolchains_features:gcc_like_toolchain_features.bzl", "toolchains_tools_features_config_gcc_like")

TOOLCHAINS_FEATURES = {
    "gcc": toolchains_tools_features_config_gcc_like,
    "clang": toolchains_tools_features_config_gcc_like,
}
