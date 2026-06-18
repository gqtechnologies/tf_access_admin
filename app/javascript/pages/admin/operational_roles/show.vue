<template>
  <div>
    <Header :itemsBreadcrumb="breadcrumbs" :title="role.name" />

    <div class="p-6 space-y-6">
      <!-- Role header card -->
      <div class="rounded-lg border bg-card px-6 py-5 flex items-start justify-between">
        <div class="space-y-1">
          <div class="flex items-center gap-2">
            <h2 class="text-xl font-semibold">{{ role.name }}</h2>
            <Badge variant="outline">{{ t('admin.operational_roles.index.role_scope_property') }}</Badge>
            <Badge class="bg-green-100 text-green-800 border-green-200">{{ t('common.status.active') }}</Badge>
          </div>
          <p class="text-sm text-muted-foreground">{{ role.description }}</p>
          <p class="text-sm text-muted-foreground">
            {{ role.users_count }} {{ pluralize('admin.operational_roles.show.users_heading', role.users_count) }}
            · {{ role.capabilities?.length ?? 0 }} {{ t('common.capabilities') }}
          </p>
        </div>
        <Link v-if="permissions.manage" href="/admin/operational_roles/assignments">
          <Button size="sm">
            <UserPlusIcon class="w-4 h-4 mr-1" />
            {{ t('admin.operational_roles.show.assign_persons_button') }}
          </Button>
        </Link>
      </div>

      <!-- Permissions section -->
      <div class="rounded-lg border bg-card">
        <div class="px-6 py-4 border-b">
          <h3 class="font-semibold">{{ t('admin.operational_roles.show.permissions_heading') }}</h3>
        </div>
        <div class="divide-y">
          <div v-for="group in capability_groups" :key="group.module">
            <div class="px-6 py-3 bg-muted/30 font-medium text-sm">{{ group.module }}</div>
            <div v-for="cap in group.capabilities" :key="cap.key"
              class="flex items-center justify-between px-6 py-3 hover:bg-muted/10">
              <span class="text-sm">{{ cap.label }}</span>
              <Badge v-if="cap.granted" class="bg-green-100 text-green-800 border-green-200">{{ t('admin.operational_roles.show.permission_status_allowed') }}</Badge>
              <Badge v-else variant="outline" class="text-muted-foreground">{{ t('admin.operational_roles.show.permission_status_restricted') }}</Badge>
            </div>
          </div>
        </div>
      </div>

      <!-- Users section -->
      <div class="rounded-lg border bg-card">
        <div class="px-6 py-4 border-b">
          <h3 class="font-semibold">{{ t('admin.operational_roles.show.users_heading') }} ({{ role.users_count }})</h3>
        </div>
        <div v-if="users.length === 0" class="px-6 py-12 text-center text-muted-foreground text-sm">
          {{ t('admin.operational_roles.show.no_assigned_users') }}
        </div>
        <table v-else class="w-full text-sm">
          <thead>
            <tr class="border-b bg-muted/40">
              <th class="text-left px-6 py-3 font-medium text-muted-foreground">{{ t('admin.operational_roles.show.table_headers.person') }}</th>
              <th class="text-left px-6 py-3 font-medium text-muted-foreground">{{ t('admin.operational_roles.show.table_headers.property') }}</th>
              <th class="text-left px-6 py-3 font-medium text-muted-foreground">{{ t('admin.operational_roles.show.table_headers.from') }}</th>
              <th class="text-left px-6 py-3 font-medium text-muted-foreground">{{ t('admin.operational_roles.show.table_headers.to') }}</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="u in users" :key="u.assignment_id" class="border-b last:border-0 hover:bg-muted/20">
              <td class="px-6 py-3">{{ u.person_name ?? '—' }}</td>
              <td class="px-6 py-3 text-muted-foreground">{{ u.property_name ?? '—' }}</td>
              <td class="px-6 py-3 text-muted-foreground">{{ u.starts_at ?? '—' }}</td>
              <td class="px-6 py-3 text-muted-foreground">{{ u.ends_at ?? '—' }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { Link } from "@inertiajs/vue3"
import { useI18n } from "vue-i18n"
import Header from "@/components/admin/layout/Header.vue"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { UserPlusIcon } from "lucide-vue-next"
import type { CapabilityModuleGroup, RoleUser } from "@/types/operational_roles"

const { t } = useI18n()

const props = defineProps<{
  role: {
    key: string
    name: string
    description: string
    scope: string
    capabilities: string[]
    users_count: number
  }
  users: RoleUser[]
  capability_groups: CapabilityModuleGroup[]
  permissions: { manage: boolean }
}>()

const pluralize = (key: string, count: number) => {
  return count === 1 ? t(key) : t(key) + 's'
}

const breadcrumbs = [
  { label: t('admin.sidebar.home'), href: "/admin/home/index" },
  { label: t('admin.operational_roles.index.title'), href: "/admin/operational_roles" },
  { label: props.role.name }
]
</script>
