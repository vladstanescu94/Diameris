/**
 * Design-system primitives — the vocabulary every screen is built from.
 *
 * Three rules bind everything here:
 *  1. **R2 — zero numeric work.** Primitives take PRE-FORMATTED strings (`"1,182 RON"`)
 *     and PRE-COMPUTED integers (`percent: 4`, already truncated by the server). Nothing
 *     in this file rounds, divides or sums; where geometry needs a fraction, it is done in
 *     CSS (`calc()`) or with SVG `pathLength={100}`.
 *  2. **No magic numbers.** Styling lives in `ui.css` and reads only design tokens.
 *  3. **No strings.** Primitives never hardcode user-visible text — labels arrive as props
 *     so the calling screen owns `t()`.
 *
 * Visual source: `Web/Docs/reference-screens/*` + `PARITY-SPEC.md`.
 */

import {
  useId,
  type ChangeEvent,
  type CSSProperties,
  type ReactNode,
} from 'react'
import { Symbol, type SFSymbolName } from '../lib/icons'
import { parseUserInput, type EditingString, type Money } from '../lib/money'

type Sym = SFSymbolName | (string & {})

function cx(...parts: Array<string | false | undefined | null>): string {
  return parts.filter(Boolean).join(' ')
}

/* ================================================================== *
 * Surface
 * ================================================================== */

export interface SurfaceProps {
  /**
   * `canvas` = ScrollView screens (Dashboard, Expenses, onboarding, New Month):
   * white in light, pure black in dark.
   * `grouped` = Form/List screens (Settings, sheets): grey in light, black in dark,
   * with cards lifting to white/#1C1C1E. PARITY-SPEC §0.3.1.
   */
  variant?: 'canvas' | 'grouped'
  children: ReactNode
  className?: string
}

export function Surface({ variant = 'canvas', children, className }: SurfaceProps) {
  return (
    <div className={cx('surface', variant === 'grouped' && 'surface--grouped', className)}>
      {children}
    </div>
  )
}

/** The centred phone-width column. The app is never a multi-column desktop layout. */
export function AppColumn({ children, className }: { children: ReactNode; className?: string }) {
  return <div className={cx('app-column', className)}>{children}</div>
}

/* ================================================================== *
 * GlassCard
 * ================================================================== */

export interface GlassCardProps {
  children: ReactNode
  /** `.glassCard()` always applies 16pt of internal padding (DESIGN-TOKENS §8). */
  padded?: boolean
  radius?: 'md' | 'lg' | 'xl'
  /** `.glassCardInteractive()` — adds the press-scale feedback. */
  interactive?: boolean
  onClick?: () => void
  className?: string
  style?: CSSProperties
  ariaLabel?: string
}

export function GlassCard({
  children,
  padded = true,
  radius = 'lg',
  interactive = false,
  onClick,
  className,
  style,
  ariaLabel,
}: GlassCardProps) {
  const classes = cx(
    'glass-card',
    padded && 'glass-card--padded',
    radius === 'md' && 'glass-card--radius-md',
    radius === 'xl' && 'glass-card--radius-xl',
    (interactive || onClick) && 'glass-card--interactive',
    className,
  )
  if (onClick) {
    return (
      <button type="button" className={classes} style={style} onClick={onClick} aria-label={ariaLabel}>
        {children}
      </button>
    )
  }
  return (
    <div className={classes} style={style} aria-label={ariaLabel}>
      {children}
    </div>
  )
}

/* ================================================================== *
 * PillButton
 * ================================================================== */

export interface PillButtonProps {
  children: ReactNode
  /** `prominent` = `.buttonStyle(.glassProminent)`, `glass` = `.buttonStyle(.glass)`. */
  variant?: 'prominent' | 'glass' | 'plain'
  size?: 'regular' | 'small'
  fullWidth?: boolean
  icon?: Sym
  disabled?: boolean
  onClick?: () => void
  type?: 'button' | 'submit'
  className?: string
  ariaLabel?: string
  testId?: string
}

