import { describe, expect, it } from 'vitest'
import {
  ONBOARDING_INDICATOR_STEPS,
  ONBOARDING_STEPS,
  dismissAllModals,
  dismissTopModal,
  goToTab,
  nextOnboardingStep,
  onboardingIndicator,
  presentModal,
  previousOnboardingStep,
  replaceTopModal,
  topModal,
  INITIAL_VIEW_STATE,
} from './viewState'

describe('onboarding: 7 screens, 5 dots', () => {
  it('has 7 screens in presentation order', () => {
    expect(ONBOARDING_STEPS).toEqual([
      'welcome',
      'name',
      'income',
      'accounts',
      'expenses',
      'savings',
      'summary',
    ])
  })

  it('shows no indicator on welcome or summary', () => {
    expect(onboardingIndicator('welcome')).toBeNull()
    expect(onboardingIndicator('summary')).toBeNull()
    expect(ONBOARDING_INDICATOR_STEPS).toHaveLength(5)
  })

  it('matches the reference screens: accounts is 3 of 5, savings is 5 of 5', () => {
    expect(onboardingIndicator('accounts')).toEqual({ position: 3, total: 5 })
    expect(onboardingIndicator('savings')).toEqual({ position: 5, total: 5 })
    expect(onboardingIndicator('name')).toEqual({ position: 1, total: 5 })
  })

  it('navigates forward and back, stopping at the ends', () => {
    expect(nextOnboardingStep('welcome')).toBe('name')
    expect(nextOnboardingStep('summary')).toBeNull()
    expect(previousOnboardingStep('name')).toBe('welcome')
    expect(previousOnboardingStep('welcome')).toBeNull()
  })
})

describe('modal stack', () => {
  it('starts empty and loading', () => {
    expect(INITIAL_VIEW_STATE.route.kind).toBe('loading')
    expect(INITIAL_VIEW_STATE.modals).toEqual([])
  })

  it('nests modals the way iOS does: Settings -> account editor', () => {
    let state = goToTab(INITIAL_VIEW_STATE, 'dashboard')
    state = presentModal(state, { kind: 'settings' })
    state = presentModal(state, { kind: 'accountEditor', accountId: 'abc' })
    expect(state.modals).toHaveLength(2)
    expect(topModal(state)).toEqual({ kind: 'accountEditor', accountId: 'abc' })

    state = dismissTopModal(state)
    expect(topModal(state)).toEqual({ kind: 'settings' })
  })

  it('nests expense sheet -> add category', () => {
    let state = presentModal(INITIAL_VIEW_STATE, { kind: 'expenseSheet' })
    state = presentModal(state, { kind: 'addCategory' })
    expect(state.modals.map((m) => m.kind)).toEqual(['expenseSheet', 'addCategory'])
  })

  it('steps New Month in place rather than stacking three modals', () => {
    let state = presentModal(INITIAL_VIEW_STATE, { kind: 'newMonth', step: 1 })
    state = replaceTopModal(state, { kind: 'newMonth', step: 2 })
    state = replaceTopModal(state, { kind: 'newMonth', step: 3 })
    expect(state.modals).toEqual([{ kind: 'newMonth', step: 3 }])
  })

  it('dismisses everything at once', () => {
    let state = presentModal(INITIAL_VIEW_STATE, { kind: 'settings' })
    state = presentModal(state, { kind: 'addAccount' })
    expect(dismissAllModals(state).modals).toEqual([])
  })

  it('changing tab keeps the route but does not resurrect modals', () => {
    const state = goToTab(dismissAllModals(INITIAL_VIEW_STATE), 'expenses')
    expect(state.route).toEqual({ kind: 'main', tab: 'expenses' })
    expect(state.modals).toEqual([])
  })
})
