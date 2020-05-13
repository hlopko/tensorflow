"""cc_toolchain_config rule for configuring CUDA toolchains on Linux, Mac, and Windows."""

load(
    "@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl",
    "action_config",
    "env_entry",
    "env_set",
    "feature",
    "feature_set",
    "flag_group",
    "flag_set",
    "tool",
    "tool_path",
    "variable_with_value",
    "with_feature_set",
)
load("@bazel_tools//tools/build_defs/cc:action_names.bzl", "ACTION_NAMES")

def libraries_to_link_group(flavour):
    if flavour == "linux":
        return flag_group(
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
        )
    elif flavour == "darwin":
        return flag_group(
            iterate_over = "libraries_to_link",
            flag_groups = [
                flag_group(
                    iterate_over = "libraries_to_link.object_files",
                    flag_groups = [
                        flag_group(
                            flags = ["%{libraries_to_link.object_files}"],
                            expand_if_false = "libraries_to_link.is_whole_archive",
                        ),
                        flag_group(
                            flags = ["-Wl,-force_load,%{libraries_to_link.object_files}"],
                            expand_if_true = "libraries_to_link.is_whole_archive",
                        ),
                    ],
                    expand_if_equal = variable_with_value(
                        name = "libraries_to_link.type",
                        value = "object_file_group",
                    ),
                ),
                flag_group(
                    flag_groups = [
                        flag_group(
                            flags = ["%{libraries_to_link.name}"],
                            expand_if_false = "libraries_to_link.is_whole_archive",
                        ),
                        flag_group(
                            flags = ["-Wl,-force_load,%{libraries_to_link.name}"],
                            expand_if_true = "libraries_to_link.is_whole_archive",
                        ),
                    ],
                    expand_if_equal = variable_with_value(
                        name = "libraries_to_link.type",
                        value = "object_file",
                    ),
                ),
                flag_group(
                    flag_groups = [
                        flag_group(
                            flags = ["%{libraries_to_link.name}"],
                            expand_if_false = "libraries_to_link.is_whole_archive",
                        ),
                        flag_group(
                            flags = ["-Wl,-force_load,%{libraries_to_link.name}"],
                            expand_if_true = "libraries_to_link.is_whole_archive",
                        ),
                    ],
                    expand_if_equal = variable_with_value(
                        name = "libraries_to_link.type",
                        value = "interface_library",
                    ),
                ),
                flag_group(
                    flag_groups = [
                        flag_group(
                            flags = ["%{libraries_to_link.name}"],
                            expand_if_false = "libraries_to_link.is_whole_archive",
                        ),
                        flag_group(
                            flags = ["-Wl,-force_load,%{libraries_to_link.name}"],
                            expand_if_true = "libraries_to_link.is_whole_archive",
                        ),
                    ],
                    expand_if_equal = variable_with_value(
                        name = "libraries_to_link.type",
                        value = "static_library",
                    ),
                ),
                flag_group(
                    flag_groups = [
                        flag_group(
                            flags = ["-l%{libraries_to_link.name}"],
                            expand_if_false = "libraries_to_link.is_whole_archive",
                        ),
                        flag_group(
                            flags = ["-Wl,-force_load,-l%{libraries_to_link.name}"],
                            expand_if_true = "libraries_to_link.is_whole_archive",
                        ),
                    ],
                    expand_if_equal = variable_with_value(
                        name = "libraries_to_link.type",
                        value = "dynamic_library",
                    ),
                ),
                flag_group(
                    flag_groups = [
                        flag_group(
                            flags = ["-l:%{libraries_to_link.name}"],
                            expand_if_false = "libraries_to_link.is_whole_archive",
                        ),
                        flag_group(
                            flags = ["-Wl,-force_load,-l:%{libraries_to_link.name}"],
                            expand_if_true = "libraries_to_link.is_whole_archive",
                        ),
                    ],
                    expand_if_equal = variable_with_value(
                        name = "libraries_to_link.type",
                        value = "versioned_dynamic_library",
                    ),
                ),
            ],
            expand_if_available = "libraries_to_link",
        )
    elif flavour == "msvc":
        return flag_group(
            iterate_over = "libraries_to_link",
            flag_groups = [
                flag_group(
                    iterate_over = "libraries_to_link.object_files",
                    flag_groups = [flag_group(flags = ["%{libraries_to_link.object_files}"])],
                    expand_if_equal = variable_with_value(
                        name = "libraries_to_link.type",
                        value = "object_file_group",
                    ),
                ),
                flag_group(
                    flag_groups = [flag_group(flags = ["%{libraries_to_link.name}"])],
                    expand_if_equal = variable_with_value(
                        name = "libraries_to_link.type",
                        value = "object_file",
                    ),
                ),
                flag_group(
                    flag_groups = [flag_group(flags = ["%{libraries_to_link.name}"])],
                    expand_if_equal = variable_with_value(
                        name = "libraries_to_link.type",
                        value = "interface_library",
                    ),
                ),
                flag_group(
                    flag_groups = [
                        flag_group(
                            flags = ["%{libraries_to_link.name}"],
                            expand_if_false = "libraries_to_link.is_whole_archive",
                        ),
                        flag_group(
                            flags = ["/WHOLEARCHIVE:%{libraries_to_link.name}"],
                            expand_if_true = "libraries_to_link.is_whole_archive",
                        ),
                    ],
                    expand_if_equal = variable_with_value(
                        name = "libraries_to_link.type",
                        value = "static_library",
                    ),
                ),
            ],
            expand_if_available = "libraries_to_link",
        )

