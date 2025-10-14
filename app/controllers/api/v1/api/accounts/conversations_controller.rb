class Api::V1::Api::Accounts::ConversationsController < Api::BaseController
  include CitadelApiAuthHelper

  skip_before_action :authenticate_user!, :validate_bot_access_token!
  before_action :authenticate_citadel_api!

  respond_to :json

  def show
    # Use display_id instead of id for lookup (webhooks use display_id)
    # account_id is required since display_id is only unique within an account
    @conversation = Conversation
                    .includes(:assignee, :contact, :inbox, :account)
                    .find_by(display_id: params[:id], account_id: params[:account_id])

    return render json: { error: 'Conversation not found' }, status: :not_found if @conversation.nil?
  end

  def toggle_status
    # Use display_id instead of id for lookup (webhooks use display_id)
    # account_id is required since display_id is only unique within an account
    @conversation = Conversation.find_by(display_id: params[:id], account_id: params[:account_id])

    return render json: { error: 'Conversation not found' }, status: :not_found if @conversation.nil?

    @conversation.update!(status: permitted_params[:status])

    render json: { status: @conversation.status }
  end

  private

  def permitted_params
    params.permit(:status)
  end
end
