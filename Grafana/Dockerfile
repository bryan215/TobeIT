FROM grafana/grafana:latest

ENV GF_INSTALL_PLUGINS=percona-percona-app

COPY ./Grafana/config/datasource.yml    /etc/grafana/provisioning/datasources/datasource.yaml
COPY ./Grafana/config/dashboard.yml     /etc/grafana/provisioning/dashboards/dashboard.yaml
COPY ./Grafana/config/Mysql.json        /etc/grafana/provisioning/dashboards/Mysql.json

EXPOSE 3000

    

