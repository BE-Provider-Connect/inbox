class Api::V1::Accounts::CommunitiesController < Api::V1::Accounts::BaseController
  def index
    @communities = if params[:community_group_id].present?
                     Current.account.communities.for_community_group(params[:community_group_id])
                   else
                     Current.account.communities
                   end
  end

  def show
    @community = Current.account.communities.find(params[:id])
  end
end
