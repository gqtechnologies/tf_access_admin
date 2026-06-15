<template>
  <div class="space-y-6">
    <div class="space-y-1">
      <h3 class="text-base font-semibold">
        {{ t('admin.units.show.occupants.add_occupant.choose.title') }}
      </h3>
      <p class="text-sm text-muted-foreground">
        {{ t('admin.units.show.occupants.add_occupant.choose.description') }}
      </p>
    </div>

    <div class="grid gap-3">
      <DrawerOptionCard
        :icon="UserSearch"
        :title="t('admin.units.show.occupants.add_occupant.choose.search.title')"
        :description="t('admin.units.show.occupants.add_occupant.choose.search.description')"
        @select="emit('select-search')"
      />
      <DrawerOptionCard
        :icon="UserPlus"
        :title="t('admin.units.show.occupants.add_occupant.choose.create.title')"
        :description="t('admin.units.show.occupants.add_occupant.choose.create.description')"
        @select="emit('select-create')"
      />
    </div>
  </div>
</template>

<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import { UserPlus, UserSearch } from 'lucide-vue-next'
import DrawerOptionCard from '@/components/admin/shared/DrawerOptionCard.vue'

const emit = defineEmits<{
  (e: 'select-search'): void
  (e: 'select-create'): void
}>()

const { t } = useI18n()
</script>
