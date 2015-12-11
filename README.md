# docker-owncloud

Simple to use Docker container with the latest ownCloud server release, complete with all the bells and whistles.

This is a fork of [the original repo](https://github.com/l3iggs/docker-owncloud). Feel free to star his  good jobs.

__Check out [the original wiki](https://github.com/l3iggs/docker-owncloud/wiki)__ for some stuff that I didn't include here because I thought the readme was getting too big. Feel free to add new content to the wiki as you see fit.

## Features
- Docker tags corresponding to ownCloud releases so you won't get unexpectedly upgraded
- Uses php-xcache for the best possible performance
- Built in (optional) MySQL database server (faster than sqlite default)
  - Or specify your own pre-existing database server during setup
- Web GUI driven initial setup of user/password/database
- Based on Arch Linux ensuring __everything__ is cutting edge & up to date
- SSL (HTTPS) encryption works out-of-the-box
  - Tweaked for maximum security while maintaining compatibility
- Optionally enable automatic SSL certificate regeneration at runtime for maximum security
  - Or easily incorporate your own SSL certificates
- In-browser document viewing and editing ready (.odt, .doc, and .docx)
- In-browser media viewing ready (pretty much everything I think)
- Comes complete with all of the official ownCloud apps pre-installed:
 - Bookmarks
 - Calendar
 - Contacts
 - Documents
 - Gallery
- Or install your own 3rd party apps

## Usage

### [**Install docker**](https://docs.docker.com/installation/)
### Download and start the owncloud server instance

    docker build -t <image_name> .
    docker run --name oc -p 80:80 -p 443:443 -d <image_name>

### Setup ownCloud
Point your browser to:
http://localhost/owncloud
or
https://localhost/owncloud
and follow the instructions in the web interface to finish the owncloud server setup.

### Stop the docker-owncloud server instance


    docker stop oc

You can restart the container later with `docker start oc`
### Delete the docker-owncloud server instance (after stopping it)


    docker rm oc


## Optional
### Harden security
This image comes complete with a self-signed ssl certificate already built in, so https access is ready to go out of the box. I've provided this pre-generated certificate for convienence and testing purposes only. It affords greatly reduced security since the "private" key is not actually private; anyone can download this image and inspect the keys and then decrypt your ownCloud traffic. To make the ssl connection to this ownCloud server secure, you can (A) provide your own (secret) ssl certificate files or (B) use the script provided here to generate new, self-signed certificate files. Both will provide equal security but (B) will result in browser warnings whenever somone visits your site since the web browser will likely not trust your self-signed keys.

  ---
_For option (A) (providing your own SSL cert files):_
Assuming you have your own `server.crt` and `server.key` files in a directory `~/sslCert` on the host machine run:

    sudo chown -R root ~/sslCert
    sudo chgrp -R root ~/sslCert
    sudo chmod 400 ~/sslCert/server.key

Then insert the following into the docker startup command (from step 2. above) between `run` and `--name`:


    docker run -v ~/sslCert:/https \
    --name oc -p 80:80 -p 443:443 -d <image_name>

  ---
_For option (B) (using the built-in script to re-generate your own self-sigend ssl certificate):_
  - You can regenerate a new SSL key anytime on the fly. After starting the docker image as described above, run the following commands:


    docker exec -it oc sh -c \
    'SUBJECT="/C=US/ST=CA/L=CITY/O=ORGANIZATION/OU=UNIT/CN=localhost" \
    /etc/httpd/conf/genSSLKey.sh'
    docker exec -it oc apachectl restart

  - To have a new ssl certificate generated automatically every time the image is started, insert the following into the docker startup command (from step 2. above) between `run` and `--name`:


    docker run -e REGENERATE_SSL_CERT=true -e \
    SUBJECT=/C=US/ST=CA/L=CITY/O=ORGANIZATION/OU=UNIT/CN=localhost \
    --name oc -p 80:80 -p 443:443 -d <image_name>

The `SUBJECT` variable is actually optional here, but I put it in there to show how to change the generated certificate to your liking, especially important if you don't want your certificate to be for `localhost`
For either (A) or (B), remember to turn on the option to force https connections in the ownCloud admin settings page to take advantage of your hardened security.


### Updating to the latest container

TODO
