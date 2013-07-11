#!/usb/bin/env ruby
require 'sqlite3'
require 'socket'

# Salvatore Criscione <salvatore@grrlz.net>

class CaptivePortal
  attr_accessor :port, :iptables_bin, :allowedDB, :deniedDB, :interface, :network_lan, :active, :nIpAllowed, :nIpBanned, :server, :db, :debug
  def initialize(port, debug)
    self.allowedDB = []  # Array that contains all ip allowed
    self.deniedDB = ["192.168.1.1","127.0.0.1","10.10.10.10"]   # Array that contains all banned ip
	self.blockConnection
	self.debug = debug == "true" ? true : false
    self.port = port.to_i
    self.nIpAllowed = 0
    self.nIpBanned = 0
	self.active = false;
	self.iptables_bin = "/sbin/ipables"
	
	if self.debug
		puts "Informazioni di debug abilitate..."
	end
	
	
	self.loadDB
	self.createTable
	# Always last line of initialize.
	self.listenAsk
  end
  def loadDB
	self.db = SQLite3::Database.new "login.db"
  end
  def createTable
	self.db.execute "CREATE TABLE IF NOT EXISTS logindata (email TEXT, password TEXT, Id INTEGER PRIMARY KEY AUTOINCREMENT)"
  end
  def addUser(email, password)
    self.db.execute "INSERT INTO logindata VALUES('#{email}','#{password}',null)"
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
	puts "Login checker activated: email = #{email} , password = #{password}" if self.debug
	rs = self.db.execute"SELECT * FROM logindata WHERE email='#{email}' AND password='#{password}'"
	puts "Returned #{rs.size} rows.." if self.debug
	if rs.size == 0
		return false
	else
		return true
	end
  end
  def status
	buff = ""
	if self.active
		buff = "<font color='green'>ONLINE</font>"
	else
		buff = "<font color='red'>OFFLINE</font>"
	end
	"Status: #{buff} </br>\n " + 
	"Ip Banned: #{self.nIpBanned}</br>\n" + 
	"Ip Allowed:#{self.nIpAllowed}</br>\n" + 
	"Server running in the port: #{self.port}</br>\n"
  end
  def listenAsk
	self.server = TCPServer.open(self.port)
	puts "Server started on port: #{self.port}"
	self.active = true;
	loop {
	  Thread.start(server.accept) do |client|
		data = client.recv(1024)
		puts "Data received: #{data}"
		data = data.split(' ')
		if data.first == "status"
			client.puts self.status
		end
		if data.first == "login"
			if(self.checkLogin(data[1],data[2]))
				client.puts "OK"
			else
				client.puts "FAIL"
			end
			client.puts "END"
		end
		if data.first == "ipbanned"
			client.puts self.deniedDB.join(' </br>- ')
		end
		if data.first == "exit"
			if data[1] == "helloworld"
				exit
			end
		end
		if data.first == "register"
			self.addUser(data[1],data[2])
		end
		
		if data.first == "deactivate"
			self.active = false
		end
		if data.first == "activate"
			self.active == true
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
if ARGV.size >= 2
	cp = CaptivePortal.new(ARGV.shift, ARGV.shift)
end
