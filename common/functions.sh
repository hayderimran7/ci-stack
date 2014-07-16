function wait_for_ssh {
	local IP=$1
	local KEY=${2:-"keys/admin_key"}
	local USER=${3:-"ubuntu"}
	if ! timeout 360 sh -c "while ! ssh -o StrictHostKeyChecking=no -i ${KEY} ${USER}@${IP} echo success; do sleep 6; done"; then
    	echo "server didn't become ssh-able!"
    	exit 1
	fi
}

function upload_bootstrap {
	local MODULE=$1
	local IP=$2
	local KEY=${3:-"keys/admin_key"}
	local USER=${4:-"ubuntu"}
	tar jcvf bootstrap.tar.bz2 common bootstrap/$1
	scp -o StrictHostKeyChecking=no -i ${KEY} bootstrap.tar.bz2 ${USER}@${IP}:
	ssh -o StrictHostKeyChecking=no -i ${KEY} ${USER}@${IP} tar jxvf bootstrap.tar.bz2
}

function provision_node {
	NODETYPE=$1
	# we expect a node for devstack to be provisioned manually
	if [ "${NODETYPE}" = "devstack" ]; then return; fi
}