"""Legacy function for the cc_toolchain rule

According to:
https://bazel.build/docs/cc-toolchain-config-reference
"""

load("@bazel_tools//tools/build_defs/cc:action_names.bzl", "ACTION_NAMES")
load(
    "@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl",
    "feature",
    "feature_set",
    "flag_group",
    "flag_set",
    "variable_with_value",
    "with_feature_set",
)

load("@bazel_utilities//toolchains:action_names.bzl", "ACTIONS_COMPILE_ALL", "ACTIONS_LINK_ALL", "ACTIONS_LINK_LTO")

def features_module_maps():
    """module_maps
    
    Returns:
        The list of all features created 
    """
    features = []
    features.append(feature(name = "module_maps", enabled = True))
    features.append(
        feature(
            name = "use_module_maps",
            requires = [feature_set(features = ["module_maps"])],
            flag_sets = [
                flag_set(
                    actions = [
                        ACTION_NAMES.c_compile,
                        ACTION_NAMES.cpp_compile,
                        ACTION_NAMES.cpp_header_parsing,
                        ACTION_NAMES.cpp_module_compile,
                    ],
                    flag_groups = [
                        flag_group(
                            flags = [
                                "-fmodule-name=%{module_name}",
                                "-fmodule-map-file=%{module_map_file}",
                            ],
                        ),
                    ],
                ),
            ],
        )
    )
    features.append(
        feature(
            name = "layering_check",
            implies = ["use_module_maps"],
            flag_sets = [
                flag_set(
                    actions = [
                        ACTION_NAMES.c_compile,
                        ACTION_NAMES.cpp_compile,
                        ACTION_NAMES.cpp_header_parsing,
                        ACTION_NAMES.cpp_module_compile,
                    ],
                    flag_groups = [
                        flag_group(flags = [
                            "-fmodules-strict-decluse",
                            "-Wprivate-header",
                        ]),
                        flag_group(
                            iterate_over = "dependent_module_map_files",
                            flags = [
                                "-fmodule-map-file=%{dependent_module_map_files}",
                            ],
                        ),
                    ],
                ),
            ],
        )
    )
    return features

def _legacy_user_compile_flags():
    return feature(
        name = "user_compile_flags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = ACTIONS_COMPILE_ALL,
                flag_groups = [
                    flag_group(
                        flags = ["%{user_compile_flags}"],
                        iterate_over = "user_compile_flags",
                        expand_if_available = "user_compile_flags",
                    ),
                ],
            ),
        ],
    )

def _legacy_user_link_flags():
    return feature(
        name = "user_link_flags",
        flag_sets = [
            flag_set(
                actions = ACTIONS_LINK_ALL,
                flag_groups = [
                    flag_group(
                        flags = ["%{user_link_flags}"],
                        iterate_over = "user_link_flags",
                        expand_if_available = "user_link_flags",
                    ),
                ],
            ),
        ],
    )

def _legacy_library_search_directories():
    return feature(
        name = "library_search_directories",
        flag_sets = [
            flag_set(
                actions = ACTIONS_LINK_ALL,
                flag_groups = [
                    flag_group(
                        flags = ["-L%{library_search_directories}"],
                        iterate_over = "library_search_directories",
                        expand_if_available = "library_search_directories",
                    ),
                ],
            ),
        ],
    )

def _legacy_random_seed():
    return feature(
        name = "random_seed",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = [
                    ACTION_NAMES.c_compile,
                    ACTION_NAMES.cpp_compile,
                    ACTION_NAMES.cpp_module_codegen,
                    ACTION_NAMES.cpp_module_compile,
                ],
                flag_groups = [
                    flag_group(
                        flags = ["-frandom-seed=%{output_file}"],
                        expand_if_available = "output_file",
                    ),
                ],
            ),
        ],
    )

def _legacy_symbol_counts():
    return feature(
        name = "symbol_counts",
        flag_sets = [
            flag_set(
                actions = ACTIONS_LINK_ALL,
                flag_groups = [
                    flag_group(
                        flags = [
                            "-Wl,--print-symbol-counts=%{symbol_counts_output}",
                        ],
                        expand_if_available = "symbol_counts_output",
                    ),
                ],
            ),
        ],
    )

