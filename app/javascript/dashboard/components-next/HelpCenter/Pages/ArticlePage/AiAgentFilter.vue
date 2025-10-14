<script setup>
import { reactive, computed, watch, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';

import Button from 'dashboard/components-next/button/Button.vue';
import SingleSelect from 'dashboard/components-next/filter/inputs/SingleSelect.vue';

const props = defineProps({
  communityGroups: {
    type: Array,
    default: () => [],
  },
  communities: {
    type: Array,
    default: () => [],
  },
  currentFilter: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['apply', 'clear']);

const { t } = useI18n();

const state = reactive({
  enabled: undefined,
  scope: undefined,
  selectedGroup: undefined,
  selectedCommunity: undefined,
});

const enabledOptions = computed(() => [
  { id: 'all', name: t('HELP_CENTER.ARTICLES_PAGE.AI_FILTER.ALL') },
  { id: 'true', name: t('HELP_CENTER.ARTICLES_PAGE.AI_FILTER.ENABLED') },
  { id: 'false', name: t('HELP_CENTER.ARTICLES_PAGE.AI_FILTER.DISABLED') },
]);

const scopeOptions = computed(() => [
  { id: 'all', name: t('HELP_CENTER.ARTICLES_PAGE.AI_FILTER.ALL_SCOPES') },
  {
    id: 'organization',
    name: t('HELP_CENTER.ARTICLES_PAGE.AI_FILTER.ORGANIZATION'),
  },
  {
    id: 'community_group',
    name: t('HELP_CENTER.ARTICLES_PAGE.AI_FILTER.COMMUNITY_GROUP'),
  },
  { id: 'community', name: t('HELP_CENTER.ARTICLES_PAGE.AI_FILTER.COMMUNITY') },
]);

const isScopeEnabled = computed(() => {
  return state.enabled?.id === 'true';
});

const hasActiveFilters = computed(() => {
  return (
    (state.enabled && state.enabled.id !== 'all') ||
    (state.scope && state.scope.id !== 'all') ||
    state.selectedGroup !== undefined ||
    state.selectedCommunity !== undefined
  );
});

const applyFilter = () => {
  const filter = {};

  if (state.enabled && state.enabled.id !== 'all') {
    filter.aiEnabled = state.enabled.id;
  }

  // Only include scope and entities if AI is enabled
  if (state.enabled?.id === 'true') {
    if (state.scope && state.scope.id !== 'all') {
      filter.aiScope = state.scope.id;
    }

    if (state.selectedGroup) {
      filter.communityGroupIds = [state.selectedGroup.id];
    }

    if (state.selectedCommunity) {
      filter.communityIds = [state.selectedCommunity.id];
    }
  }

  emit('apply', filter);
};

const clearFilter = () => {
  state.enabled = enabledOptions.value.find(opt => opt.id === 'all');
  state.scope = scopeOptions.value.find(opt => opt.id === 'all');
  state.selectedGroup = undefined;
  state.selectedCommunity = undefined;
  emit('clear');
};

// Initialize state from current filter
const initializeState = () => {
  // Initialize enabled filter
  const enabledId = props.currentFilter.aiEnabled || 'all';
  state.enabled = enabledOptions.value.find(opt => opt.id === enabledId);

  // Only initialize scope and entities if AI is enabled
  if (enabledId === 'true') {
    // Initialize scope filter
    const scopeId = props.currentFilter.aiScope || 'all';
    state.scope = scopeOptions.value.find(opt => opt.id === scopeId);

    // Initialize community group if present
    if (props.currentFilter.communityGroupIds?.length > 0) {
      const groupId = props.currentFilter.communityGroupIds[0];
      state.selectedGroup = props.communityGroups
        .map(g => ({ id: g.id, name: g.name }))
        .find(opt => opt.id === groupId);
    } else {
      state.selectedGroup = undefined;
    }

    // Initialize community if present
    if (props.currentFilter.communityIds?.length > 0) {
      const communityId = props.currentFilter.communityIds[0];
      state.selectedCommunity = props.communities
        .map(c => ({ id: c.id, name: c.name }))
        .find(opt => opt.id === communityId);
    } else {
      state.selectedCommunity = undefined;
    }
  } else {
    // Clear scope and entities when AI is not enabled
    state.scope = scopeOptions.value.find(opt => opt.id === 'all');
    state.selectedGroup = undefined;
    state.selectedCommunity = undefined;
  }
};

// Clear scope and entity selections when AI is disabled
watch(
  () => state.enabled,
  newEnabled => {
    if (newEnabled?.id === 'false' || newEnabled?.id === 'all') {
      state.scope = scopeOptions.value.find(opt => opt.id === 'all');
      state.selectedGroup = undefined;
      state.selectedCommunity = undefined;
    }
  }
);

// Clear entity selections when scope changes
watch(
  () => state.scope,
  newScope => {
    if (newScope?.id !== 'community_group') {
      state.selectedGroup = undefined;
    }
    if (newScope?.id !== 'community') {
      state.selectedCommunity = undefined;
    }
  }
);

// Watch for specific currentFilter fields to update state
watch(
  () => [
    props.currentFilter.aiEnabled,
    props.currentFilter.aiScope,
    props.currentFilter.communityGroupIds,
    props.currentFilter.communityIds,
  ],
  () => {
    initializeState();
  }
);

// Initialize on mount
onMounted(() => {
  initializeState();
});
</script>

<template>
  <div
    class="flex flex-col w-80 bg-n-alpha-3 outline outline-1 outline-n-container backdrop-blur-[100px] shadow-lg gap-4 rounded-xl p-4"
  >
    <div class="flex items-center justify-between">
      <h3 class="text-sm font-semibold">
        {{ t('HELP_CENTER.ARTICLES_PAGE.AI_FILTER.TITLE') }}
      </h3>
      <Button
        v-if="hasActiveFilters"
        :label="t('HELP_CENTER.ARTICLES_PAGE.AI_FILTER.CLEAR')"
        variant="link"
        size="xs"
        @click="clearFilter"
      />
    </div>

    <div class="flex flex-col gap-3">
      <!-- AI Enabled Filter -->
      <div class="flex flex-col gap-2">
        <label class="text-xs font-medium text-n-slate-11">
          {{ t('HELP_CENTER.ARTICLES_PAGE.AI_FILTER.STATUS') }}
        </label>
        <SingleSelect
          v-model="state.enabled"
          :options="enabledOptions"
          :placeholder="t('HELP_CENTER.ARTICLES_PAGE.AI_FILTER.SELECT_STATUS')"
          disable-search
        />
      </div>

      <!-- AI Scope Filter -->
      <div v-if="isScopeEnabled" class="flex flex-col gap-2">
        <label class="text-xs font-medium text-n-slate-11">
          {{ t('HELP_CENTER.ARTICLES_PAGE.AI_FILTER.SCOPE') }}
        </label>
        <SingleSelect
          v-model="state.scope"
          :options="scopeOptions"
          :placeholder="t('HELP_CENTER.ARTICLES_PAGE.AI_FILTER.SELECT_SCOPE')"
          disable-search
        />
      </div>

      <!-- Community Group Select -->
      <div
        v-if="
          isScopeEnabled &&
          state.scope?.id === 'community_group' &&
          communityGroups.length > 0
        "
        class="flex flex-col gap-2"
      >
        <label class="text-xs font-medium text-n-slate-11">
          {{ t('HELP_CENTER.ARTICLES_PAGE.AI_FILTER.COMMUNITY_GROUP') }}
        </label>
        <SingleSelect
          v-model="state.selectedGroup"
          :options="
            communityGroups.map(g => ({
              id: g.id,
              name: g.name,
            }))
          "
          :placeholder="t('HELP_CENTER.ARTICLES_PAGE.AI_FILTER.SELECT_GROUPS')"
        />
      </div>

      <!-- Community Select -->
      <div
        v-if="
          isScopeEnabled &&
          state.scope?.id === 'community' &&
          communities.length > 0
        "
        class="flex flex-col gap-2"
      >
        <label class="text-xs font-medium text-n-slate-11">
          {{ t('HELP_CENTER.ARTICLES_PAGE.AI_FILTER.COMMUNITY') }}
        </label>
        <SingleSelect
          v-model="state.selectedCommunity"
          :options="
            communities.map(c => ({
              id: c.id,
              name: c.name,
            }))
          "
          :placeholder="
            t('HELP_CENTER.ARTICLES_PAGE.AI_FILTER.SELECT_COMMUNITIES')
          "
        />
      </div>
    </div>

    <Button
      :label="t('HELP_CENTER.ARTICLES_PAGE.AI_FILTER.APPLY')"
      size="sm"
      class="w-full"
      @click="applyFilter"
    />
  </div>
</template>
