#!/usb/bin/env ruby
require 'sqlite3'
require 'socket'
class CaptivePortal
  attr_accessor :port, :iptables_bin, :allowedDB, :deniedDB, :interface, :network_lan, :active, :nIpAllowed, :nIpBanned, :server, :db
  def initialize(port)
    self.allowedDB = []  # Array that contains all ip allowed
    self.deniedDB = ["192.168.1.1","127.0.0.1","193.44.44.55"]   # Array that contains all banned ip
	self.blockConnection
    self.port = port.to_i
    self.nIpAllowed = 0
    self.nIpBanned = 0
	self.active = false;
	self.iptables_bin = "/sbin/ipables"
	
	# Always last line of initialize.
	self.listenAsk
  end
  def blockConnection
	system("#{self.iptables_bin} -A PREROUTING -i #{self.interface} -m tcp -s #{self.network_lan} --dport 80 -j REDIRECT --to-ports 3128 ");
	# Apache with configuration running on ports 3128
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
		str = self.db.prepare "SELECT * FROM logindata WHERE email='#{email}' AND password='#{password}'"
		rs = stm.execute
	end
  end
  def status
	"Status: #{self.active} </br>\n " + 
	"Ip Banned: #{self.nIpBanned}</br>\n" + 
	"Ip Allowed:#{self.nIpAllowed}</br>\n" + 
	"Server running in the port: #{self.port}</br>\n"
  end
  def listenAsk
	self.server = TCPServer.open(self.port)
	puts "Server started on port: #{self.port}"
	loop {
	  Thread.start(server.accept) do |client|
		data = client.recv(1024)
		puts "Data received: #{data}"
		data = data.split(' ')
		if data.first == "status"
			client.puts self.status
		end
		if data.first == "login"
			if data[1] == 'pippo' and data[2] == "12345"
				client.puts "OK"
			else
				client.puts "FAIL"
			end
		end
		if data.first == "ipbanned"
			client.puts self.deniedDB.join(' </br>')
		end
		client.close                # Disconnect from the client
	  end
	}
  end
  def deban(ip)
    sleep 60*60 # 1 hours
    self.deniedDB = self.deniedDB - [ ip ]
    self.nIpBanned -= 1
  end
end
if ARGV.size >= 1
	cp = CaptivePortal.new(ARGV.shift)
end
