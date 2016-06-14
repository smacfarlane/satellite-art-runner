require 'rest-client'
require 'json'

class SatelliteArt
  TOKEN = (ENV['SA_TOKEN']).freeze
  DEFAULT_URL = (ENV['SA_URL'] || 'http://localhost:3000').freeze
  attr_reader :source, :style, :options

  def self.fetch_pending!(url)
    response = SatelliteArt.get url, content_type: :json, accept: :json
    raise "Unable to fetch pending artwork" unless response.code == 200
    payload = JSON.parse(response.body)
    payload.select{|i| i['status'] == 'pending' }.map{|a| SatelliteArt.new(a) }
  end

  def self.get(url, params={})
    RestClient.get url, params.merge({token: TOKEN})
  end

  def self.patch(url, params={})

    RestClient.patch url, params, {token: TOKEN}
  end

  def initialize(params)
    @url = params.delete('url')
  end

  def fetch!
    response = SatelliteArt.get @url, content_type: :json, accept: :json
    raise "Unable to fetch artwork" unless response.code == 200

    payload = JSON.parse(response.body)

    @style = fetch_image!(payload.delete('style_url'))
    @source = fetch_image!(payload.delete('source_url'))
    @options = payload
  end

  def fetch_image!(url)
    # Deal with refile attachments not having host in development
    url = "#{DEFAULT_URL}/#{url}" unless url.start_with?("http")
    response = SatelliteArt.get url
    raise "Unable to fetch image #{url}" unless response.code == 200

    filename = File.basename(url)
    File.open(filename, 'wb') do |f|
      f << response.body
    end

    filename
  end

  def upload!(result)
    params = {
      image: File.new(result, 'rb')
    }
    puts "#{@url} - #{params}"
    SatelliteArt.patch @url, params
  end
end