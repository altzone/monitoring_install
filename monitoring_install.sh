#!/bin/bash
if [ ! $# == 1 ]; then
  echo
  echo " Le script requiere un agrument:"
  echo "----------------------------------------------------------------------"
  echo "Usage: $0 host_du_serveur"
  echo
  echo "Exemple pour installer le monitoring Nagios + Observium sur www-buzz:"
  echo "$0 www-buzz"
  echo "----------------------------------------------------------------------"
  echo
  exit
fi

read -p  "Voulez-vous installez observium sur :  $1 [y/n] [y] " inst_obs
case $inst_obs in
        [Yy]* ) scp /usr/local/share/observium_tmp/obs_inst.sh $1:/tmp/ && scp /usr/local/share/observium_tmp/observium_inst.tgz $1:/tmp/ && ssh $1 /tmp/obs_inst.sh ;;
        [Nn]* ) ;;
        * ) scp /usr/local/share/observium_tmp/obs_inst.sh $1:/tmp/ && scp /usr/local/share/observium_tmp/observium_inst.tgz $1:/tmp/ && ssh $1 /tmp/obs_inst.sh ;;
esac

echo
read -p "Voulez-vous installez la supervision sur :  $1 [y/n] [y] " inst_sup
case $inst_sup in
        [Yy]* ) scp /usr/local/share/nrpe_tmp/nrpe_inst.sh $1:/tmp/ && scp /usr/local/share/nrpe_tmp/nrpe_inst.tgz $1:/tmp/ && ssh $1 /tmp/nrpe_inst.sh ;;
        [Nn]* ) ;;
        * ) scp /usr/local/share/nrpe_tmp/nrpe_inst.sh $1:/tmp/ && scp /usr/local/share/nrpe_tmp/nrpe_inst.tgz $1:/tmp/ && ssh $1 /tmp/nrpe_inst.sh ;;
esac

echo
read -p  "Voulez-vous superviser le serveur? [y/n] [y] " supervise
case $supervise in
        [Yy]* ) super=1;;
        [Nn]* ) super=0;;
        * ) super=1;;
esac

if [[ $super = 1 ]]; then
        echo
        read -p  "Serveur clients [c] ou infra [i] => [c] " typ
        case $typ in
        [cC]* ) obs_type=monitor && sup_type=sup-client;;
        [iI]* ) obs_type=observium && sup_type=sup1;;
        * ) obs_type=monitor && sup_type=sup-client;;
        esac

        echo "Recuperation des informations serveurs"
        ip_pub=`ssh $1 'ifconfig eth0 | grep 91.200 | cut -d: -f2 | sed s/"  Bcast"//g'`
        ip_priv=`ssh $1 'ifconfig eth1 | grep 10.10 | cut -d: -f2 | sed s/"  Bcast"//g'`
        echo " Recapitulatif:"
        echo "   -Hostname: $1"
        [[ ! $ip_pub = "" ]] &&  echo "   -IP Pub  : $ip_pub" || $ip_pub=$ip_priv
        [[ ! $ip_priv = "" ]] &&  echo "   -IP Prive: $ip_priv" || $ip_priv=$ip_pub
        echo "Continuez ? (appuyez sur ENTER)"
        read
        echo
        read -p  "Voulez-vous ajouter le serveur sur observium? [y/n] [y]" obs_add
        case $obs_add in
                [Yy]* ) obs=1;;
                [Nn]* ) obs=0;;
                * ) obs=1;;
        esac
        if [[ $obs = 1 ]]; then
                echo "Ajout du serveur $1 sur l'observium : $obs_type"
                ssh $obs_type "/root/add_obs.sh $1"

        fi
        echo
        read -p  "Voulez-vous ajouter le serveur sur Nagios? [y/n] [y] " nag_add
        case $nag_add in
                [Yy]* ) nag=1;;
                [Nn]* ) nag=0;;
                * ) nag=1;;
        esac
        if [[ $nag = 1 ]]; then
                echo "Ajout du serveur $1 sur la supervision : $sup_type"
                ssh $sup_type "/root/add_sup.sh $1 $ip_priv $ip_pub"
        fi
fi