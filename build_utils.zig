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
