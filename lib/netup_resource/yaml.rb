module NetupResource
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