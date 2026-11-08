/**
 * Insights tab — PARITY-SPEC §6.
 *
 * `MainTabView.swift:337-357`. A placeholder and nothing else: a 64pt `lightbulb.max` in
 * accentPrimary, "Insights" as `.title .bold`, "Coming soon" as `.subheadline .secondary`.
 * It stands in for the whole of `Docs/MVP/10-BudgetAnalysis.md`, none of which ships.
 *
 * Resisting the urge to put something useful here IS the parity requirement.
 */

import { useT } from '../../lib/i18n'
import { Symbol } from '../../lib/icons'
import './insights.css'

export function InsightsScreen() {
  const t = useT('app')
  return (
    <div className="insights" data-testid="screen-insights">
      <Symbol name="lightbulb.max" size="var(--icon-xxl)" />
      <h1 className="insights__title">{t('Insights')}</h1>
      <p className="insights__body">{t('Coming soon')}</p>
    </div>
  )
}
