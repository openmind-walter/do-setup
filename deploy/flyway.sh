cd ../01-Infra-setup/
DB_URI=`terraform output db_uri`
DB_USER=`terraform output db_user`
DB_PASSWORD=`terraform output db_password`
cd -
SQL_DIR=../../session-db/session/sql
# jdbc:postgresql://<host>:<port>/appdb
docker run --rm  -v ${SQL_DIR}:/flyway/sql flyway/flyway -url="${DB_URI}" -user="${DB_USER}" -password="${DB_PASSWORD}" migrate
