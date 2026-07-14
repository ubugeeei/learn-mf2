# Differences in the CLDR 49 draft

As of 2026-07-14, Version 48.2 is the published stable release and Version 49 is proposed/draft material. This parser and its fixtures are pinned to Version 48.2; draft behavior is never mixed in implicitly.

The draft Version 49 MessageFormat changes include:

- Renaming the technology to “Unicode MessageFormat.”
- Clarifying the priority of syntax and data-model errors.
- Making the Default Bidi Strategy required and default.
- Promoting `:offset` to stable.
- Updating `:datetime`, `:date`, and `:time` around semantic skeletons.
- Adding and reorganizing `:percent` as a draft function.
- Refactoring the explanation of pattern selection.

Version 48.2 already includes some of these function names and bidi algorithms, but their status and detailed requirements change. An identical name does not guarantee an identical specification.

## Upgrade procedure

1. Wait for a final `LDML49` tag.
2. Diff `spec/message.abnf`.
3. Diff error priorities and the status and options of default functions.
4. Add the official fixtures as a separate module and run both suites without deleting Version 48.2 coverage.
5. Type-check whether IR changes remain backward compatible.
6. Update the conformance matrix and every displayed baseline version.

## References

- [CLDR 49 proposed Part 9](https://www.unicode.org/reports/tr35/tr35-79/tr35-messageFormat.html)
- [CLDR 49 modifications](https://www.unicode.org/reports/tr35/tr35-79/tr35-modifications.html#messageformat)
- [CLDR 48.2 modifications](https://www.unicode.org/reports/tr35/tr35-78/tr35-modifications.html)
- [Working Group main](https://github.com/unicode-org/message-format-wg)
