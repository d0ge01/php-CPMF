#!/usb/bin/env ruby
require 'sqlite3'
require 'socket'
require 'digest/sha1'

# Salvatore  Criscione     <salvatore@grrlz.net>
# License:	DO U WANT PIRATE FREE U ARE A PIRATE
# Date:		2013-2014
# Description:
#			This is simple captive portal using
#			Client-server programming by Ruby and
#			PHP, nothing advance

class CaptivePortal

  attr_accessor :port, :iptables_bin, :allowedDB, :deniedDB, :interface, :network_lan, :active, :server, :db, :debug, :password, :armed
  
  def initialize(debug = nil, armed = nil)
  
    self.allowedDB = [ '127.0.0.1' ]  # Array that contains all ip allowed
    self.deniedDB = [ ]   # Array that contains all banned ip
	
	self.debug = debug == "true" ? true : false
    self.port = 12345
	self.active = false;
	self.armed = armed == "true" ? true : false
	self.interface = "eth1"			# Default interface
	self.network_lan="eth0"			# Default interface
	
	self.alpha = ('a'..'z').to_a
	('A'..'Z').to_a.each do |ch|
		self.alpha << ch
	end
	
	('0'..'9').to_a.each do |ch|
		self.alpha << ch
	end
	
	self.readConf
	
	puts "[+] Informazioni di debug abilitate..." if self.debug
	
	self.resetRules
	self.defaultRules
	
	self.loadDB
	self.createTable 
	
	self.rebuildRules
	
	# This will be always last line of initialize.
	self.listenAsk
  end
  
  def rebuildRules
	self.allowedDB.each do |ip|
		self.addNewIpAllowed(ip)
	end
	
	self.deniedDB.each do |ip|
		self.banNewIpAllowed(ip)
	end
  end
  
  def genRandomHash
	word = ""
	30.times do
		word = word + self.alpha[random(self.alpha.size)]
	end
	Digest::SHA1.hexdigest(word).to_s
  end
  
  def readConf
	begin
		buff = File.readlines("system/conf/cpmf.conf")
		buff.each do |line|
			line = line.split('|')
			if ( line.first == "PORT" )
				self.port = line.last.chomp.to_i
			end
			
			if ( line.first == "INTERFACE_INT" )
				self.interface = line.last.chomp
			end
			
			if ( line.first == "INTERFACE_EXT" )
				self.network_lan = line.last.chomp
			end
			
			if ( line.first == "ALLOWIP" )
				self.allowedDB << line.last.chomp
			end
			
			if ( line.first == "BANIP" )
				self.deniedDB << line.last.chomp
			end
			
		end
	rescue
		puts("[-] Error: Parsing configuration.. switching to default")
		self.port = 12345
		puts "[!] Using default port 12345... ") if self.debug
		self.interface = "eth0"
		puts "[!] Using wan interface eth0... ") if self.debug
		self.network_lan = "eth1"
		puts "[!] Using lan interface eth1... ") if self.debug
	end
  end
  
  def resetRules
	if self.armed
		system("iptables -F")
		puts "[!] Reset rules ( iptables )" if self.debug
	end
  end
  
  def defaultRules
	if self.armed
		system("iptables -I INPUT -p tcp -i #{self.network_lan} -m state -s 0/0 --dport 1:65535 --state INVALID,NEW -j DROP")
		system("iptables -I INPUT -p icmp -i #{self.network_lan} -m state -s 0/0 --state INVALID,NEW -j DROP")
		system("iptables -I INPUT -p udp -i #{self.network_lan} -m state -s 0/0 --state INVALID,NEW -j DROP")
		system("iptables -I INPUT -p tcp -i #{self.network_lan} -s 0/0 --dport 80 -j ACCEPT")
		system("iptables -I INPUT -p tcp -i #{self.network_lan} -s 127.0.0.1 --dport #{self.port} -j ACCEPT")
		puts "[!] default rules set( iptables )" if self.debug
	end
  end
  
  def loadDB
	begin
		self.db = SQLite3::Database.new "login.db"
		puts "[!] Inizialized database" if self.debug
	rescue
		self.error('database error')
	end
  end
  
  def createTable
	begin
		self.db.execute "CREATE TABLE IF NOT EXISTS logindata (email TEXT, userhash TEXT, password TEXT, active INT, id INTEGER PRIMARY KEY AUTOINCREMENT)"
		puts "[!] Created table if not exists" if self.debug
	rescue
		self.error('create table error')
	end
  end
  
  def addUser(email, password)
	begin
		self.db.execute "INSERT INTO logindata VALUES('#{email}','#{self.genRandomHash}','#{Digest::SHA1.hexdigest(password).to_s}', '0', null)"
		puts "[!] Added User #{email},#{password} to database" if self.debug
	rescue
		self.error('add user error')
	end
  end
  
  def verify(hash)
	begin
		rs = self.db.execute "UPDATE logindata SET active='1' WHERE userhash='#{hash.to_s}'"
		if rs.size == 0
			return "NOONE"
		else
			return "OK"
		end
	rescue
		self.error('verify someone..')
	end
  end
  
  def addNewIpAllowed(ip)
	if self.deniedDB.include? ip
		puts "[!] Banned Ip made request. " if self.debug
	else
		self.allowedDB << ip
		self.nIpAllowed += 1
		if self.armed
			self.allowConnection(ip)
		end
	end
  end

  def banNewIpAllowed(ip)
    self.deniedDB << ip
    self.nIpBanned += 1
  end

  def checkLogin(email, password)
	puts "[!] Login checker activated: email = #{email} , password = #{password}" if self.debug
	rs = self.db.execute "SELECT * FROM logindata WHERE email='#{email}' AND active='1' AND password='#{Digest::SHA1.hexdigest(password).to_s}'"
	puts "Returned #{rs.size} rows.." if self.debug
	if rs.size == 0
		return false
	else
		return true
	end
  end
  
  def checkLoginAdmin(email, password)
	puts "[!] Login checker activated: email = #{email} , password = #{password}" if self.debug
	rs = self.db.execute"SELECT * FROM logindata WHERE email='#{email}' AND password='#{Digest::SHA1.hexdigest(password).to_s}' AND id='1'"
	puts "Returned #{rs.size} rows.." if self.debug
	if rs.size == 0
		return false
	else
		return true
	end
  end
  
  def userNumber
	puts "[!] Counting users in DB " if self.debug
	rs = self.db.execute"SELECT * FROM logindata"
	rs.size
  end
  
  def status
	buff = ""
	if self.active
		buff = "<font color='green'>ONLINE</font>"
	else
		buff = "<font color='red'>OFFLINE</font>"
	end
	
	"Status: #{buff} </br>\n" + 
	"Ip Allowed: #{self.allowedDB.size}</br>\n" + 
	"Ip Banned:#{self.deniedDB.size}</br>\n" + 
	"Server running in the port: #{self.port}</br>\n" + 
	"Using Internal interface: #{self.network_lan}</br>\n" + 
	"Using External interface: #{self.interface}</br>\n"
  end
  
  def listenAsk
	begin
		self.server = TCPServer.open(self.port)
	rescue
		self.error('[-] server start error')
	end
	puts "[+] Server started on port: #{self.port}"
	self.active = true;
	loop {
	  Thread.start(server.accept) do |client|
		data = client.recv(1024)
		puts "[!] Data received: #{data.chomp} from #{client.addr.last.to_s} " if self.debug
		data = data.split(' ')
		
		if client.addr.last.to_s == "::1"
			local = true
		else
			local = false
		end
		
		if data.first == "status"
			puts "[!] sending status to client" if self.debug
			client.puts self.status
		end
		
		if data.first == "login"
			if(self.checkLogin(data[1],data[2]))
				puts "[!] Login OK" if self.debug
				client.puts "OK"
			else
				puts "[!] Login FAIL" if self.debug
				client.puts "FAIL"
			end
			client.puts "END"
		end
		
		if data.first == "adminlogin"
			if(self.checkLoginAdmin(data[1],data[2]))
				puts "[!] Login OK" if self.debug
				client.puts "OK"
			else
				puts "[!] Login FAIL" if self.debug
				client.puts "FAIL"
			end
			client.puts "END"
		end
		
		if data.first == "ipbanned"
			client.puts self.deniedDB.join(' </br>- ')
		end
		
		if data.first == "ipallowed"
			client.puts self.allowedDB.join(' </br>- ')
		end
		
		if data.first == "banip" and local
			deniedDB << data[1].to_s
			puts "#{data[1]} ip banned..." if self.debug
			client.puts "#{data[1]} ip banned..."
		end
		
		if data.first == "exit" and local
			exit
		end
				
		if data.first == "register" and local
			if data.size >= 2
				self.addUser(data[1],data[2])
			end
		end
		
		if data.first == "power" and local
			self.active = ! self.active
		end
		
		if data.first == "autorize" and local
			if ( data[1] != "" )
				self.addNewIpAllowed(data[1])
				client.puts "OKS"
			else
				client.puts "FAIL"
			end
		end
		
		if data.first == "usercount"
			client.puts self.userNumber
		end
		
		if data.first == "arm" and local
			self.armed = true
			self.resetRules
			self.defaultRules
			client.puts "ARMED"
		end
		
		if data.first == "verify"
			if ( data[1] != "" )
				client.puts self.verify(data[1])
			else
				client.puts "FAIL"
			end
		end
		
		if data.first == "reset" and local
			puts "[!!!11] SOMEONE WANT DO RESET OMG"
			self.deniedDB = []
			self.allowedDB= []
			puts "[!] It's almost useless with arm disable :/ " if !self.armed
			self.resetRules
			self.defaultRules
			client.puts "RESET"
		end

		client.close                # Disconnect from the client
	  end
	}
  end
  
  def allowConnection(ip)
	system("iptables -A POSTROUTING -t nat -s #{ip} -j MASQUERADE")
  end
  
  def error(txt)
	puts "[-] Error: #{txt}"
	# exit // Do not exit, this is server
  end
end

if ARGV.size >= 2
	cp = CaptivePortal.new(ARGV.shift, ARGV.shift)
else
	cp = CaptivePortal.new("true", "false")
end