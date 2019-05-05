# lucos_router
The "front-door" for lucos apps - handles TLS unwrapping and routing to the correct backend

## Running
ADMINEMAIL=<email_address> docker run -e ADMINEMAIL -p 80:80 -p 443:443 -d lucas42/lucos_router

The ADMINEMAIL address is used for receiving emails from letsencrypt about cert renewals etc.

## Configuring

Edit the file `domain-list`.  Each line should have 2 space-separated values.  The first is the domain to listen on and create a certificate on.  The second is the backend to route traffic for that host to (don't include a path on the url, but do include the protocol)

## Gotchas

* DNS needs set-up _before_ running.  This is used as part of the letencrypt renewal step.

## Building
The build is configured to run in Dockerhub when a commit is pushed to the master branch in github.