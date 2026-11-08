/**
 * `CategoryManagementView` — PARITY-SPEC §5.4, reference `15-manage-categories.jpg`.
 *
 * `Done` / **Categories** / `+`. Section "Default Categories" lists all **8** defaults even
 * when they have no expenses; "Custom Categories" appears only when there are any.
 *
 * Two shipped behaviours reproduced deliberately:
 *  - **Rows are not tappable.** Categories cannot be renamed or edited — only created and
 *    deleted. An "edit" affordance would be an invention.
 *  - **Deleting a custom category has no confirmation and no reassignment.** Its expenses
 *    keep the dangling id and fall into the "Uncategorized" group (§5.2). `Docs/MVP/04:474`
 *    says they should become uncategorized properly; the code does not. R26a: mirror it.
 */

import { useState } from 'react'
import { api, type AppState, type Uuid } from '../../../lib/api'
import { useT } from '../../../lib/i18n'
import { Symbol } from '../../../lib/icons'
import { slugify } from '../../../lib/testid'
import { PillButton, Sheet } from '../../../ui'
import { AddCategorySheet } from './AddCategorySheet'
import { customCategories, defaultCategories } from './categoryOrder'
import './modals.css'

export interface CategoryManagementViewProps {
  state: AppState
  onClose: () => void
  onChanged: (state: AppState) => void
}

export function CategoryManagementView({
  state,
  onClose,
  onChanged,
}: CategoryManagementViewProps) {
  const t = useT('expenses')
  const [adding, setAdding] = useState(false)
  const [busy, setBusy] = useState(false)

  const defaults = defaultCategories(state.categories)
  const customs = customCategories(state.categories)

  const remove = (categoryId: Uuid) => {
    // No confirmation dialog — iOS deletes on the swipe action immediately (§5.4).
    setBusy(true)
    api
      .deleteCategory(categoryId)
      .then(onChanged)
      .finally(() => setBusy(false))
  }

  return (
    <>
      <Sheet
        title={t('Categories')}
        cancelLabel={t('Done')}
        onCancel={onClose}
        header={
          <div className="sheet__header">
            <span className="sheet__action--start">
              <PillButton variant="glass" size="small" testId="manage-categories-done" onClick={onClose}>
                {t('Done')}
              </PillButton>
            </span>
            <span className="sheet__title">{t('Categories')}</span>
            <span className="sheet__action--end">
              <PillButton
                variant="glass"
                size="small"
                icon="plus"
                ariaLabel={t('New Category')}
                testId="manage-categories-add"
                onClick={() => setAdding(true)}
              >
                {''}
              </PillButton>
            </span>
          </div>
        }
      >
        <div className="xm-form" data-testid="manage-categories-sheet">
          <section className="xm-section">
            <h3 className="xm-section__header">{t('Default Categories')}</h3>
            <div className="xm-card xm-card--rows">
              {defaults.map((category) => (
                <CategoryRow
                  key={category.id}
                  category={category}
                  isDefault
                  onDelete={undefined}
                  t={t}
                />
              ))}
            </div>
            <p className="xm-section__footer">{t('Default categories cannot be deleted.')}</p>
          </section>

          {customs.length > 0 && (
            <section className="xm-section">
              <h3 className="xm-section__header">{t('Custom Categories')}</h3>
              <div className="xm-card xm-card--rows">
                {customs.map((category) => (
                  <CategoryRow
                    key={category.id}
                    category={category}
                    isDefault={false}
                    t={t}
                    onDelete={busy ? undefined : () => remove(category.id)}
                  />
                ))}
              </div>
            </section>
          )}
        </div>
      </Sheet>

      {adding && (
        <AddCategorySheet
          state={state}
          onClose={() => setAdding(false)}
          onCreated={(next) => {
            onChanged(next)
            setAdding(false)
          }}
        />
      )}
    </>
  )
}

function CategoryRow({
  category,
  isDefault,
  onDelete,
  t,
}: {
  category: AppState['categories'][number]
  isDefault: boolean
  /** `undefined` while a delete is in flight — the key is required, the value nullable. */
  onDelete: (() => void) | undefined
  t: (key: string) => string
}) {
  return (
    // A plain row, NOT a button: iOS categories are not editable (§5.4).
    <div className="xm-category-row" data-testid={`category-row-${slugify(category.name)}`}>
      <span className="xm-category-row__icon" style={{ color: category.colorHex }}>
        <Symbol name={category.icon} size="var(--font-title2-size)" />
      </span>
      {/* Category names are RAW literals in Domain (`Category.swift:63-133`, no
          `.localized`), so they are English on iOS too — never run them through t(). */}
      <span className="xm-category-row__name">{category.name}</span>
      {isDefault ? (
        <span
          className="xm-default-pill"
          data-testid={`category-default-pill-${slugify(category.name)}`}
        >
          {t('Default')}
        </span>
      ) : (
        onDelete && (
          <button
            type="button"
            className="xm-category-row__delete"
            aria-label={t('Delete')}
            data-testid={`category-delete-${slugify(category.name)}`}
            onClick={onDelete}
          >
            <Symbol name="trash" size="var(--icon-sm)" />
          </button>
        )
      )}
    </div>
  )
}
