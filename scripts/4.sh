echo -e "Script #4: Run from bastion as root user"
read -p "Press Enter to continue"

cd ~/labrepo/content/files

oc apply -f osp-ng-dataplane-node-set-deploy.yaml
oc apply -f osp-ng-dataplane-deployment.yaml

while ! (oc get openstackdataplanedeployments -n openstack -o custom-columns=Name:.metadata.name,Status:.status.conditions[0].message | grep 'Setup complete'); do oc get jobs -n openstack; oc get openstackdataplanedeployments -n openstack; sleep 60; done

oc rsh nova-cell0-conductor-0 nova-manage cell_v2 discover_hosts --verbose

echo -e "RHOSP18 is deployed! You may connect to the openstackclient pod and to launch workload using openstack cli"
echo -e "Next run script #5 by copying it's commands on openstackclient pod's shell"
exit 0

