<template>
  <Drawer v-model:open="open" direction="right" @update:open="onOpenChange">
    <DrawerContent
      class="flex h-full max-h-screen flex-col data-[vaul-drawer-direction=right]:w-full data-[vaul-drawer-direction=right]:sm:max-w-lg"
    >
      <DrawerHeader class="shrink-0 border-b pb-4">
        <div class="flex items-start justify-between gap-4">
          <DrawerTitle class="text-lg font-semibold">
            {{ t('admin.units.show.owners.add_owner.title') }}
          </DrawerTitle>
          <DrawerClose as-child>
            <Button
              type="button"
              variant="ghost"
              size="icon"
              :aria-label="t('admin.units.show.owners.add_owner.actions.close')"
            >
              <X class="size-4" />
            </Button>
          </DrawerClose>
        </div>
        <UnitAddOwnerStepper :step-index="stepIndex" />
      </DrawerHeader>

      <div class="flex-1 space-y-6 overflow-y-auto px-4 py-5">
        <UnitAddOwnerUnitContext :unit="unit" />

        <UnitAddOwnerChooseStep
          v-if="currentStep === 'choose'"
          @select-search="goToStep('search')"
          @select-create="goToStep('create')"
        />

        <UnitAddOwnerPlaceholderStep
          v-else-if="currentStep === 'search'"
          :title="t('admin.units.show.owners.add_owner.search.title')"
          :description="t('admin.units.show.owners.add_owner.search.coming_soon')"
        />

        <UnitAddOwnerPlaceholderStep
          v-else-if="currentStep === 'create'"
          :title="t('admin.units.show.owners.add_owner.create.title')"
          :description="t('admin.units.show.owners.add_owner.create.coming_soon')"
        />

        <UnitAddOwnerPlaceholderStep
          v-else
          :title="t('admin.units.show.owners.add_owner.assign.title')"
          :description="t('admin.units.show.owners.add_owner.assign.coming_soon')"
        />
      </div>

      <DrawerFooter class="shrink-0 border-t sm:flex-row sm:justify-center">
        <Button
          v-if="currentStep === 'choose'"
          type="button"
          variant="outline"
          class="min-w-32"
          @click="closeDrawer"
        >
          {{ t('admin.units.show.owners.add_owner.actions.cancel') }}
        </Button>
        <template v-else>
          <Button type="button" variant="outline" @click="goBack">
            {{ t('common.back') }}
          </Button>
          <DrawerClose as-child>
            <Button type="button" variant="outline">
              {{ t('admin.units.show.owners.add_owner.actions.cancel') }}
            </Button>
          </DrawerClose>
        </template>
      </DrawerFooter>
    </DrawerContent>
  </Drawer>
</template>

<script setup lang="ts">
import { watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { X } from 'lucide-vue-next'
import UnitAddOwnerChooseStep from '@/components/admin/unit/add_owner/UnitAddOwnerChooseStep.vue'
import UnitAddOwnerPlaceholderStep from '@/components/admin/unit/add_owner/UnitAddOwnerPlaceholderStep.vue'
import UnitAddOwnerStepper from '@/components/admin/unit/add_owner/UnitAddOwnerStepper.vue'
import UnitAddOwnerUnitContext from '@/components/admin/unit/add_owner/UnitAddOwnerUnitContext.vue'
import { Button } from '@/components/ui/button'
import {
  Drawer,
  DrawerClose,
  DrawerContent,
  DrawerFooter,
  DrawerHeader,
  DrawerTitle,
} from '@/components/ui/drawer'
import { useUnitAddOwnerDrawer } from '@/lib/composables/unit/useUnitAddOwnerDrawer'
import type { UnitDetail } from '@/types/unit'

const props = defineProps<{
  unit: UnitDetail
}>()

const open = defineModel<boolean>('open', { required: true })

const { t } = useI18n()

const {
  currentStep,
  stepIndex,
  resetDrawer,
  goToStep,
  goBack,
} = useUnitAddOwnerDrawer()

function closeDrawer() {
  open.value = false
}

function onOpenChange(value: boolean) {
  open.value = value
  if (!value) resetDrawer()
}

watch(open, (isOpen) => {
  if (isOpen) resetDrawer()
})
</script>
