/**
 * SF Symbol → Lucide mapping.
 *
 * SF Symbols cannot be redistributed (DECISIONS.md D3), so every glyph the iOS app uses
 * is mapped to a Lucide icon here — one entry per SF name, keyed by the SF name, so the
 * whole table is reviewable in one place.
 *
 * Coverage: every symbol named in `Web/Docs/GROUND-TRUTH.md`, plus the full inventory in
 * `Web/Docs/DESIGN-TOKENS.md` §9 (data-driven symbols, per-screen chrome, the 37-glyph
 * `IconPicker` set and the 12-glyph category set).
 *
 * Lucide is stroke-only and has no filled variants, so SF `.fill` and non-`.fill`
 * spellings collapse onto the same Lucide icon. Both spellings are kept as separate
 * entries so call sites stay literal about which SF symbol they are porting.
 */

import { createElement, type ComponentType, type CSSProperties, type SVGProps } from 'react'
import {
  ArrowLeftRight,
  Banknote,
  Bandage,
  Bell,
  Bike,
  Book,
  Bookmark,
  Briefcase,
  Building2,
  Bus,
  Calendar,
  CalendarClock,
  CalendarPlus,
  Car,
  ChartPie,
  Check,
  ChevronDown,
  ChevronLeft,
  ChevronRight,
  ChevronUp,
  ChevronsUpDown,
  CircleArrowRight,
  CircleCheck,
  CircleDollarSign,
  CircleEllipsis,
  CircleHelp,
  CirclePlus,
  CircleUser,
  CircleX,
  Clock,
  Coffee,
  CreditCard,
  Download,
  Droplet,
  Dumbbell,
  FileChartColumn,
  Film,
  Flag,
  FoldVertical,
  Folder,
  FolderCog,
  Fuel,
  Gamepad2,
  Gift,
  GraduationCap,
  Hammer,
  Heart,
  House,
  Info,
  Landmark,
  Leaf,
  Lightbulb,
  List,
  ClipboardList,
  Music,
  Paintbrush,
  PawPrint,
  Pencil,
  Phone,
  Pill,
  Plane,
  Plus,
  RefreshCw,
  Repeat,
  Search,
  Settings,
  Shield,
  Shirt,
  ShoppingCart,
  Sparkles,
  Star,
  Tag,
  Target,
  TrainFront,
  Trash2,
  TrendingUp,
  TriangleAlert,
  Tv,
  UnfoldVertical,
  User,
  Users,
  UtensilsCrossed,
  Wifi,
  Wrench,
  Zap,
} from 'lucide-react'

export type IconComponent = ComponentType<SVGProps<SVGSVGElement>>

/**
 * The mapping table. Key = SF Symbol name exactly as it appears in the Swift source.
 *
 * Entries marked ⚠️ are judgement calls where Lucide has no close analogue — see the
 * scaffold report to `main`.
 */
