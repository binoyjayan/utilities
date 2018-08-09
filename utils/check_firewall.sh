# Using nmap
# A state of "filtered" against port 9418 (git) means
#   that traffic is being filtered by a firewall

nmap github.com -p http,git

#Starting Nmap 5.21 ( http://nmap.org ) at 2015-01-21 10:55 ACDT
#Nmap scan report for github.com (192.30.252.131)
#Host is up (0.24s latency).
#PORT     STATE    SERVICE
#80/tcp   open     http
#9418/tcp filtered git

# Using Netcat:
# Returns 0 if the git protocol port IS NOT blocked
# Returns 1 if the git protocol port IS blocked

nc github.com 9418 < /dev/null; echo $?

# Using CURL
# Returns an exit code of (7) if the git protocol port IS blocked
# Returns no output if the git protocol port IS NOT blocked
# curl: (7) couldn't connect to host

curl  http://github.com:9418

