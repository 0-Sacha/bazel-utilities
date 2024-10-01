"""
Utils rules
"""

# https://stackoverflow.com/questions/48545575/how-to-get-workspace-directory-in-bazel-rule
# Only work on linux for now
def _impl_workspace_dir(ctx):
    workspace_file = ctx.files.workspace_file[0]
    gen_workspace_txt = ctx.actions.declare_file("workspace.txt")
    ctx.actions.run_shell(
        inputs = ctx.files.workspace_file,
        outputs = [gen_workspace_txt],
        command = """
          full_path="$(realpath "{src_full}")"
          echo "${{full_path%/{src_short}}}" >> {out_full}
        """.format(
            src_full = workspace_file.path,
            src_short = workspace_file.short_path,
            out_full = gen_workspace_txt.path
        ),
        execution_requirements = {
            "no-sandbox": "1",
            "no-remote": "1",
            "local": "1",
        },
    )
    return [DefaultInfo(files = depset([gen_workspace_txt]))]

workspace_dir = rule(
    implementation = _impl_workspace_dir,
    attrs = {
        "workspace_file": attr.label(allow_single_file = True, mandatory = True),
    },
    doc = "Writes the full path of the current workspace dir to a file.",
)
