require 'sidekiq'
module KYC
  # TODO: Document code.
  class VerificationsWorker
    include Sidekiq::Worker

    def perform(verification_id, applicant_id)
      user = Profile.find_by(applicant_id: applicant_id).user
      verification = KYCAID::Verification.fetch(verification_id)
      return unless verification.status == 'completed'

      verification.verifications.each do |k, v|
        if v["verified"]
          next unless user.labels.find_by_key(k)
          # find user by applicant_id
          user.labels.find_by_key(k).update(key: k, value: 'verified', scope: :private)
        else
          # we can insert a comment
          user.labels.find_by_key(k).update(key: k, value: 'rejected', scope: :private)
        end
      end
    end
  end
end
