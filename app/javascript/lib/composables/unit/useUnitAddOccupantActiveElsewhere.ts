import { ref } from 'vue'
import { useRailsFetch } from '@/lib/composables/useRailsFetch'
import { adminResidentialPropertyUnitOccupanciesActiveElsewherePath } from '@/lib/paths/unit_occupancies'
import type { ActiveElsewhereOccupancy } from '@/types/unit'

type ActiveElsewhereResponse = {
  active_elsewhere_occupancies: ActiveElsewhereOccupancy[]
}

export function useUnitAddOccupantActiveElsewhere() {
  const { railsFetchJson } = useRailsFetch()
  const occupancies = ref<ActiveElsewhereOccupancy[]>([])
  const loading = ref(false)

  async function fetchForPerson(
    residentialPropertyId: string,
    unitId: string,
    personId: string,
  ) {
    loading.value = true

    try {
      const { res, data } = await railsFetchJson<ActiveElsewhereResponse>(
        'GET',
        adminResidentialPropertyUnitOccupanciesActiveElsewherePath(
          residentialPropertyId,
          unitId,
          personId,
        ),
      )

      if (!res.ok) {
        occupancies.value = []
        return
      }

      occupancies.value = data.active_elsewhere_occupancies ?? []
    } finally {
      loading.value = false
    }
  }

  function reset() {
    occupancies.value = []
  }

  return {
    occupancies,
    loading,
    fetchForPerson,
    reset,
  }
}
