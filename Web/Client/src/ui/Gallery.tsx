/**
 * Primitive gallery — `?dev=gallery`.
 *
 * Every primitive in every state, rendered twice: once with the theme pinned light and
 * once pinned dark, side by side. It exists so the Reviewer can screenshot the design
 * system before any screen is built, and so token mistakes (wrong surface, wrong
 * separator, a hardcoded colour) show up immediately instead of screen by screen.
 *
 * Strings here are literal on purpose — the gallery is a dev tool, not a shipped screen,
 * so it is exempt from the i18n rule that binds real screens.
 */

import { useState } from 'react'
import {
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
} from './index'
import { CATEGORY_ICON_SYMBOLS } from '../lib/icons'
import { editingString } from '../lib/money'
import { useTheme, type ThemePreference } from './theme'

/**
 * ⚠️ GALLERY-ONLY FIXTURE — **do not copy this into screen code.**
 *
 * DECISIONS.md R12: the palette is server-served (`reference.categoryColors`) and R22
 * removed the duplicate `--cat-*` CSS tokens for the same reason — every extra copy is a
 * place the list can drift with nothing failing when it does. This literal survives only
 * because the gallery is a route-gated dev tool that renders with no server attached.
 * A real screen that hardcodes a palette is a bug.
 */
const CATEGORY_COLORS = [
  '#3B82F6',
  '#8B5CF6',
  '#F59E0B',
  '#10B981',
  '#EC4899',
  '#EF4444',
  '#22C55E',
  '#06B6D4',
  '#F97316',
  '#6366F1',
]

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section className="gallery__section">
      <h3 className="gallery__section-title">{title}</h3>
      {children}
    </section>
  )
}

