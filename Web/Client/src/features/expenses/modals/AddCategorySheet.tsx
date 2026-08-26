/**
 * `AddCategorySheet` — PARITY-SPEC §5.5, reference `16-new-category-sheet.jpg`.
 *
 * Cancel / **New Category** / Add, with Add disabled until the name is non-empty.
 * Sections: Category Name · Icon (12) · Color (10) · Preview.
 *
 * ⚠️ **The icon grid here is a DIFFERENT list from Add Expense's 37** — they overlap on
 * only five symbols, and `calendar` is in this set and absent from that one. Both come
 * from `reference` (R12); sharing one array silently breaks whichever screen loses.
 */

import { useState } from 'react'
import { api, type AppState, type SFSymbol, type Uuid } from '../../../lib/api'
import { useT } from '../../../lib/i18n'
import { Symbol } from '../../../lib/icons'
import { ColorGrid, IconGrid, Sheet, TextField } from '../../../ui'
import './modals.css'

/**
 * R12's two category palettes. The server has served them since 2026-08-06 (12 icons, 10
 * colours, verified over HTTP) but `api.ts`'s `Reference` does not type them yet — asked
 * Frontend. Written as an intersection so it resolves silently when they land, rather than
 * failing to compile the way an `extends` would.
 */
type ReferenceWithPalettes = AppState['reference'] & {
  readonly categoryIcons?: readonly SFSymbol[]
  readonly categoryColors?: readonly string[]
}

export interface AddCategorySheetProps {
  state: AppState
  onClose: () => void
  /** The server returns the whole state; the new id is resolved from it. */
  onCreated: (state: AppState, categoryId: Uuid) => void
}

export function AddCategorySheet({ state, onClose, onCreated }: AddCategorySheetProps) {
  const t = useT('expenses')
  const reference = state.reference as ReferenceWithPalettes
  const defaults = reference.defaultNewCategory
  const [name, setName] = useState('')
  const [icon, setIcon] = useState(defaults.icon)
  const [colorHex, setColorHex] = useState(defaults.colorHex)
  const [busy, setBusy] = useState(false)

  const trimmed = name.trim()

  const add = () => {
    setBusy(true)
    api
      .createCategory({ name: trimmed, icon, colorHex })
      .then((next) => {
        /*
         * `POST /api/categories` returns the whole `AppState`, not the created row, so the
         * new id is found by difference against the ids we already had. Matching on name
         * would be wrong: iOS has **no uniqueness check** (§5.5), so a second "Travel" is
         * perfectly legal and would resolve to the first one.
         */
        const before = new Set(state.categories.map((category) => category.id))
        const created = next.categories.find((category) => !before.has(category.id))
        onCreated(next, created?.id ?? '')
      })
      .finally(() => setBusy(false))
  }

  return (
    <Sheet
      title={t('New Category')}
      cancelLabel={t('Cancel')}
      confirmLabel={t('Add')}
      confirmDisabled={trimmed === '' || busy}
      onCancel={onClose}
      onConfirm={add}
    >
      <div className="xm-form" data-testid="new-category-sheet">
        <section className="xm-section">
          <h3 className="xm-section__header">{t('Category Name')}</h3>
          <div className="xm-card">
            <TextField
              value={name}
              onChange={setName}
              placeholder={t('Name')}
              ariaLabel={t('Category Name')}
              testId="new-category-name"
            />
          </div>
        </section>

        <section className="xm-section">
          <h3 className="xm-section__header">{t('Icon')}</h3>
          <div className="xm-card" data-testid="new-category-icon-grid">
            {/* 12 symbols — `reference.categoryIcons`, NOT `expenseIcons`. */}
            <IconGrid
              symbols={reference.categoryIcons ?? []}
              value={icon}
              onChange={setIcon}
              ariaLabel={t('Icon')}
              cellTestId={(symbol) => `new-category-icon-${symbol}`}
            />
          </div>
        </section>

        <section className="xm-section">
          <h3 className="xm-section__header">{t('Color')}</h3>
          <div className="xm-card" data-testid="new-category-color-swatches">
            {/* 10 swatches, server-served. R22: never a second copy in CSS. */}
            <ColorGrid
              colors={reference.categoryColors ?? []}
              value={colorHex}
              onChange={setColorHex}
              ariaLabel={t('Color')}
              cellTestId={(hex) => `new-category-color-${hex.slice(1).toLowerCase()}`}
            />
          </div>
        </section>

        <section className="xm-section">
          <h3 className="xm-section__header">{t('Preview')}</h3>
          <div className="xm-card">
            <div className="xm-preview" data-testid="new-category-preview">
              <span
                className="xm-preview__icon"
                style={{ color: colorHex }}
                data-testid="new-category-preview-icon"
                data-symbol={icon}
              >
                <Symbol name={icon} size="var(--font-title2-size)" />
              </span>
              {/* The placeholder reuses the section-header string, exactly as iOS does. */}
              <span className="xm-preview__name" data-testid="new-category-preview-label">
                {trimmed === '' ? t('Category Name') : name}
              </span>
            </div>
          </div>
        </section>
      </div>
    </Sheet>
  )
}
