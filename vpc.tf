# //////////////////////////////
# RESOURCES
# //////////////////////////////

# VPC
resource "aws_vpc" "vpc1" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = "true"
   tags = {
    Name = "vpc1"
  }

}

# SUBNET
resource "aws_subnet" "subnet1" {
  cidr_block = var.subnet1_cidr
  vpc_id = aws_vpc.vpc1.id
  map_public_ip_on_launch = "true"
  availability_zone = data.aws_availability_zones.available.names[1]
}

resource "aws_subnet" "subnet2" {
  cidr_block = var.subnet2_cidr
  vpc_id = aws_vpc.vpc1.id
  map_public_ip_on_launch = "true"
  availability_zone = data.aws_availability_zones.available.names[2]
}

# INTERNET_GATEWAY
resource "aws_internet_gateway" "gateway1" {
  vpc_id = aws_vpc.vpc1.id
}

# ROUTE_TABLE
resource "aws_route_table" "route_table1" {
  vpc_id = aws_vpc.vpc1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway1.id
  }
}

resource "aws_route_table_association" "route-subnet1" {
  subnet_id = aws_subnet.subnet1.id
  route_table_id = aws_route_table.route_table1.id
}

# SECURITY_GROUP
resource "aws_security_group" "sg-nodejs-instance" {
  name = "nodejs_sg"
  vpc_id = aws_vpc.vpc1.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  

  # form 8863
  # 1098
  
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# INSTANCE
resource "aws_instance" "nodejs1" {
  ami = data.aws_ami.aws-linux.id
  instance_type = "t2.micro"
  subnet_id = aws_subnet.subnet1.id
 
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.sg-nodejs-instance.id]
  iam_instance_profile = aws_iam_instance_profile.test_profile.name

#  key_name               = var.ssh_key_name

#  connection {
#    type        = "ssh"
#    host        = self.public_ip
#    user        = "ec2-user"
#    private_key = file(var.private_key_path)
#  }
}


resource "aws_launch_template" "web-server" {
#  name = "web-server-template"

  name_prefix = "my-lc-template"  
  iam_instance_profile {
    name = aws_iam_instance_profile.test_profile.name

  }
  image_id = data.aws_ami.aws-linux.id
  instance_type = "t2.nano"

#  key_name = "key-1"
#  user_data = "${base64encode(data.template_file.user_data_hw.rendered)}"

  vpc_security_group_ids = [aws_security_group.sg-nodejs-instance.id]

  disable_api_termination = true
#  network_interfaces {
#    associate_public_ip_address = true
#  }
  instance_initiated_shutdown_behavior = "terminate"

}

resource "aws_autoscaling_group" "asg-web" {
  name_prefix = "my-asg"  
  launch_template { 
    id = aws_launch_template.web-server.id
    version = aws_launch_template.web-server.latest_version
  }
  # availability_zones   = data.aws_availability_zones.available.names
  min_size = 2
  max_size = 2
  desired_capacity = 2
  vpc_zone_identifier       = [aws_subnet.subnet1.id, aws_subnet.subnet2.id ]
  health_check_type = "EC2"

  tag {
    key                 = "Name"
    value               = "terraform-asg-sample"
    propagate_at_launch = true
  }
}


# //////////////////////////////
# OUTPUT
# //////////////////////////////
output "instance-dns" {
  value = aws_instance.nodejs1.public_dns
}

