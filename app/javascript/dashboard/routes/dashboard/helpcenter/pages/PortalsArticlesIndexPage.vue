<script setup>
import { computed, ref, onMounted, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useMapGetter, useStore } from 'dashboard/composables/store.js';
import allLocales from 'shared/constants/locales.js';
import { getArticleStatus } from 'dashboard/helper/portalHelper.js';
import ArticlesPage from 'dashboard/components-next/HelpCenter/Pages/ArticlePage/ArticlesPage.vue';
import CommunitiesAPI from 'dashboard/api/citadel/communities';

const route = useRoute();
const router = useRouter();
const store = useStore();

const pageNumber = ref(1);
const aiFilter = ref({});

const articles = useMapGetter('articles/allArticles');
const categories = useMapGetter('categories/allCategories');
const meta = useMapGetter('articles/getMeta');
const portalMeta = useMapGetter('portals/getMeta');
const currentUserId = useMapGetter('getCurrentUserID');
const getPortalBySlug = useMapGetter('portals/portalBySlug');
// TODO: Replace with actual store getters when community modules are available
const communityGroups = ref([]);
const communities = ref([]);

const selectedPortalSlug = computed(() => route.params.portalSlug);
const selectedCategorySlug = computed(() => route.params.categorySlug);
const status = computed(() => getArticleStatus(route.params.tab));

const author = computed(() =>
  route.params.tab === 'mine' ? currentUserId.value : null
);

const activeLocale = computed(() => route.params.locale);
const portal = computed(() => getPortalBySlug.value(selectedPortalSlug.value));
const allowedLocales = computed(() => {
  if (!portal.value) {
    return [];
  }
  const { allowed_locales: allAllowedLocales } = portal.value.config;
  return allAllowedLocales.map(locale => {
    return {
      id: locale.code,
      name: allLocales[locale.code],
      code: locale.code,
    };
  });
});

const defaultPortalLocale = computed(() => {
  return portal.value?.meta?.default_locale;
});

const selectedLocaleInPortal = computed(() => {
  return route.params.locale || defaultPortalLocale.value;
});

const isCategoryArticles = computed(() => {
  return (
    route.name === 'portals_categories_articles_index' ||
    route.name === 'portals_categories_articles_edit' ||
    route.name === 'portals_categories_index'
  );
});

const fetchArticles = ({ pageNumber: pageNumberParam } = {}) => {
  store.dispatch('articles/index', {
    pageNumber: pageNumberParam || pageNumber.value,
    portalSlug: selectedPortalSlug.value,
    locale: activeLocale.value,
    status: status.value,
    authorId: author.value,
    categorySlug: selectedCategorySlug.value,
    privacy: route.query.privacy,
    aiEnabled: aiFilter.value.aiEnabled,
    aiScope: aiFilter.value.aiScope,
    communityGroupIds: aiFilter.value.communityGroupIds,
    communityIds: aiFilter.value.communityIds,
  });
};

const onPageChange = pageNumberParam => {
  fetchArticles({ pageNumber: pageNumberParam });
};

const fetchCommunityData = async () => {
  try {
    const [groupsResponse, communitiesResponse] = await Promise.all([
      CommunitiesAPI.getCommunityGroups(),
      CommunitiesAPI.getCommunities(),
    ]);
    communityGroups.value = groupsResponse.data || [];
    communities.value = communitiesResponse.data || [];
  } catch (error) {
    // Silently handle error - community data is optional
    communityGroups.value = [];
    communities.value = [];
  }
};

const fetchPortalAndItsCategories = async locale => {
  await store.dispatch('portals/index');
  const selectedPortalParam = {
    portalSlug: selectedPortalSlug.value,
    locale: locale || selectedLocaleInPortal.value,
  };
  await Promise.all([
    store.dispatch('portals/show', selectedPortalParam),
    store.dispatch('categories/index', selectedPortalParam),
    store.dispatch('agents/get'),
    fetchCommunityData(),
  ]);
};

const handleAiFilterChange = filter => {
  // Update URL query params to persist filter
  const query = { ...route.query };

  // Clean up old AI params
  delete query.ai_enabled;
  delete query.ai_scope;
  delete query.community_group_ids;
  delete query.community_ids;

  // Add new AI params if present
  if (filter.aiEnabled) query.ai_enabled = filter.aiEnabled;
  if (filter.aiScope) query.ai_scope = filter.aiScope;
  if (filter.communityGroupIds?.length)
    query.community_group_ids = filter.communityGroupIds.join(',');
  if (filter.communityIds?.length)
    query.community_ids = filter.communityIds.join(',');

  // Pushing query will trigger route watcher which handles the rest
  router.push({ query });
};

onMounted(() => {
  // Fetch portal and categories once on mount
  // Route watcher with immediate: true handles article fetching
  fetchPortalAndItsCategories();
});

watch(
  () => route.fullPath,
  () => {
    // Update AI filter from URL changes (e.g., browser back/forward)
    const query = route.query;
    aiFilter.value = {
      aiEnabled: query.ai_enabled,
      aiScope: query.ai_scope,
      communityGroupIds:
        query.community_group_ids?.split(',').filter(Boolean).map(Number) || [],
      communityIds:
        query.community_ids?.split(',').filter(Boolean).map(Number) || [],
    };

    pageNumber.value = 1;
    fetchArticles();
  },
  { immediate: true }
);
</script>

<template>
  <div class="w-full h-full">
    <ArticlesPage
      v-if="portal"
      :articles="articles"
      :portal-name="portal.name"
      :categories="categories"
      :allowed-locales="allowedLocales"
      :meta="meta"
      :portal-meta="portalMeta"
      :is-category-articles="isCategoryArticles"
      :community-groups="communityGroups"
      :communities="communities"
      :current-ai-filter="aiFilter"
      @page-change="onPageChange"
      @fetch-portal="fetchPortalAndItsCategories"
      @ai-filter-change="handleAiFilterChange"
    />
  </div>
</template>
