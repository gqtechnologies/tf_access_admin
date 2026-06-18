<template>
  <div>
    <Header :itemsBreadcrumb="breadcrumbs" title="Roles operativos" />

    <div class="p-6 space-y-6">
      <!-- Summary cards -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div class="rounded-lg border bg-card p-5">
          <p class="text-sm text-muted-foreground">Roles definidos</p>
          <p class="text-3xl font-bold mt-1">{{ summary.defined_roles_count }}</p>
        </div>
        <div class="rounded-lg border bg-card p-5">
          <p class="text-sm text-muted-foreground">Asignaciones activas</p>
          <p class="text-3xl font-bold mt-1">{{ summary.total_assignments_count }}</p>
        </div>
        <div class="rounded-lg border bg-card p-5">
          <p class="text-sm text-muted-foreground">Propiedades con personal</p>
          <p class="text-3xl font-bold mt-1">{{ summary.properties_with_assignments }}</p>
        </div>
      </div>

      <!-- Roles table -->
      <div class="rounded-lg border bg-card">
        <div class="flex items-center justify-between px-6 py-4 border-b">
          <h2 class="font-semibold text-base">Roles definidos</h2>
          <Link v-if="permissions.manage" href="/admin/operational_roles/assignments">
            <Button size="sm">
              <PlusIcon class="w-4 h-4 mr-1" />
              Asignar rol
            </Button>
          </Link>
        </div>
        <table class="w-full text-sm">
          <thead>
            <tr class="border-b bg-muted/40">
              <th class="text-left px-6 py-3 font-medium text-muted-foreground">Rol</th>
              <th class="text-left px-6 py-3 font-medium text-muted-foreground">Descripción</th>
              <th class="text-left px-6 py-3 font-medium text-muted-foreground">Alcance</th>
              <th class="text-left px-6 py-3 font-medium text-muted-foreground">Usuarios activos</th>
              <th class="px-6 py-3"></th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="role in roles" :key="role.key" class="border-b last:border-0 hover:bg-muted/20">
              <td class="px-6 py-4 font-medium">{{ role.name }}</td>
              <td class="px-6 py-4 text-muted-foreground max-w-sm">{{ role.description }}</td>
              <td class="px-6 py-4">
                <Badge variant="outline">Propiedad</Badge>
              </td>
              <td class="px-6 py-4">{{ role.users_count }}</td>
              <td class="px-6 py-4 text-right">
                <DropdownMenu>
                  <DropdownMenuTrigger as-child>
                    <Button variant="ghost" size="icon">
                      <MoreHorizontalIcon class="w-4 h-4" />
                    </Button>
                  </DropdownMenuTrigger>
                  <DropdownMenuContent align="end">
                    <DropdownMenuItem as-child>
                      <Link :href="`/admin/operational_roles/${role.key}`" class="flex items-center gap-2 cursor-pointer">
                        <EyeIcon class="w-4 h-4" />
                        Ver detalle
                      </Link>
                    </DropdownMenuItem>
                    <DropdownMenuItem v-if="permissions.manage" as-child>
                      <Link href="/admin/operational_roles/assignments" class="flex items-center gap-2 cursor-pointer">
                        <UserPlusIcon class="w-4 h-4" />
                        Asignar personas
                      </Link>
                    </DropdownMenuItem>
                  </DropdownMenuContent>
                </DropdownMenu>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Permissions Matrix -->
      <RolePermissionsMatrix :capability_matrix="capability_matrix" />
    </div>
  </div>
</template>

<script setup lang="ts">
import { Link } from "@inertiajs/vue3"
import Header from "@/components/admin/layout/Header.vue"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import {
  DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger
} from "@/components/ui/dropdown-menu"
import { PlusIcon, MoreHorizontalIcon, EyeIcon, UserPlusIcon } from "lucide-vue-next"
import RolePermissionsMatrix from "@/components/admin/operational_roles/RolePermissionsMatrix.vue"
import type { OperationalRoleDefinition, CapabilityModuleGroup, RoleSummary } from "@/types/operational_roles"

defineProps<{
  roles: OperationalRoleDefinition[]
  summary: RoleSummary
  capability_matrix: CapabilityModuleGroup[]
  permissions: { manage: boolean }
}>()

const breadcrumbs = [
  { label: "Inicio", href: "/admin/home/index" },
  { label: "Roles operativos" }
]
</script>
