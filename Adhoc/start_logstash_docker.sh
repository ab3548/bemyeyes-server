sudo docker run -d -v /data:/data -v /data/logstash-opt:/opt -e LOGSTASH_CONFIG_URL="https://gist.githubusercontent.com/khebbie/42d72d212cf3727a03a0/raw/068f4816693f3b1171fd7c7c7d7eaadaca8801be/logstash.conf"  -p 9292:9292 -p 9200:9200 -p 9300:9300  -p 3334:3334/udp -p 3333:3333/udp pblittle/docker-logstash

