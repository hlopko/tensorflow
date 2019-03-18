load(":cc_toolchain_config.bzl", "cc_toolchain_config")

licenses(["notice"])  # Apache 2.0

package(default_visibility = ["//visibility:public"])

cc_toolchain_suite(
    name = "toolchain",
    toolchains = {
        "local|compiler": ":cc-compiler-local",
    },
)

cc_toolchain(
    name = "cc-compiler-local",
    all_files = ":empty",
    compiler_files = ":empty",
    cpu = "local",
    dwp_files = ":empty",
    dynamic_runtime_libs = [":empty"],
    linker_files = ":empty",
    objcopy_files = ":empty",
    static_runtime_libs = [":empty"],
    strip_files = ":empty",
    supports_param_files = 1,
    toolchain_config = ":local",
)

cc_toolchain_config(
    name = "local",
    cpu = "local",
    compiler = "compiler",
)

filegroup(
    name = "empty",
    srcs = [],
)
