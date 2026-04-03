resource "aws_vpc" "vpc" {
  cidr_block = var.cidr_block
  tags = {
    "Name" = var.vpc_name
  }
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = var.public_subnet_1_cidr
  availability_zone = var.az1
  map_public_ip_on_launch = true

}


resource "aws_subnet" "public_subnet_2" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = var.public_subnet_2_cidr
  availability_zone = var.az2
  map_public_ip_on_launch = true

}

resource "aws_subnet" "private_subnet_1" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = var.private_subnet_1_cidr
  availability_zone = var.az1
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = var.private_subnet_2_cidr
  availability_zone = var.az2
}

resource "aws_internet_gateway" "aws_internet_gateway" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_eip" "elasticIP" {
  domain = "vpc"
  depends_on = [ aws_internet_gateway.aws_internet_gateway ]
}

resource "aws_nat_gateway" "aws_nat_gateway" {
  allocation_id = aws_eip.elasticIP.id
  subnet_id = aws_subnet.public_subnet_1.id
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.aws_internet_gateway.id
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.aws_nat_gateway.id
  }
}


resource "aws_route_table_association" "public_route_association" {

for_each = {
    subnet1 = aws_subnet.public_subnet_1.id
    subnet2 = aws_subnet.public_subnet_2.id
}

  subnet_id = each.value
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private_route_association" {

for_each = {
    subnet1 = aws_subnet.private_subnet_1.id
    subnet2 = aws_subnet.private_subnet_2.id
}

  subnet_id = each.value
  route_table_id = aws_route_table.private_route_table.id
}




