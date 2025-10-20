# frozen_string_literal: true

module Citadel::SlackUploadsController
  def show
    if @blob
      redirect_to blob_url, allow_other_host: true
    else
      redirect_to avatar_url, allow_other_host: true
    end
  end
end