def _legacy_static_libgcc():
    return feature(
        name = "static_libgcc",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = [
                    ACTION_NAMES.cpp_link_executable,
                    ACTION_NAMES.cpp_link_dynamic_library,
                    ACTION_NAMES.lto_index_for_executable,
                    ACTION_NAMES.lto_index_for_dynamic_library,
                ],
                flag_groups = [flag_group(flags = ["-static-libgcc"])],
                with_features = [
                    with_feature_set(features = ["static_link_cpp_runtimes"]),
                ],
            ),
        ],
    )

def _legacy_sysroot():
    return feature(
        name = "sysroot",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = ACTIONS_COMPILE_ALL + ACTIONS_LINK_ALL,
                flag_groups = [
                    flag_group(
                        flags = ["--sysroot=%{sysroot}"],
                        expand_if_available = "sysroot",
                    ),
                ],
            ),
        ],
    )

def _legacy_fdo_optimize():
    return feature(
        name = "fdo_optimize",
        flag_sets = [
            flag_set(
                actions = [ACTION_NAMES.c_compile, ACTION_NAMES.cpp_compile],
                flag_groups = [
                    flag_group(
                        flags = [
                            "-fprofile-use=%{fdo_profile_path}",
                            "-fprofile-correction",
                        ],
                        expand_if_available = "fdo_profile_path",
                    ),
                ],
            ),
        ],
        provides = ["profile"],
    )

def _legacy_pic():
    return feature(
        name = "pic",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = [
                    ACTION_NAMES.assemble,
                    ACTION_NAMES.preprocess_assemble,
                    ACTION_NAMES.linkstamp_compile,
                    ACTION_NAMES.c_compile,
                    ACTION_NAMES.cpp_compile,
                    ACTION_NAMES.cpp_module_codegen,
                    ACTION_NAMES.cpp_module_compile,
                ],
                flag_groups = [
                    flag_group(flags = ["-fPIC"], expand_if_available = "pic"),
                ],
            ),
        ],
    )

def _legacy_per_object_debug_info():
    return feature(
        name = "per_object_debug_info",
        flag_sets = [
            flag_set(
                actions = [
                    ACTION_NAMES.assemble,
                    ACTION_NAMES.preprocess_assemble,
                    ACTION_NAMES.c_compile,
                    ACTION_NAMES.cpp_compile,
                    ACTION_NAMES.cpp_module_codegen,
                ],
                flag_groups = [
                    flag_group(
                        flags = ["-gsplit-dwarf"],
                        expand_if_available = "per_object_debug_info_file",
                    ),
                ],
            ),
        ],
    )

def _legacy_preprocessor_defines():
    return feature(
        name = "preprocessor_defines",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = [
                    ACTION_NAMES.preprocess_assemble,
                    ACTION_NAMES.linkstamp_compile,
                    ACTION_NAMES.c_compile,
                    ACTION_NAMES.cpp_compile,
                    ACTION_NAMES.cpp_header_parsing,
                    ACTION_NAMES.cpp_module_compile,
                    ACTION_NAMES.clif_match,
                ],
                flag_groups = [
                    flag_group(
                        flags = ["-D%{preprocessor_defines}"],
                        iterate_over = "preprocessor_defines",
                    ),
                ],
            ),
        ],
    )

def _legacy_cs_fdo_optimize():
    return feature(
        name = "cs_fdo_optimize",
        flag_sets = [
            flag_set(
                actions = [ACTION_NAMES.lto_backend],
                flag_groups = [
                    flag_group(
                        flags = [
                            "-fprofile-use=%{fdo_profile_path}",
                            "-Wno-profile-instr-unprofiled",
                            "-Wno-profile-instr-out-of-date",
                            "-fprofile-correction",
                        ],
                        expand_if_available = "fdo_profile_path",
                    ),
                ],
            ),
        ],
        provides = ["csprofile"],
    )

