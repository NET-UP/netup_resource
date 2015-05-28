require 'rails_helper'

RSpec.describe "ResponseObject" do
  let(:return_params) do 
    { 
      :status => 200, 
      :body => {:success => true}.to_json,
      :headers => {} 
    }
  end
  let(:stub_get_params) do
    {
      :headers => {
        'Accept' => '*/*',
        'User-Agent' => 'Ruby'
      }
    }
  end

  describe "<#ResponseObject>[key]" do
    it "returns the value for key" do
      stub_request(:get, "http://test/test_request?accessing_user_id")
        .with(stub_get_params)
        .to_return(return_params)

      object = TestApi.get("/test_request", {}, TestApi.auth)

      expect(object[:success]).to be true
    end
  end

  describe "<#ResponseObject>[key] = val" do
    it "sets the value for key" do
      stub_request(:get, "http://test/test_request?accessing_user_id")
        .with(stub_get_params)
        .to_return(return_params)

      object = TestApi.get("/test_request", {}, TestApi.auth)
      object[:success] = "changed"

      expect(object[:success]).to eq "changed"
    end
  end

  describe "<#ResponseObject>.each block" do
    it "yields key, value to given block" do
      stub_request(:get, "http://test/test_request?accessing_user_id")
        .with(stub_get_params)
        .to_return(return_params)

      object = TestApi.get("/test_request", {}, TestApi.auth)
      copy = ""
      object.each { |key, value| copy = "#{key} = #{value}" }

      expect(copy).to eq "success = true"
    end
  end

  describe "<#ResponseObject>.to_s" do
    it "returns a hash style string" do
      stub_request(:get, "http://test/test_request?accessing_user_id")
        .with(stub_get_params)
        .to_return(return_params)

      object = TestApi.get("/test_request", {}, TestApi.auth)

      expect(object.to_s).to eq({:success => true}.inspect)
    end
  end

  describe "<#ResponseObject>.attributes" do
    it "returns the attributes hash" do
      stub_request(:get, "http://test/test_request?accessing_user_id")
        .with(stub_get_params)
        .to_return(return_params)

      object = TestApi.get("/test_request", {}, TestApi.auth)

      expect(object.attributes).to eq({:success => true})
    end
  end

  describe "<#ResponseObject>.try(:attribute)" do
    context "when attribute exists" do
      it "returns the attribute" do
        stub_request(:get, "http://test/test_request?accessing_user_id")
          .with(stub_get_params)
          .to_return(return_params)

        object = TestApi.get("/test_request", {}, TestApi.auth)

        expect(object.try(:success)).to be true
      end
    end

    context "when attribute does not exist" do
      it "returns nil" do
        stub_request(:get, "http://test/test_request?accessing_user_id")
          .with(stub_get_params)
          .to_return(return_params)

        object = TestApi.get("/test_request", {}, TestApi.auth)

        expect(object.try(:not_there)).to be_nil
      end
    end
  end
end