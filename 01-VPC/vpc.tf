terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

// 1. Create a VPC
resource "aws_vpc" "terraform_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "terraform_vpc"
  }
}

// 2. Create a Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.terraform_vpc.id
  cidr_block = "10.0.0.0/24"

  tags = {
    Name = "Public_Subnet"
  }
}

// 3. Create a Private Subnet
resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.terraform_vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "Private_Subnet"
  }
}

// 4. Create an Internet Gateway
resource "aws_internet_gateway" "terraform_igw" {
  vpc_id = aws_vpc.terraform_vpc.id

  tags = {
    Name = "terraform_vpc_IGW"
  }
}

// 5. Create an Elastic IP for the NAT Gateway
resource "aws_eip" "terraform_eip" {
  domain = "vpc"

  depends_on = [aws_internet_gateway.terraform_igw]
}


// 6. Create a Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.terraform_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terraform_igw.id
  }

  tags = {
    Name = "public_rt"
  }
}


// 7. Create a Public Route Table Association
resource "aws_route_table_association" "public_rt_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}


// 8. Create a NAT Gateway
resource "aws_nat_gateway" "terraform_natgw" {
  allocation_id = aws_eip.terraform_eip.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name = "terraform_natgw"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.terraform_igw]
}


// 9. Create a Private Route Table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.terraform_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.terraform_natgw.id
  }

  tags = {
    Name = "private_rt"
  }
}

// 10. Create a Private Route Table Association
resource "aws_route_table_association" "private_rt_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}
