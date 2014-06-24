require 'listen'

module Refresh
  class Daemon
    extensions = %w(
      builder coffee creole css slim erb erubis jbuilder
      slim mote haml html js styl dom
      less liquid mab markdown md mdown mediawiki mkd mw
      nokogiri radius rb rdoc rhtml ru
      sass scss str textile txt wiki yajl yml
      env.*
    ).sort

    DEFAULT_RELOAD_PATTERN      = %r(\.(?:builder #{extensions.join('|')})$)

    DEFAULT_FULL_RELOAD_PATTERN = /^Gemfile(?:\.lock)?$/

    # todo> make configurable
    IGNORE_PATTERNS             = [/\.direnv/, /\.sass-cache/, /^tmp/]

    attr_accessor :options, :unicorn_args
    attr_accessor :unicorn_pid

    def initialize argv
      @unicorn_args = argv
      # @options, @unicorn_args = options, unicorn_args
      @options = {}
      options[:pattern]       ||= DEFAULT_RELOAD_PATTERN
      options[:full]          ||= DEFAULT_FULL_RELOAD_PATTERN
      options[:force_polling] ||= false
      self
    end

    def log(msg)
      $stderr.puts msg
    end

    def start_unicorn
      @unicorn_pid = Kernel.spawn('unicorn', '-c', unicorn_config, *unicorn_args)
    end

    def unicorn_config
      File.expand_path 'unicorn.conf.rb', File.dirname(__FILE__)
    end

    # TODO maybe consider doing like: http://unicorn.bogomips.org/SIGNALS.html
    def reload_everything
      Process.kill(:QUIT, unicorn_pid)
      Process.wait(unicorn_pid)
      start_unicorn
    end

    def shutdown
      listener.stop
      Process.kill(:TERM, unicorn_pid)
      Process.wait(unicorn_pid)
      exit
    end

    # tell unicorn to gracefully shut down workers
    def hup_unicorn
      log "hupping #{unicorn_pid}"
      Process.kill(:HUP, unicorn_pid)
    end

    def handle_change(modified, added, removed)
      log "File change event detected: #{{modified: modified, added: added, removed: removed}.inspect}"

      if (modified + added + removed).index {|f| f =~ options[:full]}
        reload_everything
      else
        hup_unicorn
      end
    end

    def listener
      @listener ||= begin
        x = Listen.to(Dir.pwd, :relative_paths=>true, :force_polling=> options[:force_polling]) do |modified, added, removed|
          handle_change(modified, added, removed)
        end

        x.only([ options[:pattern], options[:full] ])
        IGNORE_PATTERNS.map{|ptrn| x.ignore(ptrn) }
        x
      end
    end

    def run
      that = self
      Signal.trap("INT") { |signo| that.shutdown }
      Signal.trap("EXIT") { |signo| that.shutdown }
      listener.start
      start_unicorn

      # And now we just want to keep the thread alive--we're just waiting around to get interrupted at this point.
      sleep(99999) while true
    end
  end
end
