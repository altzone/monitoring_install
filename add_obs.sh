#!/bin/bash
if [[ `/opt/observium/discovery.php -h $1 | grep "does not exist"` ]]; then
        /opt/observium/add_device.php $1 net1csnmp
        /opt/observium/discovery.php -h $1

else
        echo "Le serveur $1 est deja present dans observium"
fi