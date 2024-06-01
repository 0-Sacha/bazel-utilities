# Actions Flags to provides:

#### Assembler
- toolchain-assemble
- toolchain-assember-w-preprocess

#### Compiler
- toolchain-compile
- toolchain-compile-c
- toolchain-compile-cxx
- toolchain-compile-header-parsing
- toolchain-compile-linkstamp

#### Linker
- toolchain-link-dynamic-lib
- toolchain-link-nodeps
- toolchain-link-exe

#### Archive
- toolchain-archive-static-lib

#### LTO
- toolchain-lto-backend
- toolchain-lto-indexing

#### Strip
- toolchain-strip

#### Cliff
- toolchain-clif-match


# Bazel variables to handle: [bazel](https://bazel.build/docs/cc-toolchain-config-reference#cctoolchainconfiginfo-build-variables)

All except 'leagacy'

#### Files
- source_file
- output_file
- input_file
- output_execpath

- dependency_file

- gcov_gcno_file
- per_object_debug_info_file

- def_file_path

#### Flags
- preprocessor_defines

- user_compile_flags
- unfiltered_compile_flags

- includes
- include_paths; quote_include_paths; system_include_paths;

- linker_param_file
- library_search_directories
- linkstamp_paths
- user_link_flags

- libraries_to_link

- runtime_library_search_directories

- stripotps
- strip_debug_symbols
----
- sysroot
- pic
- force_pic
----
- is_cc_test
- is_using_fission
----
- fdo_instrument_path
- fdo_profile_path
- fdo_prefetch_hints_path
- cs_fdo_instrument_path
----
- generate_interface_library
- interface_library_builder_path
- interface_library_input_path
- interface_library_output_path

#### Maybe
- output_assembly_file
- output_preprocess_file

# Bazel features to handle: [bazel](https://bazel.build/docs/cc-toolchain-config-reference#wellknown-features)
- opt | dbg | fastbuild
- static_linking_mode | dynamic_linking_mode

- supports_start_end_lib
- supports_interface_shared_libraries
- supports_dynamic_linker
- per_object_debug_info
- static_link_cpp_runtimes
- supports_pic

- no_legacy_features is always ON
