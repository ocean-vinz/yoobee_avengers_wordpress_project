module aws_wordpress {
    source              = "./modules/yoobee_avengers"
    database_name           = "wordpress_db"   // database name
    database_user           = "wordpress_user" //database username
    // Password here will be used to create master db user.It should be chnaged later
    database_password = "PassWord4-user" //password for user database
    access_key_aws  = "XXX" #Avengers access
    secret_key_aws  = "YYY" #Avengers access
    region                  = "us-east-1" //N.Virginia region
    // avaibility zone and their CIDR
    AZ1          = "us-east-1a" // first AZ
    AZ2          = "us-east-1b"  // second AZ
    VPC_cidr     = "10.0.0.0/16"     // VPC CIDR
    subnet1_cidr = "10.0.1.0/24"     // Public Subnet for EC2
    subnet2_cidr = "10.0.2.0/24"     //Public Subnet for EC2
    subnet3_cidr = "10.0.3.0/24"     //Private subnet for RDS
    subnet4_cidr = "10.0.4.0/24"     // Private Subnet for RDS
    PUBLIC_KEY_PATH  = "./yoobee-key.pub" // key name for ec2, make sure it is created before terrafomr apply
    PRIV_KEY_PATH    = "./yoobee-key"
    instance_type    = "t2.micro"    //type of instance
    instance_class   = "db.t2.micro" //type of RDS Instance
    root_volume_size = 30 // in GB
}



