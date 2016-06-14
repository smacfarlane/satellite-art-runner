require 'rest-client'
require 'mixlib/shellout'
require 'tempfile'

module Neural
  class Neural
    attr_reader :source, :style, :options

    VALID_PARAMS = %w(model num_iters size)
    NEURAL_PATH = ENV['NEURAL_PATH']

    def initialize(source, style, options)
      @source = source
      @style = style
      @options = sanitize_options(options)
    end

    def run
      @command = Mixlib::ShellOut.new(neural_cmd, env: { path: path })
      @command.run_command
    end

    def success?
      !@command.nil? && @command.status == 0
    end
    
    def result
      Dir.glob("frames/*.jpg").sort.last
    end

    private
    def neural_cmd
      "qlua main.lua --style #{style} --content #{source} --display-interval 0 #{options_to_flags}"
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