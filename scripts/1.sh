echo -e "Script #1: Run from bastion as root user"
read -p "Press Enter to continue"

echo
echo "Install nmstate  core prerequirements"

cat << EOF | oc apply -f -
apiVersion: v1
kind: Namespace
metadata:
  labels:
    kubernetes.io/metadata.name: openshift-nmstate
    name: openshift-nmstate
  name: openshift-nmstate
spec:
  finalizers:
  - kubernetes
EOF

while ! (oc get ns openshift-nmstate  -o custom-columns=Name:.metadata.name,Status:.status.phase | grep Active); do oc get ns openshift-nmstate; sleep 2; done
oc get ns openshift-nmstate  -o custom-columns=Name:.metadata.name,Status:.status.phase

sleep 2
cat << EOF | oc apply -f -
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  annotations:
    olm.providedAPIs: NMState.v1.nmstate.io
  name: openshift-nmstate
  namespace: openshift-nmstate
spec:
  targetNamespaces:
  - openshift-nmstate
EOF

while ! (oc get operatorgroup -n openshift-nmstate | grep openshift-nmstate); do oc get operatorgroup -n openshift-nmstate; sleep 2; done
oc get operatorgroup -n openshift-nmstate

sleep 2
cat << EOF| oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  labels:
    operators.coreos.com/kubernetes-nmstate-operator.openshift-nmstate: ""
  name: kubernetes-nmstate-operator
  namespace: openshift-nmstate
spec:
  channel: stable
  installPlanApproval: Automatic
  name: kubernetes-nmstate-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF

while ! (oc get clusterserviceversion -n openshift-nmstate  -o custom-columns=Name:.metadata.name,Phase:.status.phase | grep kubernetes-nmstate-operator | grep Succeeded); do oc get clusterserviceversion -n openshift-nmstate; sleep 5; done
oc get clusterserviceversion -n openshift-nmstate  -o custom-columns=Name:.metadata.name,Phase:.status.phase

sleep 2
cat << EOF | oc apply -f -
apiVersion: nmstate.io/v1
kind: NMState
metadata:
  name: nmstate
EOF

while ! (oc get nmstates | grep nmstate); do oc get nmstates; done
oc get nmstates

echo "Install metallb core prerequirements"

sleep 2
cat << EOF | oc apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: metallb-system
EOF

while ! (oc get ns metallb-system  -o custom-columns=Name:.metadata.name,Status:.status.phase | grep Active); do oc get ns metallb-system; sleep 2; done
oc get ns metallb-system  -o custom-columns=Name:.metadata.name,Status:.status.phase

sleep 2
cat << EOF | oc apply -f -
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: metallb-operator
  namespace: metallb-system
EOF

while ! (oc get operatorgroup -n metallb-system | grep metallb-operator); do oc get operatorgroup -n metallb-system; sleep 2; done
oc get operatorgroup -n metallb-system

sleep 2
cat << EOF| oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: metallb-operator-sub
  namespace: metallb-system
spec:
  channel: stable
  name: metallb-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF

oc get installplan -n metallb-system
while ! (oc get clusterserviceversion -n metallb-system -o custom-columns=Name:.metadata.name,Phase:.status.phase | grep metallb-operator | grep Succeeded); do oc get clusterserviceversion -n metallb-system; sleep 5; done
oc get clusterserviceversion -n metallb-system -o custom-columns=Name:.metadata.name,Phase:.status.phase

sleep 2
cat << EOF | oc apply -f -
apiVersion: metallb.io/v1beta1
kind: MetalLB
metadata:
  name: metallb
  namespace: metallb-system
EOF

while ! (oc get deployment -n metallb-system controller -o custom-columns=Name:.metadata.name,Available:.status.conditions[0].type | grep Available); do oc get deployment -n metallb-system controller; sleep 5; done
oc get deployment -n metallb-system controller -o custom-columns=Name:.metadata.name,Available:.status.conditions[0].type

oc get daemonset -n metallb-system speaker
while ! (oc get daemonset -n metallb-system speaker -o custom-columns=Name:.metadata.name,Available:.status.numberAvailable | grep 6); do oc get daemonset -n metallb-system speaker; sleep 5; done
oc get daemonset -n metallb-system speaker -o custom-columns=Name:.metadata.name,Available:.status.numberAvailable


echo "Install cert manager core prerequirements"

sleep 2
cat << EOF | oc apply -f -
apiVersion: v1
kind: Namespace
metadata:
    name: cert-manager-operator
    labels:
      pod-security.kubernetes.io/enforce: privileged
      security.openshift.io/scc.podSecurityLabelSync: "false"
EOF

while ! (oc get ns cert-manager-operator | grep Active); do oc get ns cert-manager-operator; sleep 2; done
oc get ns cert-manager-operator

sleep 2
cat << EOF | oc apply -f -
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: cert-manager-operator
  namespace: cert-manager-operator
spec:
  targetNamespaces:
  - cert-manager-operator
  upgradeStrategy: Default
EOF

while ! (oc get operatorgroup -n cert-manager-operator | grep cert-manager-operator); do oc get operatorgroup -n cert-manager-operator; sleep 2; done
oc get operatorgroup -n cert-manager-operator

