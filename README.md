# docker-geoipdb
An Alpine Linux Docker container for creating a legacy GeoIP Database using sherpya's geolite2legacy conversion utility

## VOLUME CONFIGURATION

This container requires a single volume. This can either be a named volume, or a bind mount to the host's GeoIP Database directory (/usr/share/GeoIP on my system).

## CREATING A CONTAINER

To create a container, run the following command from a shell on the host, filling in the details as per your requirements:

```
docker create \
   --name <Container name> \
   --hostname <Hostname of container> \
   --network <Name of Docker network to connect to> \
   --env TZ=<Your time zone e.g. Europe/London> \
   --volume <Named volume or host path>:<Path to your GeoIP Database directory> \
   boredazfcuk/geoipdb
```

As an example, this is the actual command I run on my host to create the container:

```
docker create \
   --name=GeoIPDb \
   --hostname geoipdb \
   --network containers \
   --restart always \
   --cpus 1 \
   --env TZ=Europe/London \
   --volume geoipdb_data:/usr/share/GeoIP/ \
   boredazfcuk/geoipdb
```

When this container first starts up, it will create and folders it needs and display the variables it's using. It will also create a crontab entry to run the database update function between 4-5am on Thursday mornings. I have randomised the minute so different installs will connect to the upstream servers at different times. Also, Maxmind release weekly updates to their database every Wednesday, so there's no point checking on other days.

When this container performs an update, it will hog CPU resources as is is very processor intensive. As it's not a critical service, I have limited it to only using a single CPU core so it doesn't interfere with more important stuff.

I also set the restart option to 'always' so that the container will automatically start up after host reboots.
