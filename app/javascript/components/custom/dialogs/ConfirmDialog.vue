<template>
    <AlertDialog>
        <AlertDialogTrigger asChild>
            <slot />
        </AlertDialogTrigger>
        <AlertDialogContent>
            <AlertDialogHeader>
                <AlertDialogTitle>{{ title }}</AlertDialogTitle>
                <AlertDialogDescription v-if="subtitle">{{ subtitle }}</AlertDialogDescription>
                <AlertDialogDescription v-if="description">{{ description }}</AlertDialogDescription>
            </AlertDialogHeader>
            <AlertDialogFooter>
                <AlertDialogCancel>{{ t('common.actions.cancel') }}</AlertDialogCancel>
                <AlertDialogAction @click="onConfirm">{{ t('common.actions.continue') }}</AlertDialogAction>
            </AlertDialogFooter>
        </AlertDialogContent>
    </AlertDialog>
</template>

<script setup lang="ts">
import { AlertDialog, AlertDialogTrigger, AlertDialogContent, AlertDialogHeader, AlertDialogFooter, AlertDialogTitle, AlertDialogDescription, AlertDialogCancel, AlertDialogAction } from "@/components/ui/alert-dialog";
import { ref } from "vue";
import { useI18n } from "vue-i18n";

const { t } = useI18n()

const open = ref<boolean>(false)
const props = withDefaults(defineProps<{
    title: string,
    subtitle?: string,
    description?: string,
    onConfirm?: () => void,
}>(), {
    title: "Confirmation",
    description: "Are you sure?",
    onConfirm: () => { },
})

defineExpose({
    open: open
})
</script>