sleep 2
cat << EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  labels:
    operators.coreos.com/openshift-cert-manager-operator.cert-manager-operator: ""
  name: openshift-cert-manager-operator
  namespace: cert-manager-operator
spec:
  channel: stable-v1.12
  installPlanApproval: Automatic
  name: openshift-cert-manager-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
  startingCSV: cert-manager-operator.v1.12.1
EOF

while ! (oc get installplan -n cert-manager-operator -o yaml -o custom-columns=Name:.metadata.name,Approved:.spec.approved | grep true); do oc get installplan -n cert-manager-operator; sleep 2; done
oc get installplan -n cert-manager-operator -o yaml -o custom-columns=Name:.metadata.name,Approved:.spec.approved

while ! (oc get clusterserviceversion -n cert-manager-operator -o custom-columns=Name:.metadata.name,Phase:.status.phase | grep cert-manager-operator | grep Succeeded); do oc get clusterserviceversion -n cert-manager-operator; sleep 5; done
oc get clusterserviceversion -n cert-manager-operator -o custom-columns=Name:.metadata.name,Phase:.status.phase

while ! (oc get pods -n cert-manager | grep -w cert-manager | grep Running | wc -l | grep 3); do oc get pods -n cert-manager; sleep 10; done
oc get pods -n cert-manager

oc new-project openstack-operators
oc new-project openstack

git clone https://github.com/pnavarro/showroom_osp-on-ocp-lb1374.git labrepo
cd labrepo/content/files

oc apply -f osp-ng-nncp-w1.yaml
oc apply -f osp-ng-nncp-w2.yaml
oc apply -f osp-ng-nncp-w3.yaml
oc apply -f osp-ng-nncp-m1.yaml
oc apply -f osp-ng-nncp-m2.yaml
oc apply -f osp-ng-nncp-m3.yaml

while ! (oc get nncp | grep Available | wc -l | grep 6); do oc get nncp; done
oc get nncp

sleep 2
oc apply -f osp-ng-netattach.yaml
oc get network-attachment-definitions.k8s.cni.cncf.io -n openstack
sleep 2

oc apply -f osp-ng-metal-lb-ip-address-pools.yaml
oc get ipaddresspools.metallb.io -n metallb-system
sleep 2

oc apply -f osp-ng-metal-lb-l2-advertisements.yaml
oc get l2advertisements.metallb.io -n metallb-system
sleep 2

read -p "Enter your Red Hat customer portal user ID: " rhnid
read -sp "Enter your Red Hat customer portal user password: " rhnpasswd

echo -e "Creating auth.json file using your credentials"
podman login --username $rhnid --password $rhnpasswd registry.redhat.io --authfile auth.json
if [ $? -eq 0 ]
then
  cat auth.json
else
  echo -e "Error authenticating to customer portal, exiting.."
  exit 1
fi

oc create secret generic osp-operators-secret \
 -n openstack-operators \
 --from-file=.dockerconfigjson=auth.json \
 --type=kubernetes.io/dockerconfigjson
 
oc get secrets -n openstack-operators osp-operators-secret

oc apply -f osp-ng-openstack-operator.yaml

oc get operators openstack-operator.openstack-operators
oc get pods -n openstack-operators

while ! (oc get pods -n openstack-operators | grep -v STATUS | grep -v Running | grep -v Completed | wc -l | grep 0); do oc get pods -n openstack-operators | grep -v STATUS | grep -v Running | grep -v Completed; sleep 5; done
sleep 2
while ! (oc get pods -n openstack-operators | grep -v STATUS | grep -v Running | grep -v Completed | wc -l | grep 0); do oc get pods -n openstack-operators | grep -v STATUS | grep -v Running | grep -v Completed; sleep 5; done

oc get pods -n openstack-operators --sort-by=.metadata.creationTimestamp

oc create -f osp-ng-ctlplane-secret.yaml
sleep 2
oc describe secret osp-secret -n openstack

echo -e "Setting up nfs storage..."

mkdir /nfs/cinder
chmod 777 /nfs/cinder

mkdir /nfs/pv6
mkdir /nfs/pv7
mkdir /nfs/pv8
mkdir /nfs/pv9
mkdir /nfs/pv10
mkdir /nfs/pv11
chmod 777 /nfs/pv*

oc create -f nfs-storage.yaml
oc get storageclasses | grep nfs
oc get pv | grep nfs

oc create secret generic cinder-nfs-config --from-file=nfs-cinder-conf
oc create secret generic glance-cinder-config --from-file=glance-conf

sleep 2
oc create -f osp-ng-ctlplane-deploy.yaml

while ! (oc get openstackcontrolplane -n openstack -o custom-columns=Name:.metadata.name,Status:.status.conditions[0].message | grep 'Setup complete'); do oc get openstackcontrolplane -n openstack; sleep 30; done
oc get openstackcontrolplane -n openstack

sleep 2
oc apply -f osp-ng-dataplane-netconfig.yaml
oc get netconfigs -n openstack

echo -e "Next run script #2 on the hypervisor as root user"
exit 0

