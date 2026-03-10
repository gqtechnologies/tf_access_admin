<script setup>
import { Link } from '@inertiajs/vue3'
import AdminSidebar from '@/components/layout/admin/sidebar.vue'
import { Toaster } from 'vue-sonner'
import 'vue-sonner/style.css'
</script>

<template>
    <main>
        <AdminSidebar>
            <article>
                <slot />
            </article>
            <Toaster position="top-right" />
        </AdminSidebar>
    </main>
</template>