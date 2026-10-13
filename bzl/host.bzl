def _host_impl(repository_ctx):
    # type: (repository_ctx) -> None

    for program_name in repository_ctx.attr.programs:
        program_path = repository_ctx.which(program_name)
        if program_path == None:
            fail("cannot find '{}' on PATH".format(program_name))
        repository_ctx.watch(program_path)
        repository_ctx.symlink(program_path, program_name)

    repository_ctx.file("BUILD.bazel", content = """\
exports_files(glob(["**"]))
""")

host = repository_rule(
    implementation = _host_impl,
    attrs = {
        "programs": attr.string_list(
            doc = "list of programs to find on host",
        ),
    },
)
