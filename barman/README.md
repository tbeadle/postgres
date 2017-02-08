# Backing up your database with barman

[Barman](http://docs.pgbarman.org/release/2.1/) is "an open-source
administration tool for disaster recovery of PostgreSQL servers".  The files in
this directory are used to build the `tbeadle/postgres:<version>-barman docker`
images.  These images are like the non-`-barman` ones except that they are tuned
to work closely with a barman server, supporting the streaming of WAL logs and
incremental base backups using rsync over ssh.  These are handled by the
following changes to the base images:

 - The following additional packages are installed:
   - `openssh-server` - For allowing SSH connections from the remote barman
     server for management and fetching base backups.
   - `rsync` - To allow the barman server to take incremental base backups,
     saving on storage on the barman server.
   - `supervisor` - To manage the postgres and sshd processes.
 - The following environment variables are allowed to be defined:

   | Variable name | Description |
   | ------------- | ----------- |
   | BARMAN_USER | This user is created as a superuser in the database during initialization.  It is the user that barman should be connecting as for its management operations.  Defaults to `barman`. |
   | BARMAN_PASSWORD | The password that gets set for the `BARMAN_USER`.  Defaults to no password.  NOTE: You are ***strongly*** encouraged to use a password for this superuser account.  The user is allowed to connect from anywhere and, with no password set, anyone could log in as a superuser to your database by knowing just the username. |
   | BARMAN_PUBKEY | The path in the container to an SSH public key that is paired with the private key that the barman server will use when connecting over SSH.  This will be copied to the location of the `authorized_keys` file for the `postgres` user on this server.  The barman server will therefore need to SSH as `postgres`.  If this file does not exist, then taking base backups over rsync will not work.  Defaults to `/private/barman.id_rsa.pub`. |
   | BARMAN_SLOT_NAME | The name of the replication slot used by barman for streaming WAL logs.  The slot will be created when the database is initialized.  Defaults to `barman`.
   | SSH_HOST_KEY | The path in the container to a private host key that should be used for sshd.  If it exists, it will be copied to `/etc/ssh/` and configured as the only host key in `sshd_config`.  The barman server can then have a `known_hosts` file containing the corresponding public key to validate that it's connecting to the correct database server when making SSH connections.  If the file does not exist, SSH host keys will automatically be generated.  Defaults to `/private/ssh_host_rsa_key`. |
   | STREAMING_USER | This user is created in the database with REPLICATION privileges.  It will be used for streaming WAL logs from the database to the barman server.  Defaults to `streaming_barman`. |
   | STREAMING_PASSWORD | The password that gets set for the `STREAMING_USER`.  Defaults to no password.  NOTE: You are ***strongly*** encouraged to use a password for this account.  The user is allowed to connect from anywhere and, with no password set, anyone could log in with replication privileges to your database by knowing just the username. |

 - When starting a container using this image, `supervisor` will run as the init
   process.  It will store the stdout and stderr logs for sshd and postgres under
   `/var/log/supervisor/{sshd,postgres}/`.
 - The `postgresql.conf` file is modified to set `wal_level`,
   `max_wal_senders`, and `max_replication_slots` to values suitable for
   working with barman.

See the examples in https://github.com/tbeadle/docker-barman for examples on how
to use this image with that barman image.

## Building the images

If you make any changes to the Dockerfile.template or supporting files, run
`./update.sh`.  Then to build all of the images, simply run:

`docker-compose build`

To build the image for a single postgres version, just run it like the following
for 9.6:

`docker-compose build pg9_6`
