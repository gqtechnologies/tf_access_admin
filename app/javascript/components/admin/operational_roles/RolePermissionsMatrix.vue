<template>
  <div class="rounded-lg border bg-card">
    <div class="px-6 py-4 border-b">
      <h2 class="font-semibold text-base">{{ t('admin.operational_roles.permissions_matrix.title') }}</h2>
      <p class="text-sm text-muted-foreground mt-0.5">{{ t('admin.operational_roles.permissions_matrix.subtitle') }}</p>
    </div>

    <div class="overflow-x-auto">
      <table class="w-full text-xs min-w-[700px]">
        <thead>
          <tr class="border-b bg-muted/30">
            <th class="text-left px-4 py-3 font-medium text-muted-foreground w-48">{{ t('common.capability') }}</th>
            <th
              v-for="role in roleColumns"
              :key="role.key"
              class="px-3 py-3 font-medium text-center text-muted-foreground whitespace-nowrap"
            >
              {{ role.label }}
            </th>
          </tr>
        </thead>
        <tbody>
          <template v-for="group in capability_matrix" :key="group.module">
            <tr class="bg-muted/20">
              <td :colspan="roleColumns.length + 1" class="px-4 py-2 font-semibold text-xs text-muted-foreground uppercase tracking-wide">
                {{ group.module }}
              </td>
            </tr>
            <tr
              v-for="cap in group.capabilities"
              :key="cap.key"
              class="border-b last:border-0 hover:bg-muted/10"
            >
              <td class="px-4 py-2.5 text-sm">{{ cap.label }}</td>
              <td
                v-for="role in roleColumns"
                :key="role.key"
                class="px-3 py-2.5 text-center"
              >
                <span v-if="cap.roles?.[role.key]" class="text-green-600">✓</span>
                <span v-else class="text-muted-foreground/40">✕</span>
              </td>
            </tr>
          </template>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useI18n } from "vue-i18n"
import type { CapabilityModuleGroup } from "@/types/operational_roles"

const { t } = useI18n()

defineProps<{
  capability_matrix: CapabilityModuleGroup[]
}>()

const roleColumns = [
  { key: "tenant_admin", label: t('admin.operational_roles.roles.tenant_admin') },
  { key: "content_manager", label: t('admin.operational_roles.roles.content_manager') },
  { key: "property_admin", label: t('admin.operational_roles.roles.property_admin') },
  { key: "concierge", label: t('admin.operational_roles.roles.concierge') },
  { key: "cleaning_staff", label: t('admin.operational_roles.roles.cleaning_staff') },
  { key: "internal_staff", label: t('admin.operational_roles.roles.internal_staff') }
]
</script>
