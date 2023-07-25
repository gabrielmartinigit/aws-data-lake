### NETWORK ###
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "bigdata-vpc"
  cidr = "10.0.0.0/16"

  azs              = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets   = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  database_subnets = ["10.0.110.0/24", "10.0.120.0/24", "10.0.130.0/24"]

  create_database_subnet_group  = true
  enable_nat_gateway            = true
  enable_dns_hostnames          = true
  enable_dns_support            = true
  manage_default_security_group = false

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_security_group" "main_allow" {
  name        = "main-sg"
  description = "Main Security Group"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "bigdata-main-sg"
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_security_group" "ssh_allow" {
  name        = "ssh-sg"
  description = "SSH Security Group"
  vpc_id      = module.vpc.vpc_id

  ingress {
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

  tags = {
    Name        = "ssh-sg"
    Terraform   = "true"
    Environment = "dev"
  }
}

### STORAGE ###
module "s3_bucket_raw" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "raw-braps"
  acl    = "private"

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

module "s3_bucket_stage" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "stage-braps"
  acl    = "private"

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

module "s3_bucket_analytics" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "analytics-braps"
  acl    = "private"

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

module "s3_bucket_queries" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "queries-braps"
  acl    = "private"

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

### BASTION ###
module "ec2_instance_bastion" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name = "bastion-braps"

  ami                         = "ami-06ca3ca175f37dd66"
  instance_type               = "t3.micro"
  key_name                    = "martinig-kp"
  monitoring                  = true
  vpc_security_group_ids      = [aws_security_group.main_allow.id, aws_security_group.ssh_allow.id]
  subnet_id                   = module.vpc.public_subnets[0]
  associate_public_ip_address = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_eip" "bastion" {
  vpc      = true
  instance = module.ec2_instance_bastion.id

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

### RDS DATABASE ###
module "source_db" {
  source = "terraform-aws-modules/rds/aws"

  identifier                     = "source-db-braps"
  instance_use_identifier_prefix = true

  create_db_option_group    = true
  create_db_parameter_group = true

  engine               = "postgres"
  engine_version       = "14"
  family               = "postgres14"
  major_engine_version = "14"
  instance_class       = "db.t4g.large"

  allocated_storage = 100

  db_name  = "dev_braps"
  username = "martinig"
  port     = 5432

  db_subnet_group_name   = module.vpc.database_subnet_group
  vpc_security_group_ids = [aws_security_group.main_allow.id]

  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  create_monitoring_role                = true
  monitoring_interval                   = 60
  monitoring_role_name                  = "monitoring-role-sourcedb"
  monitoring_role_use_name_prefix       = true
  monitoring_role_description           = "Monitoring role source db"

  maintenance_window      = "Mon:00:00-Mon:03:00"
  backup_window           = "03:00-06:00"
  backup_retention_period = 0
  skip_final_snapshot     = true
  deletion_protection     = false

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }

  db_option_group_tags = {
    "Sensitive" = "low"
  }
  db_parameter_group_tags = {
    "Sensitive" = "low"
  }
}

### DMS INSTANCE ###

# Roles #
resource "aws_iam_role" "dms_role" {
  name        = "dms-role"
  description = "Role used by DMS"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DMSAssume"
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "dms.us-east-1.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name = "dms-admin-policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = "*"
          Effect   = "Allow"
          Resource = "*"
        }
      ]
    })
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

### POWERBI GATEWAY ###

### REDSHIFT DATABASE ###

### SAGEMAKER DOMAIN ###