export const SF_TO_LUCIDE = {
  /* --- Domain-driven (DESIGN-TOKENS §9.1) ---------------------------- */
  'building.columns.fill': Landmark, // AccountType.primary — bank
  'shield.fill': Shield, // AccountType.emergency
  'banknote.fill': Banknote, // AccountType.savings
  'person.fill': User, // AccountType.personal
  'person.2.fill': Users, // AccountType.joint
  'creditcard.fill': CreditCard, // AccountType.other
  calendar: Calendar, // Frequency.monthly
  'calendar.badge.clock': CalendarClock, // Frequency.annual
  'car.fill': Car, // Category.autoTransport
  car: Car,
  'repeat.circle.fill': Repeat, // Category.subscriptions
  'arrow.triangle.2.circlepath': RefreshCw, // Subscriptions (Expenses screen) / New Month step 2
  sparkles: Sparkles, // Category.lifestyle + Welcome hero
  'house.fill': House, // Category.housing
  house: House,
  'pawprint.fill': PawPrint, // Category.pets
  'heart.fill': Heart, // Category.healthFitness
  'cart.fill': ShoppingCart, // Category.foodGroceries
  cart: ShoppingCart,
  'tv.fill': Tv, // Category.entertainment
  'fuelpump.fill': Fuel, // onboarding "Gas"
  'questionmark.circle.fill': CircleHelp, // Uncategorized fallback

  /* --- Tabs, toolbars, chrome (DESIGN-TOKENS §9.2) -------------------- */
  'chart.pie.fill': ChartPie, // Dashboard tab + SummaryCard + ExpenseBreakdownCard
  'list.bullet.rectangle': List, // ⚠️ Expenses tab + empty state
  'lightbulb.max': Lightbulb, // ⚠️ Insights tab (Lucide has no "max"/rays variant)
  'lightbulb.fill': Lightbulb, // TransferPlan tip
  'calendar.badge.plus': CalendarPlus, // New Month accessory
  gearshape: Settings, // Dashboard toolbar — Settings
  gear: Settings, // GROUND-TRUTH names this as `gear`
  'hammer.fill': Hammer, // Dashboard toolbar — Developer Tools (DEBUG)
  hammer: Hammer,
  'chart.bar.doc.horizontal': FileChartColumn, // ⚠️ Dashboard empty state
  target: Target, // Welcome value bullet
  scope: Target, // ⚠️ GROUND-TRUTH names the same bullet `scope`
  'arrow.left.arrow.right': ArrowLeftRight, // Welcome value bullet
  'chart.line.uptrend.xyaxis': TrendingUp, // Welcome value bullet
  'person.circle.fill': CircleUser, // NameScreen header
  'plus.circle.fill': CirclePlus, // Add Another Account
  'plus.circle': CirclePlus, // New Category… row
  plus: Plus, // Add Expense / Add Account
  'info.circle': Info, // helper footnotes
  'chevron.down': ChevronDown,
  'chevron.up': ChevronUp,
  'chevron.left': ChevronLeft, // New Month back
  'chevron.right': ChevronRight, // disclosure
  'chevron.up.chevron.down': ChevronsUpDown, // menu affordance
  'xmark.circle.fill': CircleX, // remove account
  'star.fill': Star, // set primary savings
  'checkmark.circle.fill': CircleCheck,
  checkmark: Check,
  'arrow.right.circle.fill': CircleArrowRight, // expense transfer / impact
  'exclamationmark.triangle.fill': TriangleAlert,
  'exclamationmark.triangle': TriangleAlert,
  'bolt.fill': Zap, // Savings Boost
  'dollarsign.circle.fill': CircleDollarSign, // New Month step 1
  'list.clipboard.fill': ClipboardList, // New Month step 3
  magnifyingglass: Search, // `.searchable` field on the Expenses tab
  'ellipsis.circle': CircleEllipsis, // Expenses overflow menu
  'rectangle.expand.vertical': UnfoldVertical, // expand all
  'rectangle.compress.vertical': FoldVertical, // collapse all
  'folder.badge.gearshape': FolderCog, // manage categories
  pencil: Pencil, // edit expense
  trash: Trash2, // delete
  'square.and.arrow.down': Download, // DevDebugView import

  /* --- IconPicker set (DESIGN-TOKENS §9.3) ---------------------------- */
  'fork.knife': UtensilsCrossed,
  'cup.and.saucer.fill': Coffee,
  'tshirt.fill': Shirt,
  'gamecontroller.fill': Gamepad2,
  'music.note': Music,
  'film.fill': Film,
  airplane: Plane,
  'gift.fill': Gift,
  'phone.fill': Phone,
  wifi: Wifi,
  'drop.fill': Droplet,
  'leaf.fill': Leaf,
  'wrench.fill': Wrench,
  'paintbrush.fill': Paintbrush,
  'bandage.fill': Bandage,
  'pills.fill': Pill,
  'dumbbell.fill': Dumbbell,
  bicycle: Bike,
  'bus.fill': Bus,
  'train.side.front.car': TrainFront,
  'book.fill': Book,
  'graduationcap.fill': GraduationCap,
  'briefcase.fill': Briefcase,
  'building.2.fill': Building2,

  /* --- Category icon set (DESIGN-TOKENS §9.4) ------------------------- */
  'tag.fill': Tag,
  'bookmark.fill': Bookmark,
  'flag.fill': Flag,
  'bell.fill': Bell,
  'clock.fill': Clock,
  'folder.fill': Folder,
} as const satisfies Record<string, IconComponent>

export type SFSymbolName = keyof typeof SF_TO_LUCIDE

