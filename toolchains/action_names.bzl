""

load("@bazel_tools//tools/build_defs/cc:action_names.bzl", "ACTION_NAMES")

ACTIONS_COMPILE_ALL = [
    ACTION_NAMES.c_compile,
    ACTION_NAMES.cpp_compile,
    ACTION_NAMES.linkstamp_compile,
    ACTION_NAMES.assemble,
    ACTION_NAMES.preprocess_assemble,
    ACTION_NAMES.cpp_header_parsing,
    ACTION_NAMES.cpp_module_compile,
    ACTION_NAMES.cpp_module_codegen,
    ACTION_NAMES.clif_match,
    ACTION_NAMES.lto_backend,
]

ACTIONS_COMPILE_CPP = [
    ACTION_NAMES.cc_flags_make_variable,
    ACTION_NAMES.linkstamp_compile,
    ACTION_NAMES.cpp_header_parsing,
    ACTION_NAMES.cpp_module_compile,
    ACTION_NAMES.cpp_module_codegen,
    ACTION_NAMES.clif_match,
]

ACTIONS_COMPILE_C = [
    ACTION_NAMES.c_compile,
    ACTION_NAMES.cc_flags_make_variable,
    ACTION_NAMES.lto_backend,
    ACTION_NAMES.clif_match,
    ACTION_NAMES.linkstamp_compile,
]

ACTIONS_COMPILE_CXX = [
    ACTION_NAMES.cpp_compile,
    ACTION_NAMES.cpp_header_parsing,
    ACTION_NAMES.cpp_module_codegen,
    ACTION_NAMES.cpp_module_compile,
    ACTION_NAMES.assemble,
    ACTION_NAMES.preprocess_assemble,
    ACTION_NAMES.linkstamp_compile,
]

ACTIONS_LINK = [
    ACTION_NAMES.cpp_link_executable,
    ACTION_NAMES.cpp_link_dynamic_library,
    ACTION_NAMES.cpp_link_nodeps_dynamic_library,
]

ACTIONS_LINK_LTO = [
    ACTION_NAMES.lto_index_for_executable,
    ACTION_NAMES.lto_index_for_dynamic_library,
    ACTION_NAMES.lto_index_for_nodeps_dynamic_library,
]

ACTIONS_LINK_ALL = ACTIONS_LINK + ACTIONS_LINK_LTO

ACTIONS_COV_COMPILE = [
    ACTION_NAMES.lto_index_for_executable,
    ACTION_NAMES.lto_index_for_dynamic_library,
    ACTION_NAMES.lto_index_for_nodeps_dynamic_library,
]

ACTIONS_COV_LINK = ACTIONS_LINK_ALL

ACTIONS_COV_ALL = ACTIONS_COV_COMPILE + ACTIONS_COV_LINK
