#!/usr/bin/expect
log_user 0
log_file -noappend not_reachable.log
set f [open "hosts.txt"]
set hosts [split [read $f] "\n"]
close $f

stty -echo
puts "Enter Root Password: "
expect_user -re "(.*)\n"
send_user "\n"
stty echo
set mypassword $expect_out(1,string)
puts "Below hosts have uptime less than 1 day, check not_reachable.log for instances which timed out during ssh"
foreach host $hosts {
	if { $host == "" } {
		continue
	}
    set timeout 30
	spawn ssh -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null root@$host
	expect {
	timeout { send_log "$host"; close; continue}
	"password: "
	}
	send "$mypassword\r"
	expect "# "
	send "uptime=\$(</proc/uptime);uptime=\${uptime%%.*};days=\$(( uptime/60/60/24 ))\r"
	expect "# "
	send "echo \$days\r"
	expect "echo \$days\r\n"
	expect "*\r"
	if { $expect_out(0,string) < 1 } {
			puts "$host"
	}

	close
}
