"""
"""

#########################
######### clang #########
#########################

### clang_tidy ###

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


### clang_format ###

filegroup(
    name = "clang_format_config_default",
    srcs = [".clang-format"],
)

label_flag(
    name = "clang_format_config",
    build_setting_default = ":clang_format_config_default",
    visibility = ["//visibility:public"],
)

filegroup(
    name = "clang_format_executable_default",
    srcs = [],  # default system clang-format
)

label_flag(
    name = "clang_format_executable",
    build_setting_default = ":clang_format_executable_default",
    visibility = ["//visibility:public"],
)