def _legacy_autofdo():
    return feature(
        name = "autofdo",
        flag_sets = [
            flag_set(
                actions = [ACTION_NAMES.c_compile, ACTION_NAMES.cpp_compile],
                flag_groups = [
                    flag_group(
                        flags = [
                            "-fauto-profile=%{fdo_profile_path}",
                            "-fprofile-correction",
                        ],
                        expand_if_available = "fdo_profile_path",
                    ),
                ],
            ),
        ],
        provides = ["profile"],
    )

def _legacy_runtime_library_search_directories():
    return feature(
        name = "runtime_library_search_directories",
        flag_sets = [
            flag_set(
                actions = ACTIONS_LINK_ALL,
                flag_groups = [
                    flag_group(
                        iterate_over = "runtime_library_search_directories",
                        flag_groups = [
                            flag_group(
                                flags = [
                                    "-Wl,-rpath,$EXEC_ORIGIN/%{runtime_library_search_directories}",
                                ],
                                expand_if_true = "is_cc_test",
                            ),
                            flag_group(
                                flags = [
                                    "-Wl,-rpath,$ORIGIN/%{runtime_library_search_directories}",
                                ],
                                expand_if_false = "is_cc_test",
                            ),
                        ],
                        expand_if_available =
                            "runtime_library_search_directories",
                    ),
                ],
                with_features = [
                    with_feature_set(features = ["static_link_cpp_runtimes"]),
                ],
            ),
            flag_set(
                actions = ACTIONS_LINK_ALL,
                flag_groups = [
                    flag_group(
                        iterate_over = "runtime_library_search_directories",
                        flag_groups = [
                            flag_group(
                                flags = [
                                    "-Wl,-rpath,$ORIGIN/%{runtime_library_search_directories}",
                                ],
                            ),
                        ],
                        expand_if_available =
                            "runtime_library_search_directories",
                    ),
                ],
                with_features = [
                    with_feature_set(
                        not_features = ["static_link_cpp_runtimes"],
                    ),
                ],
            ),
        ],
    )

def _legacy_fission_support():
    return feature(
        name = "fission_support",
        flag_sets = [
            flag_set(
                actions = ACTIONS_LINK_ALL,
                flag_groups = [
                    flag_group(
                        flags = ["-Wl,--gdb-index"],
                        expand_if_available = "is_using_fission",
                    ),
                ],
            ),
        ],
    )

def _legacy_shared_flag():
    return feature(
        name = "shared_flag",
        flag_sets = [
            flag_set(
                actions = [
                    ACTION_NAMES.cpp_link_dynamic_library,
                    ACTION_NAMES.cpp_link_nodeps_dynamic_library,
                    ACTION_NAMES.lto_index_for_dynamic_library,
                    ACTION_NAMES.lto_index_for_nodeps_dynamic_library,
                ],
                flag_groups = [flag_group(flags = ["-shared"])],
            ),
        ],
    )

def _legacy_includes():
    return feature(
        name = "includes",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = [
                    ACTION_NAMES.preprocess_assemble,
                    ACTION_NAMES.linkstamp_compile,
                    ACTION_NAMES.c_compile,
                    ACTION_NAMES.cpp_compile,
                    ACTION_NAMES.cpp_header_parsing,
                    ACTION_NAMES.cpp_module_compile,
                    ACTION_NAMES.clif_match,
                    ACTION_NAMES.objc_compile,
                    ACTION_NAMES.objcpp_compile,
                ],
                flag_groups = [
                    flag_group(
                        flags = ["-include", "%{includes}"],
                        iterate_over = "includes",
                        expand_if_available = "includes",
                    ),
                ],
            ),
        ],
    )

def _legacy_fdo_instrument():
    return feature(
        name = "fdo_instrument",
        flag_sets = [
            flag_set(
                actions = [
                    ACTION_NAMES.c_compile,
                    ACTION_NAMES.cpp_compile,
                ] + ACTIONS_LINK_ALL,
                flag_groups = [
                    flag_group(
                        flags = [
                            "-fprofile-generate=%{fdo_instrument_path}",
                            "-fno-data-sections",
                        ],
                        expand_if_available = "fdo_instrument_path",
                    ),
                ],
            ),
        ],
        provides = ["profile"],
    )

