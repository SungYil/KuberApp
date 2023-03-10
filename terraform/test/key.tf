resource "aws_key_pair" "key_pair" {
  key_name   = "${var.instance_name}_key_pair"
  public_key = file("~/.ssh/id_rsa.pub")
  tags = {
    "Name"                                       = "${var.instance_name}_key_pair"
    "kubernetes.io/cluster/${var.instance_name}" = "owned"
  }
}
