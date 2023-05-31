# main.tf

# Configuración del proveedor de AWS
provider "aws" {
  region = "us-west-2"
}

# Creación de la VPC y subred por defecto
resource "aws_vpc" "default_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "default_subnet" {
  vpc_id                  = aws_vpc.default_vpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-west-2a"
}

# Creación del Application Load Balancer
resource "aws_lb" "application_load_balancer" {
  name               = "application-lb"
  load_balancer_type = "application"
  subnets            = [aws_subnet.default_subnet.id]
  
  # Configuración adicional para el Application Load Balancer
}

# Creación de Security Groups
resource "aws_security_group" "security_group" {
  name        = "security-group"
  description = "Security Group for EC2 instances"
  vpc_id      = aws_vpc.default_vpc.id
  # Regla para permitir el acceso SSH desde una dirección IP específica
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["X.X.X.X/32"] # Dirección IP permitida
  }

  # Regla para permitir el acceso HTTP desde cualquier dirección
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Regla para permitir el acceso HTTPS desde cualquier dirección
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Regla para permitir el acceso a un puerto específico desde otro grupo de seguridad
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.example_another_sg.id] # ID del otro grupo de seguridad
  }

  # Regla para permitir todo el tráfico de salida
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Creación de una AMI con encriptación (opcional)
resource "aws_ami" "ami" {
  name                = "custom-ami"
  virtualization_type = "hvm"
  root_device_name   = "/dev/xvda"
  ebs_block_device {
    device_name = "/dev/sdf"
    volume_size = 100
    encrypted   = true
  }
  tags = {
    Name = "My AMI"
  }
}

# Creación de RDS (PostgreSQL)
resource "aws_db_instance" "rds_instance" {
  identifier             = "rds-instance"
  engine                 = "postgres"
  instance_class         = "db.t2.micro"
  allocated_storage      = 20
  storage_type           = "gp2"
  username               = "admin"
  password               = "password"
  publicly_accessible   = false
  vpc_security_group_ids = [aws_security_group.security_group.id]
  
}

# Creación de R53 Alias y Hosted Zone
resource "aws_route53_zone" "hosted_zone" {
  name = "example.com."
}

resource "aws_route53_record" "alias_record" {
  zone_id = aws_route53_zone.hosted_zone.zone_id
  name    = "example.com"
  type    = "A"
  alias {
    name                   = aws_lb.application_load_balancer.dns_name
    zone_id                = aws_lb.application_load_balancer.zone_id
    evaluate_target_health = false
  }
}

