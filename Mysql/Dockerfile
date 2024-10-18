FROM percona:latest

ENV MYSQL_USER=tobeit \
    MYSQL_DATABASE=synthetics


COPY ./Mysql/files/init.sql /docker-entrypoint-initdb.d/init.sql

EXPOSE 3306


CMD ["mysqld"]
