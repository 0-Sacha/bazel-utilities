"""
"""

filegroup(
    name = "clang_tidy_config_default",
    srcs = [".clang-tidy"],
)

label_flag(
    name = "clang_tidy_config",
    build_setting_default = ":clang_tidy_config_default",
    visibility = ["//visibility:public"],
)

filegroup(
    name = "clang_tidy_executable_default",
    srcs = [],  # default system clang-tidy
)

label_flag(
    name = "clang_tidy_executable",
    build_setting_default = ":clang_tidy_executable_default",
    visibility = ["//visibility:public"],
)
