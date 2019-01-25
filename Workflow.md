### Demo Workflows:

#### Show kubernetes off

kubectl get nodes

cat multi-service.yaml

kubectl get pods

kubectl get svc

dcos edgelb list

./open-dklb-workloads.sh

#### Switching Contexts

kubectl config get-contexts

kubectl config use-context dev

#### Upgrade Cassandra
# dcos cassandra update package-versions --name=cassandra
# dcos cassandra update start --package-version="2.4.0-3.0.16" --name=cassandra

#### Prometheus

dcos task exec -it dcos-edgelb.pools.prometheus curl ifconfig.co

Open IP:9091-9094
