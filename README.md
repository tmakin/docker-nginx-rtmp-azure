# docker-nginx-rtmp-azure
A Dockerfile installing NGINX, nginx-rtmp-module and AzCopy from source with
default settings for recording to Azure blob storage.

* Nginx 1.13.9 (compiled from source)
* nginx-rtmp-module 1.2.1 (compiled from source)
* azcopy (latest available download)
* Default record settings (See: [nginx.conf](nginx.conf))

[![Docker Stars](https://img.shields.io/docker/stars/tmakin/nginx-rtmp-azure.svg)](https://hub.docker.com/r/tmakin/nginx-rtmp-azure/)
[![Docker Pulls](https://img.shields.io/docker/pulls/tmakin/nginx-rtmp-azure.svg)](https://hub.docker.com/r/tmakin/nginx-rtmp-azure/)
[![Docker Automated build](https://img.shields.io/docker/automated/tmakin/nginx-rtmp.svg)](https://hub.docker.com/r/tmakin/nginx-rtmp-azure/builds/)
[![Build Status](https://travis-ci.org/alfg/docker-nginx-rtmp.svg?branch=master)](https://travis-ci.org/tmakin/docker-nginx-rtmp-azure)

## Prerequisites
* Download and install docker for windows from here:
https://store.docker.com/  
Note that windows 10 pro is required to run docker locally, as the Home edition does not support Hyper-V.

## Usage

### Server

In the examples below we are connecting to storage emulator running on host machine which uses a standard connection string

* Pull docker image and run:
```
docker pull tmakin/nginx-rtmp-azure
docker run -it -p 1935:1935 -p 8080:8080 --rm ^
    -e AZ_STORAGE_CONTAINER=http://<youraccount>.blob.windows.core/video-uploads ^
    -e AZ_STORAGE_KEY=<key> ^ 
    tmakin/nginx-rtmp-azure
```
or 

* Build and run container from source:
The example below creates an connection to storage emulator on host machine. I've seen authentication issues with this approach through.
```
docker build -t nginx-rtmp-azure .
docker run -it --name rtmp -p 1935:1935 -p 8080:8080 --rm -e AZ_STORAGE_CONTAINER='http://host.docker.internal:10000/devstoreaccount1/video-uplaods' -e AZ_STORAGE_KEY='Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==' nginx-rtmp-azure-record 
```

* Stream live content to:
```
rtmp://localhost:1935/stream
```

### Debugging
To log into the container use:
```
docker exec -it rtmp /bin/bash
```

To view log files:
```
cd ./opt/nginx/logs
```
or via be browser:
```
http://localhost:8080/logs
```

### OBS Configuration
* Stream Type: `Custom Streaming Server`
* URL: `rtmp://localhost:1935/stream`
* Stream Key: `somekey`



## Resources
* https://github.com/arut/nginx-rtmp-module
* https://obsproject.com
* http://www.browndogtech.com/angularjs-container-environment-variables/

## Credits
https://github.com/alfg/docker-nginx-rtmp
https://github.com/Stupeflix/WebcamRecorder
