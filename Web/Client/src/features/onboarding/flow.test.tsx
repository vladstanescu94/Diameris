import { renderToStaticMarkup } from 'react-dom/server'
import { describe, expect, it } from 'vitest'
import type { AppState } from '../../lib/api'
import { LanguageProvider } from '../../lib/i18n'
import {
  ONBOARDING_INDICATOR_STEPS,
  ONBOARDING_STEPS,
  type OnboardingStep,
} from '../../state/viewState'
import { OnboardingFlow } from './OnboardingFlow'

/**
 * The fixture mirrors the shape `GET /api/state` really returns (captured from the live
 * Vapor server on 2026-08-06) for the fields onboarding reads. Anything absent here is
 * absent because no onboarding screen touches it.
 */
const STATE = {
  schemaVersion: 1,
  onboardingCompleted: false,
  settings: {
    income: { amount: '9000', display: '9,000 RON', editing: '9000' },
    savings: {
      percentage: 0.25,
      percentageDisplay: '25%',
      effectivePercentage: 0.25,
      effectivePercentageDisplay: '25%',
      boostEnabled: false,
      boostMultiplier: 3,
      isBoostApplicable: true,
      allocationMode: 'prioritized',
      allocationModeDisplayName: 'Priority',
      allocationModeDescription: 'Emergency fund fills first, then savings',
      savingsInputMode: 'percentage',
      fixedAmount: { amount: '0', display: '0 RON', editing: '' },
      splitEmergencyInputMode: 'fixedAmount',
      splitEmergencyAmount: { amount: '0', display: '0 RON', editing: '' },
      splitEmergencyPercentage: 0.1,
      splitSavingsInputMode: 'fixedAmount',
      splitSavingsAmount: { amount: '0', display: '0 RON', editing: '' },
      splitSavingsPercentage: 0.15,
      isValid: true,
    },
  },
  accounts: [],
  expenses: [],
  categories: [
    { id: 'c1', name: 'Food/Groceries', icon: 'cart.fill', colorHex: '#22C55E', isDefault: true, sortOrder: 7 },
    { id: 'c2', name: 'Housing', icon: 'house.fill', colorHex: '#10B981', isDefault: true, sortOrder: 4 },
    { id: 'c3', name: 'Auto/Transport', icon: 'car.fill', colorHex: '#3B82F6', isDefault: true, sortOrder: 1 },
    { id: 'c4', name: 'Subscriptions', icon: 'arrow.triangle.2.circlepath', colorHex: '#8B5CF6', isDefault: true, sortOrder: 2 },
  ],
  reference: {
    accountTypes: [
      { value: 'primary', displayName: 'Primary', description: 'Where your salary lands', icon: 'building.columns.fill', hasBehavior: true, isUnique: false },
      { value: 'emergency', displayName: 'Emergency', description: 'Fills first until target reached', icon: 'shield.fill', hasBehavior: true, isUnique: true },
      { value: 'savings', displayName: 'Savings', description: 'Receives savings after emergency', icon: 'banknote.fill', hasBehavior: true, isUnique: false },
      { value: 'personal', displayName: 'Personal', description: 'Your flexible spending money', icon: 'person.fill', hasBehavior: true, isUnique: false },
      { value: 'joint', displayName: 'Joint', description: 'For shared expenses', icon: 'person.2.fill', hasBehavior: false, isUnique: false },
      { value: 'other', displayName: 'Other', description: 'Custom account', icon: 'creditcard.fill', hasBehavior: false, isUnique: false },
    ],
    frequencies: [],
    allocationModes: [
      { value: 'prioritized', displayName: 'Priority', description: 'Emergency fund fills first, then savings' },
      { value: 'split', displayName: 'Split', description: 'Fixed amounts to each account every month' },
    ],
    savingsInputModes: [
      { value: 'percentage', displayName: 'Percentage' },
      { value: 'fixedAmount', displayName: 'Fixed Amount' },
    ],
    remainingMoneyDestinations: [
      { value: 'primarySavings', displayName: 'Primary Savings', description: 'Add to your savings for future goals', icon: 'banknote.fill' },
      { value: 'personal', displayName: 'Personal Account', description: 'For flexible spending', icon: 'person.fill' },
      { value: 'primary', displayName: 'Keep in Primary', description: 'Leave in your main account', icon: 'building.columns.fill' },
    ],
    currencies: [
      { value: 'RON', symbol: 'lei', displayName: 'Romanian Leu (RON)' },
      { value: 'EUR', symbol: '€', displayName: 'Euro (EUR)' },
      { value: 'USD', symbol: '$', displayName: 'US Dollar (USD)' },
    ],
    savingsConstants: {
      minimumPercentage: 0.05,
      maximumPercentage: 0.5,
      recommendedPercentage: 0.25,
      presets: [0.1, 0.15, 0.2, 0.25, 0.3],
      defaultBoostMultiplier: 3,
      defaultEmergencyMultiplier: 3,
      emergencyMultiplierRange: [3, 6],
    },
    expenseIcons: [],
    defaultNewCategory: { icon: 'star.fill', colorHex: '#3B82F6', sortOrder: 100 },
    defaultExpenseIcon: 'dollarsign.circle.fill',
  },
  // Not read by onboarding, present so the object satisfies AppState.
  dashboard: {
    currentMonthDisplay: 'August 2026',
    summary: {
      income: { amount: '0', display: '0 RON', editing: '' },
      expenses: { amount: '0', display: '0 RON', editing: '' },
      savings: { amount: '0', display: '0 RON', editing: '' },
      personalSpending: { amount: '0', display: '0 RON', editing: '' },
    },
    otherAccounts: [],
    expenseBreakdown: [],
  },
  expensesScreen: {
    totalMonthly: { amount: '0', display: '0 RON', editing: '' },
    totalAnnual: { amount: '0', display: '0 RON', editing: '' },
    categories: [],
  },
  transferPlan: {
    income: { amount: '0', display: '0 RON', editing: '' },
    totalExpenses: { amount: '0', display: '0 RON', editing: '' },
    availableIncome: { amount: '0', display: '0 RON', editing: '' },
    totalSavings: { amount: '0', display: '0 RON', editing: '' },
    accountAllocations: [],
    remainsInPrimary: { amount: '0', display: '0 RON', editing: '' },
    accountExpenseTransfers: [],
    remainingMoney: { amount: '0', display: '0 RON', editing: '' },
    remainingDestination: 'primarySavings',
    remainingDestinationDisplayName: 'Primary Savings',
    isBalanced: true,
    hasAccountAllocations: false,
    totalAccountAllocations: { amount: '0', display: '0 RON', editing: '' },
    summary: '',
  },
} as unknown as AppState