export function PillButton({
  children,
  variant = 'prominent',
  size = 'regular',
  fullWidth = false,
  icon,
  disabled = false,
  onClick,
  type = 'button',
  className,
  ariaLabel,
  testId,
}: PillButtonProps) {
  return (
    <button
      type={type}
      className={cx(
        'pill-button',
        `pill-button--${variant}`,
        size === 'small' && 'pill-button--small',
        fullWidth && 'pill-button--full',
        className,
      )}
      disabled={disabled}
      onClick={onClick}
      aria-label={ariaLabel}
      data-testid={testId}
    >
      {icon && <Symbol name={icon} />}
      {children}
    </button>
  )
}

/* ================================================================== *
 * SegmentedControl — Priority|Split, Percentage|Fixed Amount, Monthly|Annual
 * ================================================================== */

/**
 * ⚠️ There is deliberately NO `icon` here.
 *
 * `FrequencyPicker.swift:17` is `Label(displayName, systemImage: icon)`, so the Swift reads
 * as though segments carry glyphs — but `.pickerStyle(.segmented)` **silently discards the
 * image**, and `09-expenses.jpg` / `14-add-expense-sheet.jpg` both show bare text. Every
 * segmented control in the app uses that picker style, so none will ever want an icon.
 *
 * The prop existed, went unused, and encoded that false belief. It is removed rather than
 * commented, because an unused affordance is an invitation: the next person finds it,
 * assumes it exists for a reason, and re-adds the glyphs. A missing prop is a compile
 * error; a comment can be skimmed past.
 */
export interface Segment<T extends string> {
  value: T
  label: string
  testId?: string
}

export interface SegmentedControlProps<T extends string> {
  segments: readonly Segment<T>[]
  value: T
  onChange: (value: T) => void
  /** Localized by the caller — primitives never hold strings. */
  ariaLabel: string
  compact?: boolean
  className?: string
}

export function SegmentedControl<T extends string>({
  segments,
  value,
  onChange,
  ariaLabel,
  compact = false,
  className,
}: SegmentedControlProps<T>) {
  return (
    <div
      role="tablist"
      aria-label={ariaLabel}
      className={cx('segmented', compact && 'segmented--compact', className)}
    >
      {segments.map((segment) => (
        <button
          key={segment.value}
          type="button"
          role="tab"
          aria-selected={segment.value === value}
          className="segmented__option"
          data-testid={segment.testId}
          onClick={() => onChange(segment.value)}
        >
          {segment.label}
        </button>
      ))}
    </div>
  )
}

/* ================================================================== *
 * ProgressRing / ProgressBar
 * ================================================================== */

/*
 * DECISIONS.md **R20** — geometry and label come from DIFFERENT server fields.
 *
 * iOS truncates the percentage only for the *text*; it draws the arc and the bar from the
 * full `Double`. Driving the geometry from the truncated integer instead is visibly wrong
 * at the graded 402px column: 8.759% renders as 8% and the bar is short by 2.69px, 8.990%
 * by 3.50px. And 8.759% is the GROUND-TRUTH month-2 emergency fund — the most-asserted
 * scenario in the project would be graded a ±2px failure, with the cause looking like a
 * CSS bug when it is really a wrong prop.
 *
 * So: `label` <- the truncated string (`progressDisplay`), `progress` <- the full double
 * (`emergencyProgress`, `progressBefore`, `progressAfter`). Two props for two jobs, and
 * neither is derived from the other client-side. The API already ships both, so this costs
 * nothing and adds no arithmetic.
 */

export interface ProgressRingProps {
  /**
   * ⚠️ The full **double** 0–1 (`emergencyFund.progress` = `0.04379629629629629`).
   * Geometry only. Never pass the truncated integer here, and never derive this from
   * `label` — see R20 above.
   */
  progress: number
  /**
   * The rendered caption, server-supplied and already truncated (`progressDisplay`,
   * e.g. `"4%"`). Text only.
   */
  label: string
  /**
   * iOS reads this as `"\(Int(progress * 100)) percent complete"` (`ProgressRing.swift:46`),
   * so the caller composes it through `t()`. Falls back to `label`.
   */
  ariaLabel?: string
  /** Any colour token, e.g. `var(--color-warning)`. */
  color?: string
  /** A length or token reference. Defaults to the dashboard ring size. */
  size?: string
  /** In viewBox units (the viewBox is 0 0 100 100), so it is a ratio, not a pixel value. */
  strokeWidth?: number
  /**
   * The parity harness asserts the DRAWN value is the unrounded double, because
   * "geometry silently equals the label" is the real R20 failure mode. The arc therefore
   * also carries `data-progress`.
   */
  arcTestId?: string
  labelTestId?: string
}

