echo -e "Script #3: Run from compute node as root user"
read -p "Press Enter to continue"

nmcli co delete 'Wired connection 1'
nmcli con add con-name "static-eth0" ifname eth0 type ethernet ip4 172.22.0.100/24 ipv4.dns "172.22.0.89"
nmcli con up "static-eth0"
nmcli co delete 'Wired connection 2'
nmcli con add con-name "static-eth1" ifname eth1 type ethernet ip4 192.168.123.61/24 ipv4.dns "192.168.123.100" ipv4.gateway "192.168.123.1"
nmcli con up "static-eth1"
hostnamectl set-hostname edpm-compute-0.aio.example.com

curl -ko /etc/pki/ca-trust/source/anchors/demosat-ha.infra.demo.redhat.com.ca.crt  "https://demosat-ha.infra.demo.redhat.com/pub/katello-server-ca.crt"
update-ca-trust
yum install -y "https://demosat-ha.infra.demo.redhat.com/pub/katello-ca-consumer-latest.noarch.rpm"
subscription-manager register --org="Red_Hat_RHDP_Labs"  --activationkey="demosat-smt-b1374-1711111157" --serverurl=https://demosat-ha.infra.demo.redhat.com:8443/rhsm --baseurl=https://demosat-ha.infra.demo.redhat.com/pulp/repos

sudo subscription-manager repos --disable=*
subscription-manager repos --enable=rhceph-6-tools-for-rhel-9-x86_64-rpms --enable=rhel-9-for-x86_64-baseos-rpms --enable=rhel-9-for-x86_64-appstream-rpms --enable=rhel-9-for-x86_64-highavailability-rpms --enable=openstack-dev-preview-for-rhel-9-x86_64-rpms --enable=fast-datapath-for-rhel-9-x86_64-rpms

sudo dnf install -y podman

echo -e "Next run script #4 from bastion node as root user"
exit 0
