function wait_for_ssh {
	local IP=$1
	local KEY_NAME=${2:-"admin"}
	local USER=${3:-"ubuntu"}
	if ! timeout 360 sh -c "while ! ssh -o StrictHostKeyChecking=no -i keys/${KEY_NAME}_key ${USER}@${IP} echo success; do sleep 6; done"; then
    	echo "server didn't become ssh-able!"
    	exit 1
	fi
}

function upload_bootstrap {
	local MODULE=$1
	local KEY_NAME=${2:-"admin"}
	local USER=${3:-"ubuntu"}
	local IP=`heat output-show ci_${MODULE} instance_ip|sed -e 's/"//g'`
	tar jcvf bootstrap.tar.bz2 common bootstrap/$1
	ssh-keygen -f ~/.ssh/known_hosts -R {IP}
	scp -o StrictHostKeyChecking=no -i keys/${KEY_NAME}_key bootstrap.tar.bz2 ${USER}@${IP}:
	ssh -o StrictHostKeyChecking=no -i keys/${KEY_NAME}_key ${USER}@${IP} "rm -rf common bootstrap && tar jxvf bootstrap.tar.bz2"
}

function run_bootstrap {
	local MODULE=$1
	local KEY_NAME=${2:-"admin"}
	local USER=${3:-"ubuntu"}
	# I'm sure this can be done without hard coding module names.
	# Perhaps if the module does not have a heat template?
	if [ "${MODULE}" = "devstack" ]
	then
		./bootstrap/${MODULE}/bootstrap.sh
	else
		local IP=`heat output-show ci_${MODULE} instance_ip|sed -e 's/"//g'`
		ssh -o StrictHostKeyChecking=no -i keys/${KEY_NAME}_key ${USER}@${IP} ./bootstrap/${MODULE}/bootstrap.sh
	fi
}

function run_post {
	local POST_SCRIPT=$1
	# do not attempt to read this line when drunk
	local MODULE=`echo ${POST_SCRIPT}|sed -e 's/bootstrap\/\([^/]\+\)\/.\+sh/\1/'`
	local IP=`heat output-show ci_${MODULE} instance_ip|sed -e 's/"//g'`
	local KEY_NAME=${2:-"admin"}
	local USER=${3:-"ubuntu"}
	ssh -o StrictHostKeyChecking=no -i keys/${KEY_NAME}_key ${USER}@${IP} ./${POST_SCRIPT}
}

function provision_node {
	local MODULE=$1
	# we expect a node for devstack to be provisioned manually (and you should be running the deploy on it!)
	if [ "${MODULE}" = "devstack" ]; then return; fi
	local KEY_NAME=$2
	local USER=$3
	heat stack-create ci_${MODULE} --template-file hot/${MODULE}/${MODULE}.template --parameters key_name=${KEY_NAME}
	local IP=""
	while [[ -z "${IP}" && "${IP}" != "null" ]]; do
    	IP=`heat output-show ci_${MODULE} instance_ip|sed -e 's/"//g'`
	done
	wait_for_ssh ${IP} ${KEY_NAME} ${USER}
}

function add_hosts_entry {
	local MODULE=$1
	local DOMAIN=$2
	local IP=$3
	grep -v "${MODULE}$" /etc/hosts > /tmp/ci-stack_hosts
	echo "${IP} ${MODULE}.${DOMAIN} ${MODULE}" >> /tmp/ci-stack_hosts
	sudo cp /tmp/ci-stack_hosts /etc/hosts
	rm /tmp/ci-stack_hosts
}