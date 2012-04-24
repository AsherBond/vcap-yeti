require "harness"
require "spec_helper"

describe BVT::Spec::AutoStaging::Ruby19Rails3 do
  include BVT::Spec::AutoStagingHelper, BVT::Spec

  before(:each) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  def verify_rails_db_app(app, relative_path)
    response = app.get_response(:get, relative_path)
    response.should_not == nil
    response.response_code.should == BVT::Harness::HTTP_RESPONSE_CODE::OK
    p = JSON.parse(response.body_str)
    p['operation'].should == 'success'
  end

  it "start application and write data" do
    app = @session.app("rails3_app")
    app.push
    app.healthy?.should be_true, "Application #{app.name} is not running"
    widget_name = "somewidget"
    app.get_response(:get, "/make_widget/#{widget_name}").body_str.should == \
      "Saved #{widget_name}"
  end

  it "start and test a rails db app with Gemfile that includes mysql2 gem" do
    service_manifest = MYSQL_MANIFEST
    service = @session.service(service_manifest['vendor'])
    service.create(service_manifest)

    app = @session.app("dbrails_app")
    app.push([service])
    app.healthy?.should be_true, "Application #{app.name} is not running"

    verify_rails_db_app(app, "/db/init")
    verify_rails_db_app(app, "/db/query")
    verify_rails_db_app(app, "/db/update")
    verify_rails_db_app(app, "/db/create")
  end

  it "rails db app with Gemfile that DOES NOT include mysql2 or sqllite gems" do
    service_manifest = MYSQL_MANIFEST
    service = @session.service(service_manifest['vendor'])
    service.create(service_manifest)

    app = @session.app("dbrails_broken_app")
    lambda { app.push([service]) }.should raise_error(RuntimeError, \
      "Application: #{app.name} cannot be started in 60 seconds")
  end

  it "Rails autostaging" do
    # provision service
    service_manifests = [MYSQL_MANIFEST, REDIS_MANIFEST, MONGODB_MANIFEST]
    services = []
    service_manifests.each { |manifest| services << create_service(manifest) }

    app = @session.app("app_rails_service_autoconfig")
    app.push(services)
    app.healthy?.should be_true, "Application #{app.name} is not running"
    app.get_response(:get).body_str.should == "hello from rails"

    service_manifests.each {|manifest| verify_service_autostaging(manifest, app)}
    services = @session.services
    services.each {|service| app.unbind(service.name) if service.name =~ /t.*-mysql$/}

    service_manifests = [RABBITMQ_MANIFEST, POSTGRESQL_MANIFEST]
    service_manifests.each do |service_manifest|
      bind_service(service_manifest, app)
      verify_service_autostaging(service_manifest, app)
    end
  end

  it "Rails opt-out of autostaging via config file" do
    # provision service
    service_manifests = [MYSQL_MANIFEST, REDIS_MANIFEST]
    services = []
    service_manifests.each { |manifest| services << create_service(manifest) }

    app = @session.app("rails_autoconfig_disabled_by_file")
    app.push(services)
    app.healthy?.should be_true, "Application #{app.name} is not running"
    app.get_response(:get).body_str.should == "hello from rails"

    key = "connection"
    data = "Connectionrefused-UnabletoconnecttoRedison127.0.0.1:6379"
    app.get_response(:get, "/service/redis/#{key}").body_str.should == data
  end

  it "Rails opt-out of autokstaging via cf-runtime gem" do
    # provision service
    service_manifests = [MYSQL_MANIFEST, REDIS_MANIFEST]
    services = []
    service_manifests.each { |manifest| services << create_service(manifest) }

    app = @session.app("rails_autoconfig_disabled_by_gem")
    app.push(services)
    app.healthy?.should be_true, "Application #{app.name} is not running"
    app.get_response(:get).body_str.should == "hello from rails"

    key = "connection"
    data = "Connectionrefused-UnabletoconnecttoRedison127.0.0.1:6379"
    app.get_response(:get, "/service/redis/#{key}").body_str.should == data
  end
end