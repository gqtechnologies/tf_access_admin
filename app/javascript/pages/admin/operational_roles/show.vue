<template>
  <div>
    <Header :itemsBreadcrumb="breadcrumbs" :title="role.name" />

    <div class="p-6 space-y-6">
      <!-- Role header card -->
      <div class="rounded-lg border bg-card px-6 py-5 flex items-start justify-between">
        <div class="space-y-1">
          <div class="flex items-center gap-2">
            <h2 class="text-xl font-semibold">{{ role.name }}</h2>
            <Badge variant="outline">Propiedad</Badge>
            <Badge class="bg-green-100 text-green-800 border-green-200">Activo</Badge>
          </div>
          <p class="text-sm text-muted-foreground">{{ role.description }}</p>
          <p class="text-sm text-muted-foreground">
            {{ role.users_count }} usuario{{ role.users_count !== 1 ? 's' : '' }} activo{{ role.users_count !== 1 ? 's' : '' }}
            · {{ role.capabilities?.length ?? 0 }} capacidades
          </p>
        </div>
        <Link v-if="permissions.manage" href="/admin/operational_roles/assignments">
          <Button size="sm">
            <UserPlusIcon class="w-4 h-4 mr-1" />
            Asignar personas
          </Button>
        </Link>
      </div>

      <!-- Tabs -->
      <Tabs default-value="permissions">
        <TabsList>
          <TabsTrigger value="permissions">Permisos</TabsTrigger>
          <TabsTrigger value="users">Usuarios ({{ role.users_count }})</TabsTrigger>
        </TabsList>

        <!-- Permissions tab -->
        <TabsContent value="permissions" class="mt-4">
          <div class="rounded-lg border bg-card divide-y">
            <div v-for="group in capability_groups" :key="group.module">
              <div class="px-6 py-3 bg-muted/30 font-medium text-sm">{{ group.module }}</div>
              <div v-for="cap in group.capabilities" :key="cap.key"
                class="flex items-center justify-between px-6 py-3 hover:bg-muted/10">
                <span class="text-sm">{{ cap.label }}</span>
                <Badge v-if="cap.granted" class="bg-green-100 text-green-800 border-green-200">Permitido</Badge>
                <Badge v-else variant="outline" class="text-muted-foreground">Restringido</Badge>
              </div>
            </div>
          </div>
        </TabsContent>

        <!-- Users tab -->
        <TabsContent value="users" class="mt-4">
          <div v-if="users.length === 0" class="rounded-lg border bg-card px-6 py-12 text-center text-muted-foreground text-sm">
            No hay personas asignadas a este rol.
          </div>
          <div v-else class="rounded-lg border bg-card">
            <table class="w-full text-sm">
              <thead>
                <tr class="border-b bg-muted/40">
                  <th class="text-left px-6 py-3 font-medium text-muted-foreground">Persona</th>
                  <th class="text-left px-6 py-3 font-medium text-muted-foreground">Propiedad</th>
                  <th class="text-left px-6 py-3 font-medium text-muted-foreground">Desde</th>
                  <th class="text-left px-6 py-3 font-medium text-muted-foreground">Hasta</th>
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
        </TabsContent>
      </Tabs>
    </div>
  </div>
</template>

<script setup lang="ts">
import { Link } from "@inertiajs/vue3"
import Header from "@/components/admin/layout/Header.vue"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { UserPlusIcon } from "lucide-vue-next"
import type { CapabilityModuleGroup, RoleUser } from "@/types/operational_roles"

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

const breadcrumbs = [
  { label: "Inicio", href: "/admin/home/index" },
  { label: "Roles operativos", href: "/admin/operational_roles" },
  { label: props.role.name }
]
</script>
