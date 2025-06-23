# Migration Guide: Theme Colors & Button Components (2024)

This guide documents the migration of the White Noise Flutter app to a new color system and button component architecture. It is intended for all contributors and maintainers.

---

## 1. Color System Migration

### **Background**

Previously, the app used static color constants via `AppColors` (e.g., `AppColors.glitch950`, `AppColors.white`). This approach did not support theming or dynamic color changes, and made it difficult to maintain a consistent design system.

### **New Approach: `context.colors`**

We now use a theme extension (`AppColorsThemeExt`) and a `context.colors` extension to access all app colors. This enables:

- **Dynamic theming** (light/dark mode, future custom themes)
- **Consistent color usage** across the app
- **Easier maintenance** and updates

#### **How to Use**

**Old:**
```dart
Container(
  color: AppColors.glitch950,
)
Text(
  'Hello',
  style: TextStyle(color: AppColors.glitch600),
)
```

**New:**
```dart
import 'package:whitenoise/ui/core/themes/src/extensions.dart';

Container(
  color: context.colors.primary,
)
Text(
  'Hello',
  style: TextStyle(color: context.colors.mutedForeground),
)
```

#### **Mapping Table**

| Old `AppColors`         | New `context.colors` property      |
|-------------------------|------------------------------------|
| glitch950               | primary                            |
| glitch900               | secondaryForeground                |
| glitch800, glitch700    | neutralVariant                     |
| glitch600               | mutedForeground                    |
| glitch500               | mutedForeground (or closest match) |
| glitch400               | baseMuted                          |
| glitch300               | textDefaultSecondary               |
| glitch200, glitch80     | baseMuted                          |
| glitch100               | secondary                          |
| glitch50                | primaryForeground                  |
| white                   | neutral                            |
| colorDC2626             | destructive                        |
| colorEA580C             | warning                            |

- For alpha/opacity, use `.withValues(alpha:)` (e.g., `context.colors.primary.withValues(alpha:0.1)`).

#### **Best Practices**

- Always import the extension:  
  `import 'package:whitenoise/ui/core/themes/src/extensions.dart';`
- Never use `AppColors` directly in UI code.
- For custom widgets, pass `BuildContext` if you need theme colors.

---

## 2. Button Component Migration

### **Background**

The app previously used multiple button components, including `AppFilledButton`, `CustomFilledButton`, and direct `ElevatedButton` usage. This led to inconsistent button styles and duplicated logic.

### **New Approach: `AppFilledButton` (from `app_button.dart`)**

All primary, secondary, and tertiary buttons should use `AppFilledButton` (or its variants) from `app_button.dart`. This ensures:

- **Consistent button styles** across the app
- **Centralized logic** for theming, loading, and states
- **Easier future updates**

#### **How to Use**

**Old:**
```dart
CustomFilledButton(
  title: 'Continue',
  onPressed: _onContinue,
)
```

**New:**
```dart
import 'package:whitenoise/ui/core/ui/app_button.dart';

AppFilledButton(
  title: 'Continue',
  onPressed: _onContinue,
)
```

#### **Button Variants**

- **Primary (default):**
  ```dart
  AppFilledButton(
    title: 'Send',
    onPressed: _send,
  )
  ```
- **Secondary:**
  ```dart
  AppFilledButton(
    title: 'Cancel',
    onPressed: _cancel,
    visualState: AppButtonVisualState.secondary,
  )
  ```
- **Tertiary:**
  ```dart
  AppFilledButton(
    title: 'Remove',
    onPressed: _remove,
    visualState: AppButtonVisualState.tertiary,
  )
  ```
- **With Icon:**
  ```dart
  AppFilledButton.icon(
    icon: Icon(Icons.copy),
    label: Text('Copy'),
    onPressed: _copy,
    visualState: AppButtonVisualState.secondary,
  )
  ```
- **Custom Child:**
  ```dart
  AppFilledButton.child(
    child: Row(
      children: [Icon(Icons.add), Text('Add')],
    ),
    onPressed: _add,
  )
  ```

#### **Padding**

- `AppFilledButton` does **not** add extra padding by default.
- If you need spacing (e.g., bottom navigation, dialog actions), wrap the button in a `Padding` widget:
  ```dart
  Padding(
    padding: EdgeInsets.symmetric(horizontal: 16.w).copyWith(bottom: 32.h),
    child: AppFilledButton(
      title: 'Continue',
      onPressed: _onContinue,
    ),
  )
  ```

#### **Best Practices**

- Always import:  
  `import 'package:whitenoise/ui/core/ui/app_button.dart';`
- Do **not** import or use `custom_filled_button.dart` or `app_filled_button.dart` directly.
- Use the correct `visualState` for secondary/tertiary/destructive actions.
- For icon+label, use `AppFilledButton.icon` or `AppFilledButton.child` as appropriate.

---

## 3. Migration Steps

1. **Replace all `AppColors` usages** with `context.colors` (see mapping above).
2. **Replace all `CustomFilledButton` and direct `ElevatedButton` usages** with `AppFilledButton` or its variants.
3. **Remove all imports** of `custom_filled_button.dart` and `app_filled_button.dart` from UI code.
4. **Add imports** for `app_button.dart` and `themes/src/extensions.dart` as needed.
5. **Wrap buttons in `Padding`** only where extra spacing is required by the design.

---

## 4. Example Diff

**Before:**
```dart
import 'package:whitenoise/ui/core/themes/colors.dart';
import 'package:whitenoise/ui/core/ui/custom_filled_button.dart';

Container(
  color: AppColors.glitch950,
  child: CustomFilledButton(
    title: 'Continue',
    onPressed: _onContinue,
  ),
)
```

**After:**
```dart
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/app_button.dart';

Container(
  color: context.colors.primary,
  child: AppFilledButton(
    title: 'Continue',
    onPressed: _onContinue,
  ),
)
```

---

## 5. FAQ

**Q: What if I need a custom color or button style?**  
A: Extend the theme or button system, do not use hardcoded colors or custom button widgets.

**Q: How do I migrate a button with both an icon and a label?**  
A: Use `AppFilledButton.icon` or `AppFilledButton.child`.

**Q: Can I still use `AppColors` or `CustomFilledButton`?**  
A: No. All usages should be migrated for consistency and maintainability.

---

## 6. References

- [Flutter Theming Documentation](https://docs.flutter.dev/cookbook/design/themes)

---

**For questions or help with migration, contact the maintainers or open an issue.** 