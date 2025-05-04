# Fix App Icon visibility

- Identified that the `Contents.json` file was incorrectly placed at `src/MainApp/Resources` instead of inside the `AppIcon.appiconset` directory.
- Moved `Contents.json` into `src/MainApp/Resources/Assets.xcassets/AppIcon.appiconset/` to ensure Xcode recognizes the AppIcon definitions.
- Next: Run `./run check`, rebuild the project, and verify that the app icon displays properly.
