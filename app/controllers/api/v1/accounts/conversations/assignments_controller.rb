class Api::V1::Accounts::Conversations::AssignmentsController < Api::V1::Accounts::Conversations::BaseController
  # assigns agent/team to a conversation
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

    @conversation.assignee = @agent
    @conversation.save!
    render_agent
  end

  def render_agent
    return render json: nil if @agent.nil?

    render(
      partial: "api/v1/models/#{@agent.model_name.singular}",
      formats: [:json],
      locals: { resource: @agent }
    )
  end

  def set_team
    @team = Current.account.teams.find_by(id: params[:team_id])
    @conversation.update!(team: @team)
    render json: @team
  end
end
