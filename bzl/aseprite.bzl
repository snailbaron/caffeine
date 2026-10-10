load("@bazel_skylib//lib:paths.bzl", "paths")

def _aseprite_impl(repository_ctx):
    # type: (repository_ctx) -> None

    aseprite_path = repository_ctx.which("aseprite")
    if aseprite_path == None:
        fail("cannot find 'aseprite' on PATH")
    repository_ctx.watch(aseprite_path)

    repository_ctx.symlink(aseprite_path, "aseprite")
    repository_ctx.file("BUILD.bazel", content = """\
exports_files(["aseprite"])
""")

aseprite = repository_rule(
    implementation = _aseprite_impl,
)

def _ase_generate_previews_impl(ctx):
    # type: (ctx) -> None

    out_base = "previews"

    out_files = []
    for src in ctx.files.srcs:
        out_path = paths.join(
            out_base,
            paths.replace_extension(paths.basename(src.path), ".png"),
        )
        out_file = ctx.actions.declare_file(out_path)
        out_files.append(out_file)

        ctx.actions.run(
            outputs = [out_file],
            inputs = [src],
            executable = ctx.executable._aseprite,
            arguments = [
                "--batch",
                src.path,
                "--frame-range=0,0",
                "--save-as={}".format(out_file.path),
            ],
        )

    return DefaultInfo(files = depset(out_files))

ase_generate_previews = rule(
    doc = "generate a 1-frame preview for each of the given .ase files",
    implementation = _ase_generate_previews_impl,
    attrs = {
        "_aseprite": attr.label(
            default = "@aseprite",
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
        "srcs": attr.label_list(
            doc = "input Aseprite file",
            mandatory = True,
            allow_files = True,
        ),
    },
)
