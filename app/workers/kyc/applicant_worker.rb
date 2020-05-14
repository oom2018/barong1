require 'sidekiq'
module KYC
  # TODO: Document code.
  class ApplicantWorker
    include Sidekiq::Worker

    # protected_params = params.slice(:type, :first_name, :last_name, :dob, :residence_country, :email)
    def perform(profile_id)
      profile = Profile.find(profile_id)
      applicant = KYCAID::Applicant.create(applicant_params(profile))
      profile.update(applicant_id: applicant.applicant_id, state: 'verified')
    end

    def applicant_params(profile)
      {
        type: 'PERSON',
        first_name: profile.first_name,
        last_name: profile.last_name,
        dob: profile.dob,
        residence_country: profile.country,
        email: profile.user.email,
        phone: profile.user.phones.last.number
      }
    end
  end
end