def _legacy_cs_fdo_instrument():
    return feature(
        name = "cs_fdo_instrument",
        flag_sets = [
            flag_set(
                actions = [
                    ACTION_NAMES.c_compile,
                    ACTION_NAMES.cpp_compile,
                    ACTION_NAMES.lto_backend,
                ] + ACTIONS_LINK_ALL,
                flag_groups = [
                    flag_group(
                        flags = [
                            "-fcs-profile-generate=%{cs_fdo_instrument_path}",
                        ],
                        expand_if_available = "cs_fdo_instrument_path",
                    ),
                ],
            ),
        ],
        provides = ["csprofile"],
    )

def _legacy_include_paths():
    return feature(
        name = "include_paths",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = [
                    ACTION_NAMES.preprocess_assemble,
                    ACTION_NAMES.linkstamp_compile,
                    ACTION_NAMES.c_compile,
                    ACTION_NAMES.cpp_compile,
                    ACTION_NAMES.cpp_header_parsing,
                    ACTION_NAMES.cpp_module_compile,
                    ACTION_NAMES.clif_match,
                    ACTION_NAMES.objc_compile,
                    ACTION_NAMES.objcpp_compile,
                ],
                flag_groups = [
                    flag_group(
                        flags = ["-iquote", "%{quote_include_paths}"],
                        iterate_over = "quote_include_paths",
                    ),
                    flag_group(
                        flags = ["-I%{include_paths}"],
                        iterate_over = "include_paths",
                    ),
                    flag_group(
                        flags = ["-isystem", "%{system_include_paths}"],
                        iterate_over = "system_include_paths",
                    ),
                ],
            ),
        ],
    )

def _legacy_llvm_coverage_map_format():
    return feature(
        name = "llvm_coverage_map_format",
        flag_sets = [
            flag_set(
                actions = [
                    ACTION_NAMES.preprocess_assemble,
                    ACTION_NAMES.c_compile,
                    ACTION_NAMES.cpp_compile,
                    ACTION_NAMES.cpp_module_compile,
                    ACTION_NAMES.objc_compile,
                    ACTION_NAMES.objcpp_compile,
                ],
                flag_groups = [
                    flag_group(
                        flags = [
                            "-fprofile-instr-generate",
                            "-fcoverage-mapping",
                        ],
                    ),
                ],
            ),
            flag_set(
                actions = ACTIONS_LINK_ALL + [
                    "objc-executable",
                    "objc++-executable",
                ],
                flag_groups = [
                    flag_group(flags = ["-fprofile-instr-generate"]),
                ],
            ),
        ],
        requires = [feature_set(features = ["coverage"])],
        provides = ["profile"],
    )

def _legacy_strip_debug_symbols():
    return feature(
        name = "strip_debug_symbols",
        flag_sets = [
            flag_set(
                actions = ACTIONS_LINK_ALL,
                flag_groups = [
                    flag_group(
                        flags = ["-Wl,-S"],
                        expand_if_available = "strip_debug_symbols",
                    ),
                ],
            ),
        ],
    )

def _legacy_build_interface_libraries():
    return feature(
        name = "build_interface_libraries",
        flag_sets = [
            flag_set(
                actions = [
                    ACTION_NAMES.cpp_link_dynamic_library,
                    ACTION_NAMES.cpp_link_nodeps_dynamic_library,
                    ACTION_NAMES.lto_index_for_dynamic_library,
                    ACTION_NAMES.lto_index_for_nodeps_dynamic_library,
                ],
                flag_groups = [
                    flag_group(
                        flags = [
                            "%{generate_interface_library}",
                            "%{interface_library_builder_path}",
                            "%{interface_library_input_path}",
                            "%{interface_library_output_path}",
                        ],
                        expand_if_available = "generate_interface_library",
                    ),
                ],
                with_features = [
                    with_feature_set(
                        features = ["supports_interface_shared_libraries"],
                    ),
                ],
            ),
        ],
    )

