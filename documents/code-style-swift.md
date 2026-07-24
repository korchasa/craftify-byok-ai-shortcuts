# Swift Code Style

Conventions enforced by `.swiftlint.yml` / `.swiftformat` that are easy to trip on.

- **One declaration per file** (swiftlint `one_declaration_per_file`): a second
  top-level type in a file is a hard error. Nest helper types (e.g. a
  `PreferenceKey`) inside the file's primary type, or extract them into their own
  file — as `ContentHeightKey.swift` does.
