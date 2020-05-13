require 'sidekiq'
module KYC
  # TODO: Document code.
  class AddressWorker
    include Sidekiq::Worker


    def perform(params)
      @params = params
      @user = User.find(@params[:user_id])
      @applicant_id = JSON.parse(@user.profiles.last.metadata)['applicant_id']
      @document = Document.find(@params[:document_id])

      address_id = KYCAID::Address.create(address_params).document_id
      docs.last.update(metadata: { applicant_id: applicant.applicant_id }.to_json)

      KYCAID::Verification.create(verification_params)
    end

    protected_params = params.slice(:type, :country, :state_or_province, :city, :postal_code, :street_name, :building_number)


    def address_params
      {
        front_file: {
          tempfile: open(@document.upload.url),
          file_extension: @document.file.extension,
          file_name: @document.file.filename,
        },
        type: 'REGISTERED',
        country: @params[:country],
        applicant_id: @applicant_id,
        city: @params[:city],
        postal_code: @params[:postcode],
        street_name: @params[:address],
      }.compact
    end

    def verification_params
      {
        applicant_id: @applicant_id,
        types: ['ADDRESS'],
        callback_url: "#{Barong::App.config.domain}/api/v2/identity/general/kyc",
      }
    end
  end
end
