<template>
  <div>
    <h1>Home</h1>
  </div>
</template>

<script setup>
const props = defineProps({
  auth: {
    type: Object,
    default: () => ({}),
  },
});
</script>