# Add tunnel package
dcos package install tunnel-cli --cli --yes

# Install dcos-monitoring package
dcos package install beta-dcos-monitoring --options=grafana_options.json --package-version=v0.4.2-beta --yes

echo -e "Run: \x1B[1mdcos beta-dcos-monitoring plan show deploy\x1B[0m to see the installation status. "
echo "Sleeping for 15sec"
sleep 15

echo "**** Waiting for dcos-monitoring to install"
echo
seconds=0
OUTPUT=1
while [ "$OUTPUT" != 0 ]; do
  seconds=$((seconds+10))
  printf "Waited $seconds seconds for dcos-monitoring to start. This will typically take ~60 seconds. Still waiting.\n"
  OUTPUT=`dcos beta-dcos-monitoring plan show deploy --name=dcos-monitoring | grep load-default-dashboards | awk '{print $4}'`;
  if [ "$OUTPUT" = "(COMPLETE)" ];then
        OUTPUT=0
  fi
  sleep 10
done
echo
echo "**** dcos-monitoring install complete"
echo

dcos beta-dcos-monitoring plan show deploy --name=dcos-monitoring

#launch Chrome with Grafana Dashboard
echo "Accessing Grafana Dashboard in a new browser tab."

open `dcos config show core.dcos_url`/service/dcos-monitoring/grafana/
