class TestApiController < ApplicationController
  def get_test
    render :json => {:success => true}
  end

  def put_test
    render :json => {:success => true}
  end

  def post_test
    render :json => {:success => true}
  end

  def delete_test
    render :json => {:success => true}
  end
end