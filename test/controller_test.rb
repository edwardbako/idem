require "minitest/autorun"
require "rack"

OUTER_APP = Rack::Builder.parse_file("config.ru").first

class ControllerTest < Minitest::Test
  def setup
    Storage.new.clear_table
  end

  def app
    @app ||= OUTER_APP
  end

  def redis
    @redis ||= Redis.new
  end

  def request
    @request = Rack::MockRequest.new(app)
  end

  def test_respond_to_call
    assert_respond_to app, :call
  end

  def test_status_success
    response = request.get "/"
    assert_equal 200, response.status
  end

  def test_not_found_status
    response = request.get "/not_exist"
    assert_equal 404, response.status
  end

  def test_existing_key_status
    params = {key: "key", number: 5}.to_json
    request.post "/", params: params
    response = request.post "/", params: params
    assert_equal 409, response.status
  end

  def test_locked_status
    key = "Lock"
    redis.set key, 5, ex: 1
    response = request.post "/", params: {key: key, number: 5}.to_json
    assert_equal 423, response.status
    redis.del key
  end

  def test_successful_post_status
    response = request.post "/", params: {key: "success", number: 10}.to_json
    assert_equal 301, response.status
  end

end