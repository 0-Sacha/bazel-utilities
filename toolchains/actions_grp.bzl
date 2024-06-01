"""
"""

load("@rules_cc//cc:action_names.bzl", "ACTION_NAMES")

# TODO:
# !MISSING: CPP_MODULE_CODEGEN_ACTION_NAME: ACTION_NAMES.cpp_module_compile,
# !MISSING: CPP_MODULE_COMPILE_ACTION_NAME: ACTION_NAMES.cpp_module_codegen,

# !MISSING: CC_FLAGS_MAKE_VARIABLE_ACTION_NAME

# DISCARDED: OBJC_COMPILE_ACTION_NAME
# DISCARDED: OBJC_EXECUTABLE_ACTION_NAME
# DISCARDED: OBJC_FULLY_LINK_ACTION_NAME
# DISCARDED: OBJCPP_COMPILE_ACTION_NAME

########## Assembler actions ##########
TOOLCHAIN_ASSEMBLE = [
    ACTION_NAMES.assemble,
    ACTION_NAMES.preprocess_assemble,
]

TOOLCHAIN_ASSEMBLE_W_PREPROCESS = [
    ACTION_NAMES.preprocess_assemble,
]


########## Compiler actions ##########
TOOLCHAIN_COMPILE = [
    ACTION_NAMES.c_compile,
    ACTION_NAMES.cpp_compile,
    ACTION_NAMES.linkstamp_compile,
]

TOOLCHAIN_COMPILE_C = [
    ACTION_NAMES.c_compile,
]

TOOLCHAIN_COMPILE_CXX = [
    ACTION_NAMES.cpp_compile,
    ACTION_NAMES.linkstamp_compile,
]

TOOLCHAIN_COMPILE_HEADER_PARSING = [
    ACTION_NAMES.cpp_header_parsing,
]

TOOLCHAIN_COMPILE_LINKSTAMP = [
    ACTION_NAMES.linkstamp_compile,
]


########## Link actions ##########
TOOLCHAIN_LINK_DYNAMIC_LIB = [
    ACTION_NAMES.cpp_link_dynamic_library,
    ACTION_NAMES.lto_index_for_dynamic_library,
    ACTION_NAMES.cpp_link_nodeps_dynamic_library,
    ACTION_NAMES.lto_index_for_nodeps_dynamic_library,
]

TOOLCHAIN_LINK_NODEPS = [
    ACTION_NAMES.cpp_link_nodeps_dynamic_library,
    ACTION_NAMES.lto_index_for_nodeps_dynamic_library,
]

TOOLCHAIN_LINK_EXE = [
    ACTION_NAMES.cpp_link_executable,
    ACTION_NAMES.lto_index_for_executable,
]


########## AR actions ##########
TOOLCHAIN_ARCHIVE_STATIC_LIB = [
    ACTION_NAMES.cpp_link_static_library,
]


########## LTO actions ##########
TOOLCHAIN_LTO_BACKEND = [
    ACTION_NAMES.lto_backend,
]

TOOLCHAIN_LTO_INDEXING = [
    ACTION_NAMES.lto_indexing,
    # TODO: add toolchain-lto-indexing to thoses actions
    # ACTION_NAMES.lto_index_for_executable,
    # ACTION_NAMES.lto_index_for_dynamic_library,
    # ACTION_NAMES.lto_index_for_nodeps_dynamic_library,
]


########## Strip actions ##########
TOOLCHAIN_STRIP = [
    ACTION_NAMES.strip,
]


########## Cliff ##########
TOOLCHAIN_CLIFF_MATCH = [
    ACTION_NAMES.clif_match,
]


TOOLCHAIN_ACTIONS = struct(
    assemble = TOOLCHAIN_ASSEMBLE,
    assemble_w_preprocess = TOOLCHAIN_ASSEMBLE_W_PREPROCESS,

    compile = TOOLCHAIN_COMPILE,
    compile_c = TOOLCHAIN_COMPILE_C,
    compile_cxx = TOOLCHAIN_COMPILE_CXX,
    compile_header_parsing = TOOLCHAIN_COMPILE_HEADER_PARSING,
    compile_linkstamp = TOOLCHAIN_COMPILE_LINKSTAMP,

    link_dynamic_lib = TOOLCHAIN_LINK_DYNAMIC_LIB,
    link_nodeps = TOOLCHAIN_LINK_NODEPS,
    link_exe = TOOLCHAIN_LINK_EXE,

    archive_static_lib = TOOLCHAIN_ARCHIVE_STATIC_LIB,

    lto_backend = TOOLCHAIN_LTO_BACKEND,
    lto_indexing = TOOLCHAIN_LTO_INDEXING,

    strip = TOOLCHAIN_STRIP,

    cliff_match = TOOLCHAIN_CLIFF_MATCH,
)


