import { ref } from 'vue'
import { useRailsFetch } from '@/lib/composables/useRailsFetch'
import type { UnitFilterOption } from '@/types/visit'
import type { VisitHostOption, VisitInitialStatusPreview } from '@/lib/schemas/visit_create'

type FormUnitsResponse = {
  units: UnitFilterOption[]
}

type FormHostsResponse = {
  hosts: VisitHostOption[]
}

export function useAdminVisitFormData() {
  const { railsFetchJson } = useRailsFetch()

  const units = ref<UnitFilterOption[]>([])
  const hosts = ref<VisitHostOption[]>([])
  const initialStatusPreview = ref<VisitInitialStatusPreview | null>(null)

  const unitsLoading = ref(false)
  const hostsLoading = ref(false)
  const statusLoading = ref(false)

  async function fetchUnits(propertyId: string) {
    unitsLoading.value = true
    units.value = []
    hosts.value = []
    initialStatusPreview.value = null

    const params = new URLSearchParams()
    if (propertyId) params.set('residential_property_id', propertyId)

    try {
      const { res, data } = await railsFetchJson<FormUnitsResponse>(
        'GET',
        `/admin/visits/form_units?${params.toString()}`,
      )
      units.value = res.ok ? (data.units ?? []) : []
    } finally {
      unitsLoading.value = false
    }
  }

  async function fetchHosts(unitId: string) {
    if (!unitId) {
      hosts.value = []
      initialStatusPreview.value = null
      return
    }

    hostsLoading.value = true
    hosts.value = []
    initialStatusPreview.value = null

    try {
      const { res, data } = await railsFetchJson<FormHostsResponse>(
        'GET',
        `/admin/visits/form_hosts?unit_id=${encodeURIComponent(unitId)}`,
      )
      hosts.value = res.ok ? (data.hosts ?? []) : []
    } finally {
      hostsLoading.value = false
    }
  }

  async function fetchInitialStatusPreview(unitId: string) {
    if (!unitId) {
      initialStatusPreview.value = null
      return
    }

    statusLoading.value = true

    try {
      const { res, data } = await railsFetchJson<VisitInitialStatusPreview>(
        'GET',
        `/admin/visits/initial_status_preview?unit_id=${encodeURIComponent(unitId)}`,
      )
      initialStatusPreview.value = res.ok ? data : null
    } finally {
      statusLoading.value = false
    }
  }

  async function refreshLocationData(propertyId: string, unitId: string) {
    await fetchUnits(propertyId)
    if (unitId) {
      await Promise.all([fetchHosts(unitId), fetchInitialStatusPreview(unitId)])
    }
  }

  function resetLocationData() {
    units.value = []
    hosts.value = []
    initialStatusPreview.value = null
  }

  return {
    units,
    hosts,
    initialStatusPreview,
    unitsLoading,
    hostsLoading,
    statusLoading,
    fetchUnits,
    fetchHosts,
    fetchInitialStatusPreview,
    refreshLocationData,
    resetLocationData,
  }
}
