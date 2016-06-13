#!/usr/bin/env ruby
LOCKFILE = '/tmp/satellite-art.lock'.freeze
URL = ENV['SA_URL'] || 'http://localhost:3000'
TOKEN = ENV['SA_TOKEN']
NEURAL_PATH = ENV['NEURAL_PATH']
SRC_IMAGE = "image.png"
exit unless File.new(LOCKFILE,'w').flock( File::LOCK_NB | File::LOCK_EX )

def neural_cmd(style, params)
  %W(
    qlua
    main.lua
    --style #{style}
    --content #{SRC_IMAGE}
    --model #{params['model']}
    --num_iters #{params['num_iters']}
    --size #{params['size']} )
end

require 'rest-client'
require 'json'
require 'mixlib/shellout'
require 'neural'
require 'satllite_art'


response = RestClient.get "#{URL}/api/v1/artworks", content_type: :json, accept: :json

abort("Server returned error") unless response.code == 200



JSON.parse(response.body).each do |artwork|
  next unless artwork['status'] == 'pending'

  art_response = RestClient.get artwork['url'], content_type: :json, accept: :json
  params = JSON.parse(art_response)

  style_url = params['style_url']
  style_url = File.join(URL, style_url) unless style_url.start_with?("http")
  s = RestClient.get(style_url)
  next unless s.code == 200

  Dir.mktmpdir do |tmpdir|
    Dir.chdir tmpdir

    style_file = File.open("style", "wb") do |f|
      f << s
    end

    cmd_string = neural_cmd(style_file, params)
    cmd = Mixlib::ShellOut.new(cmd_string)

    cmd.run_command
    if cmd.status == 0
      puts "Uploading output"
    end
  end
end