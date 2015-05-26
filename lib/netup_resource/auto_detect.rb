module NetupResource  
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