import { renderToStaticMarkup } from 'react-dom/server'
import { describe, expect, it } from 'vitest'
import {
  Badge,
  ColorGrid,
  GlassCard,
  IconGrid,
  ListRow,
  Menu,
  PillButton,
  ProgressBar,
  ProgressRing,
  SegmentedControl,
  Sheet,
  Slider,
  TabBar,
  Toggle,
} from './index'

const render = renderToStaticMarkup

describe('R2 + R20 contract: primitives render given values verbatim', () => {
  it('ProgressRing draws from the full double and labels with the truncated string', () => {
    // pathLength=1 means the dash array IS the 0-1 progress — no circumference maths.
    const html = render(<ProgressRing progress={0.04379629629629629} label="4%" />)
    expect(html).toContain('stroke-dasharray="0.04379629629629629 1"')
    expect(html).toContain('4%')
    expect(html).toContain('pathLength="1"')
  })

  it('R20: geometry does NOT collapse to the label\'s truncated value', () => {
    // GROUND-TRUTH month-2 emergency fund: 8.759% labelled "8%". Driving the arc from 8
    // would be 2.69px short at the graded 402px column.
    const progress = 0.08759259259259259
    const html = render(<ProgressRing progress={progress} label="8%" />)
    // Interpolated so the expectation cannot disagree with JS float stringification.
    expect(html).toContain(`stroke-dasharray="${progress} 1"`)
    expect(html).not.toContain('stroke-dasharray="0.08 1"')
    expect(html).not.toContain('stroke-dasharray="8 100"')
  })

  it('ProgressBar passes the full double to CSS rather than computing a width', () => {
    const html = render(<ProgressBar progress={0.5899} />)
    expect(html).toContain('--progress:0.5899')
    expect(html).not.toContain('width:')
  })

  it('ProgressRing uses the caller-composed aria label when given one', () => {
    const html = render(
      <ProgressRing progress={0.0438} label="4%" ariaLabel="4 percent complete" />,
    )
    expect(html).toContain('aria-label="4 percent complete"')
  })

  it('Slider hands value/min/max to CSS for the fill fraction', () => {
    const html = render(
      <Slider ariaLabel="Savings rate" value={0.25} min={0.05} max={0.5} step={0.01} onChange={() => {}} />,
    )
    expect(html).toContain('--value:0.25')
    expect(html).toContain('--min:0.05')
    expect(html).toContain('--max:0.5')
  })

  it('ListRow renders a pre-formatted money string untouched', () => {
    const html = render(<ListRow title="Rent" value="2,500 RON" />)
    expect(html).toContain('2,500 RON')
  })
})