########## ACTIONS ##########
CC_PREPROCESSOR = [
    ACTION_NAMES.preprocess_assemble,
    ACTION_NAMES.linkstamp_compile,
    ACTION_NAMES.c_compile,
    ACTION_NAMES.cpp_compile,
    ACTION_NAMES.cpp_header_parsing,
    ACTION_NAMES.cpp_module_compile,
    ACTION_NAMES.clif_match,
]

CC_COMPILE_C = [
    ACTION_NAMES.c_compile,
]
CC_COMPILE_CXX = [
    ACTION_NAMES.cpp_compile,
    ACTION_NAMES.cpp_header_parsing,
    ACTION_NAMES.linkstamp_compile,
    ACTION_NAMES.lto_backend,
    ACTION_NAMES.clif_match,
]
CC_COMPILE = CC_COMPILE_C + CC_COMPILE_CXX

CC_COMPILE_ONLY = [ ACTION_NAMES.c_compile, ACTION_NAMES.cpp_compile ]

CC_ASSEMBLE = [
    ACTION_NAMES.preprocess_assemble,
    ACTION_NAMES.assemble,
]

CC_LINK_LIB = [
    ACTION_NAMES.cpp_link_dynamic_library,
    ACTION_NAMES.cpp_link_nodeps_dynamic_library,
    ACTION_NAMES.lto_index_for_dynamic_library,
    ACTION_NAMES.lto_index_for_nodeps_dynamic_library,
]
CC_LINK_EXE = [
    ACTION_NAMES.cpp_link_executable,
    ACTION_NAMES.lto_index_for_executable,
]
CC_LINK = CC_LINK_EXE + CC_LINK_LIB

CC_LINK_LIB_NO_LTO = [
    ACTION_NAMES.cpp_link_dynamic_library,
    ACTION_NAMES.cpp_link_nodeps_dynamic_library,
]
CC_LINK_EXE_NO_LTO = [
    ACTION_NAMES.cpp_link_executable,
]
CC_LINK_NO_LTO = CC_LINK_EXE_NO_LTO + CC_LINK_LIB_NO_LTO

CC_LINK_TRANSITIVE = [
    ACTION_NAMES.cpp_link_executable,
    ACTION_NAMES.cpp_link_dynamic_library,
    ACTION_NAMES.lto_index_for_executable,
    ACTION_NAMES.lto_index_for_dynamic_library,
]
CC_LINK_NODEPS = [
    ACTION_NAMES.cpp_link_nodeps_dynamic_library,
    ACTION_NAMES.lto_index_for_nodeps_dynamic_library,
]

CC_LINK_LTO_INDEXING = [
    ACTION_NAMES.lto_index_for_executable,
    ACTION_NAMES.lto_index_for_dynamic_library,
    ACTION_NAMES.lto_index_for_nodeps_dynamic_library,
]

CC_ARCHIVE_STATIC_LIB = [
    ACTION_NAMES.cpp_link_static_library,
]

CC_STRIP = [
    ACTION_NAMES.strip,
]

CC_COVERAGE = CC_COMPILE_ONLY + [
    ACTION_NAMES.preprocess_assemble,
    ACTION_NAMES.cpp_module_compile,
]

CC_ACTIONS = struct(
    cc_preprocessor = CC_PREPROCESSOR,
    cc_compile_c = CC_COMPILE_C,
    cc_compile_cxx = CC_COMPILE_CXX,
    cc_compile = CC_COMPILE,
    cc_compile_only = CC_COMPILE_ONLY,
    cc_assemble = CC_ASSEMBLE,
    cc_link_lib = CC_LINK_LIB,
    cc_link_exe = CC_LINK_EXE,
    cc_link = CC_LINK,

    cc_link_no_lto = CC_LINK_NO_LTO,
    cc_link_exe_no_lto = CC_LINK_EXE_NO_LTO,
    cc_link_lib_no_lto = CC_LINK_LIB_NO_LTO,
    cc_link_lto_indexing = CC_LINK_LTO_INDEXING,

    cc_link_transitive = CC_LINK_TRANSITIVE,
    cc_link_nodeps = CC_LINK_NODEPS,
    cc_archive_static_lib = CC_ARCHIVE_STATIC_LIB,
    cc_strip = CC_STRIP,

    cc_coverage = CC_COVERAGE,
)
