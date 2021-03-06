#!/bin/bash
#############################
# Markus Hilsenbeck
# Feb 2022
#
# entrypoint-script: 
#   - offers volume init 
#   - able to run multiple services
#   - offers a micro cli
#

# give a change to attach immediately and see startup messages
sleep 1
echo -e "\n * Starting entrypoint script."


####################################### init volume functions

init_volume_folder () {
  if [ ! -d "/volume/$1" ]; then
    echo -e " * Create volume folder and set permissions: /volume/$1."
    mkdir -pv /volume/$1
    chown -Rv www-data /volume/$1
    chmod -Rfv 777 /volume/$1
  else
    echo -e " * Nothing to do, folder exists: /volume/$1."
  fi
}

copy_volume_folder () {
	if [ ! "$(ls -A /volume/$1)" ]; then
    echo -e " * Empty volume folder, /volume/$1, copy files from /volume.template/$1"
    cp -fvra /volume.template/$1/* /volume/$1/
  else
    echo -e " * Nothing to do, folder not empty: /volume/$1."
	fi
}

####################################### init volume folders

  init_volume_folder "svnadmin"
  copy_volume_folder "svnadmin"
  
  init_volume_folder "svnconf"
  copy_volume_folder "svnconf"
  
  init_volume_folder "svnrepo"
  # nothing to copy


####################################### Services START/STOP

####################################### cron
function START_cron()
{
  if [[ "$ENABLE_CRON" != "true" ]] ; then
    return
  fi

  echo -e " * Starting cron."
  /etc/init.d/cron start
}

function STOP_cron()
{
  if [[ "$ENABLE_CRON" != "true" ]] ; then
    return
  fi

  echo -e " * Stopping cron."
  /etc/init.d/cron stop
}


####################################### apache
function START_apache()
{
  if [[ "$ENABLE_APACHE" != "true" ]] ; then
    return
  fi

  echo -e " * Starting apache2."
  /usr/sbin/apache2ctl start
}

function STOP_apache()
{
  if [[ "$ENABLE_APACHE" != "true" ]] ; then
    return
  fi

  echo -e " * Stopping apache2."
  /usr/sbin/apache2ctl stop
}



################### signal handler ###################
# ignore Ctrl+C
function SIGINT_handler()
{
    echo -e "\nIgnore Ctrl+C, SIGINT. Use docker stop."
}

# docker stop sends SIGTERM
function SIGTERM_handler()
{
    echo -e "\n * Received SIGTERM/STOP: graceful shutdown services."

    STOP_cron
    STOP_apache

    exit 0;
}

trap SIGINT_handler SIGINT
trap SIGTERM_handler SIGTERM 


################### start services ###################
START_cron
START_apache


################### check if tty is connected ###################

if ! tty -s ; then
  echo "No Terminal connected. To use micro cli, use docker run -it ..."
  # wait for SIGTERM
  while true; do
    sleep 1
  done
fi

################### start micro cli, only when tty is connected  ###################
echo -e "Type help to show help.\n"

while true; do
  read -p "micro cli> " -r line

  case "$line" in
    help)
      echo -e "\nCtrl+P, Ctrl+Q : detach docker container."
      echo "stop : stop docker container." 
      echo "bash : start bash inside docker container.\n"
      echo "ps : show process tree."
      continue 
      ;;
    stop)
      echo -e "\n ****************************************************"
      echo -e " Stop docker container. Send SIGTERM to PID 1."
      echo -e " ATTENTION: might be restarted by docker restart policy."
      echo -e " ****************************************************\n"
      # send SIGTERM to PID 1 (tini)
      kill 1
      sleep 1
      ;;
    bash)   
      echo -e "\nStarting bash. Type exit when done or just detach with Ctrl+P, Ctrl+Q.\n"
      bash
      continue 
      ;;
    ps)   
      pstree -pslna
      ;;
    *)
      echo -e "Type help to show help."
      sleep 1
      ;;
  esac
done
