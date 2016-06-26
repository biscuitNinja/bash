#!/bin/sh

# Alternative to ShutdownPfSense.sh
# Uses SSH instead of curl

firewall="fw.network.home"
usr="upsShutdown"
identityFile="/root/.ssh/id_rsa_pf-shutdown.fw.network.home"
command="sudo /sbin/shutdown -p now 'Shutdown due to power failure'"

/usr/bin/ssh -q -i $identityFile ${usr}@${firewall} $command
