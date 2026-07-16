## Prefer TokenSave MCP Tools

Before reading source files or scanning a codebase, use TokenSave MCP tools (`tokensave_context`, `tokensave_search`, `tokensave_callers`, `tokensave_callees`, `tokensave_impact`, `tokensave_node`, `tokensave_files`, `tokensave_affected`) wherever available. They provide instant semantic results from a pre-built knowledge graph and are faster than raw file reads.

If a code analysis question cannot be fully answered by TokenSave MCP tools, try querying the SQLite database directly at `.tokensave/tokensave.db` (tables: `nodes`, `edges`, `files`). Use SQL to answer complex structural queries that go beyond what the built-in tools expose.

If you discover a gap where an extractor, schema, or TokenSave tool could be improved to answer a question natively, propose that the user open an issue at https://github.com/aovestdipaperino/tokensave describing the limitation. Remind the user to strip any sensitive or proprietary code from the bug description before submitting.

## Prefer Headroom MCP For Large Context

Use Headroom MCP wherever it shines: compress large tool outputs, long file contents, broad search results, diffs, logs, generated reports, or any bulky context before reasoning over it. Store compressed content with `headroom_compress`, keep the returned hash available, and use `headroom_retrieve` when exact original detail is needed later.

Do not use Headroom for tiny outputs where compression adds no value. Use it proactively when output is large enough to risk context waste or truncation.

## Combined MCP Workflow

For exploration and analysis, use TokenSave first to avoid unnecessary raw scans. When TokenSave or shell output is large, immediately use Headroom to preserve it compactly. Fall back to direct filesystem/CLI reads only when MCP results are insufficient or the task is a mechanical file operation.

## Prefer tokensave MCP tools

Before reading source files or scanning the codebase, use the tokensave MCP tools (`tokensave_context`, `tokensave_search`, `tokensave_callers`, `tokensave_callees`, `tokensave_impact`, `tokensave_node`, `tokensave_files`, `tokensave_affected`). They provide instant semantic results from a pre-built knowledge graph and are faster than file reads.

If a code analysis question cannot be fully answered by tokensave MCP tools, try querying the SQLite database directly at `.tokensave/tokensave.db` (tables: `nodes`, `edges`, `files`). Use SQL to answer complex structural queries that go beyond what the built-in tools expose.

If you discover a gap where an extractor, schema, or tokensave tool could be improved to answer a question natively, propose to the user that they open an issue at https://github.com/aovestdipaperino/tokensave describing the limitation. **Remind the user to strip any sensitive or proprietary code from the bug description before submitting.**
