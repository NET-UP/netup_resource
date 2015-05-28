module NetupResource  
  class ResponseObject
    require "netup_resource/auto_detect"

    #create response object
    def self.create(init_schema=nil)
      init_schema ||= [:result]

      Class.new(ResponseObject) do |c|
        attr_accessor :schema
        init_schema.each { |i| attr_accessor i }

        define_method(:initialize){instance_variable_set(:@schema,init_schema)}
      end
    end

    def self.auto_detect(data)
      AutoDetect.new(data).object
    end

    def [](arg)
      return send(arg.to_sym) if schema.include?(arg.to_sym)
      raise ArgumentError, 'Argument not in Schema'
    end

    def []=(key, value)
       schema.include?(key.to_sym) ? try("#{key}=", value) : raise(ArgumentError, 'Argument not in Schema')
    end

    def each
      return to_enum(:each) unless block_given?

      schema.each{ |key| yield(key, try(key.to_sym)) }
    end

    def to_s
      attributes.inspect
    end

    def attributes
      Hash[ schema.map { |attribute_key| [attribute_key, try(attribute_key.to_sym)] } ]
    end

    def errors?
       schema.include?(:error) || schema.include?(:errors)
    end

    def try(attribute_key, *args)
      if self.respond_to?(attribute_key.to_sym)
        self.send(attribute_key.to_sym, *args)
      else
        nil
      end
    end
  end
end