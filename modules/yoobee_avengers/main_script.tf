provider "aws" {

  region                  = var.region
  profile                  = "default"
  shared_credentials_files = var.cred_file
}


######################################################
## Create Networking VPC, SUBNETS, ROUTETABLE, etc  ##
######################################################

data "aws_availability_zones" "available" {
  state = "available"
}

# Below modules will create VPC, Public Subnets, Route table attached to IGW, Attaching Public Subnets to Route table
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.1"

  name = "avengers-vpc"
  cidr = var.VPC_cidr
  azs                  = [var.AZ1, var.AZ2]
  public_subnets       = [var.subnet1_cidr, var.subnet2_cidr]
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Terraform = "true"
    Name = "avengers-1-vpc"
  }
}


# Create Private subnet for RDS (For the first AZ)
resource "aws_subnet" "avengers-subnet-private-1" {
  vpc_id                  = module.vpc.vpc_id
  cidr_block              = var.subnet3_cidr
  map_public_ip_on_launch = "false" //it makes private subnet
  availability_zone       = var.AZ1
  tags = {
    Terraform = "true"
    Name = "avengers-2-private-subnets"
  }
}

# Create second Private subnet for RDS (For the second AZ)
resource "aws_subnet" "avengers-subnet-private-2" {
  vpc_id                  = module.vpc.vpc_id
  cidr_block              = var.subnet4_cidr
  map_public_ip_on_launch = "false" //it makes private subnet
  availability_zone       = var.AZ2
  tags = {
    Terraform = "true"
    Name = "avengers-3-private-subnets"
  }
}


//security group for EC2

resource "aws_security_group" "ec2_allow_rule" {

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "MYSQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  vpc_id = module.vpc.vpc_id
  tags = {
    Name = "avengers-5-secgroup-allow-ssh,http,https"
  }
}


# Security group for RDS
resource "aws_security_group" "RDS_allow_rule" {
  vpc_id = module.vpc.vpc_id
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = ["${aws_security_group.ec2_allow_rule.id}"]
  }
  # Allow all outbound traffic.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "avengers-6-secgroup-allow-ec2-for-rds"
  }

}


#################################################
## Create RDS Database                         ##
#################################################

# Create RDS Subnet group
resource "aws_db_subnet_group" "RDS_subnet_grp" {
  subnet_ids = ["${aws_subnet.avengers-subnet-private-1.id}", "${aws_subnet.avengers-subnet-private-2.id}"]
  tags = {
    Name = "avengers-7-rds-subnet-group"
  }
}


# Create RDS instance First AZ
resource "aws_db_instance" "wordpressdb" {
  allocated_storage      = 10
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = var.instance_class
  db_subnet_group_name   = aws_db_subnet_group.RDS_subnet_grp.id
  vpc_security_group_ids = ["${aws_security_group.RDS_allow_rule.id}"]
  db_name                = var.database_name
  username               = var.database_user
  password               = var.database_password
  multi_az               = true
  skip_final_snapshot    = true
  tags = {
    Name = "avengers-8-rds-database"
  }
 # make sure rds manual password chnages is ignored
  lifecycle {
     ignore_changes = [password]
   }
}



##################################################################
## Create EC2 with autoscaling ( only after RDS is provisioned) ##
##################################################################

# change USERDATA varible value after grabbing RDS endpoint info
data "template_file" "user_data" {
  template = file("${path.module}/user_data.tpl")
  vars = {
    db_username      = var.database_user
    db_user_password = var.database_password
    db_name          = var.database_name
    db_RDS           = aws_db_instance.wordpressdb.endpoint
  }
}


#Find the AMI image
data "aws_ami" "linux2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

## Creating the autoscaling launch configuration that contains AWS EC2 instance details ##
resource "aws_launch_configuration" "aws_autoscale_conf" {
  name          = "web_config"
  image_id      = data.aws_ami.linux2.id
  instance_type = var.instance_type
  user_data     = data.template_file.user_data.rendered
  key_name = aws_key_pair.mykey-pair.id // Defining the Key that will be used to access the AWS EC2 instance
  associate_public_ip_address = true
  security_groups  = ["${aws_security_group.ec2_allow_rule.id}"]
  root_block_device {
    volume_size = var.root_volume_size # in GB 
  }
  depends_on = [aws_db_instance.wordpressdb]
}

# Creating the autoscaling group within  availability zone
resource "aws_autoscaling_group" "mygroup" {
  vpc_zone_identifier       = module.vpc.public_subnets
  name                      = "autoscalegroup"   # Specifying the name of the autoscaling group
  max_size                  = 3
  min_size                  = 2
  health_check_grace_period = 30 # Grace period is the time after which AWS EC2 instance comes into service before checking health.
  health_check_type         = "ELB" # The Autoscaling will happen based on health of AWS EC2 instance defined in AWS CLoudwatch Alarm 
  force_delete              = true # force_delete deletes the Auto Scaling Group without waiting for all instances in the pool to terminate
  termination_policies      = ["OldestInstance"] # Defining the termination policy where the oldest instance will be replaced first 
  launch_configuration      = aws_launch_configuration.aws_autoscale_conf.name # Scaling group is dependent on autoscaling launch configuration because of AWS EC2 instance configurations
  depends_on = [aws_db_instance.wordpressdb]
  tag {
    key                 = "Name"
    value               = "avengers-9-autoscale-group-EC2"
    propagate_at_launch = true
  }
}


####################################################################
## Create LOAD BALANCER and attached autoscaling to load balancer ##
####################################################################

# Creating the load balancer

resource "aws_lb" "yoobee" {
  name               = "Yoobee-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ec2_allow_rule.id]
  subnets            = module.vpc.public_subnets
  depends_on = [aws_db_instance.wordpressdb]
  tags = {
    Name = "avengers-10-load-balancer"
  }
}

# Creating the load balancer 

resource "aws_lb_listener" "yoobee" {
  load_balancer_arn = aws_lb.yoobee.arn
  port              = "80"
  protocol          = "HTTP"
  depends_on = [aws_db_instance.wordpressdb]
  tags = {
    Name = "avengers-11-load-balancer-listener"
  }
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.yoobee_aws_lb_target.arn
  }
}

# Creating the load balancer

resource "aws_lb_target_group" "yoobee_aws_lb_target" {
  name     = "yoobee-asg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id
  tags = {
    Name = "avengers-12-load-balancer-target-group"
  }
  depends_on = [aws_db_instance.wordpressdb]
}

# attching the autoscaling to loadbalancer

resource "aws_autoscaling_attachment" "yoobee" {
  autoscaling_group_name = aws_autoscaling_group.mygroup.id
  lb_target_group_arn   = aws_lb_target_group.yoobee_aws_lb_target.arn
  depends_on = [aws_db_instance.wordpressdb]
}



##########
## MISC ##
##########

// Sends your public key to the instance - so we can login to ec2 server with this key
resource "aws_key_pair" "mykey-pair" {
  key_name   = "mykey-pair"
  public_key = file(var.PUBLIC_KEY_PATH)
}

output "RDS-Endpoint" {
  value = aws_db_instance.wordpressdb.endpoint
}

