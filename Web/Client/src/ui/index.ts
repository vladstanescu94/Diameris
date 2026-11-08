/**
 * Design system barrel — import primitives from `../ui`, never from the files directly,
 * so the surface stays reviewable in one place.
 *
 * Contract for every primitive here (DECISIONS.md R2): it takes **pre-formatted strings**
 * and **pre-computed integers**. If you find yourself wanting a primitive that computes a
 * number, the number belongs in an API response — ask Backend.
 */

import './ui.css'

export {
  AmountField,
  AppColumn,
  Badge,
  ColorGrid,
  Divider,
  GlassCard,
  IconGrid,
  ListRow,
  Menu,
  PillButton,
  ProgressBar,
  ProgressRing,
  SectionHeader,
  SegmentedControl,
  Sheet,
  Slider,
  Surface,
  TabAccessory,
  TabBar,
  TextField,
  Toggle,
} from './primitives'

export type {
  AmountFieldProps,
  BadgeProps,
  ColorGridProps,
  GlassCardProps,
  IconGridProps,
  ListRowProps,
  MenuOption,
  MenuProps,
  PillButtonProps,
  ProgressBarProps,
  ProgressRingProps,
  SectionHeaderProps,
  Segment,
  SegmentedControlProps,
  SheetProps,
  SliderProps,
  SurfaceProps,
  TabAccessoryProps,
  TabBarProps,
  TabItem,
  TextFieldProps,
  ToggleProps,
} from './primitives'

export { ThemeProvider, THEME_PREFERENCES, useTheme, useThemeToggle } from './theme'
export type { ThemePreference, ThemeContextValue } from './theme'
