require 'sinatra'
require 'sinatra/contrib'
require 'dotenv'
require "net/http"
require "uri"
require 'json'
require 'slim'
require 'fastimage'

before do
  Dotenv.load
end

def httprequest(url)
  uri = URI.parse(url)
  # Full
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  response = http.request(Net::HTTP::Get.new(uri.request_uri))
  response
end

get '/:projectid' do
  projectid = params['projectid'].to_s || '1073850074' #default is chubachi pt!!
  response = httprequest("https://aiit.backlog.jp/api/v2/wikis?projectIdOrKey=#{projectid}&apiKey=" + ENV["apiKey"])
  # Will print response.body
  result = JSON.parse(response.body)
  @wikis = result.sort_by { |k| k["id"] }
  slim :list
end

get '/:projectid/:itemid' do
  itemid = params['itemid'].to_s
  response = httprequest("https://aiit.backlog.jp/api/v2/wikis/#{itemid}?apiKey=" + ENV["apiKey"])
  @wiki = JSON.parse(response.body)
  slim :item
end

get '/:itemid/attachments/:attachmentid' do
  itemid = params['itemid'].to_s
  attachmentid = params['attachmentid'].to_s
  response = httprequest("https://aiit.backlog.jp/api/v2/wikis/#{itemid}/attachments/#{attachmentid}?apiKey=" + ENV["apiKey"])
  headers \
  'Content-Type' => "image/png"
  body response.body
end
