#!/usb/bin/env ruby


class CaptivePortal
  attr_accessor :active, :port, :nIpAllowed, :nIpBanned
  def initialize(port)
    @allowedDB = []  # Array that contains all ip allowed
    @deniedDB = []   # Array that contains all banned ip

    self.port = port.to_i
    self.nIpAllowed = 0
    self.nIpBanned = 0

    self.addServerActive
  end

  def addNewIpAllowed(ip)
    @allowedDB << ip
    self.nIpAllowed += 1
    Thread.new do
      `#{@iptables_bin} -s #{ip}`
    end
  end

  def banNewIpAllowed(ip)
    @deniedDB << ip
    self.nIpBanned += 1
    Thread.new do
      self.deban(ip)
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
    @deniedDB = @deniedDB - [ ip ]
    self.nIpBanned -= 1
  end
end
