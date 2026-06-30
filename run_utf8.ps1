docker cp d:\Reading_Station\cleanup.sql tramdoc-mysql:/cleanup.sql
docker cp d:\Reading_Station\seed_detailed.sql tramdoc-mysql:/seed_detailed.sql
docker exec tramdoc-mysql sh -c "mysql -utramdoc -ptramdoc123 --default-character-set=utf8mb4 tramdoc -e 'SET NAMES utf8mb4; SOURCE /cleanup.sql; SOURCE /seed_detailed.sql;'"
