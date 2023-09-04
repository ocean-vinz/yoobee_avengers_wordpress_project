terraform {
  required_providers {
    aws = {
      version = "~>5.13.1"
    }
    null = {
      version = "~> 3.1.1"
    }
    template ={
       version= "~> 2.2.0"       

    }
  }

  required_version = "~> 1.5.5"
}