module NetupResource
  module HttP
    require 'uri'
    require 'net/http'
    require 'json'
    require 'active_support/core_ext/hash/conversions'
    #call API using Net::HTTP
    def self.call(url,parameters,auth=nil,ssl=false,method,formats)
      request_type = parameters.delete(:request_type) || formats[:request_type] || formats[:type]
      response_type = parameters.delete(:response_type) || formats[:response_type] || formats[:type]
      formated_url = case method
        when :get then NetupResource::HttP.format_get_url(url,parameters)
        when :post, :put, :delete then url
        end
      uri = URI.parse(formated_url)
      http = Net::HTTP.new(uri.host, uri.port)
      if ssl
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      request = case method
        when :get 
          Net::HTTP::Get.new(uri.request_uri)
        when :post, :put, :delete
          header_hash = {'Content-Type' => "application/#{response_type}"}
          temp_request = "Net::HTTP::#{method.to_s.camelize}".constantize.new(uri.request_uri, initheader = header_hash)
          data = parameters.send("to_#{request_type}")
          if request_type == :html
            temp_request.set_form_data data
          else
            temp_request.body = data
          end

          temp_request
        end

      request.basic_auth(auth[:user], auth[:password]) if auth
      
      response = http.request(request).body
      return case response_type
      when :json then JSON.parse(response)
      when :xml then Hash.from_xml(response)
      when :html then response
      end
    end

    #format url with params for get requests
    def self.format_get_url(url,parameters)
      formated = url
      counter = 0
      formated = if parameters.is_a?(String)
        formated += "?#{parameters}"
      else
        # [formated,URI.encode_www_form(parameters)].join("?")
        parameters.each do |key,value|
          formated += counter==0 ? '?' : '&'
          if value.is_a?(Array)
            value.each_with_index { |obj,i| formated += (i==0 ? "" : "&") + ["#{key}[#{i}]", obj].compact.join("=") }
          elsif value.is_a?(Hash)
            formated += value.to_param
          else
            formated += [key, value].compact.join("=")
          end
          counter += 1
        end

        formated
      end
      return formated
    end
  end
end