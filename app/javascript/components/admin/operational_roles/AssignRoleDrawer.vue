<template>
  <Sheet :open="open" @update:open="$emit('close')">
    <SheetContent side="right" class="w-full sm:max-w-md">
      <SheetHeader>
        <SheetTitle>Nueva asignación</SheetTitle>
        <SheetDescription>Asigna un rol operativo a una persona en una propiedad.</SheetDescription>
      </SheetHeader>

      <form @submit.prevent="submit" class="mt-6 space-y-4">
        <!-- Rol operativo -->
        <div class="space-y-1.5">
          <label class="text-sm font-medium">Rol operativo</label>
          <select
            v-model="form.role"
            required
            class="w-full h-9 rounded-md border border-input bg-background px-3 text-sm focus:outline-none focus:ring-1 focus:ring-ring"
          >
            <option value="" disabled>Selecciona un rol...</option>
            <option v-for="r in available_roles" :key="r.key" :value="r.key">{{ r.name }}</option>
          </select>
        </div>

        <!-- Persona (person_id) -->
        <div class="space-y-1.5">
          <label class="text-sm font-medium">ID de persona</label>
          <Input
            v-model="form.person_id"
            type="number"
            placeholder="ID de la persona"
            required
            min="1"
          />
          <p class="text-xs text-muted-foreground">Ingresa el ID numérico de la persona a asignar.</p>
        </div>

        <!-- Propiedad -->
        <div class="space-y-1.5">
          <label class="text-sm font-medium">Propiedad</label>
          <select
            v-model="form.residential_property_id"
            required
            class="w-full h-9 rounded-md border border-input bg-background px-3 text-sm focus:outline-none focus:ring-1 focus:ring-ring"
          >
            <option value="" disabled>Selecciona una propiedad...</option>
            <option v-for="p in accessible_properties" :key="p.id" :value="p.id">{{ p.name }}</option>
          </select>
        </div>

        <!-- Errors -->
        <div v-if="errors.length" class="rounded-md bg-destructive/10 border border-destructive/20 px-4 py-3">
          <p v-for="(err, i) in errors" :key="i" class="text-sm text-destructive">{{ err }}</p>
        </div>

        <SheetFooter class="justify-between flex-row pt-4">
          <Button type="button" variant="outline" @click="$emit('close')">Cancelar</Button>
          <Button type="submit" :disabled="submitting">
            <span v-if="submitting">Guardando...</span>
            <span v-else>Guardar asignación</span>
          </Button>
        </SheetFooter>
      </form>
    </SheetContent>
  </Sheet>
</template>

<script setup lang="ts">
import { ref, watch } from "vue"
import { router, usePage } from "@inertiajs/vue3"
import { Sheet, SheetContent, SheetHeader, SheetTitle, SheetDescription, SheetFooter } from "@/components/ui/sheet"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import type { AccessibleProperty } from "@/types/operational_roles"

const props = defineProps<{
  open: boolean
  available_roles: Array<{ key: string; name: string }>
  accessible_properties: AccessibleProperty[]
}>()

const emit = defineEmits<{ close: [] }>()

const submitting = ref(false)
const errors = ref<string[]>([])
const form = ref({
  role: "",
  person_id: "",
  residential_property_id: "" as string | number
})

// Reset form when drawer opens
watch(() => props.open, (val) => {
  if (val) {
    form.value = { role: "", person_id: "", residential_property_id: "" }
    errors.value = []
  }
})

// Pick up server-side errors returned via Inertia
const page = usePage()
watch(() => page.props.errors, (errs: any) => {
  if (errs?.base) errors.value = Array.isArray(errs.base) ? errs.base : [errs.base]
}, { deep: true })

function submit() {
  submitting.value = true
  errors.value = []

  router.post("/admin/operational_roles/assignments", {
    role: form.value.role,
    person_id: form.value.person_id,
    residential_property_id: form.value.residential_property_id
  }, {
    onSuccess: () => { emit("close") },
    onError: (errs) => { errors.value = errs.base ? [errs.base].flat() : Object.values(errs).flat() as string[] },
    onFinish: () => { submitting.value = false }
  })
}
</script>
