#!/usr/bin/expect
log_user 0
log_file -noappend newly_installed.log
set f [open "hosts.txt"]
set hosts [split [read $f] "\n"]
close $f

puts "Enter Package Name: "
expect_user -re "(.*)\n"
send_user "\n"
set mypkg $expect_out(1,string)

stty -echo
puts "Enter Root Password: "
expect_user -re "(.*)\n"
send_user "\n"
stty echo
set mypassword $expect_out(1,string)

puts "Below hosts have $mypkg already installed, check newly_installed.log for instances where install is attempted now"
puts "newly_installed.log also contains install status. Please wait as installing packages might take a few seconds and output for install is disabled"
foreach host $hosts {
	if { $host == "" } {
		continue
	}
    set timeout 90
	spawn ssh -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null root@$host
	expect {
	timeout { send_log "$host"; close; continue}
	"password: "
	}
	send "$mypassword\r"
	expect "# "
	send "dpkg -s $mypkg\r"
	expect "# "
	send "echo \$?\r"
	expect "echo \$?\r\n"
	expect "*\r"
	if { $expect_out(0,string) == 0 } {
			puts "$host"
	} else {
		send "apt-get update\r"
		expect "apt-get update\r\n"
		expect "# "
		send "apt-get -y install $mypkg\r"
		expect "apt-get -y install $mypkg\r\n"
		expect "# "
		send "echo \$?\r"
		expect "echo \$?\r\n"
		expect "*\r"
		if { $expect_out(0,string) == 0 } {
			send_log "Success: $host\n"
		} else {
			send_log "Failed: $host\n"
		}
	}
	close
}
