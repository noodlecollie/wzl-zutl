This page assumes a static C library. Other targets should be similar in nature. This example uses the [cJSON library](https://github.com/DaveGamble/cJSON).

## Add The Repo As A Dependency

Firstly, determine the URL to the desired archive of the repository, preferably at a specific tag. This should be a `.tar.gz`. An example URL might be `https://github.com/DaveGamble/cJSON/archive/refs/tags/v1.7.18.tar.gz`

Run `zig fetch <url>`, which will print out the hash for the repo's archive. Use this to add the repo to `build.zig.zon` as follows:

```
.{
    .dependencies = .{
        .cJSON = .{
            .url = "https://github.com/DaveGamble/cJSON/archive/refs/tags/v1.7.18.tar.gz",
            .hash = "1220a3c4dfa93f6cbef20aa0cc177c7debc02ced588520dad4ab5772956ad5da1c73",
        },
    },
}
```

Note that `zig fetch --save` cannot be used here, since this expects the dependent repo to be a Zig repo, and will fail if there is no `build.zig.zon` present in the dependent repo.

Additionally, you can use `@"..." = .{ }` to name the dependency if its name contains disallowed character such as hyphens.

## Write A Build Description File For The Library

You may wish to create a directory for these build files, eg. `cdeps`. For this example, we will create `cdeps/cJSON.zig`. This file will hold a configuration used to build the library.

For `cJSON`, the file looks like this:

```
// Subdirectories under the root within which header files can be found.
pub const include_subdirs = .{
    "",
};

// Source files to be built.
pub const source_files = .{
    "cJSON.c",
    "cJSON_Utils.c",
};

// Compile flags to be applied when building.
pub const compile_flags = .{
    "-std=c89",
    "-pedantic",
    "-Wall",
    "-Wextra",
    "-Werror",
    "-Wstrict-prototypes",
    "-Wwrite-strings",
    "-Wshadow",
    "-Winit-self",
    "-Wcast-align",
    "-Wformat=2",
    "-Wmissing-prototypes",
    "-Wstrict-overflow=2",
    "-Wcast-qual",
    "-Wundef",
    "-Wswitch-default",
    "-Wconversion",
    "-Wc++-compat",
    "-fstack-protector-strong",
    "-Wcomma",
    "-Wdouble-promotion",
    "-Wparentheses",
    "-Wformat-overflow",
    "-Wunused-macros",
    "-Wmissing-variable-declarations",
    "-Wused-but-marked-unused",
    "-Wswitch-enum",
};

```

## Build The Library

Given this configuration, we can build the library as follows:

```
// At the top of build.zig:
const cJSON = @import("./cdeps/cJSON.zig");

// Then later, in the build() function:
const cjson_path = b.dependency("cJSON", .{}).path("");

const cjson_lib = b.addStaticLibrary(.{
	.name = "cJSON",
	.target = target,
	.optimize = optimize,
});

inline for (cJSON.include_subdirs) |subdir| {
	cjson_lib.addIncludePath(cjson_path.path(b, subdir));
}

cjson_lib.addCSourceFiles(.{
	.root = cjson_path,
	.files = &cJSON.source_files,
	.flags = &cJSON.compile_flags,
});

cjson_lib.linkLibC();
```

Then, to add the library to a Zig target, do:

```
inline for (cJSON.include_subdirs) |subdir| {
	my_target.addIncludePath(cjson_path.path(b, subdir));
}

my_target.linkLibrary(cjson_lib);
my_target.linkLibC();
```
