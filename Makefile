SHELL := /bin/bash
.PHONY: test build deploy clean





deploy: build
	aws cloudformation deploy --region us-west-2 --stack-name Vpc --parameter-overrides ClassB=0 PeerVpc=vpc-b76dd8d3 PeerVpcCidr=172.31.0.0/16 --template-file ./cloudformation/vpc.yaml --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset
	aws cloudformation deploy --region us-west-2 --stack-name Alert --template-file ./cloudformation/alert.yaml --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset
	aws cloudformation deploy --region us-west-2 --stack-name KMS --parameter-overrides ParentAlertStack=Alert --template-file ./cloudformation/kms.yaml  --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset
	aws cloudformation deploy --region us-west-2 --stack-name VpcBastion --parameter-overrides ParentVPCStack=Vpc IAMUserSSHAccess=true SystemsManagerAccess=true   --template-file ./cloudformation/vpc-ssh-bastion.yaml --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset
	aws cloudformation deploy --region us-west-2 --stack-name ClientSg --parameter-overrides ParentVPCStack=Vpc DefaultVpcId=vpc-b76dd8d3   --template-file ./cloudformation/client-sg.yaml --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset
	aws cloudformation deploy --region us-west-2 --stack-name DBSecret --parameter-overrides ParentVPCStack=Vpc ParentKmsKeyStack=KMS SecretName=/sandbox/db-secret DBMasterUsername=admin DeletionProtection=enabled   --template-file ./cloudformation/db-secret.yaml --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset
	aws cloudformation deploy --region us-west-2 --stack-name RDS --parameter-overrides ParentVPCStack=Vpc ParentKmsKeyStack=KMS ParentClientStack=ClientSg ParentSSHBastionStack=VpcBastion ParentAlertStack=Alert ParentSecretStack=DBSecret AutoPause=true MaxCapacity=16  MinCapacity=1 SecondsUntilAutoPause=300 EngineVersion=5.7.mysql-aurora.2.07.1 DBMasterUsername=admin --template-file ./cloudformation/rds-aurora-serverless.yaml --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset
	aws cloudformation deploy --region us-west-2 --stack-name NATInstanceA --parameter-overrides ParentVPCStack=Vpc ParentKmsKeyStack=KMS ParentSSHBastionStack=VpcBastion ParentAlertStack=Alert SubnetZone=A NATInstanceType=t3a.nano  --template-file ./cloudformation/vpc-nat-instance.yaml --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset
	aws cloudformation deploy --region us-west-2 --stack-name NATInstanceB --parameter-overrides ParentVPCStack=Vpc ParentKmsKeyStack=KMS ParentSSHBastionStack=VpcBastion ParentAlertStack=Alert SubnetZone=B NATInstanceType=t3a.nano  --template-file ./cloudformation/vpc-nat-instance.yaml --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset
	aws cloudformation deploy --region us-west-2 --stack-name NATInstanceC --parameter-overrides ParentVPCStack=Vpc ParentKmsKeyStack=KMS ParentSSHBastionStack=VpcBastion ParentAlertStack=Alert SubnetZone=C NATInstanceType=t3a.nano  --template-file ./cloudformation/vpc-nat-instance.yaml --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset
	aws cloudformation deploy --region us-west-2 --stack-name NATInstanceD --parameter-overrides ParentVPCStack=Vpc ParentKmsKeyStack=KMS ParentSSHBastionStack=VpcBastion ParentAlertStack=Alert SubnetZone=D NATInstanceType=t3a.nano  --template-file ./cloudformation/vpc-nat-instance.yaml --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset

build:
#	sam build --use-container --region us-west-2 -t apigw/template.yaml --cached -b .aws-sam/build

clean:
	rm -rf .aws-sam
