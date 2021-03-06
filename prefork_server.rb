#!/usr/bin/env ruby
Process.daemon

require 'socket'

PIDS = []
$0 = "Prefork: non-block mode"


socket = TCPServer.open('0.0.0.0', 8080)

[:QUIT, :TERM].each do |sig|
	trap(sig) do
		PIDS.each { |pid|
			Process.kill(sig, pid)
		}
		exit	# if not exit, no child processes will be terminated
	end
end

trap(:CHLD) do
	begin
		pid, status = Process.waitpid2 -1
		if PIDS.include? pid
			PIDS.delete pid
		end
	rescue Errno::ECHILD
	end
end

3.times do
	PIDS << fork do
		$0 = "Prefork: worker"
		loop do
			connection = socket.accept
			connection.puts "Damnnnnn"
			connection.close
		end
	end
end

loop do
	# Should be tapping child processes
	sleep
end