/**
 * ⚠️ REFERENCE ONLY — do NOT render from this list.
 *
 * DECISIONS.md **R12** makes it binding: all three palettes are server-served and never
 * hardcoded — `reference.expenseIcons` (37), `reference.categoryIcons` (12) and
 * `reference.categoryColors` (10). This array exists only so the mapping table's coverage
 * is verifiable, and as an offline fallback.
 *
 * COUNT CONFLICT — **resolved: 37 is correct.** `GROUND-TRUTH.md` and API-CONTRACT §2.7
 * both said 18, counted from a clipped screenshot whose last visible glyph happened to be
 * the 18th source entry (`creditcard.fill`), which made the miscount look self-consistent.
 * `AddExpenseSheet.swift:193-231` has 37. Both docs are corrected. The lesson is recorded
 * here because it is the kind of error that repeats: never infer a list length from an image.
 */
export const ICON_PICKER_SYMBOLS: readonly SFSymbolName[] = [
  'dollarsign.circle.fill',
  'cart.fill',
  'house.fill',
  'car.fill',
  'fuelpump.fill',
  'shield.fill',
  'heart.fill',
  'fork.knife',
  'cup.and.saucer.fill',
  'tshirt.fill',
  'pawprint.fill',
  'tv.fill',
  'gamecontroller.fill',
  'music.note',
  'film.fill',
  'airplane',
  'gift.fill',
  'creditcard.fill',
  'phone.fill',
  'wifi',
  'bolt.fill',
  'drop.fill',
  'leaf.fill',
  'wrench.fill',
  'hammer.fill',
  'paintbrush.fill',
  'bandage.fill',
  'pills.fill',
  'dumbbell.fill',
  'bicycle',
  'bus.fill',
  'train.side.front.car',
  'book.fill',
  'graduationcap.fill',
  'briefcase.fill',
  'building.2.fill',
  'sparkles',
]

/**
 * ⚠️ REFERENCE ONLY, same caveat as above.
 * `CategoryManagementView.swift:133-137` — 12 symbols, default selection `star.fill`
 * (the server's `reference.defaultNewCategory.icon` is authoritative).
 */
export const CATEGORY_ICON_SYMBOLS: readonly SFSymbolName[] = [
  'star.fill',
  'heart.fill',
  'bolt.fill',
  'leaf.fill',
  'gift.fill',
  'tag.fill',
  'bookmark.fill',
  'flag.fill',
  'bell.fill',
  'clock.fill',
  'calendar',
  'folder.fill',
]

const warnedUnknown = new Set<string>()

export function iconFor(name: string): IconComponent {
  const icon = (SF_TO_LUCIDE as Record<string, IconComponent | undefined>)[name]
  if (icon) return icon
  if (import.meta.env.DEV && !warnedUnknown.has(name)) {
    warnedUnknown.add(name)
    console.warn(`[icons] no Lucide mapping for SF Symbol ${JSON.stringify(name)}`)
  }
  return CircleHelp
}

export interface SymbolProps {
  /** SF Symbol name, e.g. `"cart.fill"`. */
  name: SFSymbolName | (string & {})
  /**
   * Defaults to `"1em"` so an icon scales with its container's font-size, the way
   * SF Symbols do (iOS sizes them via `.font(.system(size:))`).
   */
  size?: number | string
  /** Defaults to `currentColor`, matching SwiftUI's `.foregroundStyle` inheritance. */
  color?: string
  strokeWidth?: number
  className?: string
  style?: CSSProperties
  /** Omit for decorative icons — they are then hidden from assistive tech. */
  title?: string
}

/** `<Symbol name="cart.fill" />` */
export function Symbol({
  name,
  size = '1em',
  color = 'currentColor',
  strokeWidth,
  className,
  style,
  title,
}: SymbolProps) {
  const Icon = iconFor(name)
  return createElement(Icon, {
    width: size,
    height: size,
    color,
    ...(strokeWidth === undefined ? {} : { strokeWidth }),
    ...(className === undefined ? {} : { className }),
    ...(style === undefined ? {} : { style }),
    ...(title === undefined
      ? { 'aria-hidden': true, focusable: false }
      : { role: 'img', 'aria-label': title }),
  })
}
