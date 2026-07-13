# 记录用Docker运行的命令

```shell
docker run --name elasticsearch -p 9200:9200 -p 9300:9300 -e "discovery.type=single-node" -e ES_JAVA_OPTS="-Xms1024m -Xmx1024m" -v /data/docker/elasticsearch/data:/usr/share/elasticsearch/data -v /data/docker/elasticsearch/plugins:/usr/share/elasticsearch/plugins -d --restart=always elasticsearch:7.17.3

docker run --name kibana -p 5601:5601 -v /data/docker/kibana/config/kibana.yml:/usr/share/kibana/config/kibana.yml -d --restart=always kibana:7.17.3

docker run --name rabbitmq -p 15672:15672 -p 5672:5672 -e RABBITMQ_DEFAULT_VHOST=my_vhost -e RABBITMQ_DEFAULT_USER=admin -e RABBITMQ_DEFAULT_PASS=admin -v /data/docker/rabbitmq/log:/var/log/rabbitmq -v /data/docker/rabbitmq/data:/var/lib/rabbitmq -v /data/docker/rabbitmq/plugins:/usr/share/ra/plugins -d --restart=always rabbitmq:3.8.28

docker run --name nexus -p 28081:8081 --restart=always -v /data/docker/nexus3:/nexus-data -d sonatype/nexus3:latest

```
