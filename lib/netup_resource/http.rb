module NetupResource
  module HttP
    require 'uri'
    require 'net/http'
    require 'json'
    require 'active_support/core_ext/hash/conversions'
    #call API using Net::HTTP
    def self.call(url,parameters,auth=nil,ssl=false,method,formats,debug)
      types = extract_types(parameters, formats)
      uri = URI.parse formated_url(method, url, parameters)
      http = build_http uri, ssl
      request = build_request(method, uri, parameters, types)
      
      request.basic_auth(auth[:user], auth[:password]) if auth
      log_request http, request if debug

      parse_to_response_type http.request(request).body, types[:response_type]
    end

    #format url with params for get requests
    def self.format_get_url(url,parameters)
      formated = url
      formated = if parameters.is_a?(String)
        formated += "?#{parameters}"
      else
        complex_format_url(parameters, formated)
      end
      
      formated
    end

    private
      def self.complex_format_url(parameters, formated)
        parameters.each_with_index do |(key, value), index|
          formated += index == 0 ? '?' : '&'
          if value.is_a?(Array)
            value.each_with_index { |obj,i| formated += (i==0 ? "" : "&") + ["#{key}[#{i}]", obj].compact.join("=") }
          elsif value.is_a?(Hash)
            formated += value.to_param
          else
            formated += [key, value].compact.join("=")
          end
        end

        formated
      end

      def self.extract_types(parameters,formats)
        {
          :request_type => parameters.delete(:request_type) || formats[:request_type] || formats[:type], 
          :response_type => parameters.delete(:response_type) || formats[:response_type] || formats[:type]
        }
      end

      def self.formated_url(method,url,parameters)
        case method
        when :get then NetupResource::HttP.format_get_url(url,parameters)
        when :post, :put, :delete then url
        end
      end


      def self.log_request(http, request)
        begin
          protocol = "http"
          protocol += "s" if http.use_ssl?
          Rails.logger.info "[#{Time.now}] [#{request.class}] #{request.method} #{protocol}://#{http.address}:#{http.port}/#{request.uri}"
          request.each_header do |field, value|
            Rails.logger.info "[Request-HEADER] #{field}: #{value}"
          end
          if request.request_body_permitted? && request.body_exist?
            Rails.logger.info "[Request-BODY] #{request.body}"
          end
        rescue Exception => e
          Rails.logger.warning "Failed to log request: #{e}"
        end
	yield if block_given?
      end

      def self.build_request(method,uri,parameters,types={})
        case method
        when :get 
          Net::HTTP::Get.new(uri.request_uri)
        when :post, :put, :delete
          header_hash = {'Content-Type' => "application/#{types[:response_type]}"}
          temp_request = "Net::HTTP::#{method.to_s.camelize}".constantize.new(uri.request_uri, initheader = header_hash)
          data = parameters.send("to_#{types[:request_type]}")
          if types[:request_type] == :html
            temp_request.set_form_data data
          else
            temp_request.body = data
          end

          temp_request
        end
      end

      def self.build_http(uri,ssl=false)
        http = Net::HTTP.new(uri.host, uri.port)
        if ssl
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end

        http
      end

      def self.parse_to_response_type(response, response_type)
        case response_type
        when :json then JSON.parse(response)
        when :xml then Hash.from_xml(response)
        when :html then response
        end
      end
  end
end
