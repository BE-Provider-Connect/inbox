/* global axios */

import PortalsAPI from './portals';
import { getArticleSearchURL } from 'dashboard/helper/URLHelper.js';

class ArticlesAPI extends PortalsAPI {
  constructor() {
    super('articles', { accountScoped: true });
  }

  getArticles({
    pageNumber,
    portalSlug,
    locale,
    status,
    authorId,
    categorySlug,
    sort,
    privacy,
    aiEnabled,
    aiScope,
    communityGroupIds,
    communityIds,
  }) {
    const url = getArticleSearchURL({
      pageNumber,
      portalSlug,
      locale,
      status,
      authorId,
      categorySlug,
      sort,
      privacy,
      aiEnabled,
      aiScope,
      communityGroupIds,
      communityIds,
      host: this.url,
    });

    return axios.get(url);
  }

  searchArticles({ portalSlug, query }) {
    const url = getArticleSearchURL({
      portalSlug,
      query,
      host: this.url,
    });
    return axios.get(url);
  }

  getArticle({ id, portalSlug }) {
    return axios.get(`${this.url}/${portalSlug}/articles/${id}`);
  }

  updateArticle({ portalSlug, articleId, articleObj }) {
    return axios.patch(`${this.url}/${portalSlug}/articles/${articleId}`, {
      article: articleObj,
    });
  }

  createArticle({ portalSlug, articleObj }) {
    const {
      content,
      title,
      authorId,
      categoryId,
      locale,
      private: isPrivate,
    } = articleObj;
    return axios.post(`${this.url}/${portalSlug}/articles`, {
      content,
      title,
      author_id: authorId,
      category_id: categoryId,
      locale,
      private: isPrivate,
    });
  }

  deleteArticle({ articleId, portalSlug }) {
    return axios.delete(`${this.url}/${portalSlug}/articles/${articleId}`);
  }

  reorderArticles({ portalSlug, reorderedGroup, categorySlug }) {
    return axios.post(`${this.url}/${portalSlug}/articles/reorder`, {
      positions_hash: reorderedGroup,
      category_slug: categorySlug,
    });
  }
}

export default new ArticlesAPI();
