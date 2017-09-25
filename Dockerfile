FROM debian:stretch
MAINTAINER Joaquin Cabal "joaquincabal@gmail.com"



RUN apt-get update -y && apt-get install locales gnupg2 curl unzip -y 



## UTF8
#RUN dpkg-reconfigure locales && locale-gen en_US.UTF-8



#ENV LC_ALL en_US.UTF-8
#ENV LC_LANG en_US.UTF-8
#ENV LANGUAGE en_US.UTF-8
#ENV LANG en_US.UTF-8



## JAVA INSTALLATION
RUN echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | debconf-set-selections
RUN echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main" | tee /etc/apt/sources.list.d/webupd8team-java.list
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys EEA14886
RUN apt-get update -y && apt-get install -y --no-install-recommends  oracle-java8-installer && apt-get clean all



## POSTGRESQL INSTALLATION
RUN sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ stretch-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
RUN apt-get install wget ca-certificates -y
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN apt-get update && apt-get install postgresql-9.4 postgresql-client-9.4 -y
RUN echo "service postgresql start && exit 0" > /etc/rc.local

                    
USER postgres                    
RUN service postgresql start &&  psql --command "CREATE USER lportal WITH SUPERUSER PASSWORD 'lportal';"\
    && psql --command "CREATE DATABASE lportal WITH OWNER lportal;"

RUN echo "host all  all    0.0.0.0/0  trust" >> /etc/postgresql/9.4/main/pg_hba.conf
                                                                          
RUN echo "listen_addresses='*'" >> /etc/postgresql/9.4/main/postgresql.conf
    

USER root
## ELASTICSEARCH ISNTALLATION
#For liferay need elasticsearch version 2.4.6 
RUN apt-get install apt-transport-https -y
RUN wget https://download.elastic.co/elasticsearch/release/org/elasticsearch/distribution/deb/elasticsearch/2.4.6/elasticsearch-2.4.6.deb\
    && dpkg -i elasticsearch-2.4.6.deb\
    && apt-get install -f\
    && apt-get update\
    && rm elasticsearch-2.4.6.deb
   
#RUN echo "deb https://artifacts.elastic.co/packages/5.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-5.x.list
#RUN apt-get update && apt-get install elasticsearch -y

RUN service elasticsearch start
RUN echo "service elasticsearch start && exit 0" > /etc/rc.local
RUN /usr/share/elasticsearch/bin/plugin install analysis-icu &&\
    /usr/share/elasticsearch/bin/plugin install analysis-kuromoji &&\
    /usr/share/elasticsearch/bin/plugin install analysis-smartcn &&\
    /usr/share/elasticsearch/bin/plugin install analysis-stempel
    
RUN echo "cluster.name: LiferayElasticsearchCluster" >> /etc/elasticsearch/elasticsearch.yml


## LIFERAY 7 PROTAL
WORKDIR /opt

RUN useradd -ms /bin/bash liferay
ENV LIFERAY_HOME=/opt/liferay
ENV CATALINA_HOME=$LIFERAY_HOME/tomcat-8.0.32
ENV PATH=$CATALINA_HOME/bin:$PATH

RUN curl -O -k -L https://sourceforge.net/projects/lportal/files/Liferay%20Portal/7.0.3%20GA4/liferay-ce-portal-tomcat-7.0-ga4-20170613175008905.zip \
 && unzip liferay-ce-portal-tomcat-7.0-ga4-20170613175008905.zip -d /opt \
 && rm liferay-ce-portal-tomcat-7.0-ga4-20170613175008905.zip && mv /opt/liferay-ce-portal-7.0-ga4 /opt/liferay \
 && chown -R liferay:liferay $LIFERAY_HOME

RUN touch $LIFERAY_HOME/portal-ext.properties && touch $LIFERAY_HOME/osgi/configs/com.liferay.portal.search.elasticsearch.configuration.ElasticsearchConfiguration.cfg

RUN echo "admin.email.from.address=joaquincabal@gmail.com\
\nadmin.email.from.name=Joaquin Cabal\
\nusers.reminder.queries.enabled=false\
\nterms.of.use.required=false\
\nliferay.home=$LIFERAY_HOME\
\nsetup.wizard.enabled=false\
\njdbc.default.driverClassName=org.postgresql.Driver\
\njdbc.default.url=jdbc:postgresql://localhost:5432/lportal\
\njdbc.default.username=lportal\
\njdbc.default.password=lportal" >> $LIFERAY_HOME/portal-ext.properties

RUN echo "operationMode=REMOTE" >> $LIFERAY_HOME/osgi/configs/com.liferay.portal.search.elasticsearch.configuration.ElasticsearchConfiguration.cfg


#tomcat      
#EXPOSE 8080/tcp
#gogo shell
#EXPOSE 11311/tcp
#elasticsearch
#EXPOSE 9200/tcp
#elasticsearch
#EXPOSE 9300/tcp
#postgresql
#EXPOSE 5432/tcp


