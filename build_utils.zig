//! A file containing useful build utility functions.
//! Recommended way to use this:
//! 1. Add the `wzl-zutl` repository as a dependency using `zig fetch`.
//! 2. Add `build_utils.zig` to your gitignore file.
//! 3. In your `build()` function, get the path to this file:
//!      `const build_utils_path = b.dependency("wzl-zutl", .{}).path("build_utils.zig");`
//! 4. Copy the file to your repository by calling:
//!      `std.fs.copyFileAbsolute(build_utils_path.getPath(b), b.path("build_utils.zig").getPath(b), .{}) catch @panic("Failed to fetch build_utils.zig");`
//! 5. Import the file using `@import()`. We have to do all the above because `@import()`
//!    requires that the path to the file is compile-time known.
//!      `@import("./build_utils.zig")`

const std = @import("std");

pub const CDep = struct {
    /// Struct representing a compilation target comprised of C code.
    pub const CompileTarget = struct {
        /// Root directory of the dependency's repo.
        root: std.Build.LazyPath,

        /// Directories that users of the artifact should
        /// look in for header files.
        include_subdirs: []const []const u8,

        /// Target within the build system.
        target: *std.Build.Step.Compile,

        // Given an existing target created using eg. `addStaticLibrary()`,
        // and a build configuration, adds the relevant C source files to
        // and include paths to the target.
        pub fn init(b: *std.Build, existing_target: *std.Build.Step.Compile, config: anytype) CompileTarget {
            const concrete_config = Config.init(config);

            const c_target: CompileTarget = .{
                .root = b.dependency(concrete_config.dependency_name, .{}).path(""),
                .include_subdirs = concrete_config.include_subdirs,
                .target = existing_target,
            };

            inline for (c_target.include_subdirs) |subdir| {
                c_target.target.addIncludePath(c_target.root.path(b, subdir));
            }

            const source_root = c_target.root.path(b, if (concrete_config.source_root) concrete_config.source_root else "");

            c_target.addCSourceFiles(.{
                .root = source_root,
                .files = &concrete_config.source_files,
                .flags = &concrete_config.compile_flags,
            });

            c_target.linkLibC();

            return c_target;
        }

        // Given a `CompileTarget` initialised earlier, sets up `other` to link against it.
        pub fn link(this: CompileTarget, b: *std.Build, other: *std.Build.Step.Compile) void {
            inline for (this.include_subdirs) |subdir| {
                other.addIncludePath(this.root.path(b, subdir));
            }

            other.linkLibrary(this);
            other.linkLibC();
        }
    };

    // Internal:
    const Config = struct {
        dependency_name: []const u8,
        include_subdirs: []const []const u8,
        source_root: ?[]const []const u8,
        source_files: []const []const u8,
        compile_flags: []const []const u8,

        // The config is intended to be the result of @import("...)".
        // We need to check that it exposes the properties that we need.
        pub fn init(config: anytype) Config {
            return .{
                .dependency_name = checkFieldType(config, "dependency_name", []const u8),
                .include_subdirs = checkFieldType(config, "include_subdirs", []const []const u8),
                .source_root = checkFieldType(config, "source_files", ?[]const []const u8),
                .source_files = checkFieldType(config, "source_files", []const []const u8),
                .compile_flags = checkFieldType(config, "compile_flags", []const []const u8),
            };
        }

        fn checkFieldType(config: anytype, comptime field_name: []const u8, comptime T: type) T {
            const field = @field(config, field_name);
            const field_type = @TypeOf(field);

            comptime {
                if (field_type != T) {
                    @panic("Expected type " ++ @typeName(config) ++ " to contain field " ++ field_name ++
                        " of type " ++ @typeName(T) ++ ", but it was of type " ++ @typeName(field_type));
                }
            }

            return field;
        }
    };
};

/// Finds a module from a dependency, and imports it into the provided local module.
/// `b` is the current Zig build object.
/// `dep_name` specifies the name of the dependency (as per `build.zig.zon`).
/// `module_name` specifies the name of the module to import from within the dependency.
/// `importer` is the existing module which will import this external module.
pub fn addModuleImport(
    b: *std.Build,
    dep_name: []const u8,
    module_name: []const u8,
    importer: *std.Build.Module,
) void {
    importer.addImport(module_name, b.dependency(dep_name, .{}).module(module_name));
}
