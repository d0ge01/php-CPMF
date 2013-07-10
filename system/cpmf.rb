#!/usb/bin/env ruby
require 'sqlite3'

class CaptivePortal
  attr_reader :active, :nIpAllowed, :nIpBanned
  attr_accessor :port, :iptables_bin, :allowedDB, :deniedDB
  def initialize(port)
    self.allowedDB = []  # Array that contains all ip allowed
    self.deniedDB = []   # Array that contains all banned ip

    self.port = port.to_i
    self.nIpAllowed = 0
    self.nIpBanned = 0
    self.addServerActive
	self.iptables_bin = "/sbin/ipables"
  end

  def addNewIpAllowed(ip)
    self.allowedDB << ip
    self.nIpAllowed += 1
    Thread.new do
      `#{self.iptables_bin} -s #{ip}`
    end
  end

  def banNewIpAllowed(ip)
    self.deniedDB << ip
    self.nIpBanned += 1
    Thread.new do
      self.deban(ip)
    end
  end
  def checkLogin(email, password)
	Thread.new do
		str = @db.prepare "SELECT * FROM logindata WHERE email='#{email}' AND password='#{password}'"
		rs = stm.execute
	end
  end
  def status
    puts "Status: #{self.active} </br>\n "
    puts "Ip Banned: #{self.nIpBanned}</br>\n"
    puts "Ip Allowed:#{self.nIpAllowed}</br>\n"
    puts "Server running in the port: #{self.port}</br>\n"
  end

  def deban(ip)
    sleep 60*60 # 1 hours
    self.deniedDB = self.deniedDB - [ ip ]
    self.nIpBanned -= 1
  end
end
