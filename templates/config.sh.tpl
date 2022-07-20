#!/bin/bash -e

yum install -y amazon-efs-utils
mkdir -p ${mount_point}
mount -t efs ${export}:/ ${mount_point}
echo "${export}:/ ${mount_point} efs defaults,_netdev 0 0" >> /etc/fstab

mkdir -m 0750 -p ${mount_point}/clm-server
chown iqserver:iqserver ${mount_point}/clm-server

systemctl restart iqserver

echo "Checking if license is provided"
if [ -z "${license_secret}" ] ; then

    aws --region us-east-1 secretsmanager get-secret-value --secret-id ${license_secret} --query SecretBinary --output text | base64 -d > ${mount_point}/clm-server/license.lic

fi
