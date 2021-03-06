require "harness"
require "spec_helper"
include BVT::Spec
include BVT::Spec::AutoStagingHelper

describe BVT::Spec::AutoStaging::Ruby19Rack do

  before(:each) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  it "rack ruby 1.9 autostaging", :redis => true do
    app = create_push_app("rack_autoconfig_ruby19")
    app.get_response(:get).body_str.should == "hello from sinatra"

    # provision service
    service_manifest = REDIS_MANIFEST
    bind_service(service_manifest, app)
    key = "abc"
    data = "#{service_manifest[:vendor]}#{key}"
    url = SERVICE_URL_MAPPING[service_manifest[:vendor]]
    app.get_response(:post, "/service/#{url}/#{key}", data)
    app.get_response(:get, "/service/#{url}/#{key}").body_str.should == data
  end
end
