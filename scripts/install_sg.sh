#!/usr/bin/env bash
set -x

check_ret() {
    local status=$?
    if [ $status -ne 0 ]; then
         echo "ERR - The last command $1 failed with status $status" 1>&2
         exit $status
    fi
}


do_install() {

  REGION=$(wget -qO- http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/.$//')
  export REGION=$(sed -e 's/^"//' -e 's/"$//' <<<"$REGION")

  STACKNAME=$(aws ec2 describe-instances --filters "Name=private-ip-address,Values=$(ec2metadata --local-ipv4)" --region $REGION | jq '.Reservations[0].Instances[0].Tags | map(select (.Key == "aws:cloudformation:stack-name" )) ' | jq .[0].Value | tr -d '"')
  export STACKNAME=$(sed -e 's/^"//' -e 's/"$//' <<<"$STACKNAME")

  export INSTANCE_ID=$(ec2metadata --instance-id)

  #REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | grep region | awk -F\" '{print $4}')

  export SG_PUBHOST=$(curl -s http://169.254.169.254/latest/meta-data/public-hostname)
  export SG_PRIVHOST=$(curl -s http://169.254.169.254/latest/meta-data/hostname)

  SG_NODE_TAG=$(aws ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCE_ID" "Name=key,Values=sgnodetag" --region=$REGION --output=text | cut -f5)

  #ARN=$(aws ec2 describe-tags --filters "Name=key,Values=sg_arn" --region=$REGION --output=text | cut -f5)

  #aws ec2 describe-tags --region=$REGION --output=text

  #ARN="arn:aws:sns:eu-west-1:243222279496:sgmsg"
  #aws sns publish --topic-arn $ARN --message start --region eu-west-1


  do_log "SG_NODE_TAG: $SG_NODE_TAG"
  do_log "DIST: $DIST"
  do_log "REGION: $REGION"
  #do_log "REGION2: $REGION2"
  #do_log "STACKNAME: $STACKNAME"
  do_log "SG_PUBHOST: $SG_PUBHOST"
  do_log "SG_PRIVHOST: $SG_PRIVHOST"

  #switch branch?
  #git checkout ...

  echo "Stopping services"
  systemctl stop kibana.service > /dev/null 2>&1
  systemctl stop metricbeat.service > /dev/null 2>&1
  systemctl stop elasticsearch.service > /dev/null 2>&1

  if [ ! -f "elasticsearch-$ES_VERSION.deb" ]; then
    wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-$ES_VERSION.deb > /dev/null 2>&1
    check_ret "Downloading ES"
  fi

  dpkg --force-all -i elasticsearch-$ES_VERSION.deb > /dev/null 2>&1
  check_ret "Installing ES"

  if [ ! -f "metricbeat-$ES_VERSION-amd64.deb" ]; then
    wget https://artifacts.elastic.co/downloads/beats/metricbeat/metricbeat-$ES_VERSION-amd64.deb > /dev/null 2>&1
    check_ret "Downloading Metricbeat"
  fi

  dpkg --force-all -i metricbeat-$ES_VERSION-amd64.deb > /dev/null 2>&1
  check_ret "Installing Metricbeat"

  if [ ! -f "kibana-$ES_VERSION-amd64.deb" ]; then
    wget https://artifacts.elastic.co/downloads/kibana/kibana-$ES_VERSION-amd64.deb > /dev/null 2>&1
    check_ret "Downloading Kibana"
  fi

  dpkg --force-all -i kibana-$ES_VERSION-amd64.deb > /dev/null 2>&1
  check_ret "Installing Kibana"

  export ES_BIN=/usr/share/elasticsearch/bin
  export ES_CONF=/etc/elasticsearch
  export ES_LOG=/var/log/elasticsearch
  export ES_PLUGINS=/usr/share/elasticsearch/plugins

  # Total memory in KB
  totalMemKB=$(awk '/MemTotal:/ { print $2 }' /proc/meminfo)

  # Percentage of memory to use for Java heap
  usagePercent=50

  # heap size in KB
  let heapKB=$totalMemKB*$usagePercent/100

  # heap size in MB
  let heapMB=$heapKB/1024

  sed -i -e "s/-Xmx1g/-Xmx${heapMB}m/g" "$ES_CONF/jvm.options"
  sed -i -e "s/-Xms1g/-Xms${heapMB}m/g" "$ES_CONF/jvm.options"

  $ES_BIN/elasticsearch-plugin remove discovery-ec2 > /dev/null 2>&1
  $ES_BIN/elasticsearch-plugin remove search-guard-6 > /dev/null 2>&1
  #$ES_BIN/elasticsearch-plugin remove x-pack > /dev/null 2>&1

  $ES_BIN/elasticsearch-plugin install -b discovery-ec2 > /dev/null
  check_ret "Installing discovery-ec2 plugin"

  #$ES_BIN/elasticsearch-plugin install -b x-pack > /dev/null
  #check_ret "Installing x-pack plugin"

  $ES_BIN/elasticsearch-plugin install -b com.floragunn:search-guard-6:$SG_VERSION > /dev/null
  check_ret "Installing sg 6 plugin"

  rm -rf "$ES_PLUGINS/search-guard-6/netty-tcnative*"
  wget -O "$ES_PLUGINS/search-guard-6/netty-tcnative-$NETTY_NATIVE_VERSION-linux-x86_64.jar" "https://bintray.com/floragunncom/netty-tcnative/download_file?file_path=netty-tcnative-openssl-$OPENSSL_VERSION-static-$NETTY_NATIVE_VERSION-non-fedora-linux-x86_64.jar" > downloadnetty 2>&1
  check_ret "Downloading netty native to search-guard-6: $(cat downloadnetty)"

  chmod +x "$ES_PLUGINS/search-guard-6/tools/install_demo_configuration.sh"

  echo "cluster.name: sg-aws-demo" > "$ES_CONF/elasticsearch.yml"
  echo "discovery.zen.hosts_provider: ec2" >> "$ES_CONF/elasticsearch.yml"
  echo "discovery.ec2.host_type: public_dns" >> "$ES_CONF/elasticsearch.yml"
  echo 'discovery.ec2.endpoint: ec2.eu-west-1.amazonaws.com' >> "$ES_CONF/elasticsearch.yml"
  echo "network.host: _ec2:publicDns_" >> "$ES_CONF/elasticsearch.yml"
  echo "transport.host: _ec2:publicDns_" >> "$ES_CONF/elasticsearch.yml"
  echo "transport.tcp.port: 9300" >> "$ES_CONF/elasticsearch.yml"

  echo "http.host: _ec2:publicDns_" >> "$ES_CONF/elasticsearch.yml"
  echo "http.port: 9200" >> "$ES_CONF/elasticsearch.yml"
  echo "http.cors.enabled: true" >> "$ES_CONF/elasticsearch.yml"
  echo 'http.cors.allow-origin: "*"' >> "$ES_CONF/elasticsearch.yml"

  echo "node.name: $SG_PUBHOST" >> "$ES_CONF/elasticsearch.yml"
  echo "bootstrap.memory_lock: true" >> "$ES_CONF/elasticsearch.yml"
  echo "path.logs: /var/log/elasticsearch" >> "$ES_CONF/elasticsearch.yml"
  echo "path.data: /esdata" >> "$ES_CONF/elasticsearch.yml"

  "$ES_PLUGINS/search-guard-6/tools/install_demo_configuration.sh" -y -i

  echo "vm.max_map_count=262144" >> "/etc/sysctl.conf"
  echo 262144 > "/proc/sys/vm/max_map_count"

  mkdir -p "/etc/systemd/system/elasticsearch.service.d"
  echo "[Service]" > "/etc/systemd/system/elasticsearch.service.d/override.conf"
  echo "LimitMEMLOCK=infinity" >> "/etc/systemd/system/elasticsearch.service.d/override.conf"
  echo "LimitNOFILE=1000000" >> "/etc/systemd/system/elasticsearch.service.d/override.conf"

  echo "MAX_LOCKED_MEMORY=unlimited" >> "/etc/default/elasticsearch"
  echo "MAX_OPEN_FILES=1000000" >> "/etc/default/elasticsearch"
  echo "MAX_MAP_COUNT=262144"  >> "/etc/default/elasticsearch"

  echo "elasticsearch  -  nofile  1000000" >> "/etc/security/limits.conf"

  mkdir /esdata
  chown -R elasticsearch:elasticsearch /esdata

  /bin/systemctl daemon-reload
  check_ret "daemon-reload"
  /bin/systemctl enable elasticsearch.service
  check_ret "enable elasticsearch.service"
  systemctl start elasticsearch.service

  sleep 10

  while ! nc -z "$SG_PUBHOST" 9200 > /dev/null 2>&1; do
    sleep 5
  done

  "$DIR/../sampledata/load_sampledata_small.sh" "https://$SG_PUBHOST:9200"

  cat "$DIR/metricbeat.yml" | sed -e "s/RPLC_HOST/$SG_PUBHOST/g" > "/etc/metricbeat/metricbeat.yml"
  /bin/systemctl daemon-reload
  /bin/systemctl enable metricbeat.service
  systemctl start metricbeat.service

  cp /etc/elasticsearch/*.pem /etc/kibana/
  chown kibana:kibana /etc/kibana/*.pem

  /usr/share/kibana/bin/kibana-plugin install https://oss.sonatype.org/content/repositories/releases/com/floragunn/search-guard-kibana-plugin/$ES_VERSION-$SG_KIBANA_VERSION/search-guard-kibana-plugin-$ES_VERSION-$SG_KIBANA_VERSION.zip
  /usr/share/kibana/bin/kibana-plugin install x-pack
  cat "$DIR/kibana.yml" | sed -e "s/RPLC_HOST/$SG_PUBHOST/g" > "/etc/kibana/kibana.yml"
  chown -R kibana /usr/share/kibana/
  /bin/systemctl daemon-reload
  /bin/systemctl enable kibana.service
  systemctl start kibana.service

  chmod +x "$ES_PLUGINS/search-guard-6/tools/sgadmin.sh"
  

  #"$ES_PLUGINS/search-guard-6/tools/sgadmin.sh" -cd /demo_root_ca/sgconfig -h $SG_PUBHOST -icl -ts "$ES_CONF/truststore.jks" -ks "$ES_CONF/CN=sgadmin-keystore.jks" -nhnv


  #aws sns publish --topic-arn $ARN --message up --region eu-west-1

}



show_info() {
  do_log "Version: $version"
  do_log ""
  do_log "This script will bootstrap Search Guard 6"
  do_log "It is supposed to be run on an Ubuntu AWS instance"
  do_log "Detect OS: $DIST"
  do_log ""
}

do_log() {
  echo "$1" 1>&2
  echo "$1" >> /root/cf.log 2>&1
}

do_error_exit() {
  echo "ERR: $1" 1>&2
  echo "ERR: $1" >> /root/cf.log 2>&1
  exit 1
}

check_root() {
  if [ "$(id -u)" != "0" ]; then
   do_error_exit "This script must be run as root"
  fi
}

check_cmd() {
  if command -v $1 >/dev/null 2>&1
  then
    return 0
  else
    return 1
  fi
}

check_aws() {
   #http://stackoverflow.com/questions/6475374/how-do-i-make-cloud-init-startup-scripts-run-every-time-my-ec2-instance-boots
   #curl http://169.254.169.254/latest/user-data
  INSTANCE_ID_OK=$(curl --max-time 5 -s -o /dev/null -I -w "%{http_code}" http://169.254.169.254/latest/meta-data/instance-id)
  if [ "$INSTANCE_ID_OK" != "200" ]; then
   do_error_exit "This script must be run within AWS ($INSTANCE_ID_OK)"
  fi
}


DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DIST=`grep DISTRIB_ID /etc/*-release | awk -F '=' '{print $2}'`

ES_VERSION=6.4.0
SG_VERSION=$ES_VERSION-23.0
SG_KIBANA_VERSION=14
NETTY_NATIVE_VERSION=2.0.7.Final #static lib from bintray, unset for no openssl
OPENSSL_VERSION=1.0.2p #static lib from bintray


if ! check_cmd apt-get; then
    do_error_exit "apt-get is not installed (not ubuntu?)"
fi

apt-get -yqq update
apt-get -yqq install unzip awscli docker.io curl git jq ansible apt-transport-https openssl netcat telnet ntp ntpdate haveged



########## start OpenJDK 11
apt-get -y remove openjdk-7-jdk openjdk-7-jre openjdk-7-jre-headless || true
#echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections > /dev/null 2>&1
#apt-get -yqq install software-properties-common > /dev/null 2>&1
#add-apt-repository -y ppa:webupd8team/java > /dev/null 2>&1
#apt-get -yqq update > /dev/null 2>&1
apt-get install openjdk-11-jdk
#apt-get -yqq install oracle-java8-installer oracle-java8-unlimited-jce-policy > /dev/null 2>&1
########## end OpenJDK 11


show_info
check_aws
check_root
do_install