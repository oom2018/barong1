# frozen_string_literal: true

class KycService
  class << self
    def profile_step(profile)
      user = profile.user
      profile_label = user.labels.find_by(key: :profile)

      if profile_label.nil? # first profile everBarong::App.config.kyc_provider == 'local'
        user.labels.create(key: :profile, value: profile.state, scope: :private)
      else
        profile_label.update(value: profile.state) # re-submitted profile
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

      return unless document.doc_type.in?['Passport', 'Driver License', 'Identity Card']
      return unless document.doc_type == 'Passport' && user.documents.where(identificator: document.identificator).count == 2 ||
                    user.documents.where(identificator: document.identificator).count == 3

      if user_document_label.nil? # first document ever
        user.labels.create(key: :document, value: :pending, scope: :private)
      else
        user_document_label.update(value: :pending) # re-submitted document
      end

      return if Barong::App.config.kyc_provider == 'local'
      KYC::DocumentWorker.perform_async(user.id, document.identificator) if Barong::App.config.kyc_provider == 'kycaid'        
    end

    def address_step(address_params)
      # user = User.find(address_params[:user_id])
      # user_address_label = user.labels.find_by(key: :address)

      # if user_address_label.nil? # first address ever
      #   user.labels.create(key: :address, value: :pending, scope: :private)
      # else
      #   user_address_label.update(value: :pending) # re-submitted address
      # end
      # return if Barong::App.config.kyc_provider == 'local'

      # KYC::AddressWorker.perform_async(address_params.merge(user_id: user.id, identificator: address_params[:identificator])) if Barong::App.config.kyc_provider == 'kycaid'
    end

    def kycaid_callback(verification_id, applicant_id)
      return 422 unless Barong::App.config.kyc_provider == 'kycaid'

      KYC::VerificationsWorker.perform_async(verification_id, applicant_id)
      200
    end
  end
end
