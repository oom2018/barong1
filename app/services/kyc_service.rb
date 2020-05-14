# frozen_string_literal: true

class KycService
  class << self
    def profile_step(profile)
      profile_label = profile.user.labels.find_by(key: :profile)

      if profile_label.nil? # first profile everBarong::App.config.kyc_provider == 'local'
        user.labels.create(key: :profile, value: state, scope: :private)
      else
        profile_label.update(value: state) # re-submitted profile
      end
      
      return if Barong::App.config.kyc_provider == 'local'

      if Barong::App.config.kyc_provider == 'kycaid'
        return if profile.state == 'rejected' || profile.state == 'verified'
        # profile_label.create(value: 'submitted')
        KYC::ApplicantWorker.perform_async(profile.id)
      end
    end

    def document_step(document)
      user = document.user
      user_document_label = user.labels.find_by(key: :document)

      if user_document_label.nil? # first document ever
        user.labels.create(key: :document, value: :pending, scope: :private)
      else
        user_document_label.update(value: :pending) # re-submitted document
      end

      return if Barong::App.config.kyc_provider == 'local'
      KYC::DocumentWorker.perform_async(user.id) if Barong::App.config.kyc_provider == 'kycaid'        
    end

    def address_step(address_params)
      user = address_document.user
      user_address_label = user.labels.find_by(key: :address)

      if user_address_label.nil? # first address ever
        user.labels.create(key: :address, value: :pending, scope: :private)
      else
        user_address_label.update(value: :pending) # re-submitted address
      end
      return if Barong::App.config.kyc_provider == 'local'
      
      KYC::AddressWorker.perform_async(user.id) if Barong::App.config.kyc_provider == 'kycaid'
    end

    def kycaid_callback(verification_id, applicant_id)
      return 422 unless Barong::App.config.kyc_provider == 'kycaid'

      KYC::VerificationWorker.perform_async(verification_id, applicant_id)
      200
    end
  end
end
