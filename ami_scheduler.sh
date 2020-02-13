#!/bin/bash
# This script meant to create AMI for specified instance this script is well tested
# on python3 support awscli before you begin make sure you have configure your AWS credentials
# on your machine for security purpose we are not adding credential to part of script

# Author : Mansur Ul Hasan
# Email : mansurali901@gmail.com

## Global variables
Instance=i-0ccc9bd30bcf06aa1			# Instance to backup
Region=eu-west-1				# AWS Region
noreboot=true					# this will enable live ami
tag=gitlabprod					# Friendly tag
date=`date |awk '{print $2"-"$3"-"$6}'`		# date
OWNER=808271409558				# AWS Account ID

ImageTocheck () {
## This function will check AWS AMI exist or not
# For now this is limited in future it will be upgrade with list of AMIs

aws ec2 describe-images --owner $OWNER --region=$Region --filter "Name=tag:Name,Values=$tag" --output table --query 'Images[*].[State,ImageId]' > imagestatus

}

ImageCreate () {

if [ $noreboot == true ];
then
## If noreboot is true it means instance will not be shutdown during AMI creation process

	aws ec2 create-image --instance-id $Instance --name "$tag-$date" --no-reboot --region=$Region 1>&2 > aminame
	aminame=`cat aminame`
	aws ec2 create-tags --resource $aminame --tags Key=Name,Value="$tag" --region=$Region
else
# This is recommended for non prod or dev environment as this part of function will shutdown the server before image starts also
# this is irreversible process

	echo "Alarm:
	can be shutdown while creating image and this process is uninterruptable
	If you are sure what you are doing
	It is highly discouraging for production environments"
	read -n 1 -s -r -p "Press any key to continue "
	echo " "
	echo "System going to shutdown"
	aws ec2 create-image --instance-id $Instance --name "$tag-$date" --region=$Region 1>&2 > aminame
fi
}

imageDelete () {
# This function will delete the registered AMI

	statusapi=`cat imagecheck`
	case $statusapi in
	*"Image exist"*)
		amiid=`cat imagestatus | grep available |cut -d'|' -f3`
		echo "Ready to delete $amiid"
		aws ec2 deregister-image --image-id $amiid --region=$Region
		echo "$amiid has been deregistered"
	;;
	*)
		echo "Unable to find AMI to delete"
	;;
	esac
}

ImageExits () {
amistatus=`cat imagestatus`
echo "ImageDelete"
case $amistatus in
*"available"*)
	echo "Image exist" > imagecheck
;;
*)
	echo "doesn't exist"
	ImageCreate
;;
esac
}

case $1 in
--amicreate)
	ImageCreate
;;
--amidelete)
	ImageTocheck
	ImageExits
	imageDelete
;;
*)
	echo "Not a valid option valid options are
--amicreate	To create AMI
--amidelete	To delete AMI"
;;
esac
