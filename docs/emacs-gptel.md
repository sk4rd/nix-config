# Project conversations in Emacs

Open a file in a project and press `C-c g` to open its gptel conversation in
the right sidebar. Files in the same project reuse the same chat buffer;
each project has its own conversation and attached context. `C-u C-c g`
chooses another project. Outside a project, `C-c g` opens gptel's ordinary
buffer chooser. The chat header shows the project root; use the context
inspector to see which files are attached.

New project chats attach the root `AGENTS.md`, when present, and use the
`design` preset for architecture discussion. Only the read-only `WebSearch`
and `WebFetch` tools are enabled. Source files are attached explicitly:

- `C-c a`: choose a file to attach to the current project's conversation,
  either from a source buffer or from the chat. The current source file is
  offered as the default. A confirmation names the attached file and chat.
- `C-c RET`: send the prompt in the chat.
- `C-u C-c RET`: open gptel's menu to inspect or manage attached context.

The current file and selected region are not automatically copied into the
chat. Attached files are included as context on subsequent requests. Chats
are reused for the current Emacs session; killing a chat buffer starts a
fresh conversation next time.

Reopening a chat preserves its settings and context. Attached files,
including `AGENTS.md`, are read again for subsequent requests, so saved
edits are included without reattaching. To apply new initialization settings,
start a fresh chat.
