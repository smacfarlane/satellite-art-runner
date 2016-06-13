require 'rest-client'
require 'mixlib/shellout'
require 'tempfile'

module Neural
  class Neural
    attr_reader :image, :style, :options

    VALID_PARAMS = %w(model num_iters size)
    NEURAL_PATH = ENV['NEURAL_PATH']

    def initialize(image, style, options)
      @image = fetch_image(image)
      @style = fetch_image(style)
      @options = sanitize_options(options)
    end

    def run
      @command = Mixlib::ShellOut.new(neural_cmd, env: { path: path })
      @command.run_command
    end

    def result
      "0500.jpg"
    end

    private
    def fetch_image(src)
      return src unless src.start_with?("http")

      image = RestClient.get(src)
      raise Neural::NetworkError unless image.code == 200

      file = Tempfile.new('style', 'wb')
      file.write(image.body)
      file
    end

    def neural_cmd
      "qlua main.lua --style #{style} --content #{image} --display-interval 0 #{options_to_flags}"
    end

    def sanitize_options(options)
      options.select{ |k,v| VALID_PARAMS.include?(k) }
    end

    def options_to_flags
      options.map{ |k,v| "--#{k} #{v}" }.join(" ")
    end

    def path
      [ ENV['PATH'], NEURAL_PATH ].join(":")
    end
  end
end