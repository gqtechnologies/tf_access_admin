<script setup lang="ts" generic="T extends { id: string }">
import { computed, ref, useAttrs, watch } from 'vue'
import { ChevronsUpDown, Check } from 'lucide-vue-next'
import { cn } from '@/lib/utils'
import { Button } from '@/components/ui/button'
import SearchablePopoverSelectLayout from '@/components/custom/inputs/SearchablePopoverSelectLayout.vue'
import {
  useAsyncPaginatedSelect,
  type AsyncPaginatedFetcher,
} from '@/lib/composables/useAsyncPaginatedSelect'

defineOptions({ inheritAttrs: false })

const props = withDefaults(
  defineProps<{
    id?: string
    /** Carga paginada; recibe `search` ya debounced desde el composable interno. */
    fetchPage: AsyncPaginatedFetcher<T>
    /** Query params fijos en cada petición (además de los que añada el fetcher). */
    defaultQueryParams?: Record<string, string>
    /** Opciones extra con etiqueta conocida (p. ej. ítems ya seleccionados y no en la página actual). */
    seeds?: T[] | null
    multiple?: boolean
    getOptionLabel?: (item: T) => string
    perPage?: number
    debounceMs?: number
    /** Valor controlado si no usas vee-validate `v-bind="field"` */
    modelValue?: string | string[] | null
    placeholder?: string
    searchLabel?: string
    searchPlaceholder?: string
    listLabel?: string
    emptyText?: string
    loadingText?: string
    clearText?: string
    /** Texto cuando `multiple` y hay varios ítems (recibe número seleccionado). */
    multipleSelectedText?: (count: number) => string
    closeOnSelect?: boolean
    maxSelections?: number
  }>(),
  {
    id: undefined,
    defaultQueryParams: () => ({}),
    seeds: null,
    multiple: false,
    getOptionLabel: undefined,
    perPage: 20,
    debounceMs: 300,
    modelValue: undefined,
    placeholder: 'Select…',
    searchLabel: 'Search',
    searchPlaceholder: 'Search…',
    listLabel: 'Options',
    emptyText: 'No results.',
    loadingText: 'Loading…',
    clearText: 'Clear selection',
    multipleSelectedText: undefined,
    closeOnSelect: undefined,
    maxSelections: undefined,
  },
)

const emit = defineEmits<{
  'update:modelValue': [value: string | string[] | undefined]
}>()

const attrs = useAttrs() as {
  value?: string | string[] | undefined
  onChange?: (e: unknown) => void
  'onUpdate:modelValue'?: (v: string | string[] | undefined) => void
  'aria-invalid'?: boolean | string
  class?: string
  [key: string]: unknown
}

const open = ref(false)

const {
  search,
  loading,
  displayItems,
  setSeeds,
  resetAndFetch,
  onListScroll,
} = useAsyncPaginatedSelect<T>(props.fetchPage, {
  perPage: props.perPage,
  debounceMs: props.debounceMs,
  extraParams: () => props.defaultQueryParams ?? {},
})

watch(
  () => props.seeds,
  (s) => setSeeds(s ?? null),
  { immediate: true, deep: true },
)

watch(open, (isOpen) => {
  if (isOpen) void resetAndFetch()
})

function defaultLabel(item: T): string {
  const o = item as Record<string, unknown>
  return typeof o.name === 'string' ? o.name : String(item.id)
}

function labelOf(item: T): string {
  return (props.getOptionLabel ?? defaultLabel)(item)
}

const resolvedCloseOnSelect = computed(
  () => props.closeOnSelect ?? !props.multiple,
)

const currentValue = computed(() => {
  const fromAttrs = attrs.value
  if (fromAttrs !== undefined) return fromAttrs
  return props.modelValue
})

const selectedIds = computed(() => {
  const v = currentValue.value
  if (props.multiple) {
    return Array.isArray(v) ? v.filter(Boolean) : []
  }
  return typeof v === 'string' && v ? [v] : []
})