export function ProgressRing({
  progress,
  label,
  ariaLabel,
  color = 'var(--color-warning)',
  size = 'var(--size-ring-emergency)',
  strokeWidth = 6,
  arcTestId,
  labelTestId,
}: ProgressRingProps) {
  // pathLength={1} normalises the circle so the dash array IS the 0–1 progress —
  // no circumference arithmetic, and no precision lost to the label's truncation.
  return (
    <div
      className="progress-ring"
      style={{ '--progress-ring-color': color, width: size, height: size } as CSSProperties}
      role="img"
      aria-label={ariaLabel ?? label}
    >
      <svg className="progress-ring__svg" width={size} height={size} viewBox="0 0 100 100">
        <circle
          className="progress-ring__track"
          cx="50"
          cy="50"
          r="45"
          strokeWidth={strokeWidth}
          pathLength={1}
        />
        <circle
          className="progress-ring__fill"
          cx="50"
          cy="50"
          r="45"
          strokeWidth={strokeWidth}
          pathLength={1}
          strokeDasharray={`${progress} 1`}
          data-progress={progress}
          data-testid={arcTestId}
        />
      </svg>
      <span className="progress-ring__label" aria-hidden data-testid={labelTestId}>
        {label}
      </span>
    </div>
  )
}

export interface ProgressBarProps {
  /**
   * ⚠️ The full **double** 0–1 (R20). Geometry only — never the truncated integer.
   * The transfer-plan bars take `progressAfter`.
   */
  progress: number
  /** `gradient` = onboarding progress / savings slider track; `tint` = transfer plan rows. */
  variant?: 'gradient' | 'tint'
  color?: string
  ariaLabel?: string
  /** Pre-formatted, e.g. `"4%"` — what assistive tech announces instead of the raw double. */
  ariaValueText?: string
  /** Applied to the FILL element, which is what the harness measures. */
  fillTestId?: string
}

export function ProgressBar({
  progress,
  variant = 'gradient',
  color = 'var(--accent-primary)',
  ariaLabel,
  ariaValueText,
  fillTestId,
}: ProgressBarProps) {
  return (
    <div
      className="progress-bar"
      role="progressbar"
      // The 0–1 scale is reported as-is; converting to a percent here would be arithmetic
      // for no benefit, and `aria-valuetext` is what actually gets announced.
      aria-valuenow={progress}
      aria-valuemin={0}
      aria-valuemax={1}
      aria-valuetext={ariaValueText}
      aria-label={ariaLabel}
    >
      <div
        className={cx('progress-bar__fill', `progress-bar__fill--${variant}`)}
        style={{ '--progress': progress, '--progress-bar-color': color } as CSSProperties}
        data-progress={progress}
        data-testid={fillTestId}
      />
    </div>
  )
}

/* ================================================================== *
 * Slider
 * ================================================================== */

export interface SliderProps {
  /**
   * ⚠️ DECISIONS.md **R13**: for the savings slider, `value` is an INDEX into the
   * server's `savingsSliderPositions` table, and every caption around it
   * (`"25%"`, `"That's 1,182 RON/month"`) is read from that row. Dragging is a lookup.
   * Never derive a percentage or an amount from this number.
   */
  value: number
  min: number
  max: number
  step: number
  onChange: (value: number) => void
  variant?: 'gradient' | 'accent'
  /** All three are pre-formatted strings from the caller (e.g. "5%", "25% recommended"). */
  ticks?: { start?: string; center?: string; end?: string }
  ariaLabel: string
  /** Pre-formatted current value for assistive tech, e.g. "25%". */
  ariaValueText?: string
  /** Applied to the `<input type="range">` itself, which is what the harness drives. */
  testId?: string
}

