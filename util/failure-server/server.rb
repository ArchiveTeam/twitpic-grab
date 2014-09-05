require 'sinatra'
require 'analysand'
require 'uri'

db_uri = URI(ARGV[0])
credentials = ARGV[1]

db = Analysand::Database.new(db_uri)

post '/fail' do
  downloader = params[:downloader]
  item_name = params[:item_name]

  id = "#{downloader}:#{item_name}:#{Time.now.tai64n}"

  resp = db.put(id, {
    downloader: downloader,
    response_code: params[:response_code],
    url: params[:url],
    item_name: item_name
  }, credentials)

  status resp.code
end

# libtai64-ruby
# http://cr.yp.to/libtai/tai64.html
# Further stolen from https://gist.github.com/2983/78cbbfcc1f1dca646aff100e94e29188b5390a5a
class Time
  TAI64_REGEX = Regexp.new(/(?:^\@)?([0-9a-fA-F]{16})/)
  TAI64N_REGEX = Regexp.new(/#{TAI64_REGEX}([0-9a-fA-F]{8})/)

  def self.tai64(str, leapseconds=10)
    if match = TAI64N_REGEX.match(str).to_a.values_at(1)
      tai64 = match[0].hex - 2**62 - leapseconds
      return Time.at(tai64)
    end
    raise ArgumentError, "not TAI64 compliant date: #{str}"
  end

  def self.tai64n(str, leapseconds=10)
    if match = TAI64N_REGEX.match(str).to_a.values_at(1,2)
      tai64 = match[0].hex - 2**62 - leapseconds
      nano = match[1].hex / 10**3
      return Time.at(tai64,nano)
    end
    raise ArgumentError, "not TAI64N compliant date: #{str}"
  end

  def tai64(leapseconds=10)
    return sprintf("%016x", 2**62 + self.to_i + leapseconds)
  end

  def tai64n(leapseconds=10,nanosec=500)
    return sprintf("%016x%08x", 2**62 + self.to_i + leapseconds, self.usec * 10**3 + nanosec)
  end
end
