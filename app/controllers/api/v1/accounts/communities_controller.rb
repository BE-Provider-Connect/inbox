class Api::V1::Accounts::CommunitiesController < Api::V1::Accounts::BaseController
  def index
    @communities = if params[:community_group_id].present?
                     Community.for_community_group(params[:community_group_id])
                   else
                     Community.all
                   end
  end

  def show
    @community = Community.find(params[:id])
  end
end
