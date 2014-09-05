require 'sinatra'
require 'analysand'
require 'uri'

db_uri = URI(ARGV[0])
credentials = ARGV[1]

db = Analysand::Database.new(db_uri)

post '/fail' do
  downloader = params[:downloader]
  item_name = params[:item_name]

  id = "#{downloader}:#{item_name}:#{Time.now.to_f}"

  resp = db.put(id, {
    downloader: downloader,
    response_code: params[:response_code],
    url: params[:url],
    item_name: item_name
  }, credentials)

  status resp.code
end