def _legacy_libraries_to_link():
    return feature(
        name = "libraries_to_link",
        flag_sets = [
            flag_set(
                actions = ACTIONS_LINK_ALL,
                flag_groups = [
                    flag_group(
                        iterate_over = "libraries_to_link",
                        flag_groups = [
                            flag_group(
                                flags = ["-Wl,--start-lib"],
                                expand_if_equal = variable_with_value(
                                    name = "libraries_to_link.type",
                                    value = "object_file_group",
                                ),
                            ),
                            flag_group(
                                flags = ["-Wl,-whole-archive"],
                                expand_if_true =
                                    "libraries_to_link.is_whole_archive",
                            ),
                            flag_group(
                                flags = ["%{libraries_to_link.object_files}"],
                                iterate_over = "libraries_to_link.object_files",
                                expand_if_equal = variable_with_value(
                                    name = "libraries_to_link.type",
                                    value = "object_file_group",
                                ),
                            ),
                            flag_group(
                                flags = ["%{libraries_to_link.name}"],
                                expand_if_equal = variable_with_value(
                                    name = "libraries_to_link.type",
                                    value = "object_file",
                                ),
                            ),
                            flag_group(
                                flags = ["%{libraries_to_link.name}"],
                                expand_if_equal = variable_with_value(
                                    name = "libraries_to_link.type",
                                    value = "interface_library",
                                ),
                            ),
                            flag_group(
                                flags = ["%{libraries_to_link.name}"],
                                expand_if_equal = variable_with_value(
                                    name = "libraries_to_link.type",
                                    value = "static_library",
                                ),
                            ),
                            flag_group(
                                flags = ["-l%{libraries_to_link.name}"],
                                expand_if_equal = variable_with_value(
                                    name = "libraries_to_link.type",
                                    value = "dynamic_library",
                                ),
                            ),
                            flag_group(
                                flags = ["-l:%{libraries_to_link.name}"],
                                expand_if_equal = variable_with_value(
                                    name = "libraries_to_link.type",
                                    value = "versioned_dynamic_library",
                                ),
                            ),
                            flag_group(
                                flags = ["-Wl,-no-whole-archive"],
                                expand_if_true = "libraries_to_link.is_whole_archive",
                            ),
                            flag_group(
                                flags = ["-Wl,--end-lib"],
                                expand_if_equal = variable_with_value(
                                    name = "libraries_to_link.type",
                                    value = "object_file_group",
                                ),
                            ),
                        ],
                        expand_if_available = "libraries_to_link",
                    ),
                    flag_group(
                        flags = ["-Wl,@%{thinlto_param_file}"],
                        expand_if_true = "thinlto_param_file",
                    ),
                ],
            ),
        ],
    )

    

def _legacy_fdo_prefetch_hints():
    return feature(
        name = "fdo_prefetch_hints",
        flag_sets = [
            flag_set(
                actions = [
                    ACTION_NAMES.c_compile,
                    ACTION_NAMES.cpp_compile,
                    ACTION_NAMES.lto_backend,
                ],
                flag_groups = [
                    flag_group(
                        flags = [
                            "-mllvm",
                            "-prefetch-hints-file=%{fdo_prefetch_hints_path}",
                        ],
                        expand_if_available = "fdo_prefetch_hints_path",
                    ),
                ],
            ),
        ],
    )

def _legacy_linkstamps():
    return feature(
        name = "linkstamps",
        flag_sets = [
            flag_set(
                actions = ACTIONS_LINK_ALL,
                flag_groups = [
                    flag_group(
                        flags = ["%{linkstamp_paths}"],
                        iterate_over = "linkstamp_paths",
                        expand_if_available = "linkstamp_paths",
                    ),
                ],
            ),
        ],
    )

