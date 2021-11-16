#!/bin/bash
# pn:2018-10-31: script to auto generate a netkit lab with static routing loop
# 
#   +------+               +------+               +------+                       +------+               
#   |      |               |      |               |      |                       |      |               
#   |  h1  |               |  h2  |               |  h3  |                 ...   |  hn  |               
#   |      |               |      |               |      |                       |      |               
#   | eth0 |               | eth0 |               | eth0 |                       | eth0 |               
#   +--+---+               +--+---+               +--+---+                       +--+---+               
#    .2|                    .2|                    .2|                            .2|               
#      | 192.168.1.0/24       | 192.168.2.0/24       | 192.168.3.0/24               | 192.168.n.0/24
#    --+---+---             --+---+---             --+---+---                     --+---+---           
#          |                      |                      |                              |              
#        .1|                    .1|                    .1|                            .1|              
#    +-----+-----+          +-----+-----+          +-----+-----+                  +-----+-----+        
#    |    eth0   |          |    eth0   |          |    eth0   |                  |    eth0   |        
#    |           |          |           |          |           |                  |           |        
#    |     r1    |          |     r2    |          |     r3    |           ...    |     rn    |        
#    |           |          |           |          |           |                  |           |      
#    | eth1 eth2 |          | eth1 eth2 |          | eth1 eth2 |                  | eth1 eth2 |      
#    +--+----+---+          +--+----+---+          +--+----+---+                  +--+----+---+      
#     .1|  .2|               .1|  .2|               .1|  .2|                       .1|  .2|
#       |    |10.1.1.0/24      |    |10.2.2.0/24      |    |10.3.3.0/24              |    |10.n.n.0/24
#  -+---+-  -+-----------------+-  -+-----------------+-  -+-------------  ...  -----+-  -+------+--
#   |                                                                                            |
#   |                        ---------->>>>>>>>>>                                                |
#   |                       ^    default route   V                                               |
#   |                        <<<<<<<<<<----------                                                |
#   +--------------------------------------------------------------------------------------------+
#
#############################################
# commands to experiment with whilst capturing on any router eth1 or eth2 (not eth0 - that is the lan)
# on any h
#    ping -c1 -R -t 100 -s 3000 192.168.7.7
# same command on any r (except the one doing the dump
#
# on any r (r5 in this example)
#    ifconfig eth2
# (note the ip address eg 10.5.5.2 and mtu eg 1500 )
#    ifconfig eth2 10.5.5.2/24 mtu 100    # use the correct ip address in place of 10.5.5.2
#    route add deffault gw 10.5.5.1       # use the correct ip address in place of 10.5.5.1
#############################################

# do not overwrite existing version of the generated lab
DIR="ip4-route-loop"
mv "$DIR" "$DIR_$(date '+%F_%H-%M-%S')"  2>/dev/null || true

# create new empty lab directory and set it as pwd
mkdir -p $DIR
cd $DIR

# create common settings, shared by all machines
mkdir -p shared/etc/
cat <<-EOF > shared/etc/sysctl.conf
	net.ipv4.ip_forward=1
	net.ipv4.ip_default_ttl=60
	# disable ip6
	net.ipv6.conf.all.disable_ipv6 = 1
	net.ipv6.conf.default.disable_ipv6 = 1
	net.ipv6.conf.lo.disable_ipv6 = 1
EOF

echo "sysctl -p" > shared.startup
touch lab.dep

# establish number of routers in the loop then process each in turn:
# n can be changed, constrained by  2 < n < 254
# whatever value you give to n, there will be 2n machines created
n=6

# loop through routers, one by one, creating router and host netkit artefacts / configs as we go
for i in $(seq $n)
do
	# establish "number" of adjacent routers in the loop (trivial except for i=1 and i=n)
  prev=$(( ($i + $n - 2) % $n + 1  ))
  next=$(( $i % $n + 1  ))
  
  # each router r<i> has a lan with one host on it h<i>
  mkdir h${i} r${i}
  
  # build lab.conf for host with one nic and router with three nics
  echo "h${i}[0]=lan${i}" >> lab.conf
  echo "r${i}[0]=lan${i}" >> lab.conf
  echo "r${i}[1]=link${prev}${i}" >> lab.conf
  echo "r${i}[2]=link${i}${next}" >> lab.conf
  echo "" >> lab.conf
  
  # build startup file for h<i> 
  echo "ifconfig eth0 192.168.$i.2/24" >> h${i}.startup
  echo "route add default gw 192.168.$i.1" >> h${i}.startup
  
  # build startup file for r<i> 
  echo "ifconfig eth0 192.168.$i.1/24" >> r${i}.startup
  echo "ifconfig eth1 10.$prev.$prev.1/24" >> r${i}.startup
  echo "ifconfig eth2 10.$i.$i.2/24" >> r${i}.startup
  echo "route add default gw 10.$i.$i.1" >> r${i}.startup
  
done
  
