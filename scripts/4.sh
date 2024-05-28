echo -e "Script #4: Run from bastion as root user"
read -p "Press Enter to continue"

cd ~/labrepo/content/files

oc create secret generic dataplane-ansible-ssh-private-key-secret --save-config --dry-run=client --from-file=authorized_keys=/root/.ssh/id_rsa_compute.pub --from-file=ssh-privatekey=/root/.ssh/id_rsa_compute --from-file=ssh-publickey=/root/.ssh/id_rsa_compute.pub -n openstack -o yaml | oc apply -f-
ssh-keygen -f ./id -t ecdsa-sha2-nistp521 -N ''
oc create secret generic nova-migration-ssh-key --from-file=ssh-privatekey=id --from-file=ssh-publickey=id.pub -n openstack -o yaml | oc apply -f-

sleep 2
oc apply -f osp-ng-dataplane-node-set-deploy.yaml
oc get openstackdataplanenodesets.dataplane.openstack.org

sleep 2
oc apply -f osp-ng-dataplane-deployment.yaml
oc get openstackdataplanedeployments.dataplane.openstack.org

sleep 2
while ! (oc get openstackdataplanedeployments -n openstack -o custom-columns=Name:.metadata.name,Status:.status.conditions[0].message | grep 'Setup complete'); do oc get jobs -n openstack; oc get openstackdataplanedeployments -n openstack; sleep 60; done

oc rsh nova-cell0-conductor-0 nova-manage cell_v2 discover_hosts --verbose

echo -e "RHOSP18 is deployed! You may connect to the openstackclient pod and to launch workload using openstack cli"
echo -e "Next run script #5 by copying it's commands on openstackclient pod's shell"
exit 0

