## Description
This source code is a Spring Boot web application. A terraform file provisions the following:
1. EC2 instance
2. EKS CLuster
3. ECR Repository

##Tools Installed 
2. Jenkins
3. Install AWS CLI on Jenkins instance
4. Helm Jenkins instance for deploying to EKS cluster
5. Kubectl on Jenkins instance
6. eksctl on Jenkins instance

## The Pipeline
After EC2 provisioning and Jenkins is installed, obtain the initial administrator password from the console screen and use to configure Jenkins instance. 

Jenkins pipeline will:

- Automate maven build(jar) using Jenkins
- Automate Docker image creation
- Automate Docker image upload into Elastic container registry(ECR)
- Automate Springboot docker container deployments into Elastic Kubernetes Cluster using Helm charts

You can find the Jenkins pipeline file "Jenkinsfile" in the root folder. Copy the contents of the file to your Pipeline and replace variables where applicable

Install Docker in Jenkins and Jenkins have proper permission to perform Docker builds
Make sure to Install Docker, Docker pipeline 