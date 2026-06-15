import assert from 'node:assert/strict'
import { describe, it } from 'node:test'

function dateInputFromIso(value) {
  if (!value) return ''
  if (/^\d{4}-\d{2}-\d{2}$/.test(value)) return value
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return value.slice(0, 10)
  return date.toISOString().slice(0, 10)
}

function occupancyToEditForm(occupancy) {
  return {
    occupancy_type: occupancy.occupancy_type,
    can_authorize_visits: occupancy.can_authorize_visits,
    starts_at: dateInputFromIso(occupancy.starts_at),
    ends_at: dateInputFromIso(occupancy.ends_at),
    status: occupancy.status === 'inactive' ? 'inactive' : 'active',
  }
}

describe('unit edit occupant drawer logic', () => {
  it('maps occupancy to edit form with normalized dates and status', () => {
    const form = occupancyToEditForm({
      id: '1',
      occupancy_type: 'tenant',
      occupancy_type_label: 'Arrendatario',
      can_authorize_visits: true,
      starts_at: '2026-06-01T00:00:00.000Z',
      ends_at: null,
      status: 'active',
      status_label: 'Activo',
      validity_state: 'current',
      person_id: 'p1',
      person_display_name: 'Jane Doe',
      person_document_type: null,
      person_document_number: '1-9',
      person_email: null,
    })

    assert.equal(form.occupancy_type, 'tenant')
    assert.equal(form.can_authorize_visits, true)
    assert.equal(form.starts_at, '2026-06-01')
    assert.equal(form.ends_at, '')
    assert.equal(form.status, 'active')
  })

  it('maps inactive status to inactive', () => {
    const form = occupancyToEditForm({
      id: '1',
      occupancy_type: 'tenant',
      occupancy_type_label: 'Arrendatario',
      can_authorize_visits: false,
      starts_at: '2026-01-01',
      ends_at: '2026-12-31',
      status: 'inactive',
      status_label: 'Inactivo',
      validity_state: 'inactive',
      person_id: 'p1',
      person_display_name: 'Jane Doe',
      person_document_type: null,
      person_document_number: null,
      person_email: null,
    })

    assert.equal(form.status, 'inactive')
    assert.equal(form.ends_at, '2026-12-31')
  })
})
