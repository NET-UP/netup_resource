module NetupResource  
  class ResponseObject
    require "netup_resource/auto_detect"
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
  end
end