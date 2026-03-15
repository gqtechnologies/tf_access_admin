<script setup lang="ts">
import AdminSidebar from '@/components/layout/admin/sidebar.vue'
import { Toaster } from 'vue-sonner'
import 'vue-sonner/style.css'
import { User } from '@/types/user'
const {auth} = defineProps<{
    auth: {
        user: User
    }
}>()
</script>

<template>
    <main>
        <AdminSidebar :user="auth.user">
            <article>
                <slot />
            </article>
            <Toaster position="top-right" />
        </AdminSidebar>
    </main>
</template>