function render(step: OnboardingStep): string {
  return renderToStaticMarkup(
    <LanguageProvider language="en" setLanguage={() => {}}>
      <OnboardingFlow state={STATE} onComplete={() => {}} initialStep={step} />
    </LanguageProvider>,
  )
}

describe('the flow is 7 screens with a 5-dot indicator', () => {
  it('has seven steps and five indicator steps, both derived', () => {
    expect(ONBOARDING_STEPS).toHaveLength(7)
    expect(ONBOARDING_INDICATOR_STEPS).toHaveLength(5)
  })

  it('renders every step without throwing', () => {
    for (const step of ONBOARDING_STEPS) {
      expect(render(step).length).toBeGreaterThan(0)
    }
  })

  it('hides the indicator on welcome and summary, and shows it on the middle five', () => {
    expect(render('welcome')).not.toContain('ob-progress')
    expect(render('summary')).not.toContain('ob-progress')
    for (const step of ONBOARDING_INDICATOR_STEPS) {
      expect(render(step)).toContain('ob-progress__dot')
    }
  })

  it('draws exactly as many dots as there are indicator steps', () => {
    // Matches the dot class exactly — not the `__dots` container, not the `--modifier`s.
    const dots = render('accounts').match(/ob-progress__dot(?=[ "])/g) ?? []
    expect(dots).toHaveLength(ONBOARDING_INDICATOR_STEPS.length)
  })

  it('marks accounts as the third of five dots', () => {
    // 04-onboarding-accounts.jpg: three filled dots, the third being current.
    const html = render('accounts')
    expect(html.match(/ob-progress__dot--completed/g) ?? []).toHaveLength(3)
    expect(html.match(/ob-progress__dot--current/g) ?? []).toHaveLength(1)
  })

  it('fills the whole track on savings, the fifth of five', () => {
    const html = render('savings')
    expect(html.match(/ob-progress__dot--completed/g) ?? []).toHaveLength(5)
  })
})

describe('screen content matches PARITY-SPEC §2', () => {
  it('welcome shows the title, the em-dash subtitle, three bullets and the CTA', () => {
    const html = render('welcome')
    expect(html).toContain('Take control of your money')
    expect(html).toContain('—') // the em dash is part of the string
    expect(html).toContain('Set savings goals that fill automatically')
    expect(html).toContain('Know exactly where to transfer your money')
    expect(html).toContain('Watch your progress grow')
    expect(html).toContain("Let&#x27;s Go")
  })

  it('name disables Continue until a name is typed', () => {
    expect(render('name')).toContain('disabled')
    expect(render('name')).toContain('What should we call you?')
  })

  it('income offers the currency picker — the only place currency can change', () => {
    const html = render('income')
    expect(html).toContain('Monthly net income')
    expect(html).toContain('RON')
    expect(html).toContain('EUR')
    expect(html).toContain('USD')
  })

  it('accounts shows both recommended prompts and the primary card', () => {
    const html = render('accounts')
    expect(html).toContain('Your Accounts')
    expect(html).toContain('Main Account')
    expect(html).toContain('Primary')
    expect(html).toContain('Emergency Fund')
    expect(html).toContain('Savings Account')
    expect(html).toContain('Add Another Account')
    expect(html).toContain('Your primary account is where your salary lands')
  })

  it('expenses seeds the four rows and both CTAs', () => {
    const html = render('expenses')
    for (const name of ['Food', 'Rent', 'Gas', 'Streaming']) expect(html).toContain(name)
    expect(html).toContain('Continue')
    expect(html).toContain('Skip for now')
    expect(html).toContain('By default, expenses are paid from your main account')
  })

  it('savings shows both segmented controls and the recommendation badge', () => {
    const html = render('savings')
    expect(html).toContain('Allocation Strategy')
    expect(html).toContain('Priority')
    expect(html).toContain('Split')
    expect(html).toContain('Monthly Savings')
    expect(html).toContain('Percentage')
    expect(html).toContain('Fixed Amount')
    // The percent label comes from the SERVER's percentageDisplay, never computed.
    expect(html).toContain('25')
    // The "Great savings rate!" badge is decided by the preview row's
    // `showsGreatRateBadge`, so it is deliberately absent with no preview — asserted
    // against the running server instead.
    expect(html).not.toContain('Great savings rate!')
  })

  it('summary renders its header and CTA even before the preview lands', () => {
    const html = render('summary')
    expect(html).toContain('Your First Month')
    expect(html).toContain('Start Using Diameris')
  })
})

describe('R13 — with no position table the slider degrades instead of computing', () => {
  it('renders no draggable range input, and says why', () => {
    const html = render('savings')
    expect(html).not.toContain('type="range"')
    expect(html).toContain('ob-blocked')
  })
})
