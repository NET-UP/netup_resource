class TestApi < NetupResource::Base
  self.url = "http://test"
  self.ssl = false
  self.type = :json
  
  def self.auth
    
  end
end
