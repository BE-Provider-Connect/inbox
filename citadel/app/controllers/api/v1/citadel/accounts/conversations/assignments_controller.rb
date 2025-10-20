class Api::V1::Citadel::Accounts::Conversations::AssignmentsController < Api::BaseController
  include CitadelApiAuthHelper

  skip_before_action :authenticate_user!, :validate_bot_access_token!
  before_action :authenticate_citadel_api!
  before_action :set_conversation

  respond_to :json

  def create
    assignee = find_assignee

    # Set Current.executed_by to enable activity message creation
    # Since this is an API call without a user session, we use :automation
    Current.executed_by = :automation

    @conversation.assignee = assignee
    @conversation.save!
    render_assignee(assignee)
  end

  private

  def find_assignee
    return nil if params[:assignee_id].blank?

    if params[:assignee_id].to_s.start_with?('assistant_')
      # Extract numeric ID from "assistant_1" format
      numeric_id = params[:assignee_id].to_s.gsub(/\D/, '').to_i
      Assistant.find_by(id: numeric_id)
    else
      @conversation.account.users.find_by(id: params[:assignee_id])
    end
  end

  def render_assignee(assignee)
    if assignee.nil?
      render json: nil
    else
      # Determine which partial to use based on assignee_type, not the object's class
      partial_name = @conversation.assignee_type == 'Assistant' ? 'api/v1/models/assistant' : 'api/v1/models/agent'
      render partial: partial_name, formats: [:json], locals: { resource: assignee }
    end
  end

  def set_conversation
    # Use display_id instead of id for lookup (webhooks use display_id)
    # account_id is required since display_id is only unique within an account
    @conversation = Conversation.find_by(display_id: params[:conversation_id], account_id: params[:account_id])

    render json: { error: 'Conversation not found' }, status: :not_found if @conversation.nil?
  end
end