/** All primitives, in every state. Rendered once per pinned appearance. */
function Specimens() {
  const [segment, setSegment] = useState<'monthly' | 'annual'>('monthly')
  const [mode, setMode] = useState<'prioritized' | 'split'>('prioritized')
  const [percent, setPercent] = useState(0.25)
  const [toggleOn, setToggleOn] = useState(true)
  const [icon, setIcon] = useState<string>('star.fill')
  const [color, setColor] = useState('#3B82F6')
  const [name, setName] = useState('')
  const [amount, setAmount] = useState(editingString('2500'))
  const [account, setAccount] = useState<'primary' | 'savings'>('primary')
  const [sheetOpen, setSheetOpen] = useState(false)
  const [tab, setTab] = useState<'dashboard' | 'expenses' | 'insights'>('dashboard')

  return (
    <div className="gallery__stack">
      <Section title="GlassCard">
        <div className="gallery__stack">
          <GlassCard>Default card — 16pt padding, radius lg</GlassCard>
          <GlassCard radius="xl">Radius xl</GlassCard>
          <GlassCard interactive onClick={() => undefined}>
            Interactive (press to scale)
          </GlassCard>
        </div>
      </Section>

      <Section title="PillButton">
        <div className="gallery__row">
          <PillButton variant="prominent">Let&apos;s Go</PillButton>
          <PillButton variant="glass">Cancel</PillButton>
          <PillButton variant="plain">Skip for now</PillButton>
          <PillButton variant="prominent" disabled>
            Disabled
          </PillButton>
          <PillButton variant="glass" size="small">
            Small
          </PillButton>
          <PillButton variant="prominent" icon="checkmark">
            With icon
          </PillButton>
        </div>
        <PillButton variant="prominent" fullWidth icon="checkmark">
          Done - I made the transfers
        </PillButton>
      </Section>

      <Section title="SegmentedControl">
        <SegmentedControl
          ariaLabel="Allocation strategy"
          value={mode}
          onChange={setMode}
          segments={[
            { value: 'prioritized', label: 'Priority' },
            { value: 'split', label: 'Split' },
          ]}
        />
        <SegmentedControl
          ariaLabel="Frequency"
          value={segment}
          onChange={setSegment}
          segments={[
            { value: 'monthly', label: 'Monthly' },
            { value: 'annual', label: 'Annual' },
          ]}
        />
      </Section>

      <Section title="ProgressRing — label truncated, geometry from the full double (R20)">
        <div className="gallery__row">
          <ProgressRing progress={0} label="0%" />
          <ProgressRing progress={0.04379629629629629} label="4%" />
          {/* R20: 8.759% draws as 8.759%, not as the 8% its label reads. */}
          <ProgressRing progress={0.08759259259259259} label="8%" />
          <ProgressRing progress={1} label="100%" color="var(--color-green)" />
        </div>
      </Section>

      <Section title="ProgressBar">
        <div className="gallery__stack">
          <ProgressBar progress={0.04379629629629629} variant="tint" color="var(--color-warning)" />
          <ProgressBar progress={0.5899} variant="gradient" />
          <ProgressBar progress={1} variant="gradient" />
        </div>
      </Section>

      <Section title="Slider">
        <Slider
          ariaLabel="Savings rate"
          ariaValueText="25%"
          value={percent}
          min={0.05}
          max={0.5}
          step={0.01}
          onChange={setPercent}
          ticks={{ start: '5%', center: '25% recommended', end: '50%' }}
        />
        <Slider
          ariaLabel="Savings rate"
          variant="accent"
          value={percent}
          min={0.05}
          max={0.5}
          step={0.01}
          onChange={setPercent}
        />
      </Section>

      <Section title="Fields">
        <TextField value={name} onChange={setName} label="Account Name" placeholder="Your name" />
        <AmountField
          value={amount}
          onChange={setAmount}
          currencyCode="RON"
          label="Monthly net income"
          caption="This is your starting point."
        />
        <AmountField
          value={amount}
          onChange={setAmount}
          currencyCode="RON"
          currencyPosition="suffix"
          align="end"
          plain
        />
        <AmountField
          value={editingString('')}
          onChange={() => undefined}
          currencyCode="RON"
          placeholder="0"
        />
      </Section>

      <Section title="Toggle">
        <div className="gallery__row">
          <Toggle checked={toggleOn} onChange={setToggleOn} label="Savings Boost" />
          <Toggle checked={!toggleOn} onChange={() => setToggleOn(!toggleOn)} />
          <Toggle checked disabled onChange={() => undefined} label="Disabled" />
        </div>
      </Section>

      <Section title="ListRow / Divider / SectionHeader">
        <SectionHeader title="Account Balances" icon="building.columns.fill" />
        <SectionHeader title="Profile" variant="grouped" />
        <GlassCard padded={false}>
          <div style={{ padding: 'var(--space-md)' }}>
            <ListRow
              icon="building.columns.fill"
              title="Main Account"
              subtitle="Primary"
              accessory="chevron"
              onClick={() => undefined}
            />
            <Divider inset />
            <ListRow
              icon="car.fill"
              iconColor="#3B82F6"
              tintedIcon
              title="Auto/Transport"
              subtitle="1/1 enabled"
              value="450 RON"
              accessory="expand"
              expanded={false}
              onClick={() => undefined}
            />
            <Divider inset />
            <ListRow title="Currency" value="Romanian Leu (RON)" valueTone="secondary" accessory="menu" />
            <Divider inset />
            <ListRow
              icon="house.fill"
              title="Rent"
              value="2,500 RON"
              trailing={<Toggle checked={toggleOn} onChange={setToggleOn} ariaLabel="Rent enabled" />}
            />
          </div>
        </GlassCard>
      </Section>

      <Section title="Badge">
        <div className="gallery__row">
          <Badge>Primary</Badge>
          <Badge tone="accent">Auto-Save</Badge>
          <Badge tone="neutral">Default</Badge>
          <Badge tone="secondary" icon="checkmark.circle.fill" large>
            Great savings rate!
          </Badge>
          <Badge tone="warning" icon="exclamationmark.triangle.fill">
            Over budget
          </Badge>
        </div>
      </Section>

      <Section title="Menu">
        <div className="gallery__row">
          <Menu
            ariaLabel="Pay from"
            value={account}
            onChange={setAccount}
            options={[
              { value: 'primary', label: 'Primary' },
              { value: 'savings', label: 'Savings' },
            ]}
          />
          <Menu
            ariaLabel="Pay from"
            variant="glass"
            value={account}
            onChange={setAccount}
            options={[
              { value: 'primary', label: 'Main' },
              { value: 'savings', label: 'Savings' },
            ]}
          />
        </div>
      </Section>

      <Section title="IconGrid — reusable with any symbol set">
        <IconGrid
          ariaLabel="Category icon"
          symbols={CATEGORY_ICON_SYMBOLS}
          value={icon}
          onChange={setIcon}
        />
      </Section>

      <Section title="ColorGrid">
        <ColorGrid ariaLabel="Category colour" colors={CATEGORY_COLORS} value={color} onChange={setColor} />
      </Section>

      <Section title="TabBar + accessory">
        <TabBar
          ariaLabel="Main"
          value={tab}
          onChange={setTab}
          accessory={<TabAccessory label="New Month" onClick={() => undefined} />}
          tabs={[
            { value: 'dashboard', label: 'Dashboard', icon: 'chart.pie.fill' },
            { value: 'expenses', label: 'Expenses', icon: 'list.bullet.rectangle' },
            { value: 'insights', label: 'Insights', icon: 'lightbulb.max' },
          ]}
        />
      </Section>

      <Section title="Sheet">
        <PillButton variant="glass" onClick={() => setSheetOpen(true)}>
          Open sheet
        </PillButton>
        {sheetOpen && (
          <Sheet
            title="Add Expense"
            cancelLabel="Cancel"
            confirmLabel="Save"
            confirmDisabled
            onCancel={() => setSheetOpen(false)}
          >
            <SectionHeader title="Details" variant="grouped" />
            <GlassCard>
              <TextField value={name} onChange={setName} placeholder="Name" />
            </GlassCard>
          </Sheet>
        )}
      </Section>
    </div>
  )
}

function Pane({ theme }: { theme: 'light' | 'dark' }) {
  return (
    <div className="gallery__pane" data-theme={theme}>
      <Surface>
        <AppColumn>
          <div style={{ paddingBlock: 'var(--space-md)' }}>
            <Specimens />
          </div>
        </AppColumn>
      </Surface>
    </div>
  )
}

export function Gallery() {
  const { preference, setPreference } = useTheme()
  return (
    <div className="gallery">
      <div className="gallery__toolbar">
        <h1 className="gallery__title">Diameris — primitive gallery</h1>
        <SegmentedControl<ThemePreference>
          ariaLabel="Theme"
          value={preference}
          onChange={setPreference}
          segments={[
            { value: 'system', label: 'System' },
            { value: 'light', label: 'Light' },
            { value: 'dark', label: 'Dark' },
          ]}
        />
      </div>
      <p className="gallery__note">
        Left pane is pinned light, right pane pinned dark. The toolbar switches the page
        chrome so the surrounding page can be checked too.
      </p>
      <div className="gallery__grid">
        <Pane theme="light" />
        <Pane theme="dark" />
      </div>
    </div>
  )
}
