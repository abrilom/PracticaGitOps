resource "aws_vpc" "abril_vpc" {
  cidr_block = "10.0.0.0/16"

  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "abril-vpc"
  }
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id     = aws_vpc.abril_vpc.id
  cidr_block = "10.0.0.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-west-2a" 
  tags = {
    Name = "abril_subnet_publica_1"
  }

}

resource "aws_subnet" "public_subnet_2" {
  vpc_id     = aws_vpc.abril_vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-west-2c" 
  tags = {
    Name = "abril_subnet_publica_2"
  }

}

resource "aws_subnet" "private_subnet_1" {
  vpc_id     = aws_vpc.abril_vpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-west-2a" 
  tags = {
    Name = "abril_subnet_privada_1"
  }

}

resource "aws_subnet" "private_subnet_2" {
  vpc_id     = aws_vpc.abril_vpc.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-west-2c" 
  tags = {
    Name = "abril_subnet_privada_2"
  }

}

resource "aws_internet_gateway" "abril_igw" {
  vpc_id = aws_vpc.abril_vpc.id
  
  tags = {
    Name = "abril_igw"
  }
}

resource "aws_route_table" "public_rtb" {
  vpc_id = aws_vpc.abril_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.abril_igw.id
  }
  tags = {
    Name = "abril_routes"
  }

}

resource "aws_route_table_association" "public_subnet_1_association" {
  subnet_id = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rtb.id
}

resource "aws_route_table_association" "public_subnet_2_association" {
  subnet_id = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rtb.id
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners = ["099720109477"]
  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "ec2_sg" {
  vpc_id = aws_vpc.abril_vpc.id

  ingress {
    description = "Allow HTTP"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    description = "Allow HTTPS"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    description = "Allow SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound traffic"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "abril_sg_ec2"
  }
  
}

resource "aws_security_group" "alb_sg" {
  vpc_id = aws_vpc.abril_vpc.id

  ingress {
    description = "Allow HTTP"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "permitir trafico de salida"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "abril_sg_alb"
  }
  
}
resource "aws_security_group" "rds_sg" {
  vpc_id = aws_vpc.abril_vpc.id

  ingress {
    description = "Allow HTTPS"
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
    
  }

  egress {
    description = "permitir trafico de salida"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "abril_sg_rds"
  }

  
}

resource "aws_alb" "abril_alb" {

  load_balancer_type = "application"
  security_groups = [aws_security_group.alb_sg.id]
  internal = false
  subnets = [ 
    aws_subnet.public_subnet_1.id,
    aws_subnet.public_subnet_2.id
   ]

  tags = {
    Name = "abril_alb"
  }
  
}

resource "aws_lb_target_group" "abril_target_group" {
  vpc_id = aws_vpc.abril_vpc.id
  port = 80
  protocol = "HTTP"

  health_check {
    path = "/"
  }

  tags = {
    Name = "abril_tg"
  }
  
}

resource "aws_alb_listener" "abril_listener" {
  load_balancer_arn = aws_alb.abril_alb.arn
  port = "80"
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.abril_target_group.arn

  }
  tags = {
    Name = "abril_listener"
  }
}

resource "aws_launch_template" "abril_ec2" {
  image_id = data.aws_ami.ubuntu.id
  instance_type = var.ec2_instance_type
  key_name = aws_key_pair.abril_key.key_name

  network_interfaces {
    security_groups = [aws_security_group.ec2_sg.id]
    associate_public_ip_address = true
  }

  user_data = base64encode(<<-EOF
#!/bin/bash
apt-get update -y
apt-get install -y apache2
systemctl enable apache2
systemctl start apache2
EOF
  )

tag_specifications {
    resource_type = "instance"
    tags = {
    	Name = "abril-ec2"
    	role = "ec2"
  }
}
  
}

resource "aws_autoscaling_group" "abril_asg" {
  desired_capacity = 2
  max_size = 4
  min_size = 2
  vpc_zone_identifier = [
    aws_subnet.public_subnet_1.id,
    aws_subnet.public_subnet_2.id
    ]
  health_check_grace_period = 300

  launch_template {
    id = aws_launch_template.abril_ec2.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.abril_target_group.arn]
  
}

resource "aws_db_subnet_group" "abril_db_subnet_group" {
  name = "abril-rds-subnets"
  subnet_ids = [
    aws_subnet.private_subnet_1.id,
    aws_subnet.private_subnet_2.id
  ]

  tags = {
    Name = "abril_db_subnet_group"
  }
  
}

resource "aws_db_instance" "abril_rds" {
  engine = "postgres"
  engine_version = "16.11"
  instance_class = "db.t3.micro"
  allocated_storage = 10
  storage_type = "gp2"

  skip_final_snapshot = true

  db_subnet_group_name = aws_db_subnet_group.abril_db_subnet_group.name
  vpc_security_group_ids = [ aws_security_group.rds_sg.id ]

  username = "abril_rds"
  password = "abril_pass"
  db_name = "postgres"

}

resource "aws_eip" "abril_eip" {
  depends_on = [ aws_internet_gateway.abril_igw ]
  tags = {
    Name = "abril_eip"
  }
}

resource "aws_nat_gateway" "abril_nat" {
  allocation_id = aws_eip.abril_eip.id
  subnet_id = aws_subnet.public_subnet_1.id
  tags = {
    Name = "abril_nat"
  }
}

resource "aws_route_table" "abril_private_rt" {
  vpc_id = aws_vpc.abril_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.abril_nat.id
  }

  tags = {
    Name = "abril_private_rt"
  }

}

resource "aws_route_table_association" "abril_private_association_1" {
  subnet_id = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.abril_private_rt.id
  
}

resource "aws_route_table_association" "abril_private_association_2" {
  subnet_id = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.abril_private_rt.id
  
}


resource "aws_key_pair" "abril_key" {
  key_name = "abril-key"
  public_key = file("./abril-key.pub")
  
}


