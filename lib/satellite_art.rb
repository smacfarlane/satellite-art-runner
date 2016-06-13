require 'rest-client'
require 'json'

class SatelliteArt
  TOKEN = (ENV['SA_TOKEN']).freeze
  SRC_IMAGE = ("image.png").freeze

  attr_reader :style, :options

  def self.fetch_pending!(url)
    response = RestClient.get url, content_type: :json, accept: :json
    raise "Unable to fetch pending artwork" unless response.code == 200
    payload = JSON.parse(response.body)
    payload.select{|i| i['status'] == 'pending' }.map{|a| SatelliteArt.new(a) }
  end

  def initialize(params)
    @url = params.delete('url')
  end

  def fetch!
    response = RestClient.get @url, content_type: :json, accept: :json
    raise "Unable to fetch artwork" unless response.code == 200

    payload = JSON.parse(response.body)
    @style = payload.delete('style_url')
    @options = payload
  end

  def upload!(result)
    puts "Posting to server: #{@url}"
  end
end