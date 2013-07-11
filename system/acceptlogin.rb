require 'socket'
socket = TCPSocket.new('localhost', 12345)
if ARGV.size >= 1
	str = ARGV.join(' ')
	socket.puts str
	puts socket.recv(1024)
end