function labelForId(id: string): string {
  const row = displayItems.value.find((i) => i.id === id)
  if (row) return labelOf(row)
  const fromSeeds = (props.seeds ?? []).find((i) => i.id === id)
  if (fromSeeds) return labelOf(fromSeeds)
  return id
}

const triggerSummary = computed(() => {
  const ids = selectedIds.value
  if (ids.length === 0) return ''
  if (!props.multiple) return labelForId(ids[0]!)
  if (ids.length === 1) return labelForId(ids[0]!)
  if (props.multipleSelectedText) return props.multipleSelectedText(ids.length)
  const labels = ids.map(labelForId)
  const joined = labels.join(', ')
  return joined.length > 40 ? `${ids.length} selected` : joined
})

function emitValue(v: string | string[] | undefined) {
  const fn = attrs['onUpdate:modelValue']
  if (typeof fn === 'function') fn(v)
  else attrs.onChange?.(v)
  emit('update:modelValue', v)
}

function isSelected(id: string): boolean {
  return selectedIds.value.includes(id)
}

function selectItem(item: T) {
  if (props.multiple) {
    const ids = [...selectedIds.value]
    const i = ids.indexOf(item.id)
    if (i >= 0) ids.splice(i, 1)
    else {
      if (props.maxSelections != null && ids.length >= props.maxSelections) return
      ids.push(item.id)
    }
    emitValue(ids)
  } else {
    emitValue(item.id)
  }
  if (resolvedCloseOnSelect.value) open.value = false
}

function clearSelection() {
  emitValue(props.multiple ? [] : undefined)
}

const searchInputId = computed(() => `${props.id ?? 'async-select'}-search`)

const triggerRest = computed(() => {
  const {
    value: _v,
    onChange: _oc,
    'onUpdate:modelValue': _u,
    class: _c,
    ...rest
  } = attrs
  return rest
})

const showEmptyState = computed(
  () => !loading.value && displayItems.value.length === 0,
)

const showClear = computed(
  () =>
    props.multiple ? selectedIds.value.length > 0 : Boolean(selectedIds.value[0]),
)
</script>

<template>
  <SearchablePopoverSelectLayout
    v-model:open="open"
    v-model:search="search"
    :search-input-id="searchInputId"
    :search-label="searchLabel"
    :search-placeholder="searchPlaceholder"
    :list-aria-label="listLabel"
    :loading="loading"
    :show-empty-state="showEmptyState"
    :empty-text="emptyText"
    :loading-text="loadingText"
    @scroll="onListScroll"
  >
    <template #trigger="{ open: isOpen }">
      <Button
        :id="id"
        type="button"
        variant="outline"
        role="combobox"
        :aria-expanded="isOpen"
        :aria-invalid="attrs['aria-invalid']"
        :class="cn('w-full min-w-[220px] justify-between font-normal', attrs.class)"
        v-bind="triggerRest"
      >
        <span class="truncate text-left">
          {{ triggerSummary || placeholder }}
        </span>
        <ChevronsUpDown class="ml-2 size-4 shrink-0 opacity-50" />
      </Button>
    </template>
    <template #before-options>
      <button
        v-if="showClear"
        type="button"
        class="text-muted-foreground hover:bg-accent hover:text-accent-foreground mb-1 w-full rounded-sm px-2 py-1.5 text-left text-sm"
        @click="clearSelection"
      >
        {{ clearText }}
      </button>
    </template>
    <template #options>
      <button
        v-for="item in displayItems"
        :key="item.id"
        type="button"
        role="option"
        :aria-selected="isSelected(item.id)"
        class="hover:bg-accent hover:text-accent-foreground flex w-full items-center gap-2 rounded-sm px-2 py-1.5 text-left text-sm"
        :class="isSelected(item.id) ? 'bg-accent' : ''"
        @click="selectItem(item)"
      >
        <Check
          v-if="multiple"
          class="size-4 shrink-0"
          :class="isSelected(item.id) ? 'opacity-100' : 'opacity-0'"
          aria-hidden="true"
        />
        <span class="truncate">{{ labelOf(item) }}</span>
      </button>
    </template>
  </SearchablePopoverSelectLayout>
</template>
