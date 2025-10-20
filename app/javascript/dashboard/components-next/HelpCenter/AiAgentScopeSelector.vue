<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import SingleSelect from 'dashboard/components-next/filter/inputs/SingleSelect.vue';

const props = defineProps({
  scope: {
    type: Object,
    default: undefined,
  },
  selectedEntity: {
    type: Object,
    default: undefined,
  },
  communityGroups: {
    type: Array,
    default: () => [],
  },
  communities: {
    type: Array,
    default: () => [],
  },
  disabled: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['update:scope', 'update:selectedEntity']);

const { t } = useI18n();

const scopeOptions = [
  { id: 'organization', name: 'Organization' },
  { id: 'community_group', name: 'Community Group' },
  { id: 'community', name: 'Community' },
];

const communityGroupOptions = computed(() =>
  props.communityGroups.map(group => ({
    id: group.id,
    name: group.name,
  }))
);

const communityOptions = computed(() =>
  props.communities.map(community => ({
    id: community.id,
    name: community.name,
  }))
);

const entityOptions = computed(() => {
  if (props.scope?.id === 'community_group') {
    return communityGroupOptions.value;
  }
  if (props.scope?.id === 'community') {
    return communityOptions.value;
  }
  return [];
});

const showEntitySelector = computed(() => {
  return (
    props.scope &&
    (props.scope.id === 'community_group' || props.scope.id === 'community')
  );
});

const scopeModel = computed({
  get: () => props.scope ?? undefined,
  set: val => emit('update:scope', val ?? undefined),
});

const entityModel = computed({
  get: () => props.selectedEntity ?? undefined,
  set: val => emit('update:selectedEntity', val ?? undefined),
});

const entityLabel = computed(() => {
  if (props.scope?.id === 'community_group') {
    return t('HELP_CENTER.ARTICLE.AI_AGENT.SELECT_COMMUNITY_GROUP');
  }
  if (props.scope?.id === 'community') {
    return t('HELP_CENTER.ARTICLE.AI_AGENT.SELECT_COMMUNITY');
  }
  return '';
});

const noEntitiesMessage = computed(() => {
  if (props.scope?.id === 'community_group') {
    return t('HELP_CENTER.ARTICLE.AI_AGENT.NO_COMMUNITY_GROUPS');
  }
  if (props.scope?.id === 'community') {
    return t('HELP_CENTER.ARTICLE.AI_AGENT.NO_COMMUNITIES');
  }
  return '';
});
</script>

<template>
  <div class="flex flex-col gap-4">
    <!-- Scope Selection -->
    <div class="flex flex-col gap-2">
      <label class="text-sm font-medium text-n-slate-12">
        {{ t('HELP_CENTER.ARTICLE.AI_AGENT.SCOPE_LABEL') }}
      </label>
      <SingleSelect
        v-model="scopeModel"
        :options="scopeOptions"
        :placeholder="t('HELP_CENTER.ARTICLE.AI_AGENT.SELECT_SCOPE')"
        :disabled="disabled"
        disable-search
      />
    </div>

    <!-- Entity Selector -->
    <div v-if="showEntitySelector" class="flex flex-col gap-2">
      <label class="text-sm font-medium text-n-slate-12">
        {{ entityLabel }}
      </label>
      <SingleSelect
        v-model="entityModel"
        :options="entityOptions"
        :placeholder="entityLabel"
        :disabled="disabled"
      />
      <p
        v-if="!selectedEntity && entityOptions.length === 0"
        class="text-xs text-n-slate-10"
      >
        {{ noEntitiesMessage }}
      </p>
    </div>
  </div>
</template>
