resource "aws_security_group" "default_sg" {
  name        = "${var.instance_name}_default_sg"
  description = "allow 22, 80"
  vpc_id      = aws_vpc.vpc.id
  tags = {
    Name                                         = "${var.instance_name}_default_sg"
    "kubernetes.io/cluster/${var.instance_name}" = "owned"
  }
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group" "elb_sg" {
  name        = "${var.instance_name}_elb_sg"
  description = "Used in the terraform"
  vpc_id      = aws_vpc.vpc.id
  tags = {
    Name                                         = "${var.instance_name}_elb_sg"
    "kubernetes.io/cluster/${var.instance_name}" = "owned"
  }
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  # ensure the VPC has an Internet gateway or this step will fail
  depends_on = [aws_internet_gateway.internet_gateway]
}
