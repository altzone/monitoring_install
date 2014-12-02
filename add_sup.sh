#!/bin/bash

echo "Ajout d'un serveur dans la supervision"
echo "--------------------------------------"
echo
echo -n "Nom du client   (ex: net1c): "
read client

if [[ ! $1 ]]; then
        echo -n "Hostname (ex client-mail2) : "
        read nom
else
        nom=$1
fi

if [ ! -f "/usr/local/nagios/etc/objects/clients/$client/$nom.cfg" ]; then

        if [[ ! $2 ]]; then
                echo -n "                  Ip Privé : "
                read ip
        else
                ip=$2
        fi
        if [[ ! $3 ]]; then
                echo -n "                 IP Public : "
                read ip_pub
        else
                ip_pub=$3
        fi
        echo "Mysql [Y/N/y/n] [n] "
        read mysql
        case $mysql in
                [Yy]* ) sql=1;;
                [Nn]* ) sql=0;;
                * ) sql=0;;
        esac
        echo "Apache [Y/N/y/n] [n] "
        read  apache
        case $apache in
                [Yy]* ) web=1;;
                [Nn]* ) web=0;;
                * ) web=0;;
        esac

        echo "FTP [Y/N/y/n] [n] "
        read ftp
        case $ftp in
                [Yy]* ) ftpd=1;;
                [Nn]* ) ftpd=0;;
                * ) ftpd=0;;
        esac


        echo "SMTP [Y/N/y/n] [n] "
        read mail
        case $mail in
                [Yy]* ) smtp=1;;
                [Nn]* ) smtp=0;;
                * ) smtp=0;;
        esac

        echo "XiVo [Y/N/y/n] [n] "
        read xivo
        case $xivo in
                [Yy]* ) xiv=1;;
                [Nn]* ) xiv=0;;
                * ) xiv=0;;
        esac
        if [[ $xiv = 1 ]]; then
                ast=1
        else

                echo "Asterisk [Y/N/y/n] [n] "
                read asterisk
                case $asterisk in
                        [Yy]* ) ast=1;;
                        [Nn]* ) ast=0;;
                        * ) ast=0;;
                esac
        fi

        echo ""

        if [ ! -d "/usr/local/nagios/etc/objects/clients/$client" ]; then
                echo "Client non existant, creation du repertoire $client"
                mkdir -p /usr/local/nagios/etc/objects/clients/$client
                echo "Creation du fichier hostgroup"
                echo "define hostgroup {
                hostgroup_name          $client
                alias                   $client
                }" > /usr/local/nagios/etc/objects/clients/$client/hostgroup.cfg
        fi

        echo Ajout de la configuration pour $nom
        cat template.sup | sed -e "s/XXHOSTGROUPXX/$client/g" -e "s/XXHOSTNAMEXX/$nom/g" -e "s/XXADDRESSXX/$ip/g" -e "s/XXPUBADDRESSXX/$ip_pub/g" > /usr/local/nagios/etc/objects/clients/$client/$nom.cfg
        if [ $sql = 1 ]; then
                echo "Supervision MySQL => OK"
                echo "define service {
                host_name               $nom
                use                     network-service
                service_description     MYSQL_TCP_LOCAL
                check_command           check_nrpe_1arg!check_mysql_tcp_local
                }

                define service {
                host_name               $nom
                use                     network-service
                service_description     MYSQL_PROC
                check_command           check_nrpe_1arg!check_mysql_proc
                }

                define service {
                host_name               $nom
                use                     network-service
                service_description     MYSQL_MAX_CONN
                check_command           check_nrpe_1arg!check_mysql_max_conn
                }

                define service {
                host_name               $nom
                use                     network-service
                service_description     MYSQL_CORRUPT
                check_command           check_nrpe_1arg_timeout!180!check_mysql_corrupt
                }
                define service {
                host_name               $nom
                use                     network-service
                service_description     MYSQL
                check_command           check_nrpe_1arg_timeout!180!check_mysql
                }
                " >> /usr/local/nagios/etc/objects/clients/$client/$nom.cfg

        fi


        if [ $web = 1 ]; then
                echo "Supervision Web => OK"
                echo "define service {
                host_name               $nom
                use                     network-service
                service_description     HTTP_HOSTADDRESS_PUBLIC_IPV4
                check_command           check_http!\$_HOSTADDRESS_PUBLIC_IPV4\$!\$_HOSTADDRESS_PUBLIC_IPV4$
                }
                " >> /usr/local/nagios/etc/objects/clients/$client/$nom.cfg
        fi

        if [ $smtp = 1 ]; then
                echo "Supervision SMTP => OK"
                echo "define service {
                host_name               $nom
                use                   generic-service
                service_description     MAIL_QUEUE
                check_command           check_nrpe_1arg!check_mailq
                }
                " >> /usr/local/nagios/etc/objects/clients/$client/$nom.cfg
        fi

        if [ $ast = 1 ]; then
                echo "Supervision SIP => OK"
                echo "define service {
                host_name               $nom
                use                     generic-service
                service_description     SIP
                check_command           check_asterisk!sip:1234!\$_HOSTADDRESS_PUBLIC_IPV4\$!5060!5!10
                }
                define service {
                host_name               $nom
                use                     generic-service
                service_description     ASTERISK
                check_command           check_nrpe_1arg!check_asterisk
                }

                " >> /usr/local/nagios/etc/objects/clients/$client/$nom.cfg
        fi


        if [ $ftpd = 1 ]; then
                echo "Supervision FTP => OK"
                echo "define service {
                host_name               $nom
                use                     generic-service
                service_description     FTP
                check_command           check_ftp!\$_HOSTADDRESS_PUBLIC_IPV4\$
                }
                " >> /usr/local/nagios/etc/objects/clients/$client/$nom.cfg
        fi

        if [ $xiv = 1 ]; then
                echo "Supervision XiVo => OK"
                echo "define service {
                host_name               $nom
                use                     generic-service
                service_description     POSTGRES
                check_command           check_nrpe_1arg!check_postgres
                }
                " >> /usr/local/nagios/etc/objects/clients/$client/$nom.cfg
        fi

service nagios restart
else

echo "Une configuration pour $nom est deja presente"
fi
