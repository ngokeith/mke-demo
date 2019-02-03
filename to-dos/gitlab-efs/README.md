# Setting up Gitlab-as-a-Service on DC/OS backed by AWS EFS Storage + Jenkins CI/CD

Talking Points:

AWS EFS:
- Is NFS v4.1
- Supports a cost effective bursting mode [See EFS Throughput Modes](https://docs.aws.amazon.com/efs/latest/ug/performance.html#throughput-modes)
- Auto scales
- Good IOPS, likely more than needed for this use case
- Supports encryption at rest

Other Links:
- [Backing Up EFS](https://docs.aws.amazon.com/efs/latest/ug/efs-backup.html)
- [Alternate Backing Up EFS](https://docs.aws.amazon.com/efs/latest/ug/alternative-efs-backup.html)
- [Troubleshooting EFS](https://docs.aws.amazon.com/efs/latest/ug/troubleshooting.html)

## Prerequisites:
- DC/OS Cluster
	- OS: CoreOS
	- 1 Master
	- 1 Public Agent (m4.large - 2 vCPU - 8GB MEM)
	- 1 Private Agent (m4.xlarge - 4vCPU - 15GB MEM)
- An accessible DNS hostname address for your `VHOST` parameter used to access Gitlab
	- If you are using Cloud you can use the hostname of your public agent as your `VHOST`
	- A useful tool you can use for a temporary hostname address is [](www.noip.com)
	- You can also use a Poor Man's DNS method such as modifying your `/etc/hosts`

## Getting Started

### In the AWS Console

Copy the Existing VPC of your cluster from the AWS console and create an EFS in that VPC using all of the defaults, except set the security groups so that the EFS can be accessed

### SSH into each agent node and do the following

Make the /efs directory:
```
sudo mkdir /efs
```

Create the first `systemd` unit `efs.automount`, which is required:
```
sudo tee /etc/systemd/system/efs.automount <<- EOF
[Unit]
Description=AWS EFS automount

[Automount]
Where=/efs

[Install]
WantedBy=multi-user.target
EOF
```

**Note:** both mounts must have the filesystem path in the name, with /’s converted to -. This path of /efs is at the root, so it’s the simplest form. If it were /mnt/efs the name wound be mnt-efs.automount)

Create a second `systemd` unit `efs.mount`, which is required:

**Be sure to replace the EFS DNS FQDN from the AWS EFS Console and replace it below with yours in the `What=""` parameter**

```
sudo tee /etc/systemd/system/efs.mount <<-EOF
[Unit]
Description=AWS EFS mount

[Mount]
What=fs-06893bae.efs.us-west-2.amazonaws.com:/
Where=/efs
Type=nfs
Options=nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport

[Install]
WantedBy=multi-user.target
EOF
```

Reload the systemd daemon:
```
sudo systemctl daemon-reload
```

Enable the systemd units:
```
sudo systemctl enable efs.automount efs.mount
```

Start the `efs.mount` systemd unit:
```
sudo systemctl start efs.mount
```

Check the status of the `efs.mount` systemd unit:
```
systemctl status efs.mount
```

**Note:** If the systemd unit is in a `FAILED` state, or if it’s not connected it’s likely a firewall /security group issue.

### On any agent:

Check to see if there is anything in the directory:
```
sudo touch /efs/test
ls -lh /efs
```

Make a 100M File:
```
sudo dd if=/dev/urandom of=/efs/big-file bs=100M count=1 iflag=fullblock
```

Check to see if the 100M file was created:
```
ls -lh /efs
```

Verify that the EFS storage was mounted:
```
df -h /efs
```

Note how it shows 0% used, and a size of 8.0E? It’s shown as a huge size by design

### In another Agent Node

Check to see if EFS is working correctly by seeing if the 100M file was created
```
ls -lh /efs
```

### In DC/OS

Load up the following marathon.json as a test:
```
{
  "id": "/test",
  "backoffFactor": 1.15,
  "backoffSeconds": 1,
  "cmd": "ls -lh /data && sleep 100000",
  "container": {
    "type": "MESOS",
    "volumes": [
      {
        "containerPath": "/data",
        "hostPath": "/efs",
        "mode": "RW"
      }
    ],
    "docker": {
      "image": "centos",
      "forcePullImage": false,
      "parameters": []
    }
  },
  "cpus": 1,
  "disk": 0,
  "instances": 1,
  "maxLaunchDelaySeconds": 3600,
  "mem": 1280,
  "gpus": 0,
  "networks": [
    {
      "mode": "host"
    }
  ],
  "portDefinitions": [],
  "requirePorts": false,
  "upgradeStrategy": {
    "maximumOverCapacity": 1,
    "minimumHealthCapacity": 1
  },
  "killSelection": "YOUNGEST_FIRST",
  "unreachableStrategy": {
    "inactiveAfterSeconds": 0,
    "expungeAfterSeconds": 0
  },
  "healthChecks": [],
  "fetch": [],
  "constraints": []
}
```

Verify that the EFS mount is working correctly:

Navigate to Services --> test --> stdout to see if the file `big-file` is there

### Congrats

You have successfully set up EFS with DC/OS. Now lets move on to setting up GitLab instances tied to this AWS EFS mount

## GitLab

### In any agent:

Create the correct Gitlab directories below:
- /efs/prod/gitlab_prod-config
- /efs/prod/gitlab_prod-logs
- /efs/prod/gitlab_prod-data
- /efs/dev/gitlab_dev-config
- /efs/dev/gitlab_dev-logs
- /efs/dev/gitlab_dev-data

For our demo we will be creating Groups to seperate team isolation, so we will follow the similar syntax

Create the Gitlab Directories for team1/gitlab1:
```
sudo mkdir -p /efs/prod/gitlab_prod-config /efs/prod/gitlab_prod-logs /efs/prod/gitlab_prod-data
```

Create the Gitlab Directories for team2/gitlab1:
```
sudo mkdir -p /efs/dev/gitlab_dev-config /efs/dev/gitlab_dev-logs /efs/dev/gitlab_dev-data
```

Create a Jenkins directory which we will be using later for our CI/CD Pipeline:
```
sudo mkdir -p /efs/prod/prod-jenkins
```

```
sudo mkdir -p /efs/prod/dev-jenkins
```

Exit out of your agents once these directories have been created

### Back in DC/OS:

Deploy the  gitlab-prod.json
```
dcos marathon app add gitlab-efsprod.json
```

Deploy the  gitlab-dev.json
```
dcos marathon app add gitlab-efsdev.json
```

### Expose using EdgeLB

If you are using Edge-LB, a service configuration has been provided to expose Gitlab through Edge-LB called `gitlab-edgelb.json`
```
dcos edgelb create gitlab-edgelb.json
```

### Access the Gitlab UI:
Hit the designated VHOST parameter on each gitlab instance and you should have Gitlab backed by AWS EFS!

(Gitlab1 Pic Placeholder)

### Create a Gitlab project:

Click on "New Project" to create a new repository. Give it the name "Site-test" and make it public

(Gitlab2 Pic Placeholder)

### Set up your SSH key

Navigate to User Settings --> SSH Keys and add an SSH public key so your local machine can access Gitlab

(Gitlab3 Pic Placeholder)

### Set up Git Connection

Clone the repo that you just made in GitLab
```
git clone http://<INSERT_VHOST_HERE>/root/site-test.git
```

Output should look similar to below:
```
Cloning into 'site-test'...
warning: You appear to have cloned an empty repository.
```

Follow the instructions below to set up your new repo:
```
cd site-test
touch README.md
git add README.md
git commit -m "add README"
git push -u origin master
```

### Add the following files to your local `site-test` directory. For your convenience, the files are also located in this repo under `resources --> site-test`:

index.html:
```
<!DOCTYPE html>
<html>
<body>

<h1>Site test</h1>

<p>This is a test website. Learn more about DC/OS at <a href="https://dcos.io">dcos.io</a>!</p>

</body>
</html>
```

Dockerfile:
```
FROM nginx
COPY index.html /usr/share/nginx/html/index.html
RUN apt-get -qq update
RUN apt-get install -y linkchecker
```

**NOTE:** Be sure to replace the `<INSERT_VHOST_HERE>` parameter as well as your `<Docker_ID>` in the below Jenkinsfile

Jenkinsfile:
```
def gitCommit() {
    sh "git rev-parse HEAD > GIT_COMMIT"
def gitCommit = readFile('GIT_COMMIT').trim()
    sh "rm -f GIT_COMMIT"
    return gitCommit
}

node {
    // Checkout source code from Git
    stage 'Checkout'
    checkout scm

    // Build Docker image
    stage 'Build'
    sh "docker build -t <DOCKER_ID>/site-test:${gitCommit()} ."

    // Log in and push image to GitLab
    stage 'Publish'
    withCredentials(
        [[
            $class: 'UsernamePasswordMultiBinding',
            credentialsId: 'dockerhub',
            passwordVariable: 'DOCKERHUB_PASSWORD',
            usernameVariable: 'DOCKERHUB_USERNAME'
        ]]
    ) {
        sh "docker login -u ${env.DOCKERHUB_USERNAME} -p ${env.DOCKERHUB_PASSWORD}"
        sh "docker push <DOCKER_ID>/site-test:${gitCommit()}"
    }

    // Test links in file
    stage 'Test'
    withCredentials(
        [[
            $class: 'UsernamePasswordMultiBinding',
            credentialsId: 'dockerhub',
            passwordVariable: 'DOCKERHUB_PASSWORD',
            usernameVariable: 'DOCKERHUB_USERNAME'
        ]]
    ) {
      sh "docker login -u ${env.DOCKERHUB_USERNAME} -p ${env.DOCKERHUB_PASSWORD}"
      sh "docker run -p 8085:80 -d --name=test-container-${env.BUILD_NUMBER} <DOCKER_ID>/site-test:${gitCommit()}"
      sh "docker exec test-container-${env.BUILD_NUMBER} linkchecker /usr/share/nginx/html/index.html"
      sh "docker kill test-container-${env.BUILD_NUMBER}"
      sh "docker rm test-container-${env.BUILD_NUMBER}"
   }

    // Deploy
    stage 'Deploy'

    marathon(
        url: 'http://marathon.mesos:8080',
        forceUpdate: false,
        filename: 'marathon.json',
        id: 'site-test',
        docker: "<DOCKER_ID>/site-test:${gitCommit()}".toString()
    )
}
```

**NOTE:** Be sure to replace `<INSERT_VHOST_HERE>` parameter used earlier in the `marathon.json` below to reflect your correct VHOST hostname.

marathon.json:
```
{
  "id": "/site-test",
  "cpus": 0.5,
  "mem": 256,
  "instances": 1,
  "container": {
    "docker": {
      "image": "<DOCKER_ID>/site-test:latest",
      "portMappings": [
        {
          "containerPort": 80,
          "protocol": "tcp",
          "name": "http"
        }
      ],
      "network": "BRIDGE"
    },
    "type": "MESOS",
    "volumes": []
  },
  "labels": {
    "DCOS_SERVICE_PORT_INDEX": "0",
    "DCOS_SERVICE_SCHEME": "http",
    "DCOS_SERVICE_NAME": "webapp1"
  },
  "requirePorts": false,
  "portDefinitions": [],
  "networks": [],
  "healthChecks": [],
  "fetch": [],
  "constraints": [],
  "cmd": "ls && sleep 300"
}
```

Push the new changes to the site-test repo:
```
git add -A
git commit -m "Updates"
git push
```

Verify in Gitlab that the files were pushed to the site-test repo:

(Gitlab 4 Pic Placeholder)

## Setting up CI/CD with Gitlab + Jenkins + Dockerhub

Save the below Jenkins options configuration as `jenkins-options.json`:
```
{
  "service": {
    "name": "jenkins"
  },
  "storage": {
    "host-volume": "/efs/prod/prod-jenkins"
  }
}
```

The above options.json allows us to deploy Jenkins configured to the `/efs/jenkins` directory that we created earlier on our AWS EFS for persistent storage


Install Jenkins:
```
dcos package install jenkins --options=jenkins-options.json --yes
```

To access Jenkins, click on the icon to the right of jenkins in the Services tab

(Jenkins 1 pic placeholder)

### Add your Dockerhub credentials to Jenkins

The next step is to add your Gitlab and Dockerhub credentials. From the Homepage, navigate to Credentials --> System (top bar) --> Global Credentials --> Add credentials

(Jenkins 2 pic placeholder)

Add your Gitlab credentials, for our example we use:
- Username: root
- Password: rootroot
- ID: gitlab

Hit OK when you are done.

(Jenkins 3 pic placeholder)

Repeat the steps to add credentials for your Dockerhub account:
- Username: <DOCKER_ID>
- Password: <DOCKER_PASSWORD>
- ID: dockerhub

Hit OK when you are done.

(Jenkins 4 placeholder)

### Create your Jenkins Pipeline Project

Create a New Item and name your item `site-test` and select `Pipeline` and hit OK:

(Jenkins 5 pic placeholder)

Scroll down to `Build Triggers` and select `Poll SCM` which takes cron-style scheduling. For our demo we want this to run every minute so in the text box put `* * * * *` and hit Apply:

(Jenkins 6 pic placeholder)

Scroll down to the `Pipeline` section and select `Pipeline Script from SCM` and select `Git`. Add in your Repository URL used earlier `http://<INSERT_VHOST_HERE>/root/site-test.git` and select your Gitlab credentials, in our case `root/rootroot`. Select Apply and Save when you are done.

(Jenkins 7 placeholder)

Once this is saved, you have a pipeline.

Now return to your local site-test directory. We'll want to commit all the files you've added and push them to GitLab:
```
git add -A
git commit -m "Initial commit"
git push
```

If you navigate to your Gitlab UI `http://<INSERT_VHOST_HERE>/root/site-test`, you should see the files now uploaded there.

(Gitlab 5 pic placeholder here)

Now return back to Jenkins --> site-test Pipeline. It should run within a minute.

(Jenkins 8 pic placeholder)

If the pipeline fails for any reason, there are logs there in the UI you can use to debug where the problem is.

(Jenkins 9 pic placeholder)

Once the deployment succeeds, you can go back to the DC/OS UI and you will now see an "site-test" service running in Services --> site-test. Hover over and click on the icon next to `site-test` to open it up in a new tab

(DCOS 1 pic placeholder)

Congratulations, you have now have a deployment!

(DCOS 2 pic placeholder)
