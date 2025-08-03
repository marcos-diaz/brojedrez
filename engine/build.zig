const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "brojedrez",
        .root_module = exe_mod,
    });
    b.installArtifact(exe);


    /////////////////
    // WEBASSEMBLY //
    /////////////////

    const wasm_target = b.resolveTargetQuery(.{
        .cpu_arch = .wasm32,
        .os_tag = .freestanding,
        .cpu_features_add = std.Target.wasm.featureSet(&.{
            .bulk_memory,
            .sign_ext,
            .nontrapping_fptoint,
            .simd128,
        }),
    });

    const wasm_mod = b.createModule(.{
        .root_source_file = b.path("src/wasm.zig"),
        .target = wasm_target,
        .optimize = .ReleaseFast,
    });

    const wasm = b.addExecutable(.{
        .name = "brojedrez",
        .root_module = wasm_mod,
    });
    wasm.rdynamic = true;
    wasm.entry = .disabled;
    wasm.stack_size = 1024 * 1024;
    wasm.initial_memory = 64 * 1024 * 1024;
    wasm.max_memory = 128 * 1024 * 1024;
    wasm.link_z_notext = true;
    wasm.root_module.strip = true;
    wasm.root_module.unwind_tables = .none;
    wasm.root_module.omit_frame_pointer = true;
    b.installArtifact(wasm);


    //////////////////
    // POST-COMPILE //
    //////////////////

    const post = b.step("post-compile", "Run post-build shell command");
    post.dependOn(&wasm.step);
    post.makeFn = struct {
        pub fn make(_: *std.Build.Step, _: std.Build.Step.MakeOptions) !void {
            const allocator = std.heap.page_allocator;
            var child = std.process.Child.init(
                &[_][]const u8{
                    "sh",
                    "-c",
                    "cp zig-out/bin/brojedrez.wasm ../gui/public/brojedrez.wasm",
                },
                allocator,
            );
            child.stdout_behavior = .Pipe;
            child.stderr_behavior = .Inherit;
            child.stdin_behavior = .Inherit;
            try child.spawn();
            const stdout = try child.stdout.?.reader().readAllAlloc(allocator, 1024);
            try std.io.getStdOut().writer().writeAll(stdout);
            const term = try child.wait();
            if (term != .Exited or term.Exited != 0) {
                return error.UnexpectedExitCode;
            }
        }
    }.make;
    b.getInstallStep().dependOn(post);


    /////////
    // RUN //
    /////////

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addRunArtifact(exe);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);


    //////////
    // TEST //
    //////////

    const exe_unit_tests = b.addTest(.{
        .root_module = exe_mod,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
