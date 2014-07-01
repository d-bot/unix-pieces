#!/usr/bin/env ruby
#

puts $$

SIGNAL_QUEUE = []
R_self_pipe, w_self_pipe = IO.pipe

[:INT, :QUIT, :TERM].each do |signal|
  trap (signal) {
    # write a byte to the self-pipe
    w_self_pipe.write_nonblock('.')
		w_self_pipe.putc(0)
    SIGNAL_QUEUE << signal
  }
end


R_pc_pipe, w_pc_pipe = IO.pipe

Child_pid = fork do
	$PROGRAM_NAME = "dch worker process"
	puts $$
	R_pc_pipe.close
	sleep 2
	w_pc_pipe.puts "sending first message from #{$$} child"
	sleep 2
	w_pc_pipe.puts "sending second message from #{$$} child"
	sleep 2
	w_pc_pipe.puts "sending third message from #{$$} child"

	#w_pc_pipe.close
	exit!(0)
end

w_pc_pipe.close

$stdout.sync = true

def new_loop
	case SIGNAL_QUEUE.pop
	when :INT
		puts "received INT signal"
	when :QUIT
		puts "received QUIT signal"
	when :TERM
		puts "received TERM signal"
	else
		ready = IO.select [R_pc_pipe,  R_self_pipe]

		if ready.first.include? R_self_pipe
			R_self_pipe.read_nonblock(1)
			puts "read data from self-pipe!!!"
		end
		if (R_pc_pipe and ready[0]).any?
			msg = R_pc_pipe.gets
			if msg
				puts "#{Child_pid}: #{msg}"
			#else
			#	break
			end
		end
		#puts "before run process wait"
		begin
			pid, status = Process.waitpid2(-1, Process::WNOHANG)
			if Child_pid == pid
				puts "got the sig!!"
				break
			end
		rescue Errno::ECHILD
			break
		end
	end while true
end

new_loop
