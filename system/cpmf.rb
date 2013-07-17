#!/usb/bin/env ruby
require 'sqlite3'
require 'socket'
require 'digest'

# Salvatore Criscione <salvatore@grrlz.net>
class CaptivePortal

  attr_accessor :port, :iptables_bin, :allowedDB, :deniedDB, :interface, :network_lan, :active, :server, :db, :debug, :password
  
  def initialize(port, debug)
    self.allowedDB = []  # Array that contains all ip allowed
    self.deniedDB = []   # Array that contains all banned ip
	self.blockConnection
	self.debug = debug == "true" ? true : false
    self.port = port.to_i
	self.active = false;
	self.iptables_bin = "/sbin/ipables"
	self.password = "helloworld"
	
	if self.debug
		puts "[+] Informazioni di debug abilitate..."
	end
	
	self.loadDB
	self.createTable
	
	# Always last line of initialize.
	self.listenAsk
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
		self.db.execute "CREATE TABLE IF NOT EXISTS logindata (email TEXT, password TEXT, Id INTEGER PRIMARY KEY AUTOINCREMENT)"
		puts "[!] Created table if not exists" if self.debug
	rescue
		self.error('create table error')
	end
  end
  
  def addUser(email, password)
	begin
		self.db.execute "INSERT INTO logindata VALUES('#{email}','#{Digest::MD5.hexdigest(password).to_s}',null)"
		puts "[!] Added User #{email},#{password} to database" if self.debug
	rescue
		self.error('add user error')
	end
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
	puts "[!] Login checker activated: email = #{email} , password = #{password}" if self.debug
	rs = self.db.execute"SELECT * FROM logindata WHERE email='#{email}' AND password='#{Digest::MD5.hexdigest(password).to_s}'"
	puts "Returned #{rs.size} rows.." if self.debug
	if rs.size == 0
		return false
	else
		return true
	end
  end
  
  def checkLoginAdmin(email, password)
	puts "[!] Login checker activated: email = #{email} , password = #{password}" if self.debug
	rs = self.db.execute"SELECT * FROM logindata WHERE email='#{email}' AND password='#{Digest::MD5.hexdigest(password).to_s}' AND id='1'"
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
	"Ip Allowed: #{self.allowedDB.size}</br>\n" + 
	"Ip Banned:#{self.deniedDB.size}</br>\n" + 
	"Server running in the port: #{self.port}</br>\n"
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
		puts "[!] Data received: #{data}" if self.debug
		data = data.split(' ')
		#if data.size > 1 # Wait for a fix , freeze all
		#	data[1] = data[1].replace('\'','')
		#	data[2] = data[2].replace('\'','')
		#end
		#data.first.lowercase!
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
		
		if data.first == "banip"
			deniedDB << data[1].to_s
			puts "#{data[1]} ip banned..." if self.debug
			client.puts "#{data[1]} ip banned..."
		end
		
		if data.first == "exit"
			if data[1] == self.password
				exit
			end
		end
				
		if data.first == "register"
			if data.size >= 2
				self.addUser(data[1],data[2])
			end
		end
		
		if data.first == "power"
			self.active = not(self.active)
		end
		
		if data.first == "autorize"
			if ( data[1] != "" )
			
				self.autorize(data[1])
				client.puts "OKS"
			else
				client.puts "ZERO"
			end
		end
		
		if data.first == "reset"
			puts "[!!!11] SOMEONE WANT DO RESET OMG"
			self.deniedDB = []
			self.allowedDB= []
		end

		client.close                # Disconnect from the client
	  end
	}
  end
  def autorize(ip)
	self.allowedDB << ip
	# self.allowConnection(ip)
  end
  def deban
    sleep 60*60 # 1 hours
    self.deniedDB = []
	#self.rebuildDB
  end
  
  def error(txt)
	puts "[-] Error: #{txt}"
	exit
  end
end

if ARGV.size >= 2
	cp = CaptivePortal.new(ARGV.shift, ARGV.shift)
end
