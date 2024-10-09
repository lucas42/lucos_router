# lucos_router
The "front-door" for lucos apps - handles TLS unwrapping and routing to the correct backend

## Dependencies
* docker
* docker-compose


## Build-time environment variables (needs passing into docker compose)
* __ARCH__ - the CPU architecture of the current environment.  (Can use "local" for dev purposes)

## Running in production
`ADMINEMAIL=<email_address> PRODUCTION=true ARCH={architecture} docker-compose up -d`

The ADMINEMAIL address is used for receiving emails from letsencrypt about cert renewals etc.

## Running in lower environments
`ADMINEMAIL=<test_email_address> ARCH=local docker-compose up -d`

Doing this uses letsencrypt's staging environment.  This isn't subjected to the same rate-limiting, however the certificates given aren't accepted by standard browsers.  (Also beware you'll get lots of verification errors if you try doing this using the production domain list)

## Running locally without verification
Use [pebble](https://github.com/letsencrypt/pebble) to create a local version of letsencrypt.  Add the following to the docker-compose config:
```
    pebble:
      image: letsencrypt/pebble
      ports:
        - "14000:14000"
      environment:
        - PEBBLE_VA_ALWAYS_VALID=1
        - PEBBLE_VA_NOSLEEP=1
```
Use a .env file similar to:
```
ARCH=local
ADMINEMAIL=<test_email_address>
HOSTDOMAIN=<host_domain>
CERT_SERVER=172.17.0.1:14000
```

## Configuring

Edit the file `domain-list`.  Each line should have 2 space-separated values.  The first is the domain to listen on and create a certificate on.  The second is the backend to route traffic for that host to (don't include a path on the url, but do include the protocol)

## Gotchas

* DNS needs set-up _before_ running.  This is used as part of the letencrypt renewal step.
* If the directory `/etc/letsencrypt` isn't mounted as a volume, then certificates will be re-requested every time the container restarts, possibly hitting letsencrypt rate limits.
* If the directory `/etc/nginx/conf.d/generated` isn't mounted as a volume, then the config gets blatted every time the container restarts, resulting in a significant outage while the new container starts up.

## Building
The build is configured to run in Dockerhub when a commit is pushed to the `main` branch in github.