def _is_windows(ctx):
    return ctx.os.name.startswith("windows")

def _find_system_wasmer_dir(ctx):
    if "WASMER_DIR" in ctx.os.environ:
        if not ctx.os.environ["WASMER_DIR"]:
            fail("WASMER_DIR environment variable is set, but is empty")
        return ctx.path(ctx.os.environ["WASMER_DIR"])

    wasmer_bin_in_path = ctx.which("wasmer")
    if wasmer_bin_in_path != None:
        return wasmer_bin_in_path.dirname.dirname

    wasmer_dir = None
    if _is_windows(ctx):
        wasmer_dir = ctx.path(ctx.os.environ["USERPROFILE"] + "\\.wasmer")
    else:
        wasmer_dir = ctx.path(ctx.os.environ["HOME"] + "/.wasmer")

    if not wasmer_dir.exists:
        return None

    return wasmer_dir

def _wasmer_repo_impl(rctx):
    wasmer_dir = _find_system_wasmer_dir(rctx)
    if wasmer_dir == None:
        fail("Cannot find Wasmer installed on your system")

    for subdir in ["bin", "include", "lib"]:
        rctx.symlink(str(wasmer_dir) + "/" + subdir, subdir)

    if _is_windows(rctx):
        rctx.template("BUILD.bazel", rctx.attr._windows_build_file)
    else:
        rctx.template("BUILD.bazel", rctx.attr._unix_build_file)

_wasmer_repo = repository_rule(
    implementation = _wasmer_repo_impl,
    attrs = {
        "wasmer_version": attr.string(),
        "_windows_build_file": attr.label(
            allow_single_file = True,
            default = "@rules_wasmer//wasmer/private/templates:wasmer.windows.BUILD.bazel",
        ),
        "_unix_build_file": attr.label(
            allow_single_file = True,
            default = "@rules_wasmer//wasmer/private/templates:wasmer.unix.BUILD.bazel",
        ),
    },
)

def _wasmer_impl(mctx):
    _wasmer_repo(name = "wasmer")

wasmer = module_extension(
    implementation = _wasmer_impl,
    tag_classes = {
    },
)
