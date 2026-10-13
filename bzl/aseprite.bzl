load("@bazel_skylib//lib:paths.bzl", "paths")

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
    doc = "generate a 1-frame preview for each of the given Aseprite files",
    implementation = _ase_generate_previews_impl,
    attrs = {
        "_aseprite": attr.label(
            default = "@host//:aseprite",
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

def _ase_export_impl(ctx):
    # type: (ctx) -> DefaultInfo

    out_file = ctx.actions.declare_file(
        paths.replace_extension(paths.basename(ctx.file.src.path), ".png"),
    )

    args = ["--batch", ctx.file.src.path]
    if ctx.attr.slice:
        args.append("--slice={}".format(ctx.attr.slice))
    if ctx.attr.frame_range:
        if len(ctx.attr.frame_range) != 2:
            fail("ase_export: frame_range accepts 2 integers, got {}".format(
                ctx.attr.frame_range,
            ))
        args.append("--frame-range={},{}".format(
            ctx.attr.frame_range[0],
            ctx.attr.frame_range[1],
        ))
    args.append("--save-as={}".format(out_file.path))

    ctx.actions.run(
        outputs = [out_file],
        inputs = [ctx.file.src],
        executable = ctx.executable._aseprite,
        arguments = args,
    )

    return DefaultInfo(files = depset([out_file]))

ase_export = rule(
    doc = "export Aseprite files to PNG",
    implementation = _ase_export_impl,
    attrs = {
        "_aseprite": attr.label(
            default = "@host//:aseprite",
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
        "src": attr.label(
            doc = "Aseprite file to export",
            mandatory = True,
            allow_single_file = True,
        ),
        "slice": attr.string(
            doc = "crop the sprite to the given slice area",
        ),
        "frame_range": attr.int_list(
            doc = "only export frames in the [from,to] range",
        ),
    },
)
