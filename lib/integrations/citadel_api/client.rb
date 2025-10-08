module Integrations::CitadelApi
  class Client
    include HTTParty

    base_uri ENV.fetch('CITADEL_API_URL', 'http://localhost:8080')

    def initialize
      @api_key = ENV.fetch('CITADEL_API_KEY')
    end

    def fetch_community_groups
      response = self.class.get(
        '/v1/sync/community-groups',
        headers: auth_headers
      )

      handle_response(response)
    end

    def fetch_communities
      response = self.class.get(
        '/v1/sync/communities',
        headers: auth_headers
      )

      handle_response(response)
    end

    private

    def auth_headers
      {
        'Authorization' => "Bearer #{@api_key}",
        'Content-Type' => 'application/json'
      }
    end

    def handle_response(response)
      case response.code
      when 200
        response.parsed_response
      when 401
        raise StandardError, 'Unauthorized: Invalid API key'
      else
        raise StandardError, "API request failed with status #{response.code}: #{response.body}"
      end
    end
  end
end
