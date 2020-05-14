require 'sidekiq'
module KYC
  # TODO: Document code.
  class VerificationsWorker
    include Sidekiq::Worker

    def perform(verification_id, applicant_id)
      verification = KYCAID::Verification.fetch(verification_id)
      return unless verification.status == 'completed'

      verification.verifications.each do |k, v|
        if v["verified"]
          next unless User.last.labels.find_by_key(k)
          # find user by applicant_id
          User.last.labels.find_by_key(k).update(key: k, value: 'verified', scope: :private)
        else
          # we can insert a comment
          User.last.labels.find_by_key(k).update(key: k, value: 'rejected', scope: :private)
        end
      end
    end
  end
end
