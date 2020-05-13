# frozen_string_literal: true

module API::V2
  module Resource
    # Addresses API
    class Addresses < Grape::API
      desc 'Documents related routes'
      resource :addresses do
        desc 'Upload a new address approval document for current user',
             security: [{ 'BearerToken': [] }],
             success: { code: 201, message: 'Document is uploaded' },
             failure: [
               { code: 400, message: 'Required params are empty' },
               { code: 401, message: 'Invalid bearer token' },
               { code: 422, message: 'Validation errors' }
             ]
        params do
          requires :country,
                   type: String,
                   allow_blank: false,
                   desc: 'Document type'
          requires :address,
                   type: String,
                   allow_blank: false,
                   desc: 'Document number'
          requires :upload,
                   desc: 'Array of Rack::Multipart::UploadedFile'
          requires :city,
                   type: { value: Date, message: "resource.documents.expire_not_a_date" },
                   allow_blank: true,
                   desc: 'Document expiration date'
          requires :postcode, type: String, desc: 'Any additional key: value pairs in json string format'
        end

        post do
          params[:upload].each do |file|
            doc = current_user.documents.new(declared(params).except(:upload).merge(upload: file, doc_type: 'ADDRESS_DOCUMENT'))

            code_error!(doc.errors.details, 422) unless doc.save
          end
          status 201

        rescue Excon::Error => e
          Rails.logger.error e
          error!('Connection error', 422)
        end
      end
    end
  end
end
