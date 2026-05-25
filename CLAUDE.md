# CLAUDE.md — Typst Project Guide

## Project Overview

Typst is a markup-based typesetting system (alternative to LaTeX). This repo contains the compiler, CLI, standard library, and exporters (PDF, SVG, HTML, raster). Built in Rust, the compiler is incremental via `comemo`.

## Build & Run

```bash
cargo build                    # debug build
cargo build --release          # release build
cargo run -- compile input.typ # compile a .typ file to PDF
```

Default workspace member is `crates/typst-cli`.

## Test

```bash
cargo test --workspace         # all tests (unit + integration)
cargo testit                   # alias: integration tests only
cargo testit math              # filter by name pattern (regex)
cargo testit -p tests/suite/math/attach.typ  # by file path
cargo testit --exact math-attach-mixed       # exact test name
cargo testit --stages eval     # run only eval stage (faster)
cargo testit --exact my-test --update        # update reference output
```

Test stages: `eval` -> `paged` (render/pdf/svg) / `html`. Use `--stages eval` for fast iteration on non-visual changes.

## Lint & Format

```bash
cargo fmt --all                # format (90 char width, see rustfmt.toml)
cargo fmt --check --all        # check formatting
cargo clippy --workspace --all-targets  # lint
```

## Docs

```bash
cargo docit compile --format website  # generate docs website
cargo docit compile --format pdf      # generate docs as PDF
```

## Workspace Structure

- `crates/typst` — core compiler (language + library types)
- `crates/typst-cli` — CLI binary
- `crates/typst-eval` — interpreter
- `crates/typst-layout` — layout engine
- `crates/typst-realize` — realization subsystem
- `crates/typst-syntax` — parser and syntax tree
- `crates/typst-library` — standard library (Typst functions/elements)
- `crates/typst-macros` — proc macros
- `crates/typst-pdf` — PDF exporter
- `crates/typst-svg` — SVG exporter
- `crates/typst-html` — HTML exporter
- `crates/typst-render` — raster renderer
- `crates/typst-ide` — IDE support
- `crates/typst-kit` — default implementations for CLI
- `crates/typst-utils` — shared utilities
- `crates/typst-timing` — performance timing
- `crates/typst-bundle` — font/package bundling
- `docs/` — documentation generator (`typst-docs`)
- `tests/` — integration test suite
- `tools/` — dev tooling

Rust edition 2024, MSRV 1.92.

## Key Conventions

### Deterministic Floating-Point Math

Never use `f64::sin`, `f64::cos`, `f64::powi`, `f64::exp`, `f64::ln`, etc. directly. These are clippy-disallowed (see `clippy.toml`). Use:
- `Angle::sin` / `Angle::cos` / etc. for angle-based trig
- `libm::sin` / `libm::cos` / etc. for raw float math
- `Scalar::powi` for integer powers

This ensures cross-platform deterministic output.

### Testing

Test files live in `tests/suite/` as `.typ` files. Each test section: `--- {name} {attrs} ---` followed by Typst code. Test names must be globally unique.

Attributes: `eval`, `paged`, `html`, `pdf`, `pdftags`, `large`, `empty`.

Three test kinds:
1. Assertion tests (`eval`) — use `#test()` or `#assert.eq()`
2. Diagnostic tests — inline `// Error: 2-7 message` annotations
3. Visual/HTML output tests — reference files in `tests/ref/`

Prefer assertion tests over visual reference tests when possible.

### Code Style

- 90 char max width, chain width 70, struct lit width 50
- Use field init shorthand
- Don't merge derives
- No comments explaining WHAT code does; only WHY when non-obvious
- Doc comments on all public Rust types

### PR Guidelines

- Small, self-contained changes
- Discuss significant changes in an issue or Discord `#contributors` first
- Include tests and documentation
- CI must pass before review
- See `CONTRIBUTING.md` for full guidelines

## Release

Only distribute the binary and its SHA256 hash — no source archive, no README/LICENSE in the release package.

```bash
# Build
cargo build --release -p typst-cli

# Local release script (Windows, to GitHub)
bash release.sh
```

The `release.sh` script:
1. Builds `target/release/typst.exe`
2. Computes SHA256 hash
3. Creates a GitHub release with just `typst.exe` + `typst.exe.sha256`

The CI workflow (`.github/workflows/release.yml`) handles multi-platform builds and packages README/LICENSE alongside the binary. For personal releases, only the exe and hash are needed.

## Current Branch State

Version bumped to `0.14.3-beta` across all workspace crates (from `0.14.2`).
