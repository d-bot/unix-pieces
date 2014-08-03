#!/usr/bin/env ruby

require 'timeout'

begin
	Timeout.timeout(5) do
		@pid = fork { `sleep 30` }
		puts "#{@pid} created and started waiting"
		Process.wait(-1)
	end
rescue Timeout::Error
	#Process.kill("-KILL", @gid)
	`pkill -TERM -P #{@pid}`
	puts "killed"
end
