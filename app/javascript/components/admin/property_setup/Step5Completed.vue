<template>
  <div class="space-y-6">
    <div class="flex items-start gap-3 rounded-lg border border-green-200 bg-green-50 p-4 text-green-900">
      <CheckCircle2 class="mt-0.5 size-5 shrink-0" />
      <div>
        <p class="font-semibold">{{ t('admin.property_setup.step5.completed.success.title') }}</p>
        <p class="mt-1 text-sm leading-relaxed">{{ t('admin.property_setup.step5.completed.success.description') }}</p>
      </div>
    </div>

    <div class="space-y-6">
        <div class="grid gap-3 grid-cols-2">
          <Card v-for="card in summaryCards" :key="card.key" class="shadow-none !p-2">
            <CardContent class="flex items-start gap-3 px-2">
              <span class="bg-muted inline-flex size-9 shrink-0 items-center justify-center rounded-full">
                <component :is="card.icon" class="text-muted-foreground size-4" />
              </span>
              <div class="min-w-0 space-y-1">
                <p class="text-muted-foreground text-xs">{{ card.label }}</p>
                <p class="text-sm leading-snug font-medium">{{ card.value }}</p>
              </div>
            </CardContent>
          </Card>
        </div>

        <section class="space-y-4">
          <h3 class="text-sm font-medium">{{ t('admin.property_setup.step5.completed.next_steps.title') }}</h3>
          <div class="grid gap-3 md:grid-cols-2">
            <Card
              v-for="action in nextStepActions"
              :key="action.key"
              class="shadow-none !p-2"
              :class="action.recommended ? 'border-green-500 ring-1 ring-green-200' : ''"
            >
              <CardContent class="flex h-full flex-col gap-4 px-2">
                <div class="flex items-start justify-between gap-3">
                  <span
                    class="inline-flex size-10 shrink-0 items-center justify-center rounded-full"
                    :class="action.recommended ? 'bg-green-100 text-green-700' : 'bg-muted text-muted-foreground'"
                  >
                    <component :is="action.icon" class="size-4" />
                  </span>
                  <Badge
                    v-if="action.recommended"
                    class="border-transparent bg-green-100 font-normal text-green-800 hover:bg-green-100"
                  >
                    {{ t('admin.property_setup.step5.completed.next_steps.recommended_badge') }}
                  </Badge>
                </div>
                <div class="space-y-1">
                  <p class="text-sm font-medium">{{ action.title }}</p>
                  <p class="text-muted-foreground text-xs leading-relaxed">{{ action.description }}</p>
                </div>
                <Button
                  v-if="action.href && !action.disabled"
                  as="a"
                  :href="action.href"
                  :variant="action.recommended ? 'default' : 'outline'"
                  class="mt-auto w-full"
                >
                  {{ action.buttonLabel }}
                </Button>
                <Button
                  v-else
                  variant="outline"
                  class="mt-auto w-full"
                  disabled
                >
                  {{ action.buttonLabel }}
                </Button>
              </CardContent>
            </Card>
          </div>
        </section>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import {
  Building2,
  CheckCircle2,
  DoorOpen,
  Layers,
  Search,
  Settings2,
  ShieldCheck,
  UserRound,
  Users,
} from 'lucide-vue-next'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'

const props = defineProps<{
  preview: Record<string, any>
  nextActions: string[]
  propertyId?: string
}>()

const { t } = useI18n()

const propertyName = computed(() => props.preview?.property?.name || '—')
const unitCount = computed(() => props.preview?.counts?.units ?? 0)
const towerCount = computed(() => props.preview?.counts?.level_1 ?? 0)
const floorCount = computed(() => props.preview?.counts?.level_2 ?? 0)
const structureMode = computed(() => props.preview?.structure?.mode)

const structureSummary = computed(() => {
  if (towerCount.value > 0 && floorCount.value > 0) {
    return t('admin.property_setup.step5.completed.summary.structure_value', {
      towers: towerCount.value,
      floors: floorCount.value,
    })
  }

  return structureMode.value === 'none'
    ? t('admin.property_setup.step2.modes.none.title')
    : '—'
})

const summaryCards = computed(() => [
  {
    key: 'property',
    icon: Building2,
    label: t('admin.property_setup.step5.completed.summary.property'),
    value: propertyName.value,
  },
  {
    key: 'structure',
    icon: Layers,
    label: t('admin.property_setup.step5.completed.summary.structure'),
    value: structureSummary.value,
  },
  {
    key: 'units',
    icon: DoorOpen,
    label: t('admin.property_setup.step5.completed.summary.units'),
    value: t('admin.property_setup.step5.completed.summary.units_value', { count: unitCount.value }),
  },
  {
    key: 'status',
    icon: ShieldCheck,
    label: t('admin.property_setup.step5.completed.summary.status'),
    value: t('admin.property_setup.step5.completed.summary.status_value'),
  },
])

function showAction(action: string) {
  return props.nextActions.includes(action)
}

const nextStepActions = computed(() => {
  const propertyId = props.propertyId

  return [
    {
      key: 'property_detail',
      recommended: true,
      icon: Search,
      title: t('admin.property_setup.step5.completed.next_steps.property_detail.title'),
      description: t('admin.property_setup.step5.completed.next_steps.property_detail.description'),
      buttonLabel: t('admin.property_setup.step5.completed.next_steps.property_detail.action'),
      href: propertyId && showAction('property_detail')
        ? `/admin/residential_properties/${propertyId}/edit`
        : undefined,
      disabled: !showAction('property_detail'),
    },
    {
      key: 'reopen_setup',
      recommended: false,
      icon: Settings2,
      title: t('admin.property_setup.step5.completed.next_steps.reopen_setup.title'),
      description: t('admin.property_setup.step5.completed.next_steps.reopen_setup.description'),
      buttonLabel: t('admin.property_setup.step5.completed.next_steps.reopen_setup.action'),
      href: propertyId && showAction('reopen_setup')
        ? `/admin/property_setup/wizard/${propertyId}`
        : undefined,
      disabled: !showAction('reopen_setup'),
    },
    {
      key: 'manage_units',
      recommended: false,
      icon: Building2,
      title: t('admin.property_setup.step5.completed.next_steps.manage_units.title'),
      description: t('admin.property_setup.step5.completed.next_steps.manage_units.description'),
      buttonLabel: t('admin.property_setup.step5.completed.next_steps.manage_units.action'),
      href: propertyId && showAction('manage_units')
        ? `/admin/residential_properties/${propertyId}/units`
        : undefined,
      disabled: !showAction('manage_units'),
    },
    {
      key: 'import_owners',
      recommended: false,
      icon: Users,
      title: t('admin.property_setup.step5.completed.next_steps.import_owners.title'),
      description: t('admin.property_setup.step5.completed.next_steps.import_owners.description'),
      buttonLabel: t('admin.property_setup.step5.completed.next_steps.import_owners.action'),
      href: undefined,
      disabled: !showAction('import_owners'),
    },
    {
      key: 'configure_residents',
      recommended: false,
      icon: UserRound,
      title: t('admin.property_setup.step5.completed.next_steps.configure_residents.title'),
      description: t('admin.property_setup.step5.completed.next_steps.configure_residents.description'),
      buttonLabel: t('admin.property_setup.step5.completed.next_steps.configure_residents.action'),
      href: undefined,
      disabled: !showAction('configure_residents'),
    },
  ]
})
</script>
