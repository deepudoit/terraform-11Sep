module "iam_instance_profile" {
  source = "scottwinkler/iip/aws"
  actions = ["logs:*", "rd:*"]
}

data "template_cloudinit_config" "config" {
  gzip = true
  base64_encode = true
  part {
    content_type = "text/cloud_config"
    content = templatefile("${path.module}/cloud_config.yaml", var.db_config)
  }
}

data "aws_ami" "ubuntu" {
  owners = ["099720109477"]
  most_recent = true
  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
}

resource "aws_launch_template" "webserver" {
  name_prefix = var.namespace
  image_id = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  user_data = data.template_cloudinit_config.config.rendered
  key_name = var.ssh_key
  iam_instance_profile {
    name = module.iam_instance_profile.name
  }
  vpc_security_group_ids = [var.sg.websvr]
}

resource "aws_autoscaling_group" "webserver" {
  max_size = 3
  min_size = 1
  name = "${var.namespace}-asg"
  vpc_zone_identifier = var.vpc.private_subnets
  target_group_arns = module.alb.target_group_arns
  launch_template {

  }
}

module "alb" {
  source = "terraform-aws-modules/alb/aws"
  version = "~> 4.0"
  load_balancer_name = "${var.namespace}-alb"
  security_groups = [var.sg.lb]
  subnets = var.vpc.public_subnets
  vpc_id = var.vpc.vpc_id
  logging_enabled = false
  http_tcp_listeners       = [{ port = 80, protocol = "HTTP" }]
  http_tcp_listeners_count = "1"
  target_groups            = [{ name = "websvr", backend_protocol = "HTTP", backend_port = 8080 }]
  target_groups_count      = "1"
}