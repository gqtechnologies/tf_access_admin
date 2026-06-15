import assert from 'node:assert/strict'
import { describe, it } from 'node:test'

// Pure logic mirrored from useUnitAddOccupantDrawer for step navigation tests.
function resolveVisibleSteps(flow) {
  if (flow === 'search') return ['choose', 'search', 'assign', 'confirm']
  if (flow === 'create') return ['choose', 'create', 'assign', 'confirm']
  return ['choose']
}

function resolveBackStep(currentStep, flow) {
  if (currentStep === 'confirm') return 'assign'
  if (currentStep === 'assign') return flow === 'create' ? 'create' : 'search'
  if (currentStep === 'search' || currentStep === 'create') return 'choose'
  return null
}

function isOccupancyDrawerError(errors) {
  if (!errors || Object.keys(errors).length === 0) return false

  const keys = [
    'occupancy_type',
    'starts_at',
    'ends_at',
    'person_id',
    'base',
    'document_number',
    'email',
    'display_name',
    'first_name',
    'last_name',
    'can_authorize_visits',
  ]

  return Object.keys(errors).some((key) => keys.includes(key))
}

describe('unit add occupant drawer logic', () => {
  it('resolves visible steps for search flow', () => {
    assert.deepEqual(resolveVisibleSteps('search'), ['choose', 'search', 'assign', 'confirm'])
  })

  it('resolves visible steps for create flow', () => {
    assert.deepEqual(resolveVisibleSteps('create'), ['choose', 'create', 'assign', 'confirm'])
  })

  it('navigates back from confirm to assign', () => {
    assert.equal(resolveBackStep('confirm', 'search'), 'assign')
  })

  it('navigates back from assign to search or create depending on flow', () => {
    assert.equal(resolveBackStep('assign', 'search'), 'search')
    assert.equal(resolveBackStep('assign', 'create'), 'create')
  })

  it('navigates back from search/create to choose', () => {
    assert.equal(resolveBackStep('search', 'search'), 'choose')
    assert.equal(resolveBackStep('create', 'create'), 'choose')
  })

  it('detects occupancy drawer inertia errors', () => {
    assert.equal(isOccupancyDrawerError({ occupancy_type: ['invalid'] }), true)
    assert.equal(isOccupancyDrawerError({ unrelated: ['nope'] }), false)
    assert.equal(isOccupancyDrawerError(undefined), false)
  })
})
