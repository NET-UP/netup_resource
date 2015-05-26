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
  require "netup_resource/yaml"
  require "netup_resource/core"
  require "netup_resource/http"
  require "netup_resource/response_object"
end

class Array
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