<template>
    <div>
        <h1>New User</h1>
        <SelectRol :roles="props.roles" />
    </div>
</template>

<script setup lang="ts">
import { adminUsers } from '@/api';
import SelectRol from '@/components/admin/user/roles/inputs/SelectRol.vue';

const props = defineProps<{
    roles: string[];
}>();
// const submitUrl = adminUsers.create.path();
</script>