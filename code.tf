terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
}

# create vpc

resource "aws_vpc" "myvpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "my-Vpc"
  }
}

# Pub subnet

resource "aws_subnet" "Pub-Sub" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1a"  # we add the subnets

  tags = {
    Name = "My-Vpc-Pu-Sub"
  }
}


# Pri subnet

resource "aws_subnet" "Pri-Sub" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "My-Vpc-Pri-Sub"
  }
}


# Internet Gate Way

resource "aws_internet_gateway" "terraform_IGW" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "My-Vpc-IGW"
  }
}

# Pub Route Table

resource "aws_route_table" "Pub-Rt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terraform_IGW.id
  }


  tags = {
    Name = "My-Vpc-Pub-Rt"
  }
}

resource "aws_route_table_association" "Pub_Rt_Associ" {
  subnet_id      = aws_subnet.Pub-Sub.id
  route_table_id = aws_route_table.Pub-Rt.id
}

# Elastic Ip

resource "aws_eip" "My-EIP" {
  domain   = "vpc"
}

# Nat Gate Way

resource "aws_nat_gateway" "terraform-NAT" {
  allocation_id = aws_eip.My-EIP.id
  subnet_id     = aws_subnet.Pub-Sub.id

  tags = {
    Name = "My-Vpc-NAT"
  }
}


# Privte Route Table

resource "aws_route_table" "Pri-Rt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.terraform-NAT.id
  }


  tags = {
    Name = "My-Vpc-Pri-Rt"
  }
}


resource "aws_route_table_association" "Pri_Rt_Associ" {
  subnet_id      = aws_subnet.Pri-Sub.id
  route_table_id = aws_route_table.Pri-Rt.id
}



# Security groups

resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  tags = {
    Name = "My-Vpc-SG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4" {
  security_group_id = aws_security_group.allow_all.id
  cidr_ipv4         = aws_vpc.myvpc.cidr_block
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_ipv4" {
  security_group_id = aws_security_group.allow_all.id
  cidr_ipv4         = aws_vpc.myvpc.cidr_block
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

# resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv6" {
#   security_group_id = aws_security_group.allow_tls.id
#   cidr_ipv6         = aws_vpc.main.ipv6_cidr_block
#   from_port         = 443
#   ip_protocol       = "tcp"
#   to_port           = 443
# }

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_all.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv6" {
#   security_group_id = aws_security_group.allow_tls.id
#   cidr_ipv6         = "::/0"
#   ip_protocol       = "-1" # semantically equivalent to all ports
# }


# create EC2

resource "aws_instance" "Jumpbox1" {
    ami                             = "ami-0a7cf821b91bcccbc"
    instance_type                   = "t2.micro"
    subnet_id                       = aws_subnet.Pub-Sub.id
    vpc_security_group_ids      = [aws_security_group.allow_all.id]
    key_name                        = "mynewkeypair11"
    associate_public_ip_address      = true
}

resource "aws_instance" "Jumpbox2" {
    ami                             = "ami-0a7cf821b91bcccbc"
    instance_type                   = "t2.micro"
    subnet_id                       = aws_subnet.Pri-Sub.id
    vpc_security_group_ids      = [aws_security_group.allow_all.id]
    key_name                        = "mynewkeypair11"
    
}


