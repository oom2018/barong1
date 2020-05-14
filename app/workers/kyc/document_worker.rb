require 'sidekiq'
module KYC
  # TODO: Document code.
  class DocumentWorker
    include Sidekiq::Worker

    def perform(user_id, idenficator)
      @user = User.find(user_id)
      docs = @user.documents.where(idenficator: idenficator)
      @applicant_id = @user.profiles.last.applicant_id


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
        callback_url: "#{Barong::App.config.domain}/api/v2/barong/identity/general/kyc"
      }
    end
  end
end
