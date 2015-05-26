# -*- encoding : utf-8 -*-
# NetupResource - Object-RESTFullService-Mapper v 0.1.0-beta-p004
# NetupResource is a Object-RESTFullService-Mapper mapping http-requests on
# Ruby Objects. As all Mappers it uses Ruby class inheritance within Model-Classes.
#
# Models inherit the Rest Methods post(), get(), put(), delete()
# from NetupResource::Base
#
# For your response objects there are 4 possible types:
#  -> Model Schema  :  (see settings)
#
#  -> YAML Schema   : create a *.yml file within the dir '/config/netup_record/schema'.
#                     the name of this schema should be the downcased model name.
#                     the schema should look like:
#
#                       :foo:
#
#                       :bar:
#                         - :sub1
#                         - :sub2
#
#                      as you see, the yaml-schema accepts one sub-level schema
#                      per root. more than 1 sub-level is currently not supported.
#                      The Mapper will map all roots to attributes of the response
#                      Object. If a root has one or more sub-attributes, another
#                      Object will be generated with an attribute for each sub.
#                      This Sub-Object will be linked to the corrisponding Root-
#                      level attribute, like 'my_request.bar.sub1'.
#                      If the response to the sub-containing root-level-attribute
#                      is an Array, an Array of Sub-Objects will be linked to the
#                      corrisponding root level attribute.
#
#  -> Auto Detected Rails Record:
#
#                       If you neither define a YAML Schema nor a Model Schema,
#                       this plugin will test wether the response is an Array
#                       including only Hashes of the same Schema or not.
#                       If so, the answer to the request will be formated to
#                       an Array of Objects, whos attributes are set according to
#                       the auto detected schema.
#
#  -> Single Result:
#
#                       If non of the upper methods fits, the Mapper will create
#                       an Object having the attribute 'result' containing all
#                       of the response content.
#
# Types of Configuration on a Model:
#
#   self.url        :   required : base url of the API
#   self.schema     :   optional : (give the response object a strict schema
#                                   result object will be built out of the schema)
#   self.type       :   required : response format
#
#
# Example
# =======
#
# in your model
# class Post < NetupResource::Base
#    self.url = "http://www.example.com/" #define base url
#    self.schema = [:id,:date] #define response Object Schema if needed
#    self.type = :json # request format
# end
#
# in your controller
#
# @posts = Post.get( # get request (post has has same params)
#    'my_uri',   # required! request uri
#    {id: 1,name: 'foo'}, # optional : request params; type: ruby-hash
#    {user: 'me',password: 'test'} # optional : base auth
# )
#
#
module NetupResource
  #base class for models to inherit from
  class Base

    class << self
      #base url attribute; type: string
      attr_accessor :url
      # format type
      attr_accessor :type
      attr_accessor :request_type
      attr_accessor :response_type
      #optional response object schema
      attr_accessor :schema
      #optional ssl connector
      attr_accessor :ssl
      attr_accessor :accessing_user_id
      #GET-Request
      # uri: api-uri
      # parameters: request params hash(optional)
      # auth: base aut(optional)
      def get(uri="",parameters={},auth=nil)
        return request(@url+uri,parameters,auth,:get)
      end
      #POST-Request
      # uri: api-uri
      # parameters: request params hash(optional)
      # auth: base aut(optional)
      def post(uri="",parameters={},auth=nil)
        return request(@url+uri,parameters,auth,:post)
      end

      #PUT-Request
      # uri: api-uri
      # parameters: request params hash(optional)
      # auth: base aut(optional)
      def put(uri="",parameters={},auth=nil)
        return request(@url+uri,parameters,auth,:put)
      end

      #DELETE-Request
      # uri: api-uri
      # parameters: request params hash(optional)
      # auth: base aut(optional)
      def delete(uri="",parameters={},auth=nil)
        return request(@url+uri,parameters,auth,:delete)
      end
      #URL-Setter
      def url=(u)
        @url = u
      end
      #Type-Setter
      def type=(t)
        @type = t
      end
      #Schema-Setter
      def schema=(s)
        @schema = s
      end
      #ssl-Setter
      def ssl=(ssl)
        @ssl = ssl
      end
      private
      #general request function
      def request(uri="",parameters={},auth=nil,type)
        ### DAS HIER ($accessing_user_id) IST EINE GLOBALE VARIABLE
        ### SIE WIRD DER API ÜBERGEBEN UND ENTHÄLT DEN EINGELOGGTEN USER (FALLS VORHANDEN)
        parameters[:accessing_user_id] ||= $accessing_user_id  #self.accessing_user_id
        ### NIEMALS FÜR IRGENDETWAS ANDERES VERWENDEN!!!
        ### AM BESTEN EINFACH FINGER WEG!!!
        answer = NetupResource::HttP.call(uri,parameters,auth,@ssl,type,formats)
        resp_obj = NetupResource::ResponseObject.create(@schema)
        response = resp_obj.new
        if @schema
          for i in (0...@schema.length)
            response.instance_variable_set("@#{@schema[i].to_s}".to_sym,answer[@schema[i].to_s])
          end
        elsif YamL.schema_exists?(self.name.downcase)
          path = "#{Rails.root}/config/netup_resource/schema/#{self.name.downcase}.yml"
          return YamL.data_object(path,answer)
        else
          return ResponseObject.auto_detect(answer)
        end
        return response
      end

      def formats
        {
          :type => type,
          :request_type => request_type,
          :response_type => response_type
        }
      end
    end
  end
  protected

  #HTTP-Request Module
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
            value.each_with_index{|obj,i| formated += (i==0 ? "" : "&") + "#{key}[#{i}]=#{obj}"}
          elsif value.is_a?(Hash)
            formated += value.to_param
          else
            formated += "#{key}=#{value}"
          end
          counter += 1
        end
      end
      return formated
    end
  end

  #response object creation module
  module ResponseObject
    #create response object
    def self.create(schema=nil)
      obj = Class.new do |c|
        if schema
          attr_reader :schema
          define_method(:initialize){instance_variable_set(:@schema,schema)}
          schema.each{|i| attr_accessor i}
          define_method(:[]) do |arg|
            return instance_variable_get(('@'+arg.to_s).to_sym) if schema.include?(arg.to_sym)
            raise ArgumentError, 'Argument not in Schema'
          end
          define_method(:[]=) do |k,v|
            schema.include?(k.to_sym) ? instance_variable_set(('@'+k.to_s).to_sym,v) : raise(ArgumentError, 'Argument not in Schema')
          end
          define_method(:each) do |&proc|
            return to_enum(:each) unless proc
            schema.each{|key| proc.call(key,instance_variable_get("@#{key}".to_sym))}
          end

          define_method(:to_s) do
            str = "{"
            schema.each_with_index do |key,i|
              str += "#{key}: #{instance_variable_get("@#{key}".to_sym)}"
              str += ", " if i != schema.length - 1
            end
            str += "}"
            return str
          end
          
          define_method(:attributes) do
            hash = Hash.new
            schema.each do |attr|
              hash[attr.to_sym] = instance_variable_get("@#{attr}".to_sym)
            end
            return hash
          end
          
          define_method(:try) do |attr_key|
            answer = nil
            if schema.include?(attr_key.to_sym)
              answer = instance_variable_get("@#{attr_key}".to_sym)
            end
            return answer
          end
          
          define_method(:errors?) do
            schema.include?(:error) || schema.include?(:errors)
          end
          
        else
          attr_accessor :result
        end
      end
      return obj
    end

    def self.auto_detect(data)
      AutoDetect.new(data).object
    end

    class AutoDetect
      def initialize(data)
        if data
          if data.is_a?(Array)
            if data.is_a_record?
              ary = Array.new
              data.each{|d| ary << create_object(d)}
              @object = ary
            else
              @object = data
            end
          elsif data.is_a?(Hash)
            @object = create_object(data)
          else
            @object = data
          end
        else
          @object = nil
        end
      end

      def create_object(data)
        if data.length > 0
          schema = data.keys.map(&:to_sym)
          obj = NetupResource::ResponseObject.create(schema).new
          schema.map(&:to_s).each do |var|
          current = data[var]
          if current
            if current.is_a?(Array)
            obj.instance_variable_set("@#{var}".to_sym,from_ary(current))
            elsif current.is_a?(Hash)
            obj.instance_variable_set("@#{var}".to_sym,create_object(current))
            else
            obj.instance_variable_set("@#{var}".to_sym,current)
            end
          else
            obj.instance_variable_set("@#{var}".to_sym,nil)
          end
          end
        else
          obj = nil
        end
        return obj
      end

      def from_ary(current)
        if current.is_a_record?
          ary = Array.new
          current.each{|c| ary << create_object(c)}
          return ary
        else
          return current
        end
      end

      def object
        return @object
      end

    end
  end

  #module to read *.yml files
  module YamL
    require 'yaml'

    #parse yaml file to object
    def self.to_object(file)
      file_schema = file
      object_schema = Array.new
      sub_object_schema = Array.new
      file_schema.each do |key,value|
        object_schema << key.to_sym
        if value.is_a?(Array)
          h = Hash.new
          h[key] = Array.new
          value.each{|i| h[key] << i.to_sym}
          sub_object_schema << h
        end
      end
      object = ResponseObject.create(object_schema).new
      if sub_object_schema.length > 0
        sub_object_schema.each do |obj|
          obj.each do |key,value|
            object[key] = ResponseObject.create(value).new
          end
        end
      end
      return object
    end

    #fill object with data
    def self.data_object(file_path,data=[])
      if data.length > 0
        data = [data] if !data.is_a?(Array)
        file = YAML.load_file(file_path)
        answer = Array.new
        data.each do |d|
          object = to_object(file)
          d.each do |key,value|
            if value.is_a?(Hash)
              if object[key.to_sym].instance_variables.include?(:@schema)
                sub_schema = object[key.to_sym].schema
                sub_schema.each do |i|
                  object[key.to_sym][i] = value[i.to_s]
                end
              else
                object[key.to_sym] = value
              end
            elsif value.is_a?(Array)
              if object[key.to_sym].instance_variables.include?(:@schema)
                sub_schema = object[key.to_sym].schema
                ary = Array.new
                sub_obj = ResponseObject.create(sub_schema)
                value.each do |val|
                  sub_obj_inst = sub_obj.new
                  sub_schema.each do |i|
                    sub_obj_inst.instance_variable_set("@#{i.to_s}".to_sym, val[i.to_s])
                  end
                  ary << sub_obj_inst
                end
                object[key.to_sym] = ary
              else
                object[key.to_sym] = value
              end
            else
              object[key.to_sym] = value
            end
          end
          answer << object
        end
        return answer.length == 1 ? answer[0] : answer
      end
      return Array.new
    end

    #check if model schema exists
    def self.schema_exists?(name)
      return File.exists?("#{Rails.root}/config/netup_resource/schema/#{name}.yml")
    end

  end
end
#ruby array extension
class Array
  #check if array could be out of a record
  def is_a_record?
    if self.length > 0
      answer = true
      self.each {|i| answer = false if !i.is_a?(Hash)}
      return false unless answer
      schema = self[0].keys
      self.each {|i| answer = false if !i.keys == schema}
      return answer
    else
      return false
    end
  end
end

class Hash
  def flatten_keys(newhash={}, keys=nil)
    self.each do |k, v|
      k = k.to_s
      keys2 = keys ? keys+"[#{k}]" : k
      if v.is_a?(Hash)
        v.flatten_keys(newhash, keys2)
      else
        newhash[keys2] = v
      end
    end
    newhash
  end

  def format_form_data
    result = {}
    self.each do |k,v|
      if v.is_a? Hash
         v = v.flatten_keys
         result[k.to_s] = format_form_data(v)
      elsif v.is_a? Array
         v.length.times do |n|
           v[n] = v[n].flatten_keys if v[n].is_a?(Hash)
           result.merge! "#{k.to_s}[]" => format_form_data(v[n])
       end
      else
         result[k.to_s] = v.to_s
      end
    end
    result
  end 
  alias_method :to_html, :format_form_data
end