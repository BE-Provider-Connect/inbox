require 'rails_helper'

RSpec.describe CommunitySyncJob do
  subject(:job) { described_class.perform_now }

  let(:service) { instance_double(CommunitySyncService) }
  let(:stats) do
    {
      community_groups: { created: 2, updated: 1 },
      communities: { created: 5, updated: 3 }
    }
  end

  before do
    allow(CommunitySyncService).to receive(:new).and_return(service)
    allow(service).to receive(:perform).and_return(stats)
  end

  it 'enqueues the job' do
    expect { described_class.perform_later }.to have_enqueued_job(described_class)
      .on_queue('scheduled_jobs')
  end

  context 'when called' do
    it 'creates a new CommunitySyncService instance' do
      job
      expect(CommunitySyncService).to have_received(:new)
    end

    it 'calls perform on the service' do
      job
      expect(service).to have_received(:perform)
    end
  end

  context 'when service raises an error' do
    before do
      allow(service).to receive(:perform).and_raise(StandardError, 'API connection failed')
    end

    it 'raises the error' do
      expect { job }.to raise_error(StandardError, 'API connection failed')
    end
  end
end
