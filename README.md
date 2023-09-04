# Yoobee Avengers Wordpress Project

![YOOBEE!](./modules/Yoobee-Colleges_Logo.png)

## This Terraform configuration will deploy the below components:

- VPC
- Public Subnets (2 AZ)
- Private Subnets (2 AZ)
- Route Table for the Public subnets
- Internet Gateway for the public subnets
- Security Groups (for EC2 - HTTP, HTTPS, MYSQL, SSH)
- Security Groups (for RDS - Open port 3306)
- Create RDS in Multi AZ (2 AZ)
- Create Autoscaling Launch configuration
- Create Autoscaling Group (that will launch minimum 2 EC2 in two different AZ)
- Create Load Balancer
- Create Load Balancer Listener
- Create Load Balancer Target Group
- Attaching the Autoscaling Group to the Load Balancer
- Deploy Wordpress onto the EC2 with a script
- Attached an SSH Key (to manage EC2)


## Prerequisites and How to deploy this configuration:

1. Install GIT on your laptop (git tools needed to clone this repository to your local PC)

    https://git-scm.com/book/en/v2/Getting-Started-Installing-Git

2. Once GIT installed, from your powershell or terminal run
    ```
    git clone https://github.com/ocean-vinz/yoobee_avengers_wordpress_project.git
    ```

3. Install AWS CLI (required)

    https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html 

4. Install Terraform (required)

    https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli

5. Create AWS Programmatic access from IAM on your username. It will give you both:
    ```
    access_key_aws
    secret_key_aws
    ```
    Please keep your secret in a safe place, and update the main.tf file. (You will need this key to access the AWS account)

6. Create a ssh key, to login the the EC2 instance (from inside the directory you just cloned)
    ```
    ssh-keygen
    If it ask for a name, please give : yoobee-key
    ```

7. Test and execute the terraform
    ```
    terraform init (To initialise the terraform module and download any dependencies)
    terraform plan (Will verify to your AWS account, similar like a -dry-run, if there's no error then you can apply)
    terrafrom apply (Execute the deployment)
    ```