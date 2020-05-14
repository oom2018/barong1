require 'sidekiq'
module KYC
  # TODO: Document code.
  class DocumentWorker
    include Sidekiq::Worker

    def perform(user_id)
      @user = User.find(user_id)
      docs = @user.documents
      @applicant_id = JSON.parse(@user.profiles.last.metadata)['applicant_id']

      document_id = KYCAID::Document.create(document_params(docs, docs.first.doc_type)).document_id
      docs.last.update(metadata: { document_id: @document_id }.to_json)

      KYCAID::Verification.create(verification_params)
    end

    def document_params(docs, type)
      {
        front_file: {
          tempfile: open(docs.first.upload.url),
          file_extension: docs.first.upload.file.extension,
          file_name: docs.first.upload.file.filename,
        },
        back_file: {
          tempfile: open(docs.second.upload.url),
          file_extension: docs.second.upload.file.extension,
          file_name: docs.second.upload.file.filename,
        }.compact,
        expiry_date: docs.first.doc_expire,
        document_number: docs.first.doc_number,
        type: type,
        applicant_id: @applicant_id
      }.compact
    end

    def verification_params
      {
        applicant_id: @applicant_id,
        types: ['DOCUMENT'],
        callback_url: "http://localhost:3000/api/v2/identity/general/kyc",
      }
    end
  end
end

# == Schema Information
#
# Table name: documents
#
#  id         :bigint           not null, primary key
#  user_id    :bigint           unsigned, not null
#  upload     :string(255)
#  doc_type   :string(255)
#  doc_number :string(255)
#  doc_expire :date
#  metadata   :text(65535)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_documents_on_user_id  (user_id)
#