# About this Repo

This is a fork of the repo for generating the official Postgres docker images.

The following changes are incorporated:

 - The environment variables PGUSER, PGPASSWORD, and PGDATABASE are used
   instead of POSTGRES_USER, POSTGRES_PASSWORD and POSTGRES_DB.  This is so
   that those environment variables can be defined in a docker-compose.yml file
   for the database container and then be inherited by other services that need
   to connect to the database so that they can just define PGHOST to the name of
   the database container and then use 'psql' without any connection parameters.
 - pg_hba.conf is changed to restrict external access to the database to
   'samenet' instead of 'all'.  This makes it so that other containers in the
   deployment can connect to it, but other external addresses are not able to.
 - [pgcli](http://pgcli.com/) is installed as an alternative to the built-in
   `psql` command. (Only in the debian-based images)
 - The suggestions for postgresql.conf taken from Christophe Pettus's excellent
   talk at https://www.youtube.com/watch?v=jqmdujimzfq are included.
 - If any executable scripts are found in `/docker-pre-entrypoint.d`, then those
   scripts will be executed before initializing or starting the database.
   If any executable scripts are found in `/docker-post-entrypoint.d`, then those
   scripts will be executed immediately before starting the database.  These
   directories are different from the standard `/docker-entrypoint-initdb.d` in
   that that directory will only be processed when the database did not already
   exist and is getting initialized.  These directories are typically mounted as
   volumes for a container.  If you create a Dockerfile that extends this image,
   there are directories that you can include in your image, which will not
   interfere with the ones already mentioned (allowing your image's users to
   continue using those):
   - `/image-pre-entrypoint.d` - Scripts in here run before those in
     `/docker-pre-entrypoint.d`.
   - `/image-pre-start.d` - Scripts in here run after initdb has been run but
     before postgres started for the first time.  It can be used to modify
     `postgresql.conf`, for instance.
   - `/image-entrypoint-initdb.d` - Scripts in here run before those in
     `/docker-entrypoint-initdb.d`.
   - `/image-post-entrypoint.d` - Scripts in here run before those in
     `/docker-post-entrypoint.d`.
 - There are some environment variables that can be used to tune the
   postgresql.conf:

| Variable name | Description |
| ------------- | ----------- |
| LOG_MIN_DURATION_TIMEOUT | Cause statements taken longer than the given value to be logged.  Defaults to 600ms. |
| CHECKPOINT_TIMEOUT | Set the maximum amount of time between checkpoints.  Defaults to 20min. |

The images are on docker hub at https://hub.docker.com/r/tbeadle/postgres/

To build the images, just run `docker-compose build`.

## Using with barman for database backups

See the README.md in the `barman` directory for information on an image that can
be used in conjunction with a [barman](http://www.pgbarman.org/) server for
backing up the database.
