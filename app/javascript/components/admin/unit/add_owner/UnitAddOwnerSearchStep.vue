<template>
  <div class="space-y-6">
    <div class="space-y-1">
      <h3 class="text-base font-semibold">
        {{ t('admin.units.show.owners.add_owner.search.title') }}
      </h3>
      <p class="text-sm text-muted-foreground">
        {{ t('admin.units.show.owners.add_owner.search.description') }}
      </p>
    </div>

    <div class="flex gap-2">
      <Input
        v-model="search"
        type="search"
        :placeholder="t('admin.units.show.owners.add_owner.search.placeholder')"
        @keydown.enter.prevent="onSearch"
      />
      <Button type="button" variant="outline" :disabled="loading" @click="onSearch">
        <Search class="size-4" />
        {{ t('common.actions.search') }}
      </Button>
    </div>

    <div class="space-y-3">
      <p class="text-sm font-medium">
        {{ t('admin.units.show.owners.add_owner.search.results_title') }}
      </p>

      <div v-if="loading" class="text-sm text-muted-foreground">
        {{ t('admin.units.show.owners.add_owner.search.loading') }}
      </div>

      <div
        v-else-if="people.length === 0"
        class="rounded-lg border border-dashed p-4 text-sm text-muted-foreground"
      >
        {{ t('admin.units.show.owners.add_owner.search.empty') }}
      </div>

      <div v-else class="space-y-2">
        <button
          v-for="person in people"
          :key="person.id"
          type="button"
          class="flex w-full items-center gap-3 rounded-lg border bg-card p-4 text-left transition-colors hover:bg-muted/40 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
          @click="emit('select-person', person)"
        >
          <Avatar class="size-10">
            <AvatarFallback>{{ personInitials(person.display_name) }}</AvatarFallback>
          </Avatar>
          <span class="min-w-0 flex-1">
            <span class="block text-sm font-semibold">{{ person.display_name }}</span>
            <span class="block text-xs text-muted-foreground">
              {{ person.document_number || '—' }}
              <span v-if="person.email"> · {{ person.email }}</span>
            </span>
          </span>
          <ChevronRight class="size-5 shrink-0 text-muted-foreground" aria-hidden="true" />
        </button>
      </div>
    </div>

    <DataTablePagination
      v-if="paginationMeta"
      :current-page="currentPage"
      :total-pages="totalPages"
      :total-items="totalItems"
      :items-per-page="itemsPerPage"
      :items-per-page-options="itemsPerPageOptions"
      :on-page-change="handlePageChange"
      :on-items-per-page-change="handleItemsPerPageChange"
    />

    <div class="flex items-center justify-between gap-3 border-t pt-4">
      <p class="text-sm text-muted-foreground">
        {{ t('admin.units.show.owners.add_owner.search.not_found_prompt') }}
      </p>
      <Button type="button" variant="outline" @click="emit('create-person')">
        {{ t('admin.units.show.owners.add_owner.search.create_new') }}
      </Button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { ChevronRight, Search } from 'lucide-vue-next'
import DataTablePagination from '@/components/admin/table/DataTablePagination.vue'
import { Avatar, AvatarFallback } from '@/components/ui/avatar'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { useUnitAddOwnerPeopleSearch } from '@/lib/composables/unit/useUnitAddOwnerPeopleSearch'
import { useTable } from '@/lib/composables/useTable'
import { personInitials } from '@/lib/utils/unit'
import type { Person } from '@/types/person'

const emit = defineEmits<{
  (e: 'select-person', person: Person): void
  (e: 'create-person'): void
}>()

const { t } = useI18n()
const { people, pagination, loading, search: fetchPeople } = useUnitAddOwnerPeopleSearch()

const fetchData = (query: string, page: number, itemsPerPage: number) => {
  fetchPeople(query, page, itemsPerPage)
}

const {
  currentPage,
  totalPages,
  totalItems,
  itemsPerPage,
  itemsPerPageOptions,
  search,
  handlePageChange,
  handleItemsPerPageChange,
  setPagination,
  triggerSearch,
} = useTable(fetchData, { skipInitialFetch: true })

const paginationMeta = pagination

function onSearch() {
  currentPage.value = 1
  triggerSearch()
}

watch(pagination, (meta) => {
  if (meta) setPagination(meta)
})

onMounted(() => {
  fetchPeople('', 1, itemsPerPage.value)
})
</script>
