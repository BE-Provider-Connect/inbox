class Api::V1::Accounts::CommunityGroupsController < Api::V1::Accounts::BaseController
  def index
    @community_groups = Current.account.community_groups
  end

  def show
    @community_group = Current.account.community_groups.find(params[:id])
  end
end
