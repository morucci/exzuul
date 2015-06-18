ExZuul - Experiment Zuul on an easy to start platform
=====================================================

!!! This docker container should only be used as a test platform !!!

This docker container bundles all the needed pre-configured pieces
to experiments the Zuul gating system used by the Openstack project.
Zuul is a generic software and can be reused for other projects outside
of Openstack.

This docker container is based on a centos7 image and contains:

- Gerrit
- Zuul
- Jenkins
- Jenkins-job-builder

Services
--------

Use ci.localdomain to access the services. It means you should
add such a line in your laptop /etc/hosts:

<container_ip> ci.localdomain

### Gerrit

Gerrit is configured with "DEVELOPMENT_BECOME_ANY_ACCOUNT" setting so
no need to deal with any external authentication system. Also a local H2
database is used.

Two users are created by default:

- An admin user
- A Zuul user (to allow the zuul to perform action on Gerrit)

Gerrit can be reached at http://ci.localdomain:8080

### Zuul

Zuul is pre-configured to listen to events from the Gerrit event stream
and will connect to Gerrit at container startup. Zuul's merger
git repositories are served via a pre-configured Apache.

layout.yaml is stored at /etc/zuul/layout.yaml. Two pipeline (check and gate)
are already configured.

Zuul status page can be reached at http://ci.localdomain

### Jenkins

Only a Jenkins master is configured here.
The Jenkins Gearman plugin is pre-configured to connect on the Zuul gearman
server.

A default user "jenkins/password" is pre-configured in order to allow
to perform administrative tasks on Jenkins. This is needed in order
to use Jenkins Jobs Builder to manage jobs on Jenkins.

Jenkins Jobs Builder is pre-configured and can be used locally to update jobs.

Jenkins can be reached at http://ci.localdomain:8081/jenkins


Build and start
---------------

Install Docker at least 1.6 and build the container:

```
$ sudo docker build -t exzuul .
```

Start the container:

```
$ sudo docker run -d -h ci.localdomain -v /dev/urandom:/dev/random -p 80:80 -p 29418:29418 -p 8080:8080 -p 8081:8081 exzuul
$ CID=$(sudo docker ps | grep exzuul | cut -f1 -d' ')
```

Get a live shell inside a running container:

```
$ sudo docker exec -i -t $CID /bin/bash
```

Get the container IP:

```
$ sudo docker inspect --format '{{ .NetworkSettings.IPAddress }}' $CID
```

You should access the container using ci.localdomain hostname instead
of the IP. Please add "<container_ip> ci.localdomain" in /etc/hosts.


WARNING: If the container is stopped and restarted all local work and
configuration will be lost.


Configure a first project to be validated via Zuul
--------------------------------------------------

Here is the first steps to perform in order to have a project hosted on Gerrit
and a job triggered by Zuul.

* Login as the admin user. Add your public key in the admin user settings page.
* Create a Job for "testproject". The container already have a valid JJB
  configuration with a working job definition for "testproject".

```
$ sudo docker exec -i -t $CID /bin/bash
# # Create a job in Jenkins for a project call "testproject"
# jenkins-jobs --conf /etc/jenkins_jobs/jenkins_jobs.ini update /etc/jenkins_jobs/jobs
```

- The job must be shown in the jobs list of Jenkins
- As admin - create a project called "testproject" in Gerrit (check "create inital empty commit")
- Clone the new project on your local computer and submit the as a review

```
$ git clone http://ci.localdomain:8080/testproject
$ cd testproject
$ git checkout -b "first_commit"
$ cat > .gitreview << EOF
[gerrit]
host=ci.localdomain
port=29418
project=testproject.git
EOF
$ cat > run_tests.sh << EOF
#!/bin/bash
exit 0
EOF
$ chmod +x run_tests.sh
$ sudo pip install git-review
$ ssh-keygen -f "$HOME/.ssh/known_hosts" -R [ci.localdomain]:29418
$ git review -s # use "admin" as login and be sure to have the public key listed by ssh-add -l
$ git config --add gitreview.username "admin"
$ git add run_tests.sh .gitreview
$ git commit -m "first commit"
$ git review
```

In the Gerrit web UI you should see your new patch on "testproject" and a green check
sign added by Zuul in the "Verified" label.

If you succeed to have your patch validated by Zuul that means the platform is
ready to be used !