def _impl(ctx):
    all_compile_actions = [
        ACTION_NAMES.assemble,
        ACTION_NAMES.c_compile,
        ACTION_NAMES.cpp_compile,
        ACTION_NAMES.cpp_header_parsing,
        ACTION_NAMES.cpp_module_codegen,
        ACTION_NAMES.cpp_module_compile,
        ACTION_NAMES.linkstamp_compile,
        ACTION_NAMES.preprocess_assemble,
    ]

    all_preprocessed_actions = [
        ACTION_NAMES.c_compile,
        ACTION_NAMES.cpp_compile,
        ACTION_NAMES.cpp_header_parsing,
        ACTION_NAMES.cpp_module_codegen,
        ACTION_NAMES.cpp_module_compile,
        ACTION_NAMES.linkstamp_compile,
        ACTION_NAMES.preprocess_assemble,
    ]

    all_link_actions = [
        ACTION_NAMES.cpp_link_executable,
        ACTION_NAMES.cpp_link_dynamic_library,
        ACTION_NAMES.cpp_link_nodeps_dynamic_library,
    ]

    all_archive_actions = [ACTION_NAMES.cpp_link_static_library]

    all_cpp_compile_actions = [
        ACTION_NAMES.cpp_compile,
        ACTION_NAMES.cpp_header_parsing,
        ACTION_NAMES.cpp_module_codegen,
        ACTION_NAMES.cpp_module_compile,
        ACTION_NAMES.linkstamp_compile,
    ]

    if (ctx.attr.cpu == "darwin"):
        toolchain_identifier = "local_darwin"
    elif (ctx.attr.cpu == "local"):
        toolchain_identifier = "local_linux"
    elif (ctx.attr.cpu == "x64_windows"):
        toolchain_identifier = "local_windows"
    else:
        fail("Unreachable")

    if (ctx.attr.cpu == "darwin"):
        target_cpu = "darwin"
    elif (ctx.attr.cpu == "local"):
        target_cpu = "local"
    elif (ctx.attr.cpu == "x64_windows"):
        target_cpu = "x64_windows"
    else:
        fail("Unreachable")

    if (ctx.attr.cpu == "local"):
        target_libc = "local"
    elif (ctx.attr.cpu == "darwin"):
        target_libc = "macosx"
    elif (ctx.attr.cpu == "x64_windows"):
        target_libc = "msvcrt"
    else:
        fail("Unreachable")

    if (ctx.attr.cpu == "darwin" or
        ctx.attr.cpu == "local"):
        compiler = "compiler"
    elif (ctx.attr.cpu == "x64_windows"):
        compiler = "msvc-cl"
    else:
        fail("Unreachable")

    if (ctx.attr.cpu == "darwin" or
        ctx.attr.cpu == "local"):
        action_configs = [
            action_config(
                action_name = name,
                enabled = True,
                tools = [tool(path = ctx.attr.host_compiler_path)],
            )
            for name in all_compile_actions + all_link_actions
        ] + [
            action_config(
                action_name = name,
                enabled = True,
                tools = [tool(path = ctx.attr.host_compiler_prefix + "/ar")],
            )
            for name in all_archive_actions
        ] + [
            action_config(
                action_name = name,
                enabled = True,
                tools = [tool(path = ctx.attr.host_compiler_prefix + "/strip")],
            )
            for name in [ACTION_NAMES.strip]
        ]
    elif (ctx.attr.cpu == "x64_windows"):
        action_configs = [
            action_config(
                action_name = name,
                enabled = True,
                tools = [tool(path = ctx.attr.msvc_link_path)],
            )
            for name in all_link_actions
        ] + [
            action_config(
                action_name = name,
                enabled = True,
                tools = [tool(path = ctx.attr.msvc_lib_path)],
            )
            for name in all_archive_actions
        ] + [
            action_config(
                action_name = name,
                enabled = True,
                tools = [tool(path = ctx.attr.msvc_ml_path)],
            )
            for name in [ACTION_NAMES.assemble, ACTION_NAMES.preprocess_assemble]
        ] + [
            action_config(
                action_name = name,
                enabled = True,
                tools = [tool(path = ctx.attr.msvc_cl_path)],
            )
            for name in [ACTION_NAMES.c_compile] + all_cpp_compile_actions
        ]
    else:
        fail("Unreachable")

    if (ctx.attr.cpu == "local" or ctx.attr.cpu == "darwin"):
        sysroot_group = flag_group(
            flags = ["--sysroot=%{sysroot}"],
            expand_if_available = "sysroot",
        )
        no_canonical_prefixes_group = flag_group(
            flags = [
                "-no-canonical-prefixes",
            ] + ctx.attr.extra_no_canonical_prefixes_flags,
        )
        cuda_group = flag_group(
            flags = ["--cuda-path=" + ctx.attr.cuda_path],
        )
        features = [
            feature(name = "no_legacy_features"),
            feature(
                name = "default_compile_flags",
                enabled = True,
                flag_sets = [
                    flag_set(
                        actions = all_compile_actions,
                        flag_groups = [
                            flag_group(
                                flags = ["-MD", "-MF", "%{dependency_file}"],
                                expand_if_available = "dependency_file",
                            ),
                            flag_group(
                                flags = ["-gsplit-dwarf"],
                                expand_if_available = "per_object_debug_info_file",
                            ),
                        ],
                    ),
                    flag_set(
                        actions = all_preprocessed_actions,
                        flag_groups = [
                            flag_group(
                                flags = ["-frandom-seed=%{output_file}"],
                                expand_if_available = "output_file",
                            ),
                            flag_group(
                                flags = ["-D%{preprocessor_defines}"],
                                iterate_over = "preprocessor_defines",
                            ),
                            flag_group(
                                flags = ["-include", "%{includes}"],
                                iterate_over = "includes",
                                expand_if_available = "includes",
                            ),
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
                            flag_group(
                                flags = ["-F", "%{framework_include_paths}"],
                                iterate_over = "framework_include_paths",
                            ),
                        ],
                    ),
                    flag_set(
                        actions = all_cpp_compile_actions,
                        flag_groups = [
                            flag_group(flags = ["-fexperimental-new-pass-manager"]),
                        ] if ctx.attr.compiler == "clang" else [],
                    ),
                    flag_set(
                        actions = all_compile_actions,
                        flag_groups = [
                            flag_group(
                                flags = [
                                    "-Wno-builtin-macro-redefined",
                                    "-D__DATE__=\"redacted\"",
                                    "-D__TIMESTAMP__=\"redacted\"",
                                    "-D__TIME__=\"redacted\"",
                                ],
                            ),
                            flag_group(
                                flags = ["-fPIC"],
                                expand_if_available = "pic",
                            ),
                            flag_group(
                                flags = ["-fPIE"],
                                expand_if_not_available = "pic",
                            ),
                            flag_group(
                                flags = [
                                    "-U_FORTIFY_SOURCE",
                                    "-D_FORTIFY_SOURCE=1",
                                    "-fstack-protector",
                                    "-Wall",
                                ] + ctx.attr.host_compiler_warnings + [
                                    "-fno-omit-frame-pointer",
                                ],
                            ),
                            no_canonical_prefixes_group,
                        ],
                    ),
                    flag_set(
                        actions = all_compile_actions,
                        flag_groups = [flag_group(flags = ["-DNDEBUG"])],
                        with_features = [with_feature_set(features = ["disable-assertions"])],
                    ),
                    flag_set(
                        actions = all_compile_actions,
                        flag_groups = [
                            flag_group(
                                flags = [
                                    "-g0",
                                    "-O2",
                                    "-ffunction-sections",
                                    "-fdata-sections",
                                ],
                            ),
                        ],
                        with_features = [with_feature_set(features = ["opt"])],
                    ),
                    flag_set(
                        actions = all_compile_actions,
                        flag_groups = [flag_group(flags = ["-g"])],
                        with_features = [with_feature_set(features = ["dbg"])],
                    ),
                ] + (
                    [
                        flag_set(actions = all_compile_actions, flag_groups = [cuda_group]),
                    ] if ctx.attr.cuda_path else []
                ) + [
                    flag_set(
                        actions = all_compile_actions,
                        flag_groups = [
                            flag_group(
                                flags = ["%{user_compile_flags}"],
                                iterate_over = "user_compile_flags",
                                expand_if_available = "user_compile_flags",
                            ),
                            sysroot_group,
                            flag_group(
                                expand_if_available = "source_file",
                                flags = ["-c", "%{source_file}"],
                            ),
                            flag_group(
                                expand_if_available = "output_assembly_file",
                                flags = ["-S"],
                            ),
                            flag_group(
                                expand_if_available = "output_preprocess_file",
                                flags = ["-E"],
                            ),
                            flag_group(
                                expand_if_available = "output_file",
                                flags = ["-o", "%{output_file}"],
                            ),
                        ],
                    ),
                ],
            ),
            feature(
                name = "default_archive_flags",
                enabled = True,
                flag_sets = [
                    flag_set(
                        actions = all_archive_actions,
                        flag_groups = [
                            flag_group(
                                expand_if_available = "linker_param_file",
                                flags = ["@%{linker_param_file}"],
                            ),
                            flag_group(flags = ["rcsD"]),
                            flag_group(
                                flags = ["%{output_execpath}"],
                                expand_if_available = "output_execpath",
                            ),
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
            ),
            feature(
                name = "default_link_flags",
                enabled = True,
                flag_sets = [
                    flag_set(
                        actions = [
                            ACTION_NAMES.cpp_link_dynamic_library,
                            ACTION_NAMES.cpp_link_nodeps_dynamic_library,
                        ],
                        flag_groups = [flag_group(flags = ["-shared"])],
                    ),
                    flag_set(
                        actions = all_link_actions,
                        flag_groups = [
                            flag_group(
                                flags = ["@%{linker_param_file}"],
                                expand_if_available = "linker_param_file",
                            ),
                            flag_group(
                                flags = ["%{linkstamp_paths}"],
                                iterate_over = "linkstamp_paths",
                                expand_if_available = "linkstamp_paths",
                            ),
                            flag_group(
                                flags = ["-o", "%{output_execpath}"],
                                expand_if_available = "output_execpath",
                            ),
                            flag_group(
                                flags = ["-L%{library_search_directories}"],
                                iterate_over = "library_search_directories",
                                expand_if_available = "library_search_directories",
                            ),
                            flag_group(
                                iterate_over = "runtime_library_search_directories",
                                flags = [
                                    "-Wl,-rpath,$ORIGIN/%{runtime_library_search_directories}",
                                ] if ctx.attr.cpu == "local" else [
                                    "-Wl,-rpath,@loader_path/%{runtime_library_search_directories}",
                                ],
                                expand_if_available =
                                    "runtime_library_search_directories",
                            ),
                            libraries_to_link_group("darwin" if ctx.attr.cpu == "darwin" else "linux"),
                            flag_group(
                                flags = ["%{user_link_flags}"],
                                iterate_over = "user_link_flags",
                                expand_if_available = "user_link_flags",
                            ),
                            flag_group(
                                flags = ["-Wl,--gdb-index"],
                                expand_if_available = "is_using_fission",
                            ),
                            flag_group(
                                flags = ["-Wl,-S"],
                                expand_if_available = "strip_debug_symbols",
                            ),
                            flag_group(flags = ["-lc++" if ctx.attr.cpu == "darwin" else "-lstdc++"]),
                            no_canonical_prefixes_group,
                        ],
                    ),
                    flag_set(
                        actions = [ACTION_NAMES.cpp_link_executable],
                        flag_groups = [flag_group(flags = ["-pie"])],
                    ),
                ] + ([
                    flag_set(
                        actions = all_link_actions,
                        flag_groups = [flag_group(flags = [
                            "-Wl,-z,relro,-z,now",
                        ])],
                    ),
                ] if ctx.attr.cpu == "local" else []) + [
                    flag_set(
                        actions = all_link_actions,
                        flag_groups = [flag_group(flags = ["-Wl,-no-as-needed"])],
                        with_features = [with_feature_set(features = ["alwayslink"])],
                    ),
                    flag_set(
                        actions = all_link_actions,
                        flag_groups = [
                            flag_group(flags = ["-B" + ctx.attr.linker_bin_path]),
                        ],
                    ),
                ] + ([flag_set(
                    actions = all_link_actions,
                    flag_groups = [
                        flag_group(flags = ["-Wl,--gc-sections"]),
                        flag_group(
                            flags = ["-Wl,--build-id=md5", "-Wl,--hash-style=gnu"],
                        ),
                    ],
                )] if ctx.attr.cpu == "local" else []) + ([
                    flag_set(
                        actions = all_link_actions,
                        flag_groups = [flag_group(flags = ["-undefined", "dynamic_lookup"])],
                    ),
                ] if ctx.attr.cpu == "darwin" else []) + (
                    [
                        flag_set(
                            actions = all_link_actions,
                            flag_groups = [cuda_group],
                        ),
                    ] if ctx.attr.cuda_path else []
                ) + [
                    flag_set(
                        actions = all_link_actions,
                        flag_groups = [
                            sysroot_group,
                        ],
                    ),
                ],
            ),
            feature(name = "alwayslink", enabled = ctx.attr.cpu == "local"),
            feature(name = "opt"),
            feature(name = "fastbuild"),
            feature(name = "dbg"),
            feature(name = "supports_dynamic_linker", enabled = True),
            feature(name = "pic", enabled = True),
            feature(name = "supports_pic", enabled = True),
        ]
    elif (ctx.attr.cpu == "x64_windows"):
        features = [
            feature(name = "no_legacy_features"),
            feature(
                name = "common_flags",
                enabled = True,
                env_sets = [
                    env_set(
                        actions = all_compile_actions + all_link_actions + all_archive_actions,
                        env_entries = [
                            env_entry(key = "PATH", value = ctx.attr.msvc_env_path),
                            env_entry(key = "INCLUDE", value = ctx.attr.msvc_env_include),
                            env_entry(key = "LIB", value = ctx.attr.msvc_env_lib),
                            env_entry(key = "TMP", value = ctx.attr.msvc_env_tmp),
                            env_entry(key = "TEMP", value = ctx.attr.msvc_env_tmp),
                        ],
                    ),
                ],
                flag_sets = [
                    flag_set(
                        actions = all_compile_actions + all_link_actions + all_archive_actions,
                        flag_groups = [flag_group(flags = ["/nologo"])],
                    ),
                ],
            ),
            feature(
                name = "default_compile_flags",
                enabled = True,
                flag_sets = [
                    flag_set(
                        actions = all_compile_actions,
                        flag_groups = [
                            flag_group(
                                flags = [
                                    "-B",
                                    "external/local_config_cuda/crosstool/windows/msvc_wrapper_for_nvcc.py",
                                ],
                            ),
                            flag_group(
                                flags = [
                                    "/DCOMPILER_MSVC",
                                    "/DNOMINMAX",
                                    "/D_WIN32_WINNT=0x0600",
                                    "/D_CRT_SECURE_NO_DEPRECATE",
                                    "/D_CRT_SECURE_NO_WARNINGS",
                                    "/D_SILENCE_STDEXT_HASH_DEPRECATION_WARNINGS",
                                    "/bigobj",
                                    "/Zm500",
                                    "/J",
                                    "/Gy",
                                    "/GF",
                                    "/EHsc",
                                    "/wd4351",
                                    "/wd4291",
                                    "/wd4250",
                                    "/wd4996",
                                ],
                            ),
                            flag_group(
                                flags = ["/I%{quote_include_paths}"],
                                iterate_over = "quote_include_paths",
                            ),
                            flag_group(
                                flags = ["/I%{include_paths}"],
                                iterate_over = "include_paths",
                            ),
                            flag_group(
                                flags = ["/I%{system_include_paths}"],
                                iterate_over = "system_include_paths",
                            ),
                            flag_group(
                                flags = ["/D%{preprocessor_defines}"],
                                iterate_over = "preprocessor_defines",
                            ),
                        ],
                    ),
                    flag_set(
                        actions = all_preprocessed_actions,
                        flag_groups = [flag_group(flags = ["/showIncludes"])],
                    ),
                    flag_set(
                        actions = all_compile_actions,
                        flag_groups = [flag_group(flags = ["/MT"])],
                        with_features = [with_feature_set(features = ["static_link_msvcrt_no_debug"])],
                    ),
                    flag_set(
                        actions = all_compile_actions,
                        flag_groups = [flag_group(flags = ["/MD"])],
                        with_features = [with_feature_set(features = ["dynamic_link_msvcrt_no_debug"])],
                    ),
                    flag_set(
                        actions = all_compile_actions,
                        flag_groups = [flag_group(flags = ["/MTd"])],
                        with_features = [with_feature_set(features = ["static_link_msvcrt_debug"])],
                    ),
                    flag_set(
                        actions = all_compile_actions,
                        flag_groups = [flag_group(flags = ["/MDd"])],
                        with_features = [with_feature_set(features = ["dynamic_link_msvcrt_debug"])],
                    ),
                    flag_set(
                        actions = all_compile_actions,
                        flag_groups = [flag_group(flags = ["/Od", "/Z7", "/DDEBUG"])],
                        with_features = [with_feature_set(features = ["dbg"])],
                    ),
                    flag_set(
                        actions = all_compile_actions,
                        flag_groups = [flag_group(flags = ["/Od", "/Z7", "/DDEBUG"])],
                        with_features = [with_feature_set(features = ["fastbuild"])],
                    ),
                    flag_set(
                        actions = all_compile_actions,
                        flag_groups = [flag_group(flags = ["/O2", "/DNDEBUG"])],
                        with_features = [with_feature_set(features = ["opt"])],
                    ),
                    flag_set(
                        actions = all_preprocessed_actions,
                        flag_groups = [
                            flag_group(
                                flags = ["%{user_compile_flags}"],
                                iterate_over = "user_compile_flags",
                                expand_if_available = "user_compile_flags",
                            ),
                        ] + ([
                            flag_group(flags = ctx.attr.host_unfiltered_compile_flags),
                        ] if ctx.attr.host_unfiltered_compile_flags else []),
                    ),
                    flag_set(
                        actions = [ACTION_NAMES.assemble],
                        flag_groups = [
                            flag_group(
                                flag_groups = [
                                    flag_group(
                                        flags = ["/Fo%{output_file}", "/Zi"],
                                        expand_if_not_available = "output_preprocess_file",
                                    ),
                                ],
                                expand_if_available = "output_file",
                                expand_if_not_available = "output_assembly_file",
                            ),
                        ],
                    ),
                    flag_set(
                        actions = all_preprocessed_actions,
                        flag_groups = [
                            flag_group(
                                flag_groups = [
                                    flag_group(
                                        flags = ["/Fo%{output_file}"],
                                        expand_if_not_available = "output_preprocess_file",
                                    ),
                                ],
                                expand_if_available = "output_file",
                                expand_if_not_available = "output_assembly_file",
                            ),
                            flag_group(
                                flag_groups = [
                                    flag_group(
                                        flags = ["/Fa%{output_file}"],
                                        expand_if_available = "output_assembly_file",
                                    ),
                                ],
                                expand_if_available = "output_file",
                            ),
                            flag_group(
                                flag_groups = [
                                    flag_group(
                                        flags = ["/P", "/Fi%{output_file}"],
                                        expand_if_available = "output_preprocess_file",
                                    ),
                                ],
                                expand_if_available = "output_file",
                            ),
                        ],
                    ),
                    flag_set(
                        actions = all_compile_actions,
                        flag_groups = [
                            flag_group(
                                flags = ["/c", "%{source_file}"],
                                expand_if_available = "source_file",
                            ),
                        ],
                    ),
                ],
            ),
            feature(
                name = "default_archive_flags",
                enabled = True,
                flag_sets = [
                    flag_set(
                        actions = all_archive_actions,
                        flag_groups = [
                            flag_group(
                                flags = ["/OUT:%{output_execpath}"],
                                expand_if_available = "output_execpath",
                            ),
                        ],
                    ),
                ],
            ),
            feature(
                name = "default_link_flags",
                enabled = True,
                flag_sets = [
                    flag_set(
                        actions = [
                            ACTION_NAMES.cpp_link_dynamic_library,
                            ACTION_NAMES.cpp_link_nodeps_dynamic_library,
                        ],
                        flag_groups = [flag_group(flags = ["/DLL"])],
                    ),
                    flag_set(
                        actions = all_link_actions,
                        flag_groups = [
                            flag_group(
                                flags = ["%{linkstamp_paths}"],
                                iterate_over = "linkstamp_paths",
                                expand_if_available = "linkstamp_paths",
                            ),
                            flag_group(
                                flags = ["/OUT:%{output_execpath}"],
                                expand_if_available = "output_execpath",
                            ),
                        ],
                    ),
                    flag_set(
                        actions = [
                            ACTION_NAMES.cpp_link_dynamic_library,
                            ACTION_NAMES.cpp_link_nodeps_dynamic_library,
                        ],
                        flag_groups = [
                            flag_group(
                                flags = ["/IMPLIB:%{interface_library_output_path}"],
                                expand_if_available = "interface_library_output_path",
                            ),
                        ],
                    ),
                    flag_set(
                        actions = all_link_actions +
                                  all_archive_actions,
                        flag_groups = [
                            libraries_to_link_group("msvc"),
                        ],
                    ),
                    flag_set(
                        actions = all_link_actions,
                        flag_groups = [
                            flag_group(flags = ["/SUBSYSTEM:CONSOLE"]),
                            flag_group(
                                flags = ["%{user_link_flags}"],
                                iterate_over = "user_link_flags",
                                expand_if_available = "user_link_flags",
                            ),
                            flag_group(flags = ["/MACHINE:X64"]),
                        ],
                    ),
                    flag_set(
                        actions = all_link_actions +
                                  all_archive_actions,
                        flag_groups = [
                            flag_group(
                                flags = ["@%{linker_param_file}"],
                                expand_if_available = "linker_param_file",
                            ),
                        ],
                    ),
                    flag_set(
                        actions = all_link_actions,
                        flag_groups = [flag_group(flags = ["/DEFAULTLIB:libcmt.lib"])],
                        with_features = [with_feature_set(features = ["static_link_msvcrt_no_debug"])],
                    ),
                    flag_set(
                        actions = all_link_actions,
                        flag_groups = [flag_group(flags = ["/DEFAULTLIB:msvcrt.lib"])],
                        with_features = [with_feature_set(features = ["dynamic_link_msvcrt_no_debug"])],
                    ),
                    flag_set(
                        actions = all_link_actions,
                        flag_groups = [flag_group(flags = ["/DEFAULTLIB:libcmtd.lib"])],
                        with_features = [with_feature_set(features = ["static_link_msvcrt_debug"])],
                    ),
                    flag_set(
                        actions = all_link_actions,
                        flag_groups = [flag_group(flags = ["/DEFAULTLIB:msvcrtd.lib"])],
                        with_features = [with_feature_set(features = ["dynamic_link_msvcrt_debug"])],
                    ),
                    flag_set(
                        actions = all_link_actions,
                        flag_groups = [flag_group(flags = ["/DEBUG:FULL", "/INCREMENTAL:NO"])],
                        with_features = [with_feature_set(features = ["dbg"])],
                    ),
                    flag_set(
                        actions = all_link_actions,
                        flag_groups = [
                            flag_group(flags = ["/DEBUG:FASTLINK", "/INCREMENTAL:NO"]),
                        ],
                        with_features = [with_feature_set(features = ["fastbuild"])],
                    ),
                    flag_set(
                        actions = all_link_actions,
                        flag_groups = [
                            flag_group(
                                flags = ["/DEF:%{def_file_path}", "/ignore:4070"],
                                expand_if_available = "def_file_path",
                            ),
                        ],
                    ),
                ],
            ),
            feature(name = "no_stripping", enabled = True),
            feature(
                name = "targets_windows",
                enabled = True,
                implies = ["copy_dynamic_libraries_to_binary"],
            ),
            feature(name = "copy_dynamic_libraries_to_binary"),
            feature(
                name = "generate_pdb_file",
                requires = [
                    feature_set(features = ["dbg"]),
                    feature_set(features = ["fastbuild"]),
                ],
            ),
            feature(name = "static_link_msvcrt"),
            feature(
                name = "static_link_msvcrt_no_debug",
                requires = [
                    feature_set(features = ["fastbuild"]),
                    feature_set(features = ["opt"]),
                ],
            ),
            feature(
                name = "dynamic_link_msvcrt_no_debug",
                requires = [
                    feature_set(features = ["fastbuild"]),
                    feature_set(features = ["opt"]),
                ],
            ),
            feature(
                name = "static_link_msvcrt_debug",
                requires = [feature_set(features = ["dbg"])],
            ),
            feature(
                name = "dynamic_link_msvcrt_debug",
                requires = [feature_set(features = ["dbg"])],
            ),
            feature(
                name = "dbg",
                implies = ["generate_pdb_file"],
            ),
            feature(
                name = "fastbuild",
                implies = ["generate_pdb_file"],
            ),
            feature(
                name = "opt",
            ),
            feature(name = "windows_export_all_symbols"),
            feature(name = "no_windows_export_all_symbols"),
            feature(name = "supports_dynamic_linker", enabled = True),
            feature(
                name = "supports_interface_shared_libraries",
                enabled = True,
            ),
        ]
    else:
        fail("Unreachable")

    if (ctx.attr.cpu == "x64_windows"):
        tool_paths = [
            tool_path(name = "ar", path = ctx.attr.msvc_lib_path),
            tool_path(name = "ml", path = ctx.attr.msvc_ml_path),
            tool_path(name = "cpp", path = ctx.attr.msvc_cl_path),
            tool_path(name = "gcc", path = ctx.attr.msvc_cl_path),
            tool_path(name = "gcov", path = "wrapper/bin/msvc_nop.bat"),
            tool_path(name = "ld", path = ctx.attr.msvc_link_path),
            tool_path(name = "nm", path = "wrapper/bin/msvc_nop.bat"),
            tool_path(
                name = "objcopy",
                path = "wrapper/bin/msvc_nop.bat",
            ),
            tool_path(
                name = "objdump",
                path = "wrapper/bin/msvc_nop.bat",
            ),
            tool_path(
                name = "strip",
                path = "wrapper/bin/msvc_nop.bat",
            ),
        ]
    elif (ctx.attr.cpu == "local" or ctx.attr.cpu == "darwin"):
        tool_paths = [
            tool_path(name = "gcc", path = ctx.attr.host_compiler_path),
            tool_path(name = "ar", path = ctx.attr.host_compiler_prefix + "/ar"),
            tool_path(name = "compat-ld", path = ctx.attr.host_compiler_prefix + "/ld"),
            tool_path(name = "cpp", path = ctx.attr.host_compiler_prefix + "/cpp"),
            tool_path(name = "dwp", path = ctx.attr.host_compiler_prefix + "/dwp"),
            tool_path(name = "gcov", path = ctx.attr.host_compiler_prefix + "/gcov"),
            tool_path(name = "ld", path = ctx.attr.host_compiler_prefix + "/ld"),
            tool_path(name = "nm", path = ctx.attr.host_compiler_prefix + "/nm"),
            tool_path(name = "objcopy", path = ctx.attr.host_compiler_prefix + "/objcopy"),
            tool_path(name = "objdump", path = ctx.attr.host_compiler_prefix + "/objdump"),
            tool_path(name = "strip", path = ctx.attr.host_compiler_prefix + "/strip"),
        ]
    else:
        fail("Unreachable")

    out = ctx.actions.declare_file(ctx.label.name)
    ctx.actions.write(out, "Fake executable")
    return [
        cc_common.create_cc_toolchain_config_info(
            ctx = ctx,
            features = features,
            action_configs = action_configs,
            artifact_name_patterns = [],
            cxx_builtin_include_directories = ctx.attr.builtin_include_directories,
            toolchain_identifier = toolchain_identifier,
            host_system_name = "local",
            target_system_name = "local",
            target_cpu = target_cpu,
            target_libc = target_libc,
            compiler = compiler,
            abi_version = "local",
            abi_libc_version = "local",
            tool_paths = tool_paths,
            make_variables = [],
            builtin_sysroot = ctx.attr.builtin_sysroot,
            cc_target_os = None,
        ),
        DefaultInfo(
            executable = out,
        ),
    ]

cc_toolchain_config = rule(
    implementation = _impl,
    attrs = {
        "cpu": attr.string(mandatory = True, values = ["darwin", "local", "x64_windows"]),
        "builtin_include_directories": attr.string_list(),
        "extra_no_canonical_prefixes_flags": attr.string_list(),
        "host_compiler_path": attr.string(),
        "host_compiler_prefix": attr.string(),
        "host_compiler_warnings": attr.string_list(),
        "host_unfiltered_compile_flags": attr.string_list(),
        "linker_bin_path": attr.string(),
        "builtin_sysroot": attr.string(),
        "cuda_path": attr.string(),
        "msvc_cl_path": attr.string(default = "msvc_not_used"),
        "msvc_env_include": attr.string(default = "msvc_not_used"),
        "msvc_env_lib": attr.string(default = "msvc_not_used"),
        "msvc_env_path": attr.string(default = "msvc_not_used"),
        "msvc_env_tmp": attr.string(default = "msvc_not_used"),
        "msvc_lib_path": attr.string(default = "msvc_not_used"),
        "msvc_link_path": attr.string(default = "msvc_not_used"),
        "msvc_ml_path": attr.string(default = "msvc_not_used"),
        "compiler": attr.string(values = ["clang", "msvc", "unknown"], default = "unknown"),
    },
    provides = [CcToolchainConfigInfo],
    executable = True,
)
