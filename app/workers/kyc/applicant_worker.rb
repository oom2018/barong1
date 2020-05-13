require 'sidekiq'
module KYC
  # TODO: Document code.
  class ApplicantWorker
    include Sidekiq::Worker

    # protected_params = params.slice(:type, :first_name, :last_name, :dob, :residence_country, :email)
    def perform(profile_id)
      profile = Profile.find(profile_id)
      applicant = KYCAID::Applicant.create(applicant_params(profile))

      current_metadata = profile.metadata.nil? ? {} : JSON.parse(profile.metadata)
      profile.update(metadata: current_metadata.merge(applicant_id: applicant.applicant_id).to_json, state: 'verified')
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

#  Barond Profile scheme
#  id         :bigint           not null, primary key
#  user_id    :bigint
#  first_name :string(255)
#  last_name  :string(255)
#  dob        :date
#  address    :string(255)
#  postcode   :string(255)
#  city       :string(255)
#  country    :string(255)
#  state      :integer          unsigned
#  metadata   :text(65535)
#  created_at :datetime         not null
#  updated_at :datetime         not null