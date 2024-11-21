"""cc_toolchain rule

According to:
https://bazel.build/docs/cc-toolchain-config-reference
"""

load(
    "@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl",
    "feature",
    "feature_set",
    "flag_group",
    "flag_set",
    "variable_with_value",
    "with_feature_set",
)
load("@rules_cc//cc:action_names.bzl", "ACTION_NAMES")

load("//toolchains:actions_grp.bzl", "CC_ACTIONS", "TOOLCHAIN_ACTIONS")

def toolchains_tools_features_config_gcc_like(ctx, compiler_type):
    """features for tools action config
    
    Args:
        ctx: ctx
        compiler_type: supported compiler_type `gcc` / `clang` to disable some clang unsupported flags

    Returns:
        The list of all action_configs for this context
    """
    features = []

    ########## Well Known Features ##########
    features.append(feature(name = "no_legacy_features", enabled = True))

    # Bazel Modes
    features += [
        feature(name = "dbg"),
        feature(name = "opt"),
        feature(name = "fastbuild"),
        
        # feature(name = "coverage"), ## Described Later
    ]

    # Toolchain supports
    features += [
        feature(name = "supports_start_end_lib"),
        feature(name = "supports_interface_shared_libraries"),
        feature(name = "supports_dynamic_linker"),
    ]

    features += [
        # feature(name = "per_object_debug_info"), ## Described Later
        feature(name = "static_link_cpp_runtimes"),
        feature(name = "supports_pic"),

        feature(name = "archive_param_file"),
        feature(name = "has_configured_linker_path"),
    ]

    # MISSING: Modules related features
    features += [
        feature(name = "compile_all_modules"),
        feature(name = "exclude_private_headers_in_module_maps"),
        feature(name = "only_doth_headers_in_module_maps"),
        feature(name = "module_maps", enabled = True),
    ]

    ########## Assembler actions ##########
    features += [
        feature(
            name = "toolchain-assemble",
            flag_sets = [
                flag_set(
                    actions = TOOLCHAIN_ACTIONS.assemble,
                    flag_groups = [ flag_group(flags = [ "-c" ]) ],
                ),
            ],
        ),

        feature(
            name = "toolchain-assember-w-preprocess",
            flag_sets = [
                flag_set(
                    actions = TOOLCHAIN_ACTIONS.assemble_w_preprocess,
                    flag_groups = [ flag_group(flags = [ "-x assembler-with-cpp" ]) ],
                ),
            ],
        )
    ]

    ########## Toolchain Compiler ##########
    features += [
        feature(
            name = "toolchain-compile",
            flag_sets = [
                flag_set(
                    actions = TOOLCHAIN_ACTIONS.compile,
                    flag_groups = [ flag_group(flags = [ "-c" ]) ],
                ),
            ],
        ),
        feature(
            name = "toolchain-compile-c",
            flag_sets = [
                flag_set(
                    actions = TOOLCHAIN_ACTIONS.compile_c,
                    flag_groups = [ flag_group(flags = [ "-xc" ]) ],
                ),
            ],
        ),
        feature(
            name = "toolchain-compile-cxx",
            flag_sets = [
                flag_set(
                    actions = TOOLCHAIN_ACTIONS.compile_cxx,
                    flag_groups = [ flag_group(flags = [ "-xc++" ]) ],
                ),
            ],
        ),
        feature(
            name = "toolchain-compile-header-parsing",
            flag_sets = [
                flag_set(
                    actions = TOOLCHAIN_ACTIONS.compile_header_parsing,
                    flag_groups = [ flag_group(flags = [ "-xc++-header" ]) ],
                ),
            ],
        ),
        feature(
            name = "toolchain-compile-linkstamp",
            flag_sets = [
                flag_set(
                    actions = TOOLCHAIN_ACTIONS.compile_linkstamp,
                    flag_groups = [],
                ),
            ],
        )
    ]

    ########## Toolchain Link ##########
    features += [
        feature(
            name = "toolchain-link-dynamic-lib",
            flag_sets = [
                flag_set(
                    actions = TOOLCHAIN_ACTIONS.link_dynamic_lib,
                    flag_groups = [ flag_group(flags = [ "-shared" ]) ],
                ),
            ],
        ),
        feature(
            name = "toolchain-link-nodeps",
            flag_sets = [
                flag_set(
                    actions = TOOLCHAIN_ACTIONS.link_nodeps,
                    flag_groups = [ flag_group(flags = [ "" ]) ],
                ),
            ],
        ),
        feature(
            name = "toolchain-link-exe",
            flag_sets = [
                flag_set(
                    actions = TOOLCHAIN_ACTIONS.link_exe,
                    flag_groups = [],
                ),
            ],
        )
    ]

    ########## Toolchain AR ##########

    classic_ar_flags = [ "rcs", "-o", "%{output_execpath}" ]
    llvm_ar_flags = [ "rcs", "%{output_execpath}" ]
    ar_flags = classic_ar_flags
    if compiler_type == "clang":
        ar_flags = llvm_ar_flags

    features.append(
        feature(
            name = "toolchain-archive-static-lib",
            flag_sets = [
                flag_set(
                    actions = TOOLCHAIN_ACTIONS.archive_static_lib,
                    flag_groups = [
                        flag_group(
                            flags = ar_flags,
                            expand_if_available = "output_execpath",
                        ),
                    ],
                ),
                flag_set(
                    actions = TOOLCHAIN_ACTIONS.archive_static_lib,
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
    )

    ########## Toolchain LTO ##########
    features += [
        feature(
            name = "toolchain-lto-backend",
            flag_sets = [
                flag_set(
                    actions = TOOLCHAIN_ACTIONS.lto_backend,
                    flag_groups = [],
                ),
            ],
        ),
        feature(
            name = "toolchain-lto-indexing",
            flag_sets = [
                flag_set(
                    actions = TOOLCHAIN_ACTIONS.lto_indexing,
                    flag_groups = [],
                ),
            ],
        )
    ]

    ########## Toolchain Strip ##########
    features.append(
        feature(
            name = "toolchain-strip",
            flag_sets = [
                flag_set(
                    actions = TOOLCHAIN_ACTIONS.strip,
                    flag_groups = [
                        flag_group(flags = ["-S", "-o", "%{output_file}"]),
                        flag_group(
                            flags = ["%{stripopts}"],
                            iterate_over = "stripopts",
                        ),
                        flag_group(flags = ["%{input_file}"]),
                    ],
                ),
            ],
        )
    )

    ########## Toolchain Cliff ##########
    features.append(
        feature(
            name = "toolchain-clif-match",
            flag_sets = [
                flag_set(
                    actions = TOOLCHAIN_ACTIONS.cliff_match,
                    flag_groups = [],
                ),
            ],
        )
    )

    ########## Files ##########
    features += [
        feature(
            name = "compiler_input_flags",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = CC_ACTIONS.cc_compile + CC_ACTIONS.cc_assemble,
                    flag_groups = [
                        flag_group(
                            flags = ["%{source_file}"],
                            expand_if_available = "source_file",
                        ),
                    ],
                ),
            ],
        ),
        feature(
            name = "compiler_output_flags",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = CC_ACTIONS.cc_compile + CC_ACTIONS.cc_assemble,
                    flag_groups = [
                        flag_group(
                            flags = ["-S"],
                            expand_if_available = "output_assembly_file",
                        ),
                        flag_group(
                            flags = ["-E"],
                            expand_if_available = "output_preprocess_file",
                        ),
                        flag_group(
                            flags = ["-o", "%{output_file}"],
                            expand_if_available = "output_file",
                        ),
                    ],
                ),
            ],
        ),
        feature(
            name = "output_execpath_flags",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = CC_ACTIONS.cc_link,
                    flag_groups = [
                        flag_group(
                            flags = [ "-o", "%{output_execpath}" ],
                            expand_if_available = "output_execpath",
                        ),
                    ],
                ),
            ],
        ),
        feature(
            name = "dependency_file",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = CC_ACTIONS.cc_compile,
                    flag_groups = [
                        flag_group(
                            flags = ["-MD", "-MF", "%{dependency_file}"],
                            expand_if_available = "dependency_file",
                        ),
                    ],
                ),
            ],
        ),

        feature(
            name = "per_object_debug_info",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = CC_ACTIONS.cc_compile + CC_ACTIONS.cc_assemble,
                    flag_groups = [
                        flag_group(
                            flags = ["-gsplit-dwarf", "-g"],
                            expand_if_available = "per_object_debug_info_file",
                        ),
                    ],
                ),
            ],
        ),
    ]


    ########## Preprocessor Defines ##########
    features += [
        feature(
            name = "bazel-preprocessor-defines",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = CC_ACTIONS.cc_preprocessor,
                    flag_groups = [
                        flag_group(
                            flags = ["-D", "%{preprocessor_defines}"],
                            iterate_over = "preprocessor_defines",
                        ),
                    ],
                ),
            ],
        ),
        feature(
            name = "toolchain-preprocessor-defines",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = CC_ACTIONS.cc_preprocessor,
                    flag_groups = ([
                        flag_group(
                            flags = [ "-D " + define for define in ctx.attr.defines ],
                        ),
                    ] if len(ctx.attr.defines) > 0 else []),
                ),
            ],
        )
    ]

    ########## Includes Flags ##########
    features += [
        feature(
            name = "bazel-includedirs",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = CC_ACTIONS.cc_preprocessor,
                    flag_groups = [
                        flag_group(
                            flags = ["-iquote", "%{quote_include_paths}"],
                            iterate_over = "quote_include_paths",
                            expand_if_available = "quote_include_paths",
                        ),
                        flag_group(
                            flags = ["-I", "%{include_paths}"],
                            iterate_over = "include_paths",
                            expand_if_available = "include_paths",
                        ),
                        flag_group(
                            flags = ["-isystem", "%{system_include_paths}"],
                            iterate_over = "system_include_paths",
                            expand_if_available = "system_include_paths",
                        ),
                    ],
                ),
            ],
        ),
        feature(
            name = "bazel-includes",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = CC_ACTIONS.cc_preprocessor,
                    flag_groups = [
                        flag_group(
                            flags = ["-include", "%{includes}"],
                            iterate_over = "includes",
                            expand_if_available = "includes",
                        ),
                    ],
                ),
            ]
        ),

        feature(
            name = "toolchain-includedirs",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = CC_ACTIONS.cc_preprocessor,
                    flag_groups = ([
                        flag_group(
                            flags = [ "-I " + includedir for includedir in ctx.attr.includedirs ],
                        ),
                    ] if len(ctx.attr.includedirs) > 0 else []),
                ),
            ],
        ),

        feature(
            name = "toolchain-builtin-includedirs",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = CC_ACTIONS.cc_preprocessor,
                    flag_groups =
                        [ flag_group(flags = [ "-isystem", includedir ]) for includedir in ctx.attr.toolchain_builtin_includedirs ]
                ),
            ],
        ),
    ]

    ########## Compiler Flags ##########
    features += [
        feature(
            name = "unfiltered_compile_flags",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = CC_ACTIONS.cc_compile + CC_ACTIONS.cc_assemble,
                    flag_groups = [
                        flag_group(
                            flags = ["%{unfiltered_compile_flags}"],
                            iterate_over = "unfiltered_compile_flags",
                            expand_if_available = "unfiltered_compile_flags",
                        ),
                    ],
                ),
            ],
        ),
        feature(
            name = "user_compile_flags",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = CC_ACTIONS.cc_compile,
                    flag_groups = [
                        flag_group(
                            flags = ["%{user_compile_flags}"],
                            iterate_over = "user_compile_flags",
                            expand_if_available = "user_compile_flags",
                        ),
                    ],
                ),
            ],
        ),

        feature(
            name = "toolchain-copts",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = CC_ACTIONS.cc_compile,
                    flag_groups = ([
                        flag_group(
                            flags = ctx.attr.copts,
                        ),
                    ] if len(ctx.attr.copts) > 0 else []),
                ),
            ],
        ),
        feature(
            name = "toolchain-conlyopts",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = CC_ACTIONS.cc_compile_c,
                    flag_groups = ([
                        flag_group(
                            flags = ctx.attr.conlyopts,
                        ),
                    ] if len(ctx.attr.conlyopts) > 0 else []),
                ),
            ],
        ),
        feature(
            name = "toolchain-cxxopts",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = CC_ACTIONS.cc_compile_cxx,
                    flag_groups = ([
                        flag_group(
                            flags = ctx.attr.cxxopts,
                        ),
                    ] if len(ctx.attr.cxxopts) > 0 else []),
                ),
            ],
        ),

        feature(
            name = "toolchain-dbg-copts",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = CC_ACTIONS.cc_compile,
                    flag_groups = ([
                        flag_group(
                            flags = ctx.attr.dbg_copts if len(ctx.attr.dbg_copts) > 0 else [ "-g", "-Og" ],
                        ),
                    ]),
                    with_features = [with_feature_set(features = ["dbg"])],
                ),
            ],
        ),
        feature(
            name = "toolchain-opt-copts",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = CC_ACTIONS.cc_compile,
                    flag_groups = ([
                        flag_group(
                            flags = ctx.attr.opt_copts if len(ctx.attr.opt_copts) > 0 else [ "-O2" ],
                        ),
                    ]),
                    with_features = [with_feature_set(features = ["opt"])],
                ),
            ],
        ),
    ]

    ########## Linker Flags ##########
    features += [
        feature(
            name = "linker_param_file",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = CC_ACTIONS.cc_link,
                    flag_groups = [
                        flag_group(
                            flags = ["@%{linker_param_file}"],
                            expand_if_available = "linker_param_file",
                        ),
                    ],
                ),
            ],
        ),
        feature(
            name = "linkstamp_paths",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = CC_ACTIONS.cc_link,
                    flag_groups = [
                        flag_group(
                            flags = ["%{linkstamp_paths}"],
                            iterate_over = "linkstamp_paths",
                            expand_if_available = "linkstamp_paths",
                        ),
                    ],
                ),
            ],
        ),
        feature(
            name = "user_link_flags",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = CC_ACTIONS.cc_link,
                    flag_groups = [
                        flag_group(
                            flags = ["%{user_link_flags}"],
                            iterate_over = "user_link_flags",
                            expand_if_available = "user_link_flags",
                        ),
                    ],
                ),
            ],
        ),

        feature(
            name = "toolchain-linkopts",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = CC_ACTIONS.cc_link,
                    flag_groups = ([
                        flag_group(
                            flags = ctx.attr.linkopts,
                        ),
                    ] if len(ctx.attr.linkopts) > 0 else []),
                ),
            ],
        ),

        feature(
            name = "toolchain-dbg-linkopts",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = CC_ACTIONS.cc_link,
                    flag_groups = ([
                        flag_group(
                            flags = ctx.attr.dbg_linkopts,
                        ),
                    ] if len(ctx.attr.dbg_linkopts) > 0 else []),
                    with_features = [with_feature_set(features = ["dbg"])],
                ),
            ],
        ),
        feature(
            name = "toolchain-opt-linkopts",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = CC_ACTIONS.cc_link,
                    flag_groups = ([
                        flag_group(
                            flags = ctx.attr.opt_linkopts,
                        ),
                    ] if len(ctx.attr.opt_linkopts) > 0 else []),
                    with_features = [with_feature_set(features = ["opt"])],
                ),
            ],
        ),
    ]

    ########## Link Paths ##########
    features += [
        feature(
            name = "library_search_directories",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = CC_ACTIONS.cc_link,
                    flag_groups = [
                        flag_group(
                            flags = ["-L", "%{library_search_directories}"],
                            iterate_over = "library_search_directories",
                            expand_if_available = "library_search_directories",
                        ),
                    ],
                ),
            ],
        ),
        feature(
            name = "toolchain-linkdirs",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = CC_ACTIONS.cc_link,
                    flag_groups = ([
                        flag_group(
                            flags = [ "-L " + linkdir for linkdir in ctx.attr.linkdirs ],
                        ),
                    ] if len(ctx.attr.linkdirs) > 0 else []),
                ),
            ],
        ),
    ]

    ########## Link Libs ##########
    features += [
        feature(
            name = "libraries_to_link",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = CC_ACTIONS.cc_link,
                    flag_groups = [
                        flag_group(
                            iterate_over = "libraries_to_link",
                            expand_if_available = "libraries_to_link",
                            flag_groups = [
                                # object_file_group
                                flag_group(
                                    flags = ["-Wl,--start-lib"],
                                    expand_if_equal = variable_with_value(
                                        name = "libraries_to_link.type",
                                        value = "object_file_group",
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
                                flag_group(
                                    flags = ["-Wl,--end-lib"],
                                    expand_if_equal = variable_with_value(
                                        name = "libraries_to_link.type",
                                        value = "object_file_group",
                                    ),
                                ),

                                # static_library
                                flag_group(
                                    flags = ["-Wl,-whole-archive"],
                                    expand_if_true = "libraries_to_link.is_whole_archive",
                                    expand_if_equal = variable_with_value(
                                        name = "libraries_to_link.type",
                                        value = "static_library",
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
                                    flags = ["-Wl,-no-whole-archive"],
                                    expand_if_true = "libraries_to_link.is_whole_archive",
                                    expand_if_equal = variable_with_value(
                                        name = "libraries_to_link.type",
                                        value = "static_library",
                                    ),
                                ),

                                # object_file
                                flag_group(
                                    flags = ["%{libraries_to_link.name}"],
                                    expand_if_equal = variable_with_value(
                                        name = "libraries_to_link.type",
                                        value = "object_file",
                                    ),
                                ),

                                # interface_library
                                flag_group(
                                    flags = ["%{libraries_to_link.name}"],
                                    expand_if_equal = variable_with_value(
                                        name = "libraries_to_link.type",
                                        value = "interface_library",
                                    ),
                                ),
                                
                                # dynamic_library
                                flag_group(
                                    flags = ["-l%{libraries_to_link.name}"],
                                    expand_if_equal = variable_with_value(
                                        name = "libraries_to_link.type",
                                        value = "dynamic_library",
                                    ),
                                ),

                                # versioned_dynamic_library
                                flag_group(
                                    flags = ["-l:%{libraries_to_link.name}"],
                                    expand_if_equal = variable_with_value(
                                        name = "libraries_to_link.type",
                                        value = "versioned_dynamic_library",
                                    ),
                                ),
                            ],
                        ),
                    ],
                ),
            ],
        ),

        feature(
            name = "static_libgcc",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = CC_ACTIONS.cc_link_transitive,
                    flag_groups = [flag_group(flags = ["-static-libgcc"])],
                    with_features = [
                        with_feature_set(features = ["static_link_cpp_runtimes"]),
                    ],
                ),
            ],
        ),

        feature(
            name = "toolchain-linklibs",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = CC_ACTIONS.cc_link,
                    flag_groups = ([
                        flag_group(
                            flags = [ "-l " + linklibs for linklibs in ctx.attr.linklibs ],
                        ),
                    ] if len(ctx.attr.linklibs) > 0 else []),
                ),
            ],
        ),
    ]

    ########## Runtime Lib ##########
    ## features.append(
    ##     feature(
    ##         name = "runtime_library_search_directories",
    ##         flag_sets = [
    ##             flag_set(
    ##                 actions = CC_ACTIONS.cc_link + CC_ACTIONS.,
    ##                 flag_groups = [
    ##                     flag_group(
    ##                         iterate_over = "runtime_library_search_directories",
    ##                         expand_if_available = "runtime_library_search_directories",
    ##                         flag_groups = [
    ##                             flag_group(
    ##                                 flags = [
    ##                                     "-Xlinker",
    ##                                     "-rpath",
    ##                                     "-Xlinker",
    ##                                     "@loader_path/%{runtime_library_search_directories}",
    ##                                 ],
    ##                                 expand_if_true = "is_cc_test",
    ##                             ),
    ##                         ],
    ##                     ),
    ##                 ],
    ##                 with_features = [
    ##                     with_feature_set(features = ["static_link_cpp_runtimes"]),
    ##                 ],
    ##             ),
    ##             flag_set(
    ##                 actions = CC_ACTIONS.cc_link,
    ##                 flag_groups = [
    ##                     flag_group(
    ##                         iterate_over = "runtime_library_search_directories",
    ##                         expand_if_available = "runtime_library_search_directories",
    ##                         flag_groups = [
    ##                             flag_group(
    ##                                 flags = [
    ##                                     "-Xlinker",
    ##                                     "-rpath",
    ##                                     "-Xlinker",
    ##                                     "$ORIGIN/%{runtime_library_search_directories}",
    ##                                 ],
    ##                             ),
    ##                         ],
    ##                     ),
    ##                 ],
    ##                 with_features = [
    ##                     with_feature_set(not_features = ["static_link_cpp_runtimes"]),
    ##                 ],
    ##             ),
    ##         ],
    ##     )
    ## )

    ########## Interface Library ##########
    features += [
        feature(
            name = "build_interface_libraries",
            flag_sets = [
                flag_set(
                    actions = CC_ACTIONS.cc_link_lib,
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
                        with_feature_set(features = ["supports_interface_shared_libraries"]),
                    ],
                ),
            ],
        ),
        feature(
            name = "dynamic_library_linker_tool",
            flag_sets = [
                flag_set(
                    actions = CC_ACTIONS.cc_link_lib,
                    flag_groups = [
                        flag_group(
                            flags = [" + cppLinkDynamicLibraryToolPath + "],
                            expand_if_available = "generate_interface_library",
                        ),
                    ],
                    with_features = [
                        with_feature_set(features = ["supports_interface_shared_libraries"]),
                    ],
                ),
            ],
        )
    ]

    ########## Miscs ##########
    features += [
        feature(
            name = "sysroot",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = CC_ACTIONS.cc_compile + CC_ACTIONS.cc_assemble + CC_ACTIONS.cc_link,
                    flag_groups = [
                        flag_group(
                            flags = ["--sysroot=%{sysroot}"],
                            expand_if_available = "sysroot",
                        ),
                    ],
                ),
            ],
        ),
        feature(
            name = "random_seed",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = CC_ACTIONS.cc_compile + CC_ACTIONS.cc_assemble,
                    flag_groups = [
                        flag_group(
                            flags = ["-frandom-seed=%{output_file}"],
                            expand_if_available = "output_file",
                        ),
                    ],
                ),
            ],
        ),
        feature(
            name = "toolchain-canonical-prefixes",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = CC_ACTIONS.cc_compile + CC_ACTIONS.cc_link,
                    flag_groups = [
                        flag_group(
                            flags = [ "-no-canonical-prefixes" ] + (
                                [ "-fno-canonical-system-headers" ] if compiler_type == "gcc" else []
                            ),
                        ),
                    ],
                ),
            ],
        ),
        feature(
            name = "toolchain-date-macros",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = CC_ACTIONS.cc_preprocessor,
                    flag_groups = [
                        flag_group(
                            flags = [
                                "-Wno-builtin-macro-redefined",
                                "-D__DATE__=\"redacted\"",
                                "-D__TIMESTAMP__=\"redacted\"",
                                "-D__TIME__=\"redacted\"",
                            ],
                        ),
                    ],
                ),
            ],
        )
    ]

    ########## Strip ##########
    features.append(
        feature(
            name = "strip_debug_symbols",
            flag_sets = [
                flag_set(
                    actions = CC_ACTIONS.cc_link,
                    flag_groups = [
                        flag_group(
                            flags = ["-Wl,-S"],
                            expand_if_available = "strip_debug_symbols",
                        ),
                    ],
                ),
            ],
        )
    )

    ########## Pic ##########
    features += [
        feature(
            name = "pic",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = CC_ACTIONS.cc_compile + CC_ACTIONS.cc_assemble,
                    flag_groups = [
                        flag_group(
                            flags = ["-fPIC"],
                            expand_if_available = "pic"
                        ),
                    ],
                ),
            ],
        ),
        feature(
            name = "force_pic",
            flag_sets = [
                flag_set(
                    actions = CC_ACTIONS.cc_link_exe,
                    flag_groups = [
                        flag_group(
                            flags = ["-Wl,-pie"],
                            expand_if_available = "force_pic",
                        ),
                    ],
                ),
            ],
        )
    ]


    ########## Coverage ##########
    features += [
        feature(
            name = "coverage",
            provides = ["profile"],
            flag_sets = [
                flag_set(
                    actions = CC_ACTIONS.cc_compile,
                    flag_groups = [],
                ),
                flag_set(
                    actions = CC_ACTIONS.cc_link,
                    flag_groups = [],
                ),
            ],
        ),

        feature(
            name = "gcc_coverage_map_format",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = CC_ACTIONS.cc_compile,
                    flag_groups = [
                        flag_group(
                            flags = ["-fprofile-arcs", "-ftest-coverage", "-g"],
                            expand_if_available = "gcov_gcno_file",
                        ),
                    ],
                ),
                flag_set(
                    actions = CC_ACTIONS.cc_link,
                    flag_groups = [
                        flag_group(
                            flags = ["--coverage"],
                            expand_if_available = "gcov_gcno_file",
                        )
                    ],
                ),
            ],
            requires = [feature_set(features = ["coverage"])],
        ),
        feature(
            name = "llvm_coverage_map_format",
            flag_sets = [
                flag_set(
                    actions = CC_ACTIONS.cc_compile,
                    flag_groups = [
                        flag_group(
                            flags = ["-fprofile-instr-generate", "-fcoverage-mapping", "-g"],
                        ),
                    ],
                ),
                flag_set(
                    actions = CC_ACTIONS.cc_link,
                    flag_groups = [flag_group(flags = ["-fprofile-instr-generate"])],
                ),
            ],
            requires = [feature_set(features = ["coverage"])],
        ),

        feature(
            name = "coverage_prefix_map",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = CC_ACTIONS.cc_compile,
                    flag_groups = [
                        flag_group(
                            flags = ["-fcoverage-prefix-map=__BAZEL_EXECUTION_ROOT__=."],
                        ),
                    ],
                ),
            ],
            requires = [feature_set(features = ["coverage"])],
        ),
    ]

    ########## LTO / ThinLTO ##########
    features.append(
        feature(
            name = "thin_lto",
            flag_sets = [
                flag_set(
                    actions = CC_ACTIONS.cc_compile_only + CC_ACTIONS.cc_link,
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
                    actions = CC_ACTIONS.cc_link_lto_indexing,
                    flag_groups = [
                        flag_group(
                            flags = [
                                "-flto=thin",
                                "-Wl,-plugin-opt,thinlto-index-only%{thinlto_optional_params_file}",
                                "-Wl,-plugin-opt,thinlto-emit-imports-files",
                                "-Wl,-plugin-opt,thinlto-prefix-replace=%{thinlto_prefix_replace}",
                            ]
                        ),
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
    )

    ########## FDO ##########
    features += [
        feature(
            name = "fdo_instrument",
            provides = ["profile"],
            flag_sets = [
                flag_set(
                    actions = CC_ACTIONS.cc_compile_only + CC_ACTIONS.cc_link,
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
        ),
        feature(
            name = "fdo_optimize",
            provides = ["profile"],
            flag_sets = [
                flag_set(
                    actions = CC_ACTIONS.cc_compile_only,
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
        ),
        feature(
            name = "cs_fdo_optimize",
            provides = ["csprofile"],
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
        ),
        feature(
            name = "autofdo",
            provides = ["profile"],
            flag_sets = [
                flag_set(
                    actions = CC_ACTIONS.cc_compile_only,
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
        ),
        feature(
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
        ),
        feature(
            name = "cs_fdo_instrument",
            provides = ["csprofile"],
            flag_sets = [
                flag_set(
                    actions = [
                        ACTION_NAMES.c_compile,
                        ACTION_NAMES.cpp_compile,
                        ACTION_NAMES.lto_backend,
                    ] + CC_ACTIONS.cc_link,
                    flag_groups = [
                        flag_group(
                            flags = ["-fcs-profile-generate=%{cs_fdo_instrument_path}"],
                            expand_if_available = "cs_fdo_instrument_path",
                        ),
                    ],
                ),
            ],
        )
    ]

    ########## Sanitizer Features ##########
    def sanitizer_features(name, sanitizer_type, extra_compiler_flags = [], extra_linker_flags = []):
        return feature(
            name = name,
            provides = ["sanitizer"],
            flag_sets = [
                flag_set(
                    actions = CC_ACTIONS.cc_compile_only + CC_ACTIONS.cc_link,
                    flag_groups = [
                        flag_group(
                            flags = [
                                "-fsanitize={}".format(sanitizer_type),
                            ]
                        ),
                    ],
                ),
                flag_set(
                    actions = CC_ACTIONS.cc_compile_only,
                    flag_groups = [flag_group(flags = extra_compiler_flags)] if len(extra_compiler_flags) > 0 else [],
                ),
                flag_set(
                    actions = CC_ACTIONS.cc_link,
                    flag_groups = [flag_group(flags = extra_linker_flags)] if len(extra_linker_flags) > 0 else [],
                ),
            ],
        )

    features += [
        sanitizer_features("asan", "address"),
        sanitizer_features("tsan", "thread"),
        sanitizer_features("ubsan", "undefined"),

        feature(
            name = "default_sanitizer_flags",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = CC_ACTIONS.cc_compile_only,
                    flag_groups = [
                        flag_group(
                            flags = [
                                "-fno-omit-frame-pointer",
                                "-fno-sanitize-recover=all",
                            ],
                        ),
                    ],
                    with_features = [
                        with_feature_set(features = ["asan"]),
                        with_feature_set(features = ["tsan"]),
                        with_feature_set(features = ["ubsan"]),
                    ],
                ),
            ],
        )
    ]

    ########## Custom Features ##########
    # buildifier: disable=list-append
    features += [
        feature(
            name = "fatal-warnings",
            flag_sets = [
                flag_set(
                    actions = CC_ACTIONS.cc_compile_only,
                    flag_groups = [flag_group(flags = ["-Werror"])],
                ),
                flag_set(
                    actions = CC_ACTIONS.cc_link,
                    flag_groups = [
                        flag_group(flags = ["-Wl,-fatal-warnings"]),
                    ],
                ),
            ],
        )
    ]

    return features