def _legacy_gcc_coverage_map_format():
    return feature(
        name = "gcc_coverage_map_format",
        flag_sets = [
            flag_set(
                actions = [
                    ACTION_NAMES.preprocess_assemble,
                    ACTION_NAMES.c_compile,
                    ACTION_NAMES.cpp_compile,
                    ACTION_NAMES.cpp_module_compile,
                    ACTION_NAMES.objc_compile,
                    ACTION_NAMES.objcpp_compile,
                    "objc-executable",
                    "objc++-executable",
                ],
                flag_groups = [
                    flag_group(
                        flags = ["-fprofile-arcs", "-ftest-coverage"],
                        expand_if_available = "gcov_gcno_file",
                    ),
                ],
            ),
            flag_set(
                actions = ACTIONS_LINK_ALL,
                flag_groups = [flag_group(flags = ["--coverage"])],
            ),
        ],
        requires = [feature_set(features = ["coverage"])],
        provides = ["profile"],
    )

def _legacy_archiver_flags():
    return feature(
        name = "archiver_flags",
        flag_sets = [
            flag_set(
                actions = [ACTION_NAMES.cpp_link_static_library],
                flag_groups = [
                    flag_group(flags = ["rcsD"]),
                    flag_group(
                        flags = ["%{output_execpath}"],
                        expand_if_available = "output_execpath",
                    ),
                ],
            ),
            flag_set(
                actions = [ACTION_NAMES.cpp_link_static_library],
                flag_groups = [
                    flag_group(
                        iterate_over = "libraries_to_link",
                        flag_groups = [
                            flag_group(
                                flags = ["%{libraries_to_link.name}"],
                                expand_if_equal = variable_with_value(
                                    name = "libraries_to_link.type",
                                    value = "object_file",
                                ),
                            ),
                            flag_group(
                                flags = ["%{libraries_to_link.object_files}"],
                                iterate_over = "libraries_to_link.object_files",
                                expand_if_equal = variable_with_value(
                                    name = "libraries_to_link.type",
                                    value = "object_file_group",
                                ),
                            ),
                        ],
                        expand_if_available = "libraries_to_link",
                    ),
                ],
            ),
        ],
    )

def _legacy_force_pic_flags():
    return feature(
        name = "force_pic_flags",
        flag_sets = [
            flag_set(
                actions = [
                    ACTION_NAMES.cpp_link_executable,
                    ACTION_NAMES.lto_index_for_executable,
                ],
                flag_groups = [
                    flag_group(
                        flags = ["-pie"],
                        expand_if_available = "force_pic",
                    ),
                ],
            ),
        ],
    )

def _legacy_dependency_file():
    return feature(
        name = "dependency_file",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = [
                    ACTION_NAMES.assemble,
                    ACTION_NAMES.preprocess_assemble,
                    ACTION_NAMES.c_compile,
                    ACTION_NAMES.cpp_compile,
                    ACTION_NAMES.cpp_module_compile,
                    ACTION_NAMES.objc_compile,
                    ACTION_NAMES.objcpp_compile,
                    ACTION_NAMES.cpp_header_parsing,
                    ACTION_NAMES.clif_match,
                ],
                flag_groups = [
                    flag_group(
                        flags = ["-MD", "-MF", "%{dependency_file}"],
                        expand_if_available = "dependency_file",
                    ),
                ],
            ),
        ],
    )

def _legacy_dynamic_library_linker_tool():
    return feature(
        name = "dynamic_library_linker_tool",
        flag_sets = [
            flag_set(
                actions = [
                    ACTION_NAMES.cpp_link_dynamic_library,
                    ACTION_NAMES.cpp_link_nodeps_dynamic_library,
                    ACTION_NAMES.lto_index_for_dynamic_library,
                    ACTION_NAMES.lto_index_for_nodeps_dynamic_library,
                ],
                flag_groups = [
                    flag_group(
                        flags = [" + cppLinkDynamicLibraryToolPath + "],
                        expand_if_available = "generate_interface_library",
                    ),
                ],
                with_features = [
                    with_feature_set(
                        features = ["supports_interface_shared_libraries"],
                    ),
                ],
            ),
        ],
    )

def _legacy_output_execpath_flags():
    return feature(
        name = "output_execpath_flags",
        flag_sets = [
            flag_set(
                actions = ACTIONS_LINK_ALL,
                flag_groups = [
                    flag_group(
                        flags = ["-o", "%{output_execpath}"],
                        expand_if_available = "output_execpath",
                    ),
                ],
            ),
        ],
    )

