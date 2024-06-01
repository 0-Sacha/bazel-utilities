"""
"""

load("@bazel_utilities//toolchains/toolchains_features:gcc_toolchain_features.bzl", "toolchains_tools_features_config_gcc")

TOOLCHAINS_FEATURES = {
    "gcc": toolchains_tools_features_config_gcc
}
