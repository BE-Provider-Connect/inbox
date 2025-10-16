json.payload do
  json.array! @assignable_agents do |agent|
    if agent.is_a?(Assistant)
      json.partial! 'api/v1/models/assistant', formats: [:json], resource: agent
    else
      json.partial! 'api/v1/models/agent', formats: [:json], resource: agent
    end
  end
end
