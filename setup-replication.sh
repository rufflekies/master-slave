#!/bin/bash

GREEN="\033[0;32m"
NC="\033[0m"

echo -e "${GREEN}Tunggu mysql-master siap...${NC}"
sleep 20

echo -e "${GREEN}Ambil MASTER STATUS...${NC}"
MASTER_STATUS=$(docker exec -i mysql-master mysql -uroot -padmin123 -e "SHOW MASTER STATUS\G")
echo "$MASTER_STATUS"

MASTER_LOG_FILE=$(echo "$MASTER_STATUS" | grep "File:" | awk '{print $2}')
MASTER_LOG_POS=$(echo "$MASTER_STATUS" | grep "Position:" | awk '{print $2}')

echo -e "${GREEN}File: $MASTER_LOG_FILE, Pos: $MASTER_LOG_POS${NC}"

echo -e "${GREEN}Setup slave...${NC}"
docker exec -i mysql-slave mysql -uroot -padmin123 -e "
STOP SLAVE;
CHANGE MASTER TO
  MASTER_HOST='mysql-master',
  MASTER_USER='admin',
  MASTER_PASSWORD='admin123',
  MASTER_LOG_FILE='$MASTER_LOG_FILE',
  MASTER_LOG_POS=$MASTER_LOG_POS;
START SLAVE;
"

echo -e "${GREEN}Tambahkan user readonly (rufflekies)...${NC}"
docker exec -i mysql-slave mysql -uroot -padmin123 -e "
CREATE USER IF NOT EXISTS 'rufflekies'@'%' IDENTIFIED BY 'rufflekies';
GRANT SELECT ON *.* TO 'rufflekies'@'%';
FLUSH PRIVILEGES;
"

echo -e "${GREEN}Status Slave:${NC}"
docker exec -i mysql-slave mysql -uroot -padmin123 -e "SHOW SLAVE STATUS\G" | grep -E "(Slave_IO_Running|Slave_SQL_Running)"
