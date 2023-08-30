# Yoobee Avengers Wordpress Project

Prerequisites:

1. Install GIT on your laptop (to clone this repository)

    https://git-scm.com/book/en/v2/Getting-Started-Installing-Git

2. From your powershell or terminal run
    ```
    git clone https://github.com/ocean-vinz/yoobee_avengers_wordpress_project.git
    ```

3. Install AWS CLI

    https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html 

4. Install Terraform

    https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli

5. Create AWS Programmatic access from IAM on your username. It will give you both:
    ```
    access_key_aws
    secret_key_aws
    ```
    Please keep your secret in a safe place, and update the main.tf file

6. Create a ssh key, to login the the EC2 instance (from inside the directory you just cloned)
    ```
    ssh-keygen
    If it ask for a name, please give : yoobee-key
    ```

7. Test and execute the terraform
    ```
    terraform init
    terraform plan (if there's no error then you can apply)
    terrafrom apply
    ```