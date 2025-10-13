class Api::V1::Api::ConversationsController < Api::BaseController
  include CitadelApiAuthHelper

  skip_before_action :authenticate_user!, :validate_bot_access_token!
  before_action :authenticate_citadel_api!

  respond_to :json

  def show
    # Account ID can be passed as query param for filtering
    # Use display_id instead of id for lookup (webhooks use display_id)
    query = { display_id: params[:id] }
    query[:account_id] = params[:account_id] if params[:account_id].present?

    @conversation = Conversation
                    .includes(:assignee, :contact, :inbox, :account)
                    .find_by(query)

    return render json: { error: 'Conversation not found' }, status: :not_found if @conversation.nil?
  end

  def toggle_status
    # Use display_id instead of id for lookup (webhooks use display_id)
    query = { display_id: params[:id] }
    query[:account_id] = params[:account_id] if params[:account_id].present?

    @conversation = Conversation.find_by(query)

    if @conversation.nil?
      render json: { error: 'Conversation not found' }, status: :not_found
      return
    end

    if params[:status].present?
      @conversation.status = params[:status]
      @conversation.save!
    else
      @conversation.toggle_status
    end

    render json: { status: @conversation.status }
  end
end
