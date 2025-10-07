/* global axios */
import ApiClient from '../ApiClient';

class CommunitiesAPI extends ApiClient {
  constructor() {
    super('', { accountScoped: true });
  }

  getCommunityGroups() {
    return axios.get(`${this.url}/community_groups`);
  }

  getCommunities(communityGroupId = null) {
    const params = communityGroupId
      ? { community_group_id: communityGroupId }
      : {};
    return axios.get(`${this.url}/communities`, { params });
  }
}

export default new CommunitiesAPI();
