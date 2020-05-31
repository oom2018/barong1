# frozen_string_literal: true

require_dependency 'barong/jwt'

module API::V2
  module Identity
    class Sessions < Grape::API
      desc 'Session related routes'
      resource :sessions do
        desc 'Start a new session',
             failure: [
                 {code: 400, message: 'Required params are empty'},
                 {code: 404, message: 'Record is not found'}
             ]
        params do
          requires :email
          requires :password
          optional :captcha_response,
                   types: {value: [String, Hash], message: 'identity.session.invalid_captcha_format'},
                   desc: 'Response from captcha widget'
          optional :otp_code,
                   type: String,
                   desc: 'Code from Google Authenticator'
        end
        post do
          puts "---------======#{params} ---- #{params.inspect}"
          verify_captcha!(response: params['captcha_response'], endpoint: 'session_create')

          declared_params = declared(params, include_missing: false)
          user = User.find_by(email: declared_params[:email])
          error!({errors: ['identity.session.invalid_params']}, 401) unless user

          if user.state == 'banned'
            login_error!(reason: 'Your account is banned', error_code: 401,
                         user: user.id, action: 'login', result: 'failed', error_text: 'banned')
          end

          if user.state == 'deleted'
            login_error!(reason: 'Your account is deleted', error_code: 401,
                         user: user.id, action: 'login', result: 'failed', error_text: 'deleted')
          end

          # if user is not active or pending, then return 401
          unless user.state.in?(%w[active pending])
            login_error!(reason: 'Your account is not active', error_code: 401,
                         user: user.id, action: 'login', result: 'failed', error_text: 'not_active')
          end

          unless user.authenticate(declared_params[:password])
            login_error!(reason: 'Invalid Email or Password', error_code: 401, user: user.id,
                         action: 'login', result: 'failed', error_text: 'invalid_params')
          end
          #puts "======== 1 unless user.otp"
          unless user.otp
            activity_record(user: user.id, action: 'login', result: 'succeed', topic: 'session')
            csrf_token = open_session(user)

            # 生成php所需token
            response = Faraday.post "http://ljf.happyrmb.com/api/get_token", "u_id" => user.id, "uid" => user.uid
            data = JSON.load(response.body).deep_symbolize_keys
            puts "api response data #{data}"
            cookies[:token] = data[:data][:token]

            publish_session_create(user)

            present user, with: API::V2::Entities::UserWithFullInfo, csrf_token: csrf_token
            return status 200
          end
          #puts "======== 2"
          if declared_params[:otp_code].blank?
            login_error!(reason: 'The account has enabled 2FA but OTP code is missing', error_code: 403,
                         user: user.id, action: 'login::2fa', result: 'failed', error_text: 'missing_otp')
          end
          #puts "======== 3"
          unless TOTPService.validate?(user.uid, declared_params[:otp_code])
            login_error!(reason: 'OTP code is invalid', error_code: 403,
                         user: user.id, action: 'login::2fa', result: 'failed', error_text: 'invalid_otp')
          end
          #puts "======== 4"
          activity_record(user: user.id, action: 'login::2fa', result: 'succeed', topic: 'session')
          csrf_token = open_session(user)
          #puts "csrf_token------------#{csrf_token}"
          publish_session_create(user)
          #puts "user------------#{user}"

          # 生成php所需token
          response = Faraday.post "http://ljf.happyrmb.com/api/get_token", "u_id" => user.id, "uid" => user.uid
          data = JSON.load(response.body).deep_symbolize_keys
          puts "api response data #{data}"
          cookies[:token] = data[:data][:token]

          present user, with: API::V2::Entities::UserWithFullInfo, csrf_token: csrf_token, token_php: "2222"
          status(200)
        end
        #http --session barong_session http://127.0.0.1:8001/api/v2/identity/sessions email=sdxiyuan@163.com password=Baidu.c0m otp_code=806080


        desc 'Destroy current session',
             failure: [
                 {code: 400, message: 'Required params are empty'},
                 {code: 404, message: 'Record is not found'}
             ]
        delete do
          user = User.find_by(uid: session[:uid])
          error!({errors: ['identity.session.not_found']}, 404) unless user

          activity_record(user: user.id, action: 'logout', result: 'succeed', topic: 'session')

          session.destroy
          status(200)
        end
      end
    end
  end
end