export function Slider({
  value,
  min,
  max,
  step,
  onChange,
  variant = 'gradient',
  ticks,
  ariaLabel,
  ariaValueText,
  testId,
}: SliderProps) {
  // The filled fraction is computed by CSS from these three custom properties, so no
  // arithmetic happens in JS (R2).
  const vars = { '--value': value, '--min': min, '--max': max } as CSSProperties
  return (
    <div className="slider">
      <div className="slider__control" style={vars}>
        <div className="slider__track" />
        <div className={cx('slider__fill', `slider__fill--${variant}`)} />
        <input
          className="slider__input"
          type="range"
          min={min}
          max={max}
          step={step}
          value={value}
          aria-label={ariaLabel}
          aria-valuetext={ariaValueText}
          data-testid={testId}
          onChange={(event: ChangeEvent<HTMLInputElement>) => onChange(event.target.valueAsNumber)}
        />
      </div>
      {ticks && (
        <div className="slider__ticks">
          <span>{ticks.start}</span>
          <span className="slider__tick--center">{ticks.center}</span>
          <span className="slider__tick--end">{ticks.end}</span>
        </div>
      )}
    </div>
  )
}

/* ================================================================== *
 * Fields
 * ================================================================== */

export interface TextFieldProps {
  value: string
  onChange: (value: string) => void
  label?: string
  placeholder?: string
  caption?: string
  autoFocus?: boolean
  ariaLabel?: string
  /** Applied to the `<input>` itself — the harness calls `fill()`, so a wrapper is no use. */
  testId?: string
}

export function TextField({
  value,
  onChange,
  label,
  placeholder,
  caption,
  autoFocus,
  ariaLabel,
  testId,
}: TextFieldProps) {
  const id = useId()
  return (
    <div className="field">
      {label && (
        <label className="field__label" htmlFor={id}>
          {label}
        </label>
      )}
      <input
        id={id}
        className="text-field__input"
        type="text"
        value={value}
        placeholder={placeholder}
        autoFocus={autoFocus}
        aria-label={ariaLabel ?? label}
        data-testid={testId}
        onChange={(event) => onChange(event.target.value)}
      />
      {caption && <p className="field__caption">{caption}</p>}
    </div>
  )
}

export interface AmountFieldProps {
  /**
   * The input text, as an `EditingString`.
   *
   * DECISIONS.md **R24**: this is branded so that passing a `MoneyValue.display`
   * (`"9,000 RON"`) is a **compile error** rather than a 1000× silent data loss. Seed it
   * from the server's `editing` field; wrap user-typed text with `editingString()`.
   */
  value: EditingString
  onChange: (text: EditingString) => void
  /**
   * Fired on blur with the parsed canonical decimal. Parsing reproduces the iOS
   * `AmountFormatter.parse` comma quirk (`"1,234"` -> `1.234`) deliberately —
   * see `money.ts` and PARITY-GAPS.md.
   */
  onCommit?: (amount: Money) => void
  /** Currency CODE, never the symbol — e.g. "RON" (PARITY-SPEC §0.3). */
  currencyCode: string
  /** iOS shows the code as a leading prefix in sheets and a trailing suffix in fields. */
  currencyPosition?: 'prefix' | 'suffix'
  label?: string
  caption?: string
  placeholder?: string
  align?: 'start' | 'end'
  plain?: boolean
  ariaLabel?: string
  /** Applied to the `<input>` itself. */
  testId?: string
}

export function AmountField({
  value,
  onChange,
  onCommit,
  currencyCode,
  currencyPosition = 'prefix',
  label,
  caption,
  placeholder,
  align = 'start',
  plain = false,
  ariaLabel,
  testId,
}: AmountFieldProps) {
  const id = useId()
  const currency = <span className="amount-field__currency">{currencyCode}</span>
  return (
    <div className="field">
      {label && (
        <label className="field__label" htmlFor={id}>
          {label}
        </label>
      )}
      <div className={cx('amount-field', plain && 'amount-field--plain')}>
        {currencyPosition === 'prefix' && currency}
        <input
          id={id}
          className={cx('amount-field__input', align === 'end' && 'amount-field__input--end')}
          type="text"
          inputMode="decimal"
          value={value}
          placeholder={placeholder}
          aria-label={ariaLabel ?? label}
          data-testid={testId}
          onChange={(event) => onChange(event.target.value as EditingString)}
          onBlur={() => onCommit?.(parseUserInput(value))}
        />
        {currencyPosition === 'suffix' && currency}
      </div>
      {caption && <p className="field__caption">{caption}</p>}
    </div>
  )
}

/* ================================================================== *
 * Toggle
 * ================================================================== */

export interface ToggleProps {
  checked: boolean
  onChange: (checked: boolean) => void
  label?: string
  disabled?: boolean
  ariaLabel?: string
  testId?: string
}

