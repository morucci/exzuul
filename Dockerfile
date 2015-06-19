FROM centos:7
MAINTAINER "Fabien Boucher" <fabien.boucher@enovance.com>

RUN yum -y install epel-release
RUN yum -y install vim java-1.6.0-openjdk python git supervisor python-pip gcc python-devel httpd rsyslog unzip

ENV GERRIT_HOME /opt/gerrit
ENV JENKINS_HOME /var/lib/jenkins
ENV SITE_PATH $GERRIT_HOME/site_path

ENV GERRIT_VERSION 2.8.6.1
ENV MYSQLJAVA_VERSION 5.1.21
ENV BCPROV_VERSION 1.49
ENV BCPROV_VERSION_T 149
ENV BCPROVJDK_VERSION jdk15on
ENV BCPKIX_VERSION $BCPROV_VERSION
ENV BCPKIXJDK_VERSION $BCPROVJDK_VERSION

ENV GERRIT_URL http://gerrit-releases.storage.googleapis.com/gerrit-${GERRIT_VERSION}.war
ENV MYSQLJAVA_URL http://repo2.maven.org/maven2/mysql/mysql-connector-java/${MYSQLJAVA_VERSION}/mysql-connector-java-${MYSQLJAVA_VERSION}.jar
ENV BCPROVJAVA_URL http://central.maven.org/maven2/org/bouncycastle/bcprov-${BCPROVJDK_VERSION}/${BCPROV_VERSION}/bcprov-${BCPROVJDK_VERSION}-${BCPROV_VERSION}.jar
ENV BCPKIXJAVA_URL http://central.maven.org/maven2/org/bouncycastle/bcpkix-${BCPKIXJDK_VERSION}/${BCPKIX_VERSION}/bcpkix-${BCPKIXJDK_VERSION}-${BCPKIX_VERSION}.jar

ENV JENKINS_VERSION 1.580-1.1
ENV JENKINS_REPO http://pkg.jenkins-ci.org/redhat/jenkins.repo
ENV JENKINS_REPO_KEY http://pkg.jenkins-ci.org/redhat/jenkins-ci.org.key
ENV JENKINS_REPO_PLUGINS https://updates.jenkins-ci.org/download/plugins
ENV JENKINS_GEARMAN_PLUGIN ${JENKINS_REPO_PLUGINS}/gearman-plugin/0.1.1/gearman-plugin.hpi

RUN mkdir -p $SITE_PATH
RUN mkdir $SITE_PATH/lib
RUN mkdir $SITE_PATH/etc
RUN mkdir $SITE_PATH/bin
RUN mkdir $SITE_PATH/plugins

RUN curl --silent --show-error --retry 12 --retry-delay 10 -L -o $SITE_PATH/gerrit.war $GERRIT_URL
RUN curl --silent --show-error --retry 12 --retry-delay 10 -L -o $SITE_PATH/lib/mysql-connector-java-$MYSQLJAVA_VERSION.jar $MYSQLJAVA_URL
RUN curl --silent --show-error --retry 12 --retry-delay 10 -L -o $SITE_PATH/lib/bcprov-$BCPROVJDK_VERSION-$BCPROV_VERSION_T.jar $BCPROVJAVA_URL
RUN curl --silent --show-error --retry 12 --retry-delay 10 -L -o $SITE_PATH/lib/bcpkix.$BCPROVJDK_VERSION-$BCPROV_VERSION_T.jar $BCPKIXJAVA_URL

RUN curl --silent --show-error --retry 12 --retry-delay 10 -L -o /etc/yum.repos.d/jenkins.repo $JENKINS_REPO
RUN rpm --import http://pkg.jenkins-ci.org/redhat/jenkins-ci.org.key
RUN yum -y install jenkins-${JENKINS_VERSION}

RUN mkdir -p $JENKINS_HOME/plugins
RUN curl --silent --show-error --retry 12 --retry-delay 10 -L -o $JENKINS_HOME/plugins/gearman-plugin.hpi $JENKINS_GEARMAN_PLUGIN

RUN pip install virtualenv nose flake8 mock

RUN mkdir /etc/zuul
RUN mkdir /var/log/zuul
RUN mkdir /var/lib/zuul
RUN mkdir /var/www/zuul
RUN git clone https://github.com/openstack-infra/zuul /tmp/zuul
RUN pip install /tmp/zuul
RUN cp -Rf /tmp/zuul/etc/status/public_html/* /var/www/zuul/
RUN rm -Rf /tmp/zuul

RUN curl --silent --show-error --retry 12 --retry-delay 10 -L -o /var/www/zuul/fetch.sh https://raw.githubusercontent.com/openstack-infra/zuul/master/etc/status/fetch-dependencies.sh
RUN sed -i "s|public_html/||" /var/www/zuul/fetch.sh
RUN bash /var/www/zuul/fetch.sh

RUN mkdir /etc/jenkins_jobs
RUN mkdir /etc/jenkins_jobs/jobs
RUN pip install jenkins-job-builder

ADD ./confs/gerrit.config $SITE_PATH/etc/gerrit.config

RUN mkdir -p $JENKINS_HOME/plugins/users/jenkins/
ADD ./confs/gearman_config.xml $JENKINS_HOME/hudson.plugins.gearman.GearmanPluginConfig.xml
ADD ./confs/jenkins-config.xml $JENKINS_HOME/config.xml
ADD ./confs/jenkins-user.xml $JENKINS_HOME/users/jenkins/config.xml
ADD ./confs/jenkins.model.JenkinsLocationConfiguration.xml $JENKINS_HOME/jenkins.model.JenkinsLocationConfiguration.xml
RUN chown -R jenkins:jenkins $JENKINS_HOME

ADD ./confs/zuul.conf /etc/zuul/zuul.conf
ADD ./confs/logging.conf /etc/zuul/logging.conf
ADD ./confs/merger-logging.conf /etc/zuul/merger-logging.conf
ADD ./confs/gearman-logging.conf /etc/zuul/gearman-logging.conf
ADD ./confs/layout.yaml /etc/zuul/layout.yaml
ADD ./confs/zuul_site.conf /etc/httpd/conf.d/zuul.conf

ADD ./confs/jenkins_jobs.ini /etc/jenkins_jobs/jenkins_jobs.ini
ADD ./confs/jjb.yaml /etc/jenkins_jobs/jobs/jjb.yaml

ADD ./confs/ssh_wrapper.sh /tmp/ssh_wrapper.sh
ADD ./confs/gerrit-post.sh /tmp/gerrit-post.sh
RUN chmod +x /tmp/ssh_wrapper.sh /tmp/gerrit-post.sh
ADD ./confs/project.config /tmp/project.config

ADD ./supervisord.conf /etc/supervisord.conf
ADD ./start.sh /start.sh

RUN chmod +x /start.sh

RUN adduser gerrit
RUN chown -R gerrit:gerrit $GERRIT_HOME

EXPOSE 29418 8080 8081 80

CMD ["/start.sh"]
