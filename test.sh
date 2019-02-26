HDFS_ENABLED="true"
PORTWORX_ENABLED="true"


#### INSTALL HDFS
if [ "$HDFS_ENABLED" = "true" ] && [ "$PORTWORX_ENABLED" = "false" ]; then

echo dcos package install hdfs

fi

#### INSTALL PORTWORX
if [ "$PORTWORX_ENABLED" = "true" ] && [ "$HDFS_ENABLED" = "false" ]; then

echo installing portworx

fi

if [ "$PORTWORX_ENABLED" = "true" ] && [ "$HDFS_ENABLED" = "true" ]; then

echo installing portworx and hdfs-portworx

fi