export function Toggle({
  checked,
  onChange,
  label,
  disabled = false,
  ariaLabel,
  testId,
}: ToggleProps) {
  return (
    <label className="toggle">
      <input
        className="toggle__input"
        type="checkbox"
        role="switch"
        checked={checked}
        disabled={disabled}
        aria-label={ariaLabel ?? label}
        data-testid={testId}
        onChange={(event) => onChange(event.target.checked)}
      />
      <span className="toggle__track">
        <span className="toggle__knob" />
      </span>
      {label && <span className="toggle__label">{label}</span>}
    </label>
  )
}

/* ================================================================== *
 * ListRow / SectionHeader / Badge / Divider
 * ================================================================== */

export interface ListRowProps {
  icon?: Sym
  /** Any colour — category `colorHex` values arrive from the server. */
  iconColor?: string
  /** Renders the icon in a tinted rounded square, as category rows do. */
  tintedIcon?: boolean
  title: ReactNode
  subtitle?: ReactNode
  /** Pre-formatted display string, e.g. `"2,500 RON"`. */
  value?: ReactNode
  valueTone?: 'primary' | 'secondary'
  accessory?: 'chevron' | 'menu' | 'expand' | ReactNode
  /** Rotates the `expand` chevron to the open position. */
  expanded?: boolean
  trailing?: ReactNode
  onClick?: () => void
  className?: string
}

export function ListRow({
  icon,
  iconColor,
  tintedIcon = false,
  title,
  subtitle,
  value,
  valueTone = 'primary',
  accessory,
  expanded = false,
  trailing,
  onClick,
  className,
}: ListRowProps) {
  const content = (
    <>
      {icon && (
        <span
          className={cx('list-row__icon', tintedIcon && 'list-row__icon--tinted')}
          style={iconColor ? ({ '--list-row-icon-color': iconColor } as CSSProperties) : undefined}
        >
          <Symbol name={icon} />
        </span>
      )}
      <span className="list-row__text">
        <span className="list-row__title">{title}</span>
        {subtitle && <span className="list-row__subtitle">{subtitle}</span>}
      </span>
      {value !== undefined && (
        <span
          className={cx('list-row__value', valueTone === 'secondary' && 'list-row__value--secondary')}
        >
          {value}
        </span>
      )}
      {trailing}
      {accessory === 'chevron' && (
        <span className="list-row__accessory">
          <Symbol name="chevron.right" />
        </span>
      )}
      {accessory === 'menu' && (
        <span className="list-row__accessory">
          <Symbol name="chevron.up.chevron.down" />
        </span>
      )}
      {accessory === 'expand' && (
        <span className={cx('list-row__accessory', expanded && 'list-row__accessory--rotated')}>
          <Symbol name="chevron.right" />
        </span>
      )}
      {accessory !== undefined &&
        accessory !== 'chevron' &&
        accessory !== 'menu' &&
        accessory !== 'expand' &&
        accessory}
    </>
  )

  if (onClick) {
    return (
      <button
        type="button"
        className={cx('list-row', 'list-row--tappable', className)}
        onClick={onClick}
        aria-expanded={accessory === 'expand' ? expanded : undefined}
      >
        {content}
      </button>
    )
  }
  return <div className={cx('list-row', className)}>{content}</div>
}

export function Divider({ inset = false }: { inset?: boolean }) {
  return <hr className={cx('list-divider', inset && 'list-divider--inset')} />
}

export interface SectionHeaderProps {
  title: string
  icon?: Sym
  /** `plain` = bold headline over a ScrollView; `grouped` = grey caption over a Form. */
  variant?: 'plain' | 'grouped'
}

export function SectionHeader({ title, icon, variant = 'plain' }: SectionHeaderProps) {
  return (
    <h2 className={cx('section-header', variant === 'grouped' && 'section-header--grouped')}>
      {icon && (
        <span className="section-header__icon">
          <Symbol name={icon} />
        </span>
      )}
      {title}
    </h2>
  )
}

export interface BadgeProps {
  children: ReactNode
  tone?: 'neutral' | 'accent' | 'secondary' | 'warning'
  icon?: Sym
  large?: boolean
}

