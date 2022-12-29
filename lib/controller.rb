require "pry"
require "json"
require "redis"
require "connection_pool"
require "securerandom"
require_relative "./storage"

class Controller
  def initialize(app)
    @app = app
  end

  def call(env)
    @env = env
    @status, @headers, @body = @app.call(@env)

    case request.path_info
    when "/"
      if request.request_method == "POST"
        lock { post }
      end
    else
      @status = 404
    end
    [@status, @headers, self]
  end

  def each(&block)
    block.call(result)
    @body.each(&block)
  end

  private

  def post
    if number
      storage.save number, key
    end
    @status = 301
    @headers["location"] = "/"
  rescue Storage::ExistsError
    @status = 409
  end

  def request
    @request ||= Rack::Request.new(@env)
  end

  def params
    @params ||= request.content_length ? JSON.parse(request.body.read) : {}
  end

  def key
    @key ||= params["key"]
  end

  def number
    @number ||= params["number"]
  end

  def lock
    if block_given?
      begin
        if key and !locked?
          redis.set key, uuid, ex: expiration_default_seconds
        end

        if locked_by_me?
          yield
        else
          @status = 423
        end
      ensure
        unlock!
      end
    end
  end

  def unlock!
    redis.del key
  end

  def locked?
    redis.get key
  end

  def locked_by_me?
    redis.get(key) == uuid
  end

  def uuid
    @uuid ||= SecureRandom.uuid
  end

  def result
    message = case @status
              when 200
                storage.sum
              when 301
                "Number added successfully."
              when 404
                "Not found."
              when 409
                "This Key is obsolete. Try another."
              when 423
                "Locked for this key. Try later!"
              else
                @body
              end
    {
      result: message
    }.to_json
  end

  def storage
    Storage.new
  end

  def redis
    @redis ||=  ConnectionPool::Wrapper.new(size: 7) do
      Redis.new
    end
  end

  def expiration_default_seconds
    10
  end

end