describe('primitives render and carry their states', () => {
  it('GlassCard applies padding by default and can drop it', () => {
    expect(render(<GlassCard>x</GlassCard>)).toContain('glass-card--padded')
    expect(render(<GlassCard padded={false}>x</GlassCard>)).not.toContain('glass-card--padded')
  })

  it('PillButton variants and disabled state', () => {
    expect(render(<PillButton>Go</PillButton>)).toContain('pill-button--prominent')
    expect(render(<PillButton variant="glass">Go</PillButton>)).toContain('pill-button--glass')
    expect(render(<PillButton disabled>Go</PillButton>)).toContain('disabled')
    expect(render(<PillButton fullWidth>Go</PillButton>)).toContain('pill-button--full')
  })

  it('SegmentedControl marks exactly one selected segment', () => {
    const html = render(
      <SegmentedControl
        ariaLabel="Frequency"
        value="monthly"
        onChange={() => {}}
        segments={[
          { value: 'monthly', label: 'Monthly' },
          { value: 'annual', label: 'Annual' },
        ]}
      />,
    )
    expect(html.match(/aria-selected="true"/g)).toHaveLength(1)
    expect(html).toContain('Monthly')
    expect(html).toContain('Annual')
  })

  it('Toggle is a switch reflecting checked state', () => {
    expect(render(<Toggle checked onChange={() => {}} label="Savings Boost" />)).toContain(
      'role="switch"',
    )
    expect(render(<Toggle checked onChange={() => {}} />)).toContain('checked')
  })

  it('Sheet disables confirm when asked and keeps caller-supplied labels', () => {
    const html = render(
      <Sheet title="Add Expense" cancelLabel="Cancel" confirmLabel="Save" confirmDisabled onCancel={() => {}}>
        body
      </Sheet>,
    )
    expect(html).toContain('Add Expense')
    expect(html).toContain('Cancel')
    expect(html).toContain('Save')
    expect(html).toContain('disabled')
    expect(html).toContain('aria-modal="true"')
  })

  it('TabBar renders three tabs with one selected', () => {
    const html = render(
      <TabBar
        ariaLabel="Main"
        value="expenses"
        onChange={() => {}}
        tabs={[
          { value: 'dashboard', label: 'Dashboard', icon: 'chart.pie.fill' },
          { value: 'expenses', label: 'Expenses', icon: 'list.bullet.rectangle' },
          { value: 'insights', label: 'Insights', icon: 'lightbulb.max' },
        ]}
      />,
    )
    expect(html.match(/role="tab"/g)).toHaveLength(3)
    expect(html.match(/aria-selected="true"/g)).toHaveLength(1)
  })

  it('Badge tones', () => {
    expect(render(<Badge>Primary</Badge>)).toContain('badge--neutral')
    expect(render(<Badge tone="accent">Auto-Save</Badge>)).toContain('badge--accent')
  })

  it('Menu shows the selected option label', () => {
    const html = render(
      <Menu
        ariaLabel="Pay from"
        value="savings"
        onChange={() => {}}
        options={[
          { value: 'primary', label: 'Main' },
          { value: 'savings', label: 'Savings' },
        ]}
      />,
    )
    expect(html).toContain('Savings')
  })
})

describe('IconGrid / ColorGrid are set-agnostic', () => {
  it('IconGrid renders whatever symbol list it is given', () => {
    const eighteen = Array.from({ length: 18 }, (_, i) => (i % 2 ? 'cart.fill' : 'house.fill'))
    const twelve = Array.from({ length: 12 }, () => 'star.fill')
    expect(render(<IconGrid ariaLabel="Icon" symbols={eighteen} value="cart.fill" onChange={() => {}} />)
      .match(/<button/g)).toHaveLength(18)
    expect(render(<IconGrid ariaLabel="Icon" symbols={twelve} value="star.fill" onChange={() => {}} />)
      .match(/<button/g)).toHaveLength(12)
  })

  it('IconGrid emits per-cell identity, not just a count', () => {
    /*
     * A `toHaveCount(37)` assertion passes on the right NUMBER of the WRONG symbols, and
     * the expense (37) and category (12) grids overlap on only five — so counting cannot
     * distinguish them. These attributes are what let the harness assert identity.
     */
    const html = render(
      <IconGrid
        ariaLabel="Icon"
        symbols={['cart.fill', 'calendar']}
        value="cart.fill"
        onChange={() => {}}
        cellTestId={(s) => `add-expense-icon-${s}`}
      />,
    )
    expect(html).toContain('data-testid="add-expense-icon-cart.fill"')
    // `calendar` is the discriminator: in the category grid, absent from the expense grid.
    expect(html).toContain('data-symbol="calendar"')
  })

  it('ColorGrid emits per-swatch identity', () => {
    const html = render(
      <ColorGrid
        ariaLabel="Colour"
        colors={['#3B82F6']}
        value="#3B82F6"
        onChange={() => {}}
        cellTestId={(hex) => `new-category-color-${hex.slice(1).toLowerCase()}`}
      />,
    )
    expect(html).toContain('data-testid="new-category-color-3b82f6"')
    expect(html).toContain('data-color="#3B82F6"')
  })

  it('grids omit the attribute entirely when no cellTestId is given', () => {
    const html = render(
      <IconGrid ariaLabel="Icon" symbols={['cart.fill']} value="cart.fill" onChange={() => {}} />,
    )
    expect(html).not.toContain('data-testid')
  })

  it('ColorGrid marks the selected swatch', () => {
    const html = render(
      <ColorGrid ariaLabel="Colour" colors={['#3B82F6', '#EF4444']} value="#EF4444" onChange={() => {}} />,
    )
    expect(html.match(/aria-pressed="true"/g)).toHaveLength(1)
    expect(html).toContain('#EF4444')
  })
})
