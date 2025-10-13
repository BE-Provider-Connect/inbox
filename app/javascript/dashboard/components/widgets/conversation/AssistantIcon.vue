<script setup>
import { computed } from 'vue';

const props = defineProps({
  size: {
    type: Number,
    default: 24,
  },
});

const sizeClass = computed(() => {
  const sizeMap = {
    16: 'w-4 h-4',
    20: 'w-5 h-5',
    24: 'w-6 h-6',
    32: 'w-8 h-8',
    40: 'w-10 h-10',
  };
  return sizeMap[props.size] || 'w-6 h-6';
});
</script>

<template>
  <div
    :class="sizeClass"
    class="flex items-center justify-center rounded-full bg-gradient-to-br from-purple-500 to-blue-500"
  >
    <fluent-icon icon="bot" :size="size * 0.6" class="text-white" />
  </div>
</template>
