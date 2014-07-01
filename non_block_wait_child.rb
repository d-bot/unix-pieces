#!/usr/bin/env ruby

PIDS = []

3.times do
	pid = fork do
		sleep 5; puts "#{$$}: woke up after sleeping 10 sec!!"
	end
	PIDS.push(pid)
end

def wait_pids
	begin
		pid, status = Process.waitpid2(-1, Process::WNOHANG)
		pid or return
		if PIDS.include? pid
			puts "#{pid} terminated"
			PIDS.delete pid
		else
			puts "waiting for pid to be terminated"
		end
	rescue Errno::ECHILD
		break
	end while true
end


loop do
	if PIDS.length > 0
		wait_pids
	else
		break
	end
end
