# frozen_string_literal: true

class KycService
  class << self
    def profile_step(profile)
      profile_label = profile.user.labels.find_by(key: :profile)

      if Barong::App.config.kyc_provider == 'local'
        return user.labels.create(key: :profile, value: state, scope: :private) if profile_label.nil? # first profile ever

        profile_label.update(value: state) # re-submitted profile
      elsif Barong::App.config.kyc_provider == 'kycaid'
        return if profile.state == 'rejected' || profile.state == 'verified'
        # profile_label.create(value: 'submitted')
        KYC::ApplicantWorker.perform_async(profile.id)
      end
    end

    def document_step(document)
      user = document.user
      user_document_label = user.labels.find_by(key: :document)

      if Barong::App.config.kyc_provider == 'local'
        return user.labels.create(key: :document, value: :pending, scope: :private) if user_document_label.nil? # first document ever

        user_document_label.update(value: :pending) # re-submitted document
      elsif Barong::App.config.kyc_provider == 'kycaid'
        # make document uploads as array in DB

        KYC::DocumentWorker.perform_async(user.id)
      end
    end

    def address_step(address_params)
      user = address_document.user
      user_address_label = user.labels.find_by(key: :address)

      if Barong::App.config.kyc_provider == 'local'
        return user.labels.create(key: :address, value: :pending, scope: :private) if user_address_label.nil? # first address ever

        user_address_label.update(value: :pending) # re-submitted address
      elsif Barong::App.config.kyc_provider == 'kycaid'
        KYC::AddressWorker.perform_async(user.id)
      end
    end

    def kycaid_callback(params)
      return 422 unless Barong::App.config.kyc_provider == 'kycaid'

      KYC::AddressWorker.perform_async(params)
      200
    end
  end
end
