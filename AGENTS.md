# AGENTS.md

This project keeps a single set of guidance for coding agents in
[CLAUDE.md](CLAUDE.md). Read that file.

It covers the pub workspace layout, the package dependency rules that CI
enforces, the route contract used for navigation, dependency injection, and the
coding conventions — deprecated APIs to avoid, and the runtime traps this
codebase has actually hit (Riverpod lifecycle, type inference around
`ref.read`, async guards when moving widget logic into a view model).

This file used to be a byte-for-byte copy of CLAUDE.md. Two copies drifted apart
as soon as either was edited, so the content now lives in one place.
