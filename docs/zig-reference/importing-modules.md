## Exporting A Module

Assuming your dependency is located at `https://github.com/yourname/my-dep.git`, create a module in the `build.zig` file as follows:

```
b.addModule("my-module", .{ ... });
```

This will create a module named `my-module`. This is the name that other projects will refer to the module by.

## Importing The Module

### Fetch Dependency
Firstly, add the exporting project as a dependency of the importing project by calling `zig fetch --save <url>` in the importing project. This will add the dependency it to `build.zig.zon`.

The `<url>` should be a link to a `.tar.gz` for a particular commit or tag. For example: `https://github.com/yourname/my-dep/archive/42724050804f77e4fd273ba193434fa421ec3b89.tar.gz`

### Get Dependency Pointer
Next, in the `build.zig` for the importing project, get the dependency by calling `const mydep = b.dependency("my-dep", .{})`.

The name passed as the first argument is, technically speaking, whatever the dependency is called in `build.zig.zon`, but `zig fetch --save` should save it based on the name of the Git repository in the URL you provided.

`mydep` will now refer to the Zig code object representing your imported dependency.

### Get Module Pointer

To obtain a pointer to the module within the dependency, call `const mymodule = mydep.module("my-module")`.

The argument to `module()` should be the name of the module in the original `b.addModule()` call in the exporting project's `build.zig`.

`mymodule` will now refer to the Zig code object representing the module for you to import. However, there is one final step before it can be used.

### Add Import
Finally, call `addImport()` on the root module of your Zig target to allow the target's module to access the imported module:

```
mytarget.root_module.addImport("my-module", mymodule);
```

The first argument is the name that will be used to refer to the module in an `@import()` statement, and the second argument is the module itself from the dependency. For simplicity, it's recommended to provide the same name as the exported module.
