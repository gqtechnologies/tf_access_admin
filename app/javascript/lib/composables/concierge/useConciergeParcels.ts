import { ref } from 'vue'
import { router } from '@inertiajs/vue3'
import { concierge_parcels_path, withdraw_concierge_parcel_path } from '@/routes'
import type { ConciergeParcel, ParcelReceivePayload, ParcelTab } from '@/types/parcel'

type ListQuery = {
  search: string
  page: number
  itemsPerPage: number
  tab: ParcelTab
  propertyId?: string | null
}

const LIST_PROPS = [
  'parcels',
  'pagination',
  'counters',
  'tab',
  'query',
  'properties',
  'active_property',
  'units',
]

export function useConciergeParcelsList(initialTab: ParcelTab = 'received') {
  const activeTab = ref<ParcelTab>(initialTab)

  function fetchParcels({ search, page, itemsPerPage, tab, propertyId }: ListQuery) {
    activeTab.value = tab

    const params: Record<string, string | number | Record<string, string>> = {
      page,
      per_page: itemsPerPage,
      tab,
    }

    const trimmedSearch = search.trim()
    if (trimmedSearch) params.q = { query: trimmedSearch }
    if (propertyId) params.property_id = propertyId

    router.get(concierge_parcels_path(), params, {
      preserveState: true,
      preserveScroll: true,
      only: LIST_PROPS,
    })
  }

  return { activeTab, fetchParcels }
}

// Posts for the two front-desk mutations. Both redirect back to the list; a
// rejection comes back as Inertia `errors`, surfaced here as plain messages.
export function useConciergeParcelSubmit() {
  const submitting = ref(false)
  const errors = ref<string[]>([])

  function post(url: string, data: Record<string, unknown>, onSuccess?: () => void) {
    submitting.value = true
    errors.value = []

    router.post(url, data as never, {
      preserveScroll: true,
      onSuccess: () => onSuccess?.(),
      onError: (errs) => {
        errors.value = Object.values(errs as Record<string, string | string[]>).flatMap((value) =>
          Array.isArray(value) ? value : [value],
        )
      },
      onFinish: () => {
        submitting.value = false
      },
    })
  }

  function submitReceive(
    context: { propertyId: string; tab: ParcelTab },
    parcel: ParcelReceivePayload,
    onSuccess?: () => void,
  ) {
    post(concierge_parcels_path(), { property_id: context.propertyId, tab: context.tab, parcel }, onSuccess)
  }

  function submitWithdraw(
    parcel: ConciergeParcel,
    context: { personId: string; tab: ParcelTab },
    onSuccess?: () => void,
  ) {
    post(
      withdraw_concierge_parcel_path(parcel.id),
      { person_id: context.personId, tab: context.tab },
      onSuccess,
    )
  }

  return { submitting, errors, submitReceive, submitWithdraw }
}
