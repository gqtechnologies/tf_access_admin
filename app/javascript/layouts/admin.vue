<script setup>
import { Link } from '@inertiajs/vue3'
import AdminSidebar from '@/components/layout/admin/sidebar.vue'
</script>

<template>
    <main>
        <AdminSidebar>
            <article>
                <slot />
            </article>
        </AdminSidebar>
    </main>
</template>