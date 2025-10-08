class CommunitySyncJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    CommunitySyncService.new.perform
  end
end
