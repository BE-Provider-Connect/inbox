# frozen_string_literal: true

module Citadel::Api::V1::AccountsController
  def update
    @account.assign_attributes(account_params.slice(:name, :locale, :domain, :support_email, :external_id))
    @account.custom_attributes.merge!(custom_attributes_params)
    @account.settings.merge!(settings_params)
    @account.custom_attributes['onboarding_step'] = 'invite_team' if @account.custom_attributes['onboarding_step'] == 'account_update'
    @account.save!
  end

  private

  def account_params
    params.permit(:account_name, :email, :name, :password, :locale, :domain, :support_email, :external_id, :user_full_name)
  end
end
