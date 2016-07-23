cd /opt/solr/solr-5.3.2
sudo bin/solr start -p 8983
if [[ $1 ]]; then
	sudo bin/solr create -c $1 -d server/solr/$1
fi