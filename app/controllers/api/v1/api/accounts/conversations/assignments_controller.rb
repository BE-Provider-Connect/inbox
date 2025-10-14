class Api::V1::Api::Accounts::Conversations::AssignmentsController < Api::BaseController
  include CitadelApiAuthHelper

  skip_before_action :authenticate_user!, :validate_bot_access_token!
  before_action :authenticate_citadel_api!
  before_action :set_conversation

  respond_to :json

  def create
    assignee = (@conversation.account.users.find_by(id: params[:assignee_id]) if params[:assignee_id].present?)
    @conversation.update!(assignee: assignee)
    render json: { assignee_id: @conversation.assignee_id }
  end

  private

  def set_conversation
    # Use display_id instead of id for lookup (webhooks use display_id)
    # account_id is required since display_id is only unique within an account
    @conversation = Conversation.find_by(display_id: params[:conversation_id], account_id: params[:account_id])

    render json: { error: 'Conversation not found' }, status: :not_found if @conversation.nil?
  end
end
