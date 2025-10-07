<script setup>
import { reactive, watch, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';

import Button from 'dashboard/components-next/button/Button.vue';
import ToggleSwitch from 'dashboard/components-next/switch/Switch.vue';
import SingleSelect from 'dashboard/components-next/filter/inputs/SingleSelect.vue';

const props = defineProps({
  article: {
    type: Object,
    required: true,
  },
  communityGroups: {
    type: Array,
    default: () => [],
  },
  communities: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['saveArticle', 'close']);

const { t } = useI18n();

const i18nBase = 'HELP_CENTER.ARTICLE.AI_AGENT';

const state = reactive({
  enabled: false,
  scope: undefined,
  selectedEntity: undefined,
  isSaving: false,
  isUpdatingFromProp: false,
});

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
  if (state.scope?.id === 'community_group') {
    return communityGroupOptions.value;
  }
  if (state.scope?.id === 'community') {
    return communityOptions.value;
  }
  return [];
});

const showEntitySelector = computed(() => {
  return (
    state.enabled &&
    state.scope &&
    (state.scope.id === 'community_group' || state.scope.id === 'community')
  );
});

// Computed property to ensure scope is never null (for Vue validation)
const scopeModel = computed({
  get: () => state.scope ?? undefined,
  set: val => {
    state.scope = val ?? undefined;
  },
});

const updateState = () => {
  state.isUpdatingFromProp = true;

  state.enabled = props.article.aiAgentEnabled || false;

  // Map scope string to scope object
  if (props.article.aiAgentScope) {
    state.scope = scopeOptions.find(
      opt => opt.id === props.article.aiAgentScope
    );
  } else {
    state.scope = undefined;
  }

  // Get the first selected entity from arrays and map to entity object
  if (props.article.communityGroups?.length > 0) {
    const group = props.article.communityGroups[0];
    state.selectedEntity = { id: group.id, name: group.name };
  } else if (props.article.communities?.length > 0) {
    const community = props.article.communities[0];
    state.selectedEntity = { id: community.id, name: community.name };
  } else {
    state.selectedEntity = undefined;
  }

  // Use nextTick to reset the flag after all reactive updates complete
  setTimeout(() => {
    state.isUpdatingFromProp = false;
  }, 0);
};

const saveImmediately = () => {
  const payload = {
    ai_agent_enabled: state.enabled,
  };

  if (!state.enabled) {
    // When disabling, clear all AI agent related fields
    payload.ai_agent_scope = null;
    payload.community_group_ids = [];
    payload.community_ids = [];
  } else if (state.scope) {
    // Enabled with a scope selected
    payload.ai_agent_scope = state.scope.id;

    if (state.scope.id === 'community_group' && state.selectedEntity) {
      payload.community_group_ids = [state.selectedEntity.id];
      payload.community_ids = [];
    } else if (state.scope.id === 'community' && state.selectedEntity) {
      payload.community_ids = [state.selectedEntity.id];
      payload.community_group_ids = [];
    } else if (state.scope.id === 'organization') {
      payload.community_group_ids = [];
      payload.community_ids = [];
    }
  } else {
    // Enabled but no scope selected - clear scope and entities
    payload.ai_agent_scope = null;
    payload.community_group_ids = [];
    payload.community_ids = [];
  }

  state.isSaving = true;
  emit('saveArticle', payload);

  setTimeout(() => {
    state.isSaving = false;
  }, 1000);
};

watch(
  () => state.enabled,
  () => {
    // Only save if not updating from prop (prevent loop)
    if (!state.isUpdatingFromProp) {
      // Only save immediately when disabling
      // When enabling, wait for scope selection
      if (!state.enabled) {
        saveImmediately();
      }
    }
  }
);

watch(
  () => state.scope,
  (newScope, oldScope) => {
    if (
      !state.isUpdatingFromProp &&
      newScope &&
      newScope?.id !== oldScope?.id
    ) {
      // Scope changed by user - clear entity selection
      state.selectedEntity = undefined;

      if (newScope.id === 'organization') {
        // Organization scope - save immediately
        saveImmediately();
      }
      // For community/community_group scopes, don't save until entity is selected
    }
  }
);

watch(
  () => state.selectedEntity,
  newEntity => {
    if (
      !state.isUpdatingFromProp &&
      newEntity &&
      state.enabled &&
      state.scope &&
      (state.scope.id === 'community' || state.scope.id === 'community_group')
    ) {
      // Entity selected for community/community_group scope - save immediately
      saveImmediately();
    }
  }
);

// Watch for article changes to update state
watch(
  () => [props.article.aiAgentEnabled, props.article.aiAgentScope],
  ([newEnabled, newScope]) => {
    // Always update state when article changes (isUpdatingFromProp flag will prevent save loops)
    if (newEnabled !== state.enabled || newScope !== state.scope?.id) {
      updateState();
    }
  }
);

onMounted(() => {
  updateState();
});
</script>

<template>
  <div
    class="flex flex-col absolute w-[25rem] bg-n-alpha-3 outline outline-1 outline-n-container backdrop-blur-[100px] shadow-lg gap-6 rounded-xl p-6"
  >
    <div class="flex items-center justify-between">
      <h3>{{ t(`${i18nBase}.TITLE`) }}</h3>
      <Button
        icon="i-lucide-x"
        size="sm"
        variant="ghost"
        color="slate"
        class="hover:text-n-slate-11"
        @click="emit('close')"
      />
    </div>

    <div class="flex flex-col gap-4">
      <!-- Enable Toggle -->
      <div class="flex items-center justify-between">
        <label class="text-sm font-medium text-n-slate-12">
          {{ t(`${i18nBase}.ENABLE_LABEL`) }}
        </label>
        <ToggleSwitch v-model="state.enabled" :disabled="state.isSaving" />
      </div>

      <!-- Scope Selection -->
      <div v-if="state.enabled" class="flex flex-col gap-4">
        <div class="flex flex-col gap-2">
          <label class="text-sm font-medium text-n-slate-12">
            {{ t(`${i18nBase}.SCOPE_LABEL`) }}
          </label>
          <SingleSelect
            v-model="scopeModel"
            :options="scopeOptions"
            :placeholder="t(`${i18nBase}.SELECT_SCOPE`)"
            disable-search
          />
        </div>

        <!-- Entity Selector -->
        <div v-if="showEntitySelector" class="flex flex-col gap-2">
          <label class="text-sm font-medium text-n-slate-12">
            {{
              state.scope.id === 'community_group'
                ? t(`${i18nBase}.SELECT_COMMUNITY_GROUP`)
                : t(`${i18nBase}.SELECT_COMMUNITY`)
            }}
          </label>
          <SingleSelect
            v-model="state.selectedEntity"
            :options="entityOptions"
            :placeholder="
              state.scope.id === 'community_group'
                ? t(`${i18nBase}.SELECT_COMMUNITY_GROUP`)
                : t(`${i18nBase}.SELECT_COMMUNITY`)
            "
          />
          <p
            v-if="!state.selectedEntity && entityOptions.length === 0"
            class="text-xs text-n-slate-10"
          >
            {{
              state.scope.id === 'community_group'
                ? t(`${i18nBase}.NO_COMMUNITY_GROUPS`)
                : t(`${i18nBase}.NO_COMMUNITIES`)
            }}
          </p>
        </div>
      </div>
    </div>
  </div>
</template>
