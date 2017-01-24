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
   If any executable scripts are found in `/docker-pre-entrypoint.d`, then those
   scripts will be executed immediately before starting the database.  These
   directories are different from the standard `/docker-entrypoint-initdb.d` in
   that that directory will only be processed when the database did not already
   exist and is getting initialized.

The images are on docker hub at https://hub.docker.com/r/tbeadle/postgres/

To build the images, just run `docker-compose build`.
