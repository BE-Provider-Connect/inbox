# frozen_string_literal: true

module Citadel::Api::V1::Accounts::Conversations::AssignmentsController
  def create
    if params.key?(:assignee_id)
      set_assignee
    elsif params.key?(:team_id)
      set_team
    else
      render json: nil
    end
  end

  private

  def set_assignee
    type = params.require(:assignee_type).to_s.safe_constantize
    id   = params.require(:assignee_id)

    @agent = if type == User
               Current.account.users.find_by(id: id)
             elsif type == Assistant
               # Strip 'assistant_' prefix since frontend sends it with prefix
               actual_id = id.to_s.sub(/^assistant_/, '')
               type.find(actual_id)
             end

    Rails.logger.info '=== CITADEL ASSIGNMENT DEBUG ==='
    Rails.logger.info "Current.user: #{Current.user&.name || 'nil'}"
    Rails.logger.info "Agent: #{@agent&.name} (#{@agent&.class})"
    Rails.logger.info "Conversation assignee_id changed: #{@conversation.assignee_id} -> #{@agent&.id}"

    @conversation.assignee = @agent
    @conversation.save!

    Rails.logger.info "After save - assignee_id: #{@conversation.assignee_id}, assignee_type: #{@conversation.assignee_type}"
    Rails.logger.info "saved_change_to_assignee_id?: #{@conversation.saved_change_to_assignee_id?}"
    Rails.logger.info '================================'

    render_agent
  end

  def render_agent
    return render json: nil if @agent.nil?

    # Determine partial based on actual type, handling STI (SuperAdmin -> user)
    partial_name = if @agent.is_a?(Assistant)
                     'assistant'
                   else
                     'agent' # Use agent partial for all User subclasses (User, SuperAdmin, etc)
                   end

    render(
      partial: "api/v1/models/#{partial_name}",
      formats: [:json],
      locals: { resource: @agent }
    )
  end
end
