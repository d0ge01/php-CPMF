require 'socket'
socket = TCPSocket.new('localhost', 12345)

str = ARGV.join(' ')
socket.puts str
puts socket.recv(1024)