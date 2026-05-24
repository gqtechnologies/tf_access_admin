<template>
  <Drawer v-model:open="open" direction="right">
    <DrawerContent
      :class="[
        'flex h-full max-h-screen flex-col data-[vaul-drawer-direction=right]:w-full',
        currentStep === 'preview'
          ? 'data-[vaul-drawer-direction=right]:sm:max-w-6xl'
          : 'data-[vaul-drawer-direction=right]:sm:max-w-4xl',
      ]"
    >
      <DrawerHeader class="shrink-0 border-b pb-4">
        <div class="flex items-start justify-between gap-4">
          <DrawerTitle class="text-lg font-semibold">
            {{ t('admin.residential_properties.structure.bulk_import.title') }}
          </DrawerTitle>
          <DrawerClose as-child>
            <Button
              type="button"
              variant="ghost"
              size="icon"
              :aria-label="t('admin.residential_properties.structure.bulk_import.actions.close')"
            >
              <X class="size-4" />
            </Button>
          </DrawerClose>
        </div>
        <BulkUnitsImportStepper :step-index="stepIndex" />
      </DrawerHeader>

      <div class="flex-1 space-y-6 overflow-y-auto px-4 py-5">
        <Card class="gap-3 py-4">
          <CardContent class="flex flex-col justify-between gap-3 px-4 md:flex-row">
            <div class="flex items-center gap-4 sm:col-span-3">
              <Layers class="size-6 shrink-0 text-primary" />
              <div class="flex flex-col gap-1">
                <p class="text-xs font-medium text-muted-foreground">
                  {{ t('admin.residential_properties.structure.bulk_import.context.selected_section') }}
                </p>
                <p class="text-sm font-medium text-muted-foreground">
                  {{ sectionBreadcrumb }}
                </p>
              </div>
            </div>
            <div class="space-y-1">
              <p class="text-xs font-medium text-muted-foreground">
                {{ t('admin.residential_properties.structure.bulk_import.context.property') }}
              </p>
              <p class="text-sm font-medium">{{ propertyName }}</p>
            </div>
            <div class="space-y-1">
              <p class="text-xs font-medium text-muted-foreground">
                {{ t('admin.residential_properties.structure.bulk_import.context.section_type') }}
              </p>
              <p class="text-sm font-medium">{{ sectionTypeLabel }}</p>
            </div>
          </CardContent>
        </Card>

        <BulkUnitsImportMethodStep
          v-if="currentStep === 'method'"
          v-model:creation-method="creationMethod"
          v-model:selected-file="selectedFile"
          v-model:file-error="fileError"
          :excel-accept="BULK_UNITS_EXCEL_ACCEPT"
          @download-template="onDownloadTemplate"
        />

        <BulkUnitsImportConfigureStep
          v-else-if="currentStep === 'configure' && bulkImport && configureForm"
          v-model:configure-form="configureForm"
          :bulk-import="bulkImport"
          :default-section-id="propertySectionId"
          :default-section-name="selectedSection?.name ?? ''"
          :is-refreshing-sheet="isRefreshingSheet"
          @change-file="onChangeFile"
          @refresh-sheet="onRefreshSheet"
          @valid-change="setConfigureStepValid"
        />

        <BulkUnitsImportPreviewStep
          v-else-if="currentStep === 'preview' && bulkImport && configureForm"
          ref="previewStepRef"
          :residential-property-id="residentialPropertyId"
          :bulk-import="bulkImport"
          :initial-preview="initialPreview"
          :is-validating="isValidating"
          :owner-import-mode="configureForm.owner_import_mode"
          @can-continue-change="setPreviewStepConfirmable"
        />

        <div
          v-else
          class="flex min-h-48 items-center justify-center rounded-lg border border-dashed bg-muted/20 px-6 text-center text-sm text-muted-foreground"
        >
          {{ t('admin.residential_properties.structure.bulk_import.placeholder_step') }}
        </div>
      </div>

      <DrawerFooter class="shrink-0 gap-2 border-t sm:flex-row sm:justify-between">
        <div class="flex flex-wrap gap-2">
          <Button
            v-if="canGoBack"
            type="button"
            variant="outline"
            :disabled="isSubmitting || isValidating"
            @click="goToPreviousStep()"
          >
            {{ t('admin.residential_properties.structure.bulk_import.actions.back') }}
          </Button>
          <Button
            v-if="currentStep === 'preview'"
            type="button"
            variant="outline"
            :disabled="!canDownloadErrors || isSubmitting || isValidating"
            @click="onDownloadErrors"
          >
            <Download class="size-4" />
            {{ t('admin.residential_properties.structure.bulk_import.actions.download_errors') }}
          </Button>
        </div>

        <div class="flex flex-wrap justify-end gap-2">
          <DrawerClose as-child>
            <Button type="button" variant="outline" :disabled="isSubmitting || isValidating">
              {{ t('common.actions.cancel') }}
            </Button>
          </DrawerClose>
          <Button type="button" :disabled="!canGoNext || isSubmitting || isValidating" @click="onNext">
            <Loader2 v-if="isSubmitting || isValidating" class="size-4 animate-spin" />
            {{ nextButtonLabel }}
          </Button>
        </div>
      </DrawerFooter>
    </DrawerContent>
  </Drawer>
