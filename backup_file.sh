#!/bin/bash

BACKUP_DIR=/servers_files/sgm/latacunga/foto_predios/
DAYS_TO_KEEP=1

find $BACKUP_DIR -maxdepth 1 -mtime -$DAYS_TO_KEEP -exec cp -f '{}' /servers_files/sgm/latacunga/enviar/ ';'

sshpass -p 'xxxxxx' scp  /servers_files/sgm/latacunga/enviar/* root@xxx.xxx.xxx.xx:/servers_files/sgm/latacunga/foto_predios/
rm -rf /servers_files/sgm/latacunga/enviar/*

