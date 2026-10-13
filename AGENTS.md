# nixos-setup — agent notes

## Scope

This file exists only for the Hyprland + Quickshell migration. It is not a
general guideline set for this repository — none has been designed yet.
Treat everything below as migration-scoped instructions, not repo-wide
policy. Once the repository has real guidelines, review this file against
them and fold or delete it accordingly.

NixOS flake for machines Taihou (main laptop), TaihouLite (ISO), Hearts.
User: retblast. Shell: fish. Desktop: Hyprland + Quickshell (GNOME removed on
Taihou; see docs/ for the migration).

## Session protocol

- Before any work, read `docs/MIGRATION_STATUS.md` and
  `docs/HYPRLAND_QUICKSHELL_MIGRATION.md`. The status file is the source of
  truth for progress, decisions, and journal.
- After any real work, update `docs/MIGRATION_STATUS.md`: batch status, a
  journal entry, decisions taken, next actions.
- Follow the verification gates in the runbook before marking a batch done.
- Do not change `machines/Hearts` or `machines/TaihouLite` as part of the
  desktop migration. `modules/gnome.nix` must stay (they still use it).
- The tree is often mid flake-update. Check `git status` and the flake.lock
  state before attributing build failures to recent changes.
- Do not update the flake unless asked. Do not commit unrelated files.

## Conventions

- NixOS modules live in `modules/` with `localModule.*` options. Follow the
  pattern of `modules/gnome.nix` / `modules/hyprland.nix`.
- Home-manager modules live in `users/retblast/hm/` and branch on machine
  config via the `taihouConfig` specialArg.
- Runtime-mutated configs (btop, easyeffects, htop, ...) go through
  `users/retblast/hm/to-symlink/` with `mkOutOfStoreSymlink` (see
  `workarounds.nix`).
- Package pins and local derivations live in `overlay/`.
- Shell theming (fonts, sizes, colors) has one source of truth:
  `users/retblast/hm/shell-theme.nix` (HM option `retTheme`). Do not
  hardcode theme values elsewhere.