def _legacy_thinlto():
    return feature(
        name = "thin_lto",
        flag_sets = [
            flag_set(
                actions = [
                    ACTION_NAMES.c_compile,
                    ACTION_NAMES.cpp_compile,
                ] + ACTIONS_LINK_ALL,
                flag_groups = [
                    flag_group(flags = ["-flto=thin"]),
                    flag_group(
                        expand_if_available = "lto_indexing_bitcode_file",
                        flags = [
                            "-Xclang",
                            "-fthin-link-bitcode=%{lto_indexing_bitcode_file}",
                        ],
                    ),
                ],
            ),
            flag_set(
                actions = [ACTION_NAMES.linkstamp_compile],
                flag_groups = [flag_group(flags = ["-DBUILD_LTO_TYPE=thin"])],
            ),
            flag_set(
                actions = ACTIONS_LINK_LTO,
                flag_groups = [
                    flag_group(flags = [
                        "-flto=thin",
                        "-Wl,-plugin-opt,thinlto-index-only%{thinlto_optional_params_file}",
                        "-Wl,-plugin-opt,thinlto-emit-imports-files",
                        "-Wl,-plugin-opt,thinlto-prefix-replace=%{thinlto_prefix_replace}",
                    ]),
                    flag_group(
                        expand_if_available = "thinlto_object_suffix_replace",
                        flags = [
                            "-Wl,-plugin-opt,thinlto-object-suffix-replace=%{thinlto_object_suffix_replace}",
                        ],
                    ),
                    flag_group(
                        expand_if_available = "thinlto_merged_object_file",
                        flags = [
                            "-Wl,-plugin-opt,obj-path=%{thinlto_merged_object_file}",
                        ],
                    ),
                ],
            ),
            flag_set(
                actions = [ACTION_NAMES.lto_backend],
                flag_groups = [
                    flag_group(flags = [
                        "-c",
                        "-fthinlto-index=%{thinlto_index}",
                        "-o",
                        "%{thinlto_output_object_file}",
                        "-x",
                        "ir",
                        "%{thinlto_input_bitcode_file}",
                    ]),
                ],
            ),
        ],
    )

def features_legacy():
    """Legacy Features
    
    TODO: Order them and dcheck if there are really needded

    Legacy features list can be found at: https://bazel.build/docs/cc-toolchain-config-reference

    Returns:
        The list of all legacy features created 
    """
    features = []
    features.append(_legacy_user_compile_flags())
    features.append(_legacy_user_link_flags())
    features.append(_legacy_library_search_directories())
    features.append(_legacy_random_seed())
    features.append(_legacy_symbol_counts())
    features.append(_legacy_static_libgcc())
    features.append(_legacy_sysroot())
    features.append(_legacy_fdo_optimize())
    features.append(_legacy_pic())
    features.append(_legacy_per_object_debug_info())
    features.append(_legacy_preprocessor_defines())
    features.append(_legacy_cs_fdo_optimize())
    features.append(_legacy_autofdo())
    features.append(_legacy_runtime_library_search_directories())
    features.append(_legacy_fission_support())
    features.append(_legacy_shared_flag())
    features.append(_legacy_includes())
    features.append(_legacy_fdo_instrument())
    features.append(_legacy_cs_fdo_instrument())
    features.append(_legacy_include_paths())
    features.append(_legacy_llvm_coverage_map_format())
    features.append(_legacy_strip_debug_symbols())
    features.append(_legacy_build_interface_libraries())
    features.append(_legacy_libraries_to_link())
    features.append(_legacy_fdo_prefetch_hints())
    features.append(_legacy_linkstamps())
    features.append(_legacy_gcc_coverage_map_format())
    features.append(_legacy_archiver_flags())
    features.append(_legacy_force_pic_flags())
    features.append(_legacy_dependency_file())
    features.append(_legacy_dynamic_library_linker_tool())
    features.append(_legacy_output_execpath_flags())
    features.append(_legacy_thinlto())
    return features
