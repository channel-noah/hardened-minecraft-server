#!/bin/bash
# Nightly backup with 7-day retention. Pauses world saving so the archive is consistent.
SERVER_DIR="/home/<USER>/minecraft-server"
BACKUP_DIR="/home/<USER>/minecraft-backups"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_NAME="minecraft-backup-$TIMESTAMP.tar.gz"
RETENTION_DAYS=7

screen -S minecraft -X stuff "say Starting automated backup...\n"
screen -S minecraft -X stuff "save-off\n"
screen -S minecraft -X stuff "save-all\n"
sleep 10

cd "$SERVER_DIR"
tar -czf "$BACKUP_DIR/$BACKUP_NAME" $(ls -d world world_nether world_the_end server.properties whitelist.json 2>/dev/null)

screen -S minecraft -X stuff "save-on\n"
screen -S minecraft -X stuff "say Backup complete!\n"
find "$BACKUP_DIR" -name "minecraft-backup-*.tar.gz" -mtime +$RETENTION_DAYS -delete
echo "Backup completed: $BACKUP_NAME"
