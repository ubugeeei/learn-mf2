# Environment setup and your first run

## Nix shell

The development environment is pinned in [`flake.nix`](../flake.nix) to prevent Idris 2 version drift.

```console
$ nix develop
$ idris2 --version
$ make build
$ make test
```

These are the canonical development commands:

| Command | Purpose |
|---|---|
| `make build` | Build the `mf2` executable |
| `make typecheck` | Check every module without code generation |
| `make test` | Build the compiler, then run every test |
| `make docs` | Generate HTML from `|||` documentation comments |
| `make check` | Run the complete release gate, including documentation links and the 250-line file-size budget |
| `nix flake check` | Run the tests in an isolated Nix build |

## CLI

```console
$ ./build/exec/mf2 check '.input {$n :number} .match $n one {{one}} * {{other}}'
valid
$ ./build/exec/mf2 format 'Hello, {$name}!' name=Ada
Hello, Ada!
```

The CLI converts a `name=value` argument to an exact decimal when its value matches the MF2 `number-literal` grammar; otherwise it supplies a string. Application code can construct [`Value`](../src/MF2/Runtime/Types.idr) directly, including typed date, time, unit, and currency values.

## IDE and documentation

Start your language server inside `nix develop` as well. Every public API has an Idris `|||` comment so that the API documentation presents the same design rationale as this handbook.

## Corresponding implementation

- [`flake.nix`](../flake.nix)
- [`Makefile`](../Makefile)
- [`mf2.ipkg`](../mf2.ipkg)
- [`Main`](../src/Main.idr)
- [GitHub Actions](../.github/workflows/ci.yml)
