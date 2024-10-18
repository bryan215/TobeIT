# PRUEBA DE CONOCIMIENTO.
## REQUISITOS
> tener instalado Docker, minikube y Make

## iniciar Proyecto
```shell
make build
```
## Explicacion del proyecto.

Primero de todo empiezo creando el entorno de prueba.
Para ello comienzo creando una imagen de grafana, en el cual incluyo la instalacion del plugin de percona, utilizando una variable de entorno

```Dockerfile
ENV GF_INSTALL_PLUGINS=percona-percona-app
```

asi mismo, tambien incluyo la configuracion necesaria para que grafana se pueda conectar a la BBDD y extrar los datos del mismo, de esta forma dejo esta imagen preparada para obtener datos de un MYSQL sin necesidad de configuraciones a posteriori, la mayoria de estos datos de configuracion son estaticos, pero se podrian manejar con varibales de entorno, pongo el ejmplo en la contraseña, ya que mas adelante lo controlare con un secret de kubernetes.

```yaml
apiVersion: 1

datasources:
- name: MySQL
  type: mysql
  url: percona.bbdd.svc.cluster.local:3306
  user: grafana
  jsonData:
    database: synthetics
    maxOpenConns: 100
    maxIdleConns: 100
    maxIdleConnsAuto: true
    connMaxLifetime: 14400
  secureJsonData:
    password: ${GRAFANA_MYSQL_PASSWORD}
```

ahora que ya tengo una imagen de Grafana, procedo a la creacion de otra imagen para la BBDD, en este caso utilizo la imagen base de percona, asi mismo configuro unas variables de entorno para la creacion de una BBDD llamda synthetics y el usuario tobeit.

```Dockerfile
ENV MYSQL_USER=tobeit \
    MYSQL_DATABASE=synthetics
```

Leyendo en la documentacion de Grafana, recomiendan crear un usuario propio con solamente permisos de select, para evitar posibles problemas, es por ello que en esta misma imagen añado un init.sql, en el cual creo un usuario llamado grafana y solo le doy permisos para realizar selecs en la BBDD synthetics, tambien aprobecho para dejar ya una estructura basica para poder almacenar los datos que recogere posteriormente de elastic. 

```sql
CREATE USER 'grafana'@'%' IDENTIFIED BY 'SecretP@assword';
GRANT SELECT ON synthetics.* TO 'grafana'@'%';
FLUSH PRIVILEGES;

CREATE TABLE monitoring (
    id INT AUTO_INCREMENT PRIMARY KEY,
    monitor_name VARCHAR(255),
    step_name VARCHAR(255),
    step_status VARCHAR(50),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

EXPLICAR COMO FUNCIONA INIT.SQL


Teniendo ya las imagenes preparadas para este entorno, empiezo con la creacion de los manifiestos de K8s para poder levantar ambas images en kubernetes.

Para levantar Grafana en K8s, es bastante sencillo, ya que en la propia documentacion te facilitan los manifistos necesarios, en este caso parto de esta base, en la cual se puede encontrar en este [enlace](https://grafana.com/docs/grafana/latest/setup-grafana/installation/kubernetes/).


Lo primero que edito es el SERVICIO, ya que esta en loadbalancer y como estamos en un cluster en local con minikube este tipo de servicio no es funcional sin ayuda de plugins externos, y como tampoco se ha configurado un ingress controller, cambio este servicio a nodePort, asignandole el puerto 32000, ya que sin una configuracion previa de kubernetes, este no acepta puertos inferiores al 30000.


```yaml

apiVersion: v1
kind: Service
metadata:
  name: grafana
spec:
  ports:
  - port: 3000
    protocol: TCP
    targetPort: http-grafana
    nodePort: 32000
  selector:
    app: grafana
  type: NodePort

``` 

lo siguente que modifico es la imagen, ya que queremos usar la imagen personalizada que he creado anteriormente. dicha imagen la he nombrado grafana-personalizado:latest. 

```yaml
    - name: grafana
        image: grafana-personalizado:latest
        imagePullPolicy: IfNotPresent
```

tambien he añadio un manifisto para crear un secret
donde almaceno la contraseña del user admin de grafana y el usuario del mysql creado anteriormente para grafana.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: grafana-conf
  namespace: grafana
type: Opaque
data:
  admin-password: U2VjcmV0UEBhc3N3b3Jk
  mysql-password: U2VjcmV0UEBhc3N3b3Jk
```
luego en el propio deployment configuro las siguentes variables con las contraseñas anteriormente creadas.

```yaml
- name: GRAFANA_MYSQL_PASSWORD
          valueFrom:
            secretKeyRef:
              name: grafana-conf
              key: mysql-password
        - name: GF_SECURITY_ADMIN_PASSWORD
          valueFrom:
            secretKeyRef:
              name: grafana-conf
              key: admin-password
```

por ultimo, creo un PV para que los datos de configuracion de grafana sean persistentes.

```yaml

apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: grafana-pvc
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
``` 
 
 a continuacion, creo los manifiestos para deployar la BBDD, inteto seguir los mismos criterios que en los manifiestos de grafana, es por ello que la pass del user root y del usuario tobeit los añado a un secret.

 creo tambien un namespace separado, y un PV para hacer los datos persistentes, coomo tambien creo un servido tipo nodePort con el puerto 30000.


 ahora bien, para automatizar todo este entorno creo un Makefile,
 donde voy poco a poco, segun la necesidad creando varios comandos, como por ejemplo, para hacer un build de la imagen de grafana, para hacer el deploy solamente de percona en minikube, entre otros mas, es por ello que para poder levantar todo el proyecto, simplemente tenemos que lanzar un make build, este creara las imagenes de grafana y percona, para despues deployar los manifiestos en kubernetes, automatizando todo el proceso.

 ahora que ya tengo grafana escuchando a un mysql para obtener los datos, proceso a la creacion del script, donde principalmente voy a recoger los datos de elastic y exportarlos al mysql, una vez exportods, estos se podran visualizar en grafana, es por ello que creae un dashboard, para poder visualizar estos graficos.















SecretP@assword