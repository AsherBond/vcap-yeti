class Bignum
  def to_json(options = nil)
    to_s
  end
end

class Fixnum
  def to_json(options = nil)
    to_s
  end
end


module CFoundry::V1
  class Base < CFoundry::BaseClient

    def system_services
      get("services", "v1", "offerings", :json => :json)
    end
  end

  class Client

    def services
      services = []

      @base.system_services.each do |type, vendors|
        vendors.each do |vendor, provider|
          provider[:core].each do |num, meta|
            services << Service.new(vendor.to_s, num, meta[:description], type)
            meta[:supported_versions].delete(num)
            meta[:supported_versions].each do |v|
              services <<
                  Service.new(vendor.to_s, v, meta[:description], type)
            end
          end
        end
      end

      services
    end
  end

end