export function Badge({ children, tone = 'neutral', icon, large = false }: BadgeProps) {
  return (
    <span className={cx('badge', `badge--${tone}`, large && 'badge--large')}>
      {icon && <Symbol name={icon} />}
      {children}
    </span>
  )
}

/* ================================================================== *
 * Menu — a native <select> dressed as the iOS menu row. Native gives us
 * keyboard, screen-reader and touch behaviour for free.
 * ================================================================== */

export interface MenuOption<T extends string> {
  value: T
  label: string
}

export interface MenuProps<T extends string> {
  options: readonly MenuOption<T>[]
  value: T
  onChange: (value: T) => void
  ariaLabel: string
  /** `glass` renders the pill-shaped `.buttonStyle(.glass)` menu used in expense rows. */
  variant?: 'plain' | 'glass'
  /**
   * Leading glyph, rendered before the value at caption size in accentSecondary.
   * `AccountTypeSelector(compact:)` (`AccountTypeSelector.swift:514-519`,
   * PARITY-SPEC §2.4.3) is a capsule of glyph + displayName + chevron — the type pill on
   * every account card in `04-onboarding-accounts.jpg`. Also serves the expense row's
   * "From:" pill and the Settings menus.
   */
  icon?: Sym
  testId?: string
}

export function Menu<T extends string>({
  options,
  value,
  onChange,
  ariaLabel,
  variant = 'plain',
  icon,
  testId,
}: MenuProps<T>) {
  const selected = options.find((option) => option.value === value)
  return (
    <span className={cx('menu', variant === 'glass' && 'menu--glass')}>
      <select
        className="menu__select"
        value={value}
        aria-label={ariaLabel}
        data-testid={testId}
        onChange={(event) => onChange(event.target.value as T)}
      >
        {options.map((option) => (
          <option key={option.value} value={option.value}>
            {option.label}
          </option>
        ))}
      </select>
      <span className="menu__face" aria-hidden>
        {icon && (
          <span className="menu__icon">
            <Symbol name={icon} />
          </span>
        )}
        <span className="menu__value">{selected?.label ?? value}</span>
        <span className="menu__chevron">
          <Symbol name="chevron.up.chevron.down" />
        </span>
      </span>
    </span>
  )
}

/* ================================================================== *
 * IconGrid / ColorGrid
 * ================================================================== */

export interface IconGridProps {
  /**
   * ⚠️ Reusable with ANY symbol set — Add Expense and New Category use different lists.
   * Feed it `state.reference.expenseIcons` or the category set; never hardcode here.
   */
  symbols: readonly string[]
  value: string
  onChange: (symbol: string) => void
  ariaLabel: string
  /**
   * Per-cell test id, e.g. `(s) => `add-expense-icon-${s}``.
   *
   * Identity, not count: a `toHaveCount(37)` assertion passes on **the right number of the
   * wrong symbols**, and the expense (37) and category (12) grids overlap on only five —
   * so counting cannot tell them apart. Each cell also carries `data-symbol`.
   */
  cellTestId?: (symbol: string) => string
}

export function IconGrid({ symbols, value, onChange, ariaLabel, cellTestId }: IconGridProps) {
  return (
    <div className="icon-grid" role="group" aria-label={ariaLabel}>
      {symbols.map((symbol) => (
        <button
          key={symbol}
          type="button"
          className="icon-grid__cell"
          aria-pressed={symbol === value}
          aria-label={symbol}
          data-symbol={symbol}
          data-testid={cellTestId?.(symbol)}
          onClick={() => onChange(symbol)}
        >
          <Symbol name={symbol} />
        </button>
      ))}
    </div>
  )
}

export interface ColorGridProps {
  /** Hex strings, e.g. the 10 swatches in DESIGN-TOKENS §1.4. */
  colors: readonly string[]
  value: string
  onChange: (color: string) => void
  ariaLabel: string
  /**
   * Per-swatch test id, e.g. `(hex) => `new-category-color-${hex.slice(1).toLowerCase()}``.
   * Same identity-over-count reasoning as `IconGrid.cellTestId`. Each swatch also carries
   * `data-color`, so a test can assert the palette's contents without parsing ids.
   */
  cellTestId?: (color: string) => string
}

