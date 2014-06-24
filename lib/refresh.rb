require "refresh/version"
require "refresh/daemon"

module Refresh
  extend self

  def server
    Daemon.new(ARGV).run
  end
end
