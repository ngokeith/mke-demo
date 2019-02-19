nodes=$(dcos node --json | jq --raw-output ".[] | select((.type | test(\"agent\")) and (.attributes.public_ip == null)) | .id" | wc -l | awk '{ print $1 }')
sed "s/NODES/${nodes}/g" options-portworx.json.template > options-portworx.json
