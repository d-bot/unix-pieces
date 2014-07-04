#!/usr/bin/env ruby
Process.daemon

require 'socket'
require 'logger'

log = Logger.new('/home/dchoi/projects/unix-pieces/prefork.log')

log.info "=======> master pid: #{$$}"
PIDS = []
$0 = "Prefork: non-block mode"


socket = TCPServer.open('0.0.0.0', 8080)

[:TERM, :QUIT].each do |sig|
	trap sig do
		PIDS.each do |pid|
			Process.kill(sig, pid)
			s = rand(10000); `touch /home/dchoi/projects/unix-pieces/sent_#{sig}_to_#{pid}`
		end
		exit
	end
end

5.times do
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

# Process.waitall or below if you care the status code from children

def wait_processes
	begin
		pid, status = Process.waitpid2(-1, Process::WNOHANG)
		pid or return
		if PIDS.include? pid
			PIDS.delete pid
			`touch /home/dchoi/projects/unix-pieces/killed_#{pid}`
		else
			puts "waiting for pid to be terminated"
		end
	rescue Errno::ECHILD
		break
	end while true
end

loop do
	trap(:CHLD) do
		if PIDS.length > 0
			wait_processes
		else
			break
		end
	end
end
