#WIP
# Setup Grafana Datasource and Dashboard
curl -s -u admin:admin \
-H "Content-Type: application/json" \
-d '{ "name": "Prometheus", "type": "prometheus", "url": "http://prometheus.prometheus.l4lb.thisdcos.directory:9090", "access": "proxy", "isDefault": true }' \
-X POST \
http://$PUBLIC_IP:3000/api/datasources

for dashboard_url in $(cat graphana_dashboards.txt); do
    dashboard=$(curl -s -H "Content-Type: application/json" $dashboard_url | jq -c .)
    curl -s -u admin:admin \
    -H "Content-Type: application/json" \
    -d "{ \
        \"dashboard\": $dashboard, \
        \"overwrite\": true, \
        \"inputs\": [{ \
            \"name\": \"DS_PROMETHEUS\", \
            \"type\": \"datasource\", \
            \"pluginId\": \"prometheus\", \
            \"value\": \"Prometheus\" \
        }] \
    }" \
    -X POST \
    http://$PUBLIC_IP:3000/api/dashboards/import
done
