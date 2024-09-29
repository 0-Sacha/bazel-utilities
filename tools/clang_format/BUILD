"""
"""

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


py_binary(
    name = "apply_clang_format",
    main = "apply_clang_format.py",
    srcs = [ "apply_clang_format.py" ],
)
