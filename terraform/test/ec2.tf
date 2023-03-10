resource "aws_instance" "instance" {
  subnet_id              = aws_subnet.subnet.id
  count                  = var.instance_count
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.key_pair.id
  vpc_security_group_ids = ["${aws_security_group.default_sg.id}"]
  iam_instance_profile   = aws_iam_instance_profile.ec2_k8s_master_profile.name

  root_block_device {
    volume_size = var.volume_size # in GB
    volume_type = var.volume_type
    tags = {
      "Name"                                       = "root_volume_${var.instance_name}"
      "kubernetes.io/cluster/${var.instance_name}" = "owned"
    }
  }

  tags = {
    "Name"                                       = element(var.instance_tags, count.index)
    "kubernetes.io/cluster/${var.instance_name}" = "owned"
    "Schedule"                                   = "running"
  }
}
