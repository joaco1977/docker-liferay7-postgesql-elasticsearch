# Docker file for creating a Docker image with:
* PostgreSQL 9.4
* Oracle Java 8
* Elasticsearch 2.4.6
* Liferay 7.0 GA4

# For running this image:
* docker run --name newContainerName -v /liferay_home/osgi/modules:/opt/liferay/osgi/modules -p 8080:8080 -d -t imageName 

You can work localy in your host with liferay workspace and deploy your modules to /liferay_home/osgi/modules , so these will be deployed in liferay container.
