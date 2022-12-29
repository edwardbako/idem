require "minitest/autorun"
require "rack"
require "rack/test"

OUTER_APP = Rack::Builder.parse_file("config.ru").first

class IntegrationTest < Minitest::Test
  include Rack::Test::Methods

  def clear_table!
    Storage.new.clear_table
  end

  def app
    @app ||= OUTER_APP
  end

  def redis
    @redis ||= Redis.new
  end

  def pool
    20
  end

  def test_response_is_ok
    get "/"
    assert last_response.ok?
  end

  def test_sum
    clear_table!
    post "/", JSON.generate({key: "key_1", number: 5})
    post "/", JSON.generate({key: "key_1", number: 3})
    post "/", JSON.generate({key: "key_2", number: 2})
    get "/"
    body = JSON.parse(last_response.body)
    assert_equal 7, body["result"].to_i
  end

  def test_concurrent
    clear_table!
    get "/"
    before = JSON.parse(last_response.body)["result"].to_i
    number = 5
    wait = true
    statuses = []
    sleeper = rand(pool)

    threads = pool.times.map do |i|
      Thread.new do
        true while wait
        post "/", JSON.generate({key: "race", number: number})
        puts last_response.status
        statuses << last_response.status
      end
    end
    wait = false
    threads.each(&:join)

    get "/"
    after = JSON.parse(last_response.body)["result"].to_i

    assert_only_one_or_not_success statuses
    assert_4xx_for_other statuses

    if success_count(statuses) > 0
      assert_equal number + before, after
    end
  end

  private

  def assert_only_one_or_not_success(statuses)
    assert_includes [0, 1], success_count(statuses)
  end

  def success_count(statuses)
    statuses.select { |status| status == 301 }.size
  end

  def assert_4xx_for_other(statuses)
    statuses.each do |status|
      assert_includes [409, 423], status if status != 301
    end
  end

end