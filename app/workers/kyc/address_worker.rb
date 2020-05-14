# require 'sidekiq'
# module KYC
#   # TODO: Document code.
#   class AddressWorker
#     include Sidekiq::Worker

#     def perform(params = {})
#       @params = params
      
#       @user = User.find(@params['user_id'])
#       @applicant_id = JSON.parse(@user.profiles.last.metadata)['applicant_id']
#       @document = Document.find(@params['identificator'])
#       KYCAID::Document.create(address_params)
#       KYCAID::Verification.create(verification_params)
#     end

#     def address_params
#       {
#         front_file: {
#           tempfile: open(@document.upload.url),
#           file_extension: @document.upload.file.extension,
#           file_name: @document.upload.file.filename,
#         },
#         type: 'ADDRESS_DOCUMENT',
#         applicant_id: @applicant_id
#         # country: @params['country'],
#         # city: @params['city'],
#         # postal_code: @params['postcode'],
#         # street_name: @params['address'],
#       }.compact
#     end

#     def verification_params
#       {
#         applicant_id: @applicant_id,
#         types: ['ADDRESS'],
#         callback_url: "#{Barong::App.config.domain}/api/v2/identity/general/kyc"
#       }
#     end
#   end
# end