export function ColorGrid({ colors, value, onChange, ariaLabel, cellTestId }: ColorGridProps) {
  return (
    <div className="color-grid" role="group" aria-label={ariaLabel}>
      {colors.map((color) => (
        <button
          key={color}
          type="button"
          className="color-grid__swatch"
          style={{ background: color }}
          aria-pressed={color === value}
          aria-label={color}
          data-color={color}
          data-testid={cellTestId?.(color)}
          onClick={() => onChange(color)}
        >
          {color === value && <Symbol name="checkmark" />}
        </button>
      ))}
    </div>
  )
}

/* ================================================================== *
 * Sheet — Cancel / title / Save, Save disabled until valid.
 * ================================================================== */

export interface SheetProps {
  title: string
  /** All labels localized by the caller. */
  cancelLabel: string
  confirmLabel?: string
  onCancel: () => void
  onConfirm?: () => void
  confirmDisabled?: boolean
  /** `.presentationDetents([.medium])` -> 50%, `[.large]` -> 90% (DESIGN-TOKENS §8). */
  size?: 'medium' | 'large'
  /** `.interactiveDismissDisabled` — blocks backdrop-click dismissal. */
  dismissDisabled?: boolean
  children: ReactNode
  /** Replaces the Cancel/title/Save header, for the New Month "Step n of 3" chrome. */
  header?: ReactNode
}

export function Sheet({
  title,
  cancelLabel,
  confirmLabel,
  onCancel,
  onConfirm,
  confirmDisabled = false,
  size = 'large',
  dismissDisabled = false,
  children,
  header,
}: SheetProps) {
  return (
    <div
      className="sheet-backdrop"
      onClick={dismissDisabled ? undefined : onCancel}
      role="presentation"
    >
      <div
        className={cx('sheet', 'surface--grouped', `sheet--${size}`)}
        role="dialog"
        aria-modal="true"
        aria-label={title}
        onClick={(event) => event.stopPropagation()}
      >
        {header ?? (
          <div className="sheet__header">
            <span className="sheet__action--start">
              <PillButton variant="glass" size="small" onClick={onCancel}>
                {cancelLabel}
              </PillButton>
            </span>
            <span className="sheet__title">{title}</span>
            <span className="sheet__action--end">
              {confirmLabel && (
                <PillButton
                  variant="glass"
                  size="small"
                  disabled={confirmDisabled}
                  {...(onConfirm ? { onClick: onConfirm } : {})}
                >
                  {confirmLabel}
                </PillButton>
              )}
            </span>
          </div>
        )}
        <div className="sheet__body">{children}</div>
      </div>
    </div>
  )
}

/* ================================================================== *
 * TabBar + the New Month accessory that floats above it.
 * ================================================================== */

export interface TabItem<T extends string> {
  value: T
  label: string
  icon: Sym
  testId?: string
}

export interface TabBarProps<T extends string> {
  tabs: readonly TabItem<T>[]
  value: T
  onChange: (value: T) => void
  ariaLabel: string
  /** The "New Month" pill — `.tabViewBottomAccessory` has no web analogue, so it is a
   *  fixed element directly above the bar (DESIGN-TOKENS §8). */
  accessory?: ReactNode
}

export function TabBar<T extends string>({
  tabs,
  value,
  onChange,
  ariaLabel,
  accessory,
}: TabBarProps<T>) {
  return (
    <div className="tab-dock">
      {accessory}
      <nav className="tab-bar" role="tablist" aria-label={ariaLabel}>
        {tabs.map((tab) => (
          <button
            key={tab.value}
            type="button"
            role="tab"
            aria-selected={tab.value === value}
            className="tab-bar__tab"
            data-testid={tab.testId}
            onClick={() => onChange(tab.value)}
          >
            <span className="tab-bar__icon">
              <Symbol name={tab.icon} />
            </span>
            {tab.label}
          </button>
        ))}
      </nav>
    </div>
  )
}

export interface TabAccessoryProps {
  label: string
  icon?: Sym
  onClick: () => void
  disabled?: boolean
  testId?: string
}

export function TabAccessory({
  label,
  icon = 'calendar.badge.plus',
  onClick,
  disabled,
  testId,
}: TabAccessoryProps) {
  return (
    <button
      type="button"
      className="tab-accessory"
      onClick={onClick}
      disabled={disabled}
      data-testid={testId}
    >
      <Symbol name={icon} />
      {label}
    </button>
  )
}
