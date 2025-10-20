import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

/**
 * Composable for formatting AI Agent labels consistently across the application
 * @param {Object} config - Computed or ref containing AI agent configuration
 * @param {boolean} config.enabled - Whether AI agent is enabled
 * @param {string} config.scope - AI agent scope (organization, community_group, community)
 * @param {Array} config.communityGroups - Array of community group objects
 * @param {Array} config.communities - Array of community objects
 * @returns {Object} Object containing the computed label
 */
export const useAiAgentLabel = config => {
  const { t } = useI18n();

  const label = computed(() => {
    const cfg = config.value || config;

    if (!cfg.enabled) {
      return t('HELP_CENTER.ARTICLE.AI_OFF');
    }

    if (cfg.scope === 'organization') {
      return t('HELP_CENTER.ARTICLE.AI_ON_ORGANIZATION');
    }

    if (cfg.scope === 'community_group' && cfg.communityGroups?.length > 0) {
      const groupNames = cfg.communityGroups.map(g => g.name).join(', ');
      return `${t('HELP_CENTER.ARTICLE.AI_ON')} ${groupNames}`;
    }

    if (cfg.scope === 'community' && cfg.communities?.length > 0) {
      const communityNames = cfg.communities.map(c => c.name).join(', ');
      return `${t('HELP_CENTER.ARTICLE.AI_ON')} ${communityNames}`;
    }

    return t('HELP_CENTER.ARTICLE.AI_ON');
  });

  return { label };
};
