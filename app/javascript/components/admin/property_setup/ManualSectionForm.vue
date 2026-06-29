<template>
  <div v-if="selectedMode === 'manual'" class="space-y-4 rounded-lg border p-4">
    <ul v-if="hasSections" class="space-y-2 rounded-md border p-3 text-sm">
      <li v-for="node in tree" :key="node.id">
        <p class="font-medium">{{ node.name }}</p>
        <ul v-if="node.children?.length" class="text-muted-foreground mt-1 space-y-1 pl-4">
          <li v-for="child in node.children" :key="child.id">{{ child.name }}</li>
        </ul>
      </li>
    </ul>
    <p v-if="!hasSections" class="text-muted-foreground text-sm">
      {{ t('admin.property_setup.step2.manual.empty') }}
    </p>
    <form class="grid gap-3 md:grid-cols-2" @submit.prevent="submitSection">
      <Field :data-invalid="!!fieldErrors.name">
        <FieldLabel>{{ t('admin.property_setup.step2.manual.name') }}</FieldLabel>
        <Input v-model="form.name" :aria-invalid="!!fieldErrors.name" />
        <FieldError v-if="fieldErrors.name" :errors="translateErrors([fieldErrors.name])" />
      </Field>
      <Field :data-invalid="!!fieldErrors.section_type">
        <FieldLabel>{{ t('admin.property_setup.step2.manual.type') }}</FieldLabel>
        <select
          v-model="form.section_type"
          class="border-input bg-background flex h-10 w-full rounded-md border px-3 py-2 text-sm"
          :aria-invalid="!!fieldErrors.section_type"
        >
          <option v-for="type in sectionTypes" :key="type" :value="type">
            {{ t(`admin.property_sections.section_types.${type}`) }}
          </option>
        </select>
        <FieldError
          v-if="fieldErrors.section_type"
          :errors="translateErrors([fieldErrors.section_type])"
        />
        <p v-if="showFormatWarning" class="text-amber-600 text-xs">
          {{ t('admin.property_setup.step2.manual.format_warning', { types: recommendedLabels }) }}
        </p>
      </Field>
      <Field class="md:col-span-2" :data-invalid="!!fieldErrors.parent_id">
        <FieldLabel>{{ t('admin.property_setup.step2.manual.parent') }}</FieldLabel>
        <select
          v-model="form.parent_id"
          class="border-input bg-background flex h-10 w-full rounded-md border px-3 py-2 text-sm"
          :aria-invalid="!!fieldErrors.parent_id"
        >
          <option value="">{{ t('admin.property_setup.step2.manual.root') }}</option>
          <option v-for="section in rootSections" :key="section.id" :value="section.id">
            {{ `${'— '.repeat(section.depth)}${section.name}` }}
          </option>
        </select>
        <FieldError v-if="fieldErrors.parent_id" :errors="translateErrors([fieldErrors.parent_id])" />
      </Field>
      <div class="md:col-span-2">
        <Button type="submit" :disabled="submitting">{{ t('admin.property_setup.step2.manual.add') }}</Button>
      </div>
    </form>
  </div>
</template>

<script setup lang="ts">
import { computed, reactive, ref } from 'vue'
import { router } from '@inertiajs/vue3'
import { useI18n } from 'vue-i18n'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Field, FieldError, FieldLabel } from '@/components/ui/field'
import { useTranslateErrors } from '@/lib/composables/i18n/translate_errors'
import { mapPropertySetupZodErrors } from '@/lib/schemas/property_setup'
import { propertySectionStructureCreateSchema } from '@/lib/schemas/property_section_structure'

type SectionNode = {
  id: string
  name: string
  section_type: string
  children?: SectionNode[]
}

const props = defineProps<{
  propertyId: string
  sectionTypes: string[]
  recommendedSectionTypes?: string[]
  tree: SectionNode[]
  selectedMode: string
}>()

const { t } = useI18n()
const { translateErrors } = useTranslateErrors()
const submitting = ref(false)
const fieldErrors = ref<Record<string, string>>({})
const form = reactive({
  name: '',
  section_type: 'tower',
  parent_id: '',
})

const hasSections = computed(() => props.tree.length > 0)
const rootSections = computed(() => flattenSections(props.tree))

const recommended = computed(() => props.recommendedSectionTypes ?? [])
const showFormatWarning = computed(
  () => recommended.value.length > 0 && !recommended.value.includes(form.section_type),
)
const recommendedLabels = computed(() =>
  recommended.value.map((type) => t(`admin.property_sections.section_types.${type}`)).join(', '),
)

function flattenSections(nodes: SectionNode[], depth = 0): Array<SectionNode & { depth: number }> {
  return nodes.flatMap((node) => [
    { ...node, depth },
    ...flattenSections(node.children ?? [], depth + 1),
  ])
}

function submitSection() {
  const payload = {
    placement: form.parent_id ? 'child' as const : 'root' as const,
    name: form.name,
    section_type: form.section_type,
    parent_id: form.parent_id || undefined,
  }

  const result = propertySectionStructureCreateSchema.safeParse(payload)
  if (!result.success) {
    fieldErrors.value = mapPropertySetupZodErrors(result.error)
    return
  }

  fieldErrors.value = {}
  submitting.value = true
  router.post(
    `/admin/property_setup/wizard/${props.propertyId}/sections`,
    {
      property_section: {
        name: form.name,
        section_type: form.section_type,
        parent_id: form.parent_id || null,
      },
    },
    {
      preserveScroll: true,
      onFinish: () => {
        submitting.value = false
        form.name = ''
      },
    },
  )
}
</script>
