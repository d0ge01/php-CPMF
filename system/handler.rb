require 'socket'

#
#	This file is a part of CPMF
#
if ARGV.size >= 3
	socket = TCPSocket.new(ARGV.shift, ARGV.shift.to_i)
	str = ARGV.join(' ')
	socket.puts str
	puts socket.recv(1024)
end