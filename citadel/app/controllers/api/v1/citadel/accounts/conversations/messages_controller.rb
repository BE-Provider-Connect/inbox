class Api::V1::Citadel::Accounts::Conversations::MessagesController < Api::BaseController
  include CitadelApiAuthHelper

  skip_before_action :authenticate_user!, :validate_bot_access_token!
  before_action :authenticate_citadel_api!
  before_action :set_conversation

  respond_to :json

  def index
    @messages = @conversation.messages
                             .includes(:sender, :attachments)
                             .order(created_at: :asc)
  end

  def create
    @message = Messages::MessageBuilder.new(nil, @conversation, message_params).perform
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def set_conversation
    # Use display_id instead of id for lookup (webhooks use display_id)
    # account_id is required since display_id is only unique within an account
    @conversation = Conversation.find_by(display_id: params[:conversation_id], account_id: params[:account_id])

    render json: { error: 'Conversation not found' }, status: :not_found if @conversation.nil?
  end

  def message_params
    params.permit(:content, :message_type, :private, :echo_id)
  end
end
