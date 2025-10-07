class Api::V1::Accounts::CommunityGroupsController < Api::V1::Accounts::BaseController
  def index
    @community_groups = CommunityGroup.all
  end

  def show
    @community_group = CommunityGroup.find(params[:id])
  end
end
