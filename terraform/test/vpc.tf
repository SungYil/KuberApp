resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_blocks[0]
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name                                         = "${var.instance_name}_vpc"
    "kubernetes.io/cluster/${var.instance_name}" = "owned"

  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name                                         = "${var.instance_name}_igw"
    "kubernetes.io/cluster/${var.instance_name}" = "owned"
  }
}

resource "aws_subnet" "subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.cidr_blocks[0]
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name                                         = "${var.instance_name}_subnet"
    "kubernetes.io/cluster/${var.instance_name}" = "owned"
  }
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name                                         = "${var.instance_name}_route_table"
    "kubernetes.io/cluster/${var.instance_name}" = "owned"
  }
}

resource "aws_route" "route" {
  route_table_id         = aws_route_table.route_table.id
  destination_cidr_block = var.cidr_blocks[1]
  gateway_id             = aws_internet_gateway.internet_gateway.id
}

resource "aws_route_table_association" "route_table_association" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.route_table.id
}

resource "aws_eip" "eip" {
  vpc        = true
  count      = var.instance_count
  instance   = element(aws_instance.instance.*.id, count.index)
  depends_on = [aws_internet_gateway.internet_gateway]

  tags = {
    Name                                         = "${var.instance_name}_eip"
    "kubernetes.io/cluster/${var.instance_name}" = "owned"
  }
}
