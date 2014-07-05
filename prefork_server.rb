#!/usr/bin/env ruby
Process.daemon

require 'socket'
require 'logger'

log = Logger.new('/home/dchoi/projects/unix-pieces/test.log')

log.info "=======> master pid: #{$$}"
PIDS = []
$0 = "Prefork: non-block mode"


socket = TCPServer.open('0.0.0.0', 8080)

[:QUIT, :TERM].each do |sig|
	trap(sig) do
		PIDS.each { |pid|
			Process.kill(sig, pid)
			s = rand(10000); `touch /home/dchoi/projects/unix-pieces/sent_#{sig}_to_#{pid}`
		}
		exit	# if not exit, no child processes will be terminated
	end
end

trap(:CHLD) do
	begin
		pid, status = Process.waitpid2 -1
		if PIDS.include? pid
			PIDS.delete pid
			`touch /home/dchoi/projects/unix-pieces/killed_#{pid}`
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

PIDS.each { |id| log.info "subprocess created as #{id}" }

loop do
	# Should be tapping child processes
	sleep
end