</template>

<script setup lang="ts">
import { computed, ref, toRefs, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { toast } from 'vue-sonner'
import { Download, Layers, Loader2, X } from 'lucide-vue-next'
import BulkUnitsImportConfigureStep from '@/components/admin/bulk_units/BulkUnitsImportConfigureStep.vue'
import BulkUnitsImportPreviewStep from '@/components/admin/bulk_units/BulkUnitsImportPreviewStep.vue'
import BulkUnitsImportMethodStep from '@/components/admin/bulk_units/BulkUnitsImportMethodStep.vue'
import BulkUnitsImportStepper from '@/components/admin/bulk_units/BulkUnitsImportStepper.vue'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import {
  Drawer,
  DrawerClose,
  DrawerContent,
  DrawerFooter,
  DrawerHeader,
  DrawerTitle,
} from '@/components/ui/drawer'
import {
  BULK_UNITS_EXCEL_ACCEPT,
  useBulkUnitsImportWizard,
} from '@/lib/composables/bulk_units/useBulkUnitsImportDrawer'
import { buildSectionBreadcrumbPath } from '@/lib/utils/property_section_path'
import type { PropertySectionTreeNode } from '@/types/property_section'

const open = defineModel<boolean>('open', { required: true })

const props = defineProps<{
  propertyName: string
  residentialPropertyId: string
  propertySectionId: string
  sectionTree: PropertySectionTreeNode[]
  selectedSection: PropertySectionTreeNode | null
}>()

const { t } = useI18n()
const {
  state,
  stepIndex,
  canGoNext,
  canGoBack,
  reset,
  goToNextStep,
  goToPreviousStep,
  prepareFileReplacement,
  refreshSheetInspection,
  setConfigureStepValid,
  setPreviewStepConfirmable,
} = useBulkUnitsImportWizard()

const previewStepRef = ref<InstanceType<typeof BulkUnitsImportPreviewStep> | null>(null)

const {
  creationMethod,
  selectedFile,
  fileError,
  currentStep,
  bulkImport,
  configureForm,
  initialPreview,
  isSubmitting,
  isRefreshingSheet,
  isValidating,
} = toRefs(state)

watch(open, (isOpen, wasOpen) => {
  if (isOpen && !wasOpen) {
    reset()
  }
})

const sectionBreadcrumb = computed(() => {
  if (!props.selectedSection) {
    return t('admin.residential_properties.structure.bulk_import.context.no_section')
  }

  return buildSectionBreadcrumbPath(
    props.sectionTree,
    props.selectedSection.id,
    props.propertyName,
  ).join(' > ')
})

const sectionTypeLabel = computed(() => {
  if (!props.selectedSection) return '—'

  return t(`admin.property_sections.section_types.${props.selectedSection.section_type}`)
})

const canDownloadErrors = computed(
  () => previewStepRef.value?.hasDownloadableErrors ?? false,
)

const nextButtonLabel = computed(() => {
  if (isValidating.value) {
    return t('admin.residential_properties.structure.bulk_import.actions.validating')
  }
  if (isSubmitting.value) {
    return t('admin.residential_properties.structure.bulk_import.actions.uploading')
  }
  if (isRefreshingSheet.value) {
    return t('admin.residential_properties.structure.bulk_import.actions.refreshing_sheet')
  }
  if (currentStep.value === 'preview') {
    return t('admin.residential_properties.structure.bulk_import.actions.continue_to_import')
  }
  return t('admin.residential_properties.structure.bulk_import.actions.next')
})

function onDownloadErrors() {
  toast.info(t('admin.residential_properties.structure.bulk_import.preview.download_errors_coming_soon'))
}

function onDownloadTemplate() {
  toast.info(t('admin.residential_properties.structure.bulk_import.upload.template_coming_soon'))
}

function onNext() {
  goToNextStep(props.residentialPropertyId, props.propertySectionId)
}

function onChangeFile() {
  prepareFileReplacement()
}

function onRefreshSheet(sheet: string) {
  void refreshSheetInspection(props.residentialPropertyId, sheet)
}
</script>
