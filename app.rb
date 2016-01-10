require 'sinatra'
require 'sinatra/contrib'
require 'dotenv'
require "net/http"
require "uri"
require 'json'
require 'slim'
require 'redis'

before do
  Dotenv.load
  $redis = Redis.new(url: ENV["REDIS_URL"])
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

get '/' do
  redirect to("/1073850074")
end

get '/:projectid' do
  projectid = params['projectid'].to_s || '1073850074' #default is chubachi pt!!
  resultJson = $redis.get(projectid)
  if resultJson.nil?
    response = httprequest("https://aiit.backlog.jp/api/v2/wikis?projectIdOrKey=#{projectid}&apiKey=" + ENV["apiKey"])
    # Will print response.body
    resultJson = response.body
    $redis.set(projectid, resultJson)
    $redis.expire(projectid, 30)
  end
  result = JSON.parse(resultJson)
  @wikis = result.sort_by { |k| k["id"] }
  slim :list
end

get '/:projectid/:itemid' do
  itemid = params['itemid'].to_s
  resultJson = $redis.get(itemid)
  if resultJson.nil?
    response = httprequest("https://aiit.backlog.jp/api/v2/wikis/#{itemid}?apiKey=" + ENV["apiKey"])
    resultJson = response.body
    $redis.set(itemid, resultJson)
    $redis.expire(itemid, 600)
  end
  @wiki = JSON.parse(resultJson)
  slim :item
end

get '/:itemid/attachments/:attachmentid' do
  itemid = params['itemid'].to_s
  attachmentid = params['attachmentid'].to_s
  image = $redis.get(attachmentid)
  if image.nil?
    response = httprequest("https://aiit.backlog.jp/api/v2/wikis/#{itemid}/attachments/#{attachmentid}?apiKey=" + ENV["apiKey"])
    $redis.set(attachmentid, response.body)
    $redis.expire(attachmentid, 600)
    image = response.body
  end
  
  headers \
  'Content-Type' => "image/png"
  body image 
end
