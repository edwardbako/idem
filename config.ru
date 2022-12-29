require_relative "./lib/controller"

 app = Rack::Builder.new do
   use Rack::Runtime
   use Rack::CommonLogger
   use Rack::ShowExceptions
   use Rack::Lint
   map "/" do
     # use Locker
     use Controller
     use Rack::ContentType, "application/json"
     run -> (env) { Rack::Response.new.finish }
   end
 end

run app