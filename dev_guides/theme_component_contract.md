# Theme Component Contract

## Baseline

- The base project does not prescribe a visual theme.
- New projects should add `resources/themes/<project>_theme.tres` when visual direction exists.
- Reusable UI components should rely on theme types or theme variations instead of hardcoded styles.

## Suggested Theme Types

| Component | Suggested Theme Type |
|---|---|
| Primary panel | `PanelContainer` or `PrimaryPanel` variation |
| Secondary panel | `SecondaryPanel` variation |
| Primary button | `Button` or `PrimaryButton` variation |
| Danger button | `DangerButton` variation |
| Tooltip panel | `TooltipPanel` variation, especially if using ProperUI tooltip |
| Toast panel | `ToastPanel` variation if using ProperUI toast |

## Test Rule

- Once a project has a theme, add integration tests that load critical UI scenes and assert required theme variations exist.
