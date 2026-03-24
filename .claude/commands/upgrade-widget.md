Update the widget or file specified in $ARGUMENTS to use current Flutter/Material Design 3 patterns:

1. Read the target widget file(s) first to understand the current implementation
2. Replace deprecated widgets:
   - `FlatButton` → `TextButton`
   - `RaisedButton` → `ElevatedButton` or `FilledButton`
   - `OutlineButton` → `OutlinedButton`
   - `ButtonBar` → `OverflowBar`
   - `Chip` with `deleteIcon` deprecated params → current Chip API
3. Replace deprecated theme access:
   - `Theme.of(context).primaryColor` → `Theme.of(context).colorScheme.primary`
   - `Theme.of(context).accentColor` → `Theme.of(context).colorScheme.secondary`
   - `Theme.of(context).backgroundColor` → `Theme.of(context).colorScheme.surface`
4. Add `const` constructors wherever possible
5. Add semantic labels (tooltip, semanticLabel) for accessibility on interactive widgets
6. Run `flutter analyze` after changes and fix any warnings introduced
7. Report what was changed and confirm zero analysis warnings
