require 'rails_helper'

RSpec.describe TestApi do
  let(:return_params) do 
    { 
      :status => 200, 
      :body => {:success => true}.to_json,
      :headers => {} 
    }
  end
  let(:stub_params) do 
    { 
      :body => '{"accessing_user_id":null}',
      :headers => {
        'Accept' => '*/*', 
        'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 
        'Content-Type' => 'application/json', 
        'User-Agent' => 'Ruby'
      }
    }
  end
  let(:stub_get_params) do
    {
      :headers => {
        'Accept' => '*/*', 
        'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 
        'User-Agent' => 'Ruby'
      }
    }
  end
  let(:nested_params) do
    {
      :nested => {
        :nested_deeper => {
          :say => ["what", "up"]
        }
      }
    }
  end
  let(:nested_stub_params) do
    p = stub_params
    p[:body] = nested_params.merge!({"accessing_user_id" => nil}).to_json
    p
  end



  describe ".get" do
    it "sends a http GET request" do
      stub_request(:get, "http://test/test_request?accessing_user_id")
        .with(stub_get_params)
        .to_return(return_params)

      TestApi.get("/test_request", {}, TestApi.auth)

      expect(WebMock).to have_requested(:get, "http://test/test_request?accessing_user_id").once
    end

    it "sends nested params" do
      parsed_url = "http://test/test_request?accessing_user_id&nested=%7B:nested_deeper=%3E%7B:say=%3E%5B%22what%22,%20%22up%22%5D%7D%7D"
      stub_request(:get, parsed_url)
        .with(stub_get_params)
        .to_return(return_params)

      TestApi.get("/test_request", nested_params, TestApi.auth)

      expect(WebMock).to have_requested(:get, parsed_url).once
    end

    it "can receive nested params" do
      stub_request(:get, "http://test/test_request?accessing_user_id")
        .with(stub_get_params)
        .to_return(:body => nested_params.to_json)

      expect(TestApi.get("/test_request", {}, TestApi.auth).nested.nested_deeper.say).to eq ["what", "up"]
    end
  end


  describe ".put" do
    it "sends a http PUT request" do
      stub_request(:put, "http://test/test_request")
        .with(stub_params)
        .to_return(return_params)
      
      TestApi.put("/test_request", {}, TestApi.auth)

      expect(WebMock).to have_requested(:put, "http://test/test_request").once
    end

    it "sends nested params" do
      stub_request(:put, "http://test/test_request")
        .with(nested_stub_params)
        .to_return(return_params)
      
      TestApi.put("/test_request", nested_params, TestApi.auth)

      expect(WebMock).to have_requested(:put, "http://test/test_request")
        .with(:body => hash_including(nested_params)).once
    end

    it "can receive nested params" do
      stub_request(:put, "http://test/test_request")
        .with(stub_get_params)
        .to_return(:body => nested_params.to_json)

      expect(TestApi.put("/test_request", {}, TestApi.auth).nested.nested_deeper.say).to eq ["what", "up"]
    end
  end


  describe ".post" do
    it "sends a http POST request" do
      stub_request(:post, "http://test/test_request")
        .with(stub_params)
        .to_return(return_params)
      
      TestApi.post("/test_request", {}, TestApi.auth)

      expect(WebMock).to have_requested(:post, "http://test/test_request").once
    end

    it "sends nested params" do
      stub_request(:post, "http://test/test_request")
        .with(nested_stub_params)
        .to_return(return_params)
      
      TestApi.post("/test_request", nested_params, TestApi.auth)

      expect(WebMock).to have_requested(:post, "http://test/test_request")
        .with(:body => hash_including(nested_params)).once
    end

    it "can receive nested params" do
      stub_request(:post, "http://test/test_request")
        .with(stub_get_params)
        .to_return(:body => nested_params.to_json)

      expect(TestApi.post("/test_request", {}, TestApi.auth).nested.nested_deeper.say).to eq ["what", "up"]
    end
  end


  describe ".delete" do
    it "sends a http DELETE request" do
      stub_request(:delete, "http://test/test_request")
        .with(stub_params)
        .to_return(return_params)
      
      TestApi.delete("/test_request", {}, TestApi.auth)

      expect(WebMock).to have_requested(:delete, "http://test/test_request").once
    end

    it "sends nested params" do
      stub_request(:delete, "http://test/test_request")
        .with(nested_stub_params)
        .to_return(return_params)
      
      TestApi.delete("/test_request", nested_params, TestApi.auth)

      expect(WebMock).to have_requested(:delete, "http://test/test_request")
        .with(:body => hash_including(nested_params)).once
    end

    it "can receive nested params" do
      stub_request(:delete, "http://test/test_request")
        .with(stub_get_params)
        .to_return(:body => nested_params.to_json)

      expect(TestApi.delete("/test_request", {}, TestApi.auth).nested.nested_deeper.say).to eq ["what", "up"]
    end
  end
end
