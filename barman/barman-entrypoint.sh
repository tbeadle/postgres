#!/bin/bash

set -eo pipefail

function configure_ssh {
	if [[ ! -d ~postgres/.ssh ]]; then
		install -d -m 0700 -o postgres -g postgres ~postgres/.ssh
	fi
	install -d -m 0755 -o root -g root /var/run/sshd
	if [[ -n ${BARMAN_PUBKEY} ]] && [[ -f ${BARMAN_PUBKEY} ]]; then
		echo "Installing SSH public key for ${BARMAN_USER} user in postgres user's authorized_keys file."
		install -m 0400 -o postgres -g postgres ${BARMAN_PUBKEY} ~postgres/.ssh/authorized_keys
	else
		echo "WARNING: SSH public key for ${BARMAN_USER} user does not exist.  Taking basebackups over rsync using barman will not work!  BARMAN_PUBKEY must be set to the location of a valid SSH public key."
	fi
	if [[ -n ${SSH_HOST_KEY} ]] && [[ -f ${SSH_HOST_KEY} ]]; then
		echo "Installing SSH host key"
		rm -f /etc/ssh/ssh_host_*_key*
		install -m 0400 -o root -g root ${SSH_HOST_KEY} /etc/ssh/
		sed -i '/^HostKey[[:space:]]/ d' /etc/ssh/sshd_config
		echo "HostKey /etc/ssh/$(basename ${SSH_HOST_KEY})" >> /etc/ssh/sshd_config
	else
		echo "WARNING: Unable to install SSH host key.  SSH_HOST_KEY is not defined or file does not exist."
	fi
}

if [[ $# -eq 0 ]]; then
	configure_ssh
	mkdir -p /var/log/supervisor/{postgres,sshd}
	exec supervisord -c /etc/supervisord.conf
else
	exec "$@"
fi
