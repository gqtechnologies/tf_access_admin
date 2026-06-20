import { ref } from 'vue'
import { router } from '@inertiajs/vue3'
import type { ConciergeVisitTab } from '@/types/visit'

type ListQuery = {
  search: string
  page: number
  itemsPerPage: number
  tab: ConciergeVisitTab
  visitType: string
}

export function useConciergeVisitsList(initialTab: ConciergeVisitTab = 'authorized') {
  const activeTab = ref<ConciergeVisitTab>(initialTab)
  const visitTypeFilter = ref('')

  function buildQueryParams({ search, page, itemsPerPage, tab, visitType }: ListQuery) {
    const q: Record<string, string> = {}

    if (search.trim()) {
      q.visitor_person_display_name_or_host_person_display_name_or_unit_identifier_cont = search.trim()
    }
    if (visitType) {
      q.visit_type_eq = visitType
    }

    return {
      page,
      per_page: itemsPerPage,
      tab,
      q,
    }
  }

  function fetchVisits(query: ListQuery) {
    activeTab.value = query.tab
    visitTypeFilter.value = query.visitType

    router.get('/concierge/visits', buildQueryParams(query), {
      preserveState: true,
      preserveScroll: true,
      only: ['visits', 'pagination', 'counters', 'tab', 'filters'],
    })
  }

  function refreshList() {
    router.reload({
      only: ['visits', 'pagination', 'counters', 'tab', 'filters'],
    })
  }

  return {
    activeTab,
    visitTypeFilter,
    fetchVisits,
    refreshList,
  }
}
