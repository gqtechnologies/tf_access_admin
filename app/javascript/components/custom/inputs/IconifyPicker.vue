<script setup lang="ts">
import { computed, onBeforeUnmount, ref, watch } from "vue";
import { Icon } from "@iconify/vue";
import { ChevronsUpDown, Loader2, Search, X } from "lucide-vue-next";
import { useI18n } from "vue-i18n";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover";

const props = defineProps<{
  modelValue?: string | null
  placeholder?: string
}>();

const emit = defineEmits<{
  (e: "update:modelValue", payload: string | null): void
}>();
const { t } = useI18n();

const open = ref(false);
const searchQuery = ref("");
const icons = ref<{ id: string; name: string }[]>([]);
const loading = ref(false);
const fetchError = ref<string | null>(null);
const searchInputId = "iconify-picker-search";
const currentPage = ref(1);
const hasNextPage = ref(false);
const pageSize = 48;

let timeout: ReturnType<typeof setTimeout> | undefined;
let activeController: AbortController | null = null;

const selectedIcon = computed(() => props.modelValue ?? "");
const hasResults = computed(() => icons.value.length > 0);

const loadIcons = async ({ append = false }: { append?: boolean } = {}) => {
  const query = searchQuery.value.trim();
  const pageToLoad = append ? currentPage.value + 1 : 1;

  activeController?.abort();
  activeController = new AbortController();
  loading.value = true;
  fetchError.value = null;

  try {
    const params = new URLSearchParams({
      page: String(pageToLoad),
      per_page: String(pageSize),
    });
    if (query.length > 0) params.set("q", query);

    const response = await fetch(`/admin/icons?${params.toString()}`, {
      headers: { Accept: "application/json" },
      signal: activeController.signal,
    });

    if (!response.ok) {
      throw new Error(`Icon catalog request failed with status ${response.status}`);
    }

    const data = await response.json();
    const incoming = Array.isArray(data?.icons)
      ? data.icons.filter((item: unknown) =>
        typeof item === "object"
        && item !== null
        && typeof (item as { id?: unknown }).id === "string"
        && typeof (item as { name?: unknown }).name === "string",
      ) as { id: string; name: string }[]
      : [];

    icons.value = append ? [...icons.value, ...incoming] : incoming;
    currentPage.value = data?.meta?.current_page ?? pageToLoad;
    hasNextPage.value = Boolean(data?.meta?.has_next_page);
  } catch (error) {
    if ((error as Error).name === "AbortError") {
      return;
    }

    fetchError.value = t("admin.common.icon_picker.fetch_error");
    if (!append) icons.value = [];
    console.error("Error consultando iconos:", error);
  } finally {
    loading.value = false;
  }
};

watch(searchQuery, () => {
  if (timeout) clearTimeout(timeout);
  timeout = setTimeout(() => loadIcons({ append: false }), 300);
});

watch(open, (isOpen) => {
  if (isOpen) loadIcons({ append: false });
});

onBeforeUnmount(() => {
  if (timeout) clearTimeout(timeout);
  activeController?.abort();
});

const selectIcon = (iconName: string) => {
  emit("update:modelValue", iconName);
  open.value = false;
};

const clearSelection = () => {
  emit("update:modelValue", null);
  open.value = false;
};

const onScroll = (event: Event) => {
  const target = event.target as HTMLElement;
  const remaining = target.scrollHeight - target.scrollTop - target.clientHeight;

  if (remaining < 120 && hasNextPage.value && !loading.value) {
    loadIcons({ append: true });
  }
};
</script>

<template>
  <div class="w-full">
    <Popover v-model:open="open">
      <PopoverTrigger as-child>
        <Button
          type="button"
          variant="outline"
          class="text-foreground w-full justify-between gap-2"
          :aria-label="t('admin.common.icon_picker.aria_select_icon')"
        >
          <span class="flex min-w-0 items-center gap-2">
            <Icon
              v-if="selectedIcon"
              :icon="selectedIcon"
              class="size-4 shrink-0"
            />
            <span class="truncate text-left">
              {{ selectedIcon ? t("admin.common.icon_picker.selected") : (placeholder || t("admin.common.icon_picker.select")) }}
            </span>
          </span>
          <ChevronsUpDown class="text-muted-foreground size-4 shrink-0" />
        </Button>
      </PopoverTrigger>
      <PopoverContent
        align="start"
        class="w-[var(--reka-popover-trigger-width)] min-w-[260px] p-0"
      >
        <div class="border-b p-2">
          <div class="mb-2 flex items-center justify-between gap-2">
            <Label :for="searchInputId" class="sr-only">
              {{ t("admin.common.icon_picker.search_label") }}
            </Label>
            <Button
              v-if="selectedIcon"
              type="button"
              variant="ghost"
              size="sm"
              class="text-muted-foreground h-8 px-2"
              @click="clearSelection"
            >
              <X class="mr-1 size-4" />
              {{ t("admin.common.icon_picker.clear") }}
            </Button>
          </div>
          <div class="relative">
            <Search class="text-muted-foreground absolute top-1/2 left-3 size-4 -translate-y-1/2" />
            <Input
              :id="searchInputId"
              v-model="searchQuery"
              type="search"
              autocomplete="off"
              :placeholder="t('admin.common.icon_picker.search_placeholder')"
              class="h-9 pr-10 pl-9"
              @keydown.stop
            />
            <Loader2
              v-if="loading"
              class="text-muted-foreground absolute top-1/2 right-3 size-4 -translate-y-1/2 animate-spin"
            />
          </div>
        </div>

        <div class="max-h-72 overflow-y-auto p-2" @scroll="onScroll">
          <div class="grid grid-cols-3 gap-2 sm:grid-cols-4">
            <button
              v-for="icon in icons"
              :key="icon.id"
              type="button"
              class="hover:bg-muted focus-visible:ring-ring/50 flex flex-col items-center gap-2 rounded-md border p-2 transition-colors outline-none focus-visible:ring-[3px]"
              :class="{
                'bg-muted border-primary text-primary': selectedIcon === icon.name,
              }"
              :aria-label="`Seleccionar ${icon.name}`"
              @click="selectIcon(icon.name)"
            >
              <Icon :icon="icon.name" class="size-5" />
              <!-- <span class="text-muted-foreground w-full truncate text-[10px]">
                {{ icon.name }}
              </span> -->
            </button>
          </div>

          <p
            v-if="fetchError"
            class="text-destructive py-6 text-center text-sm"
          >
            {{ fetchError }}
          </p>
          <p
            v-else-if="!loading && icons.length === 0"
            class="text-muted-foreground py-6 text-center text-sm"
          >
            {{ t("admin.common.icon_picker.empty") }}
          </p>
          <p v-if="loading && hasResults" class="text-muted-foreground py-4 text-center text-xs">
            {{ t("admin.common.icon_picker.loading_more") }}
          </p>
        </div>
      </PopoverContent>
    </Popover>
  </div>
</template>