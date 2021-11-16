#!/bin/bash
# Peter Norris: University of Warwick: 2019-10-21
# Generate raw binary file from hex text file
# Deletes from # to end of line (ie shell comments) from input file

# Sed strips from # to end of line (ie shell comments) from input
# Inspired by poc||gtfo 7:5 "When Scapy is too high-level" by Eric Davisson
# sed comment stripping derived from:
# https://superuser.com/questions/332252/how-to-create-and-format-a-partition-using-a-bash-script

# Typical use:
#      ./hex2bin.sh < f1.ascii  > f2.bin
# where f1.ascii is (commented) ascii hex source and f2.bin is binary output
# Confirm f2.bin is as is should be via:
#      xxd f2.bin

sed -e 's/\([^#]*\).*/\1/' | xxd -r -p 

