module NetupResource  
  class Base < ResponseObject

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

      #optional _*logging*_
      attr_accessor :debug
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

      protected
      def parse_answer(answer)
        if @schema
          return create_response_object(answer)
        elsif YamL.schema_exists?(self.name.downcase)
          path = "#{Rails.root}/config/netup_resource/schema/#{self.name.downcase}.yml"
          return YamL.data_object(path,answer)
        else
          return ResponseObject.auto_detect(answer)
        end
      end

      private
      #general request function
      def request(uri="",parameters={},auth=nil,type)
        ### DAS HIER ($accessing_user_id) IST EINE GLOBALE VARIABLE
        ### SIE WIRD DER API ÜBERGEBEN UND ENTHÄLT DEN EINGELOGGTEN USER (FALLS VORHANDEN)
        parameters[:accessing_user_id] ||= $accessing_user_id  #self.accessing_user_id
        ### NIEMALS FÜR IRGENDETWAS ANDERES VERWENDEN!!!
        ### AM BESTEN EINFACH FINGER WEG!!!
        parse_answer(NetupResource::HttP.call(uri,parameters,auth,@ssl,type,formats,@debug))
      end


      def create_response_object(obj)
        if obj.is_a? Array
          return obj.map{|obj| create_response_object(obj)}
        end

        response = new
        for i in (0...@schema.length)
          response.instance_variable_set("@#{@schema[i].to_s}".to_sym, obj[@schema[i].to_s])
        end
        response
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
end