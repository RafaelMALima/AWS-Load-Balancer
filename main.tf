locals {
  db_name = "Shitdb"
}




resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc-cidr_block
  enable_dns_hostnames = true

  tags = {
    Name = "Some Custom VPC"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.public_subnet_cidr_blocks[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  count                   = var.subnet_count.public
  map_public_ip_on_launch = true

  tags = {
    Name = "Public Subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.private_subnet_cidr_blocks[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  count                   = var.subnet_count.private
  map_public_ip_on_launch = true

  tags = {
    Name = "Private Subnet"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "Gateway"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name = "Public Route Table"
  }
}

resource "aws_route_table_association" "public_1_rt_a" {
  count          = var.subnet_count.public
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_rt.id
}


resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.vpc.id

}

resource "aws_route_table_association" "private_1_rt_a" {
  count          = var.subnet_count.private
  route_table_id = aws_route_table.private_rt.id
  subnet_id      = aws_subnet.private_subnet[count.index].id
}


resource "aws_security_group" "web_sg" {
  name   = "HTTP and SSH"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    name = "Security group ec2"
  }
}


resource "aws_security_group" "db_sg" {
  name   = "database-sec-group"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }
  tags = {
    name = "Security group DB"
  }
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db_subnet_group"
  subnet_ids = [for subnet in aws_subnet.private_subnet : subnet.id]
}

resource "aws_db_instance" "database" {
  allocated_storage      = var.settings.database.allocated_storage
  engine                 = var.settings.database.engine
  engine_version         = var.settings.database.engine_version
  instance_class         = var.settings.database.instance_class
  db_name                = var.settings.database.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.id
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot    = var.settings.database.skip_final_snapshot
  multi_az               = true
}

resource "aws_key_pair" "instance_keypair" {
  key_name = "instances_kp"

  public_key = file("~/.ssh/instancekp.pub")
}

data "aws_ami" "ubuntu" {
  most_recent = "true"
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"]
}

resource "aws_autoscaling_group" "autoscale_group" {
  min_size            = 1
  max_size            = 5
  desired_capacity    = 2
  vpc_zone_identifier = [aws_subnet.public_subnet[0].id, aws_subnet.public_subnet[1].id]
  launch_template {
    id      = aws_launch_template.django_template.id
    version = "$Latest"
  }
  target_group_arns = [aws_lb_target_group.target_autoscale_group.arn]
}

resource "aws_lb" "autoscale_group_lb" {
  name                             = "autoscale-group-lb"
  internal                         = false
  load_balancer_type               = "application"
  security_groups                  = [aws_security_group.web_sg.id]
  subnets                          = [aws_subnet.public_subnet[0].id, aws_subnet.public_subnet[1].id]
  enable_deletion_protection       = false
  enable_cross_zone_load_balancing = true
}

resource "aws_lb_target_group" "target_autoscale_group" {
  name     = "asg-autoscale-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id


  health_check {
    path     = "/"    # Health check path for your application
    interval = 10     # Health check interval in seconds
    protocol = "HTTP" # Health check protocol
    #port                = "traffic-port" # Port used for health checks
    timeout             = 9 # Health check timeout in seconds
    healthy_threshold   = 5 # Number of consecutive successful health checks required to mark the target healthy
    unhealthy_threshold = 2 # Number of consecutive failed health checks required to mark the target unhealthy
  }
}

resource "aws_lb_listener" "lb_listener" {
  load_balancer_arn = aws_lb.autoscale_group_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.target_autoscale_group.arn
    type             = "forward"
  }
}

resource "aws_autoscaling_attachment" "autoscale_group" {
  autoscaling_group_name = aws_autoscaling_group.autoscale_group.id
  alb_target_group_arn   = aws_lb_target_group.target_autoscale_group.arn
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "ScaleDown"
  autoscaling_group_name = aws_autoscaling_group.autoscale_group.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 120
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "ScaleUp"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 10
  autoscaling_group_name = aws_autoscaling_group.autoscale_group.name
}

resource "aws_cloudwatch_metric_alarm" "scale_down_alarm" {
  alarm_description   = "Monitors CPU utilization for django instances"
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]
  alarm_name          = "scale_down"
  comparison_operator = "LessThanOrEqualToThreshold"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  threshold           = "20"
  evaluation_periods  = "2"
  period              = "10"
  statistic           = "Average"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.autoscale_group.name
  }
}

resource "aws_cloudwatch_metric_alarm" "scale_up_alarm" {
  alarm_description   = "Monitors CPU utilization for django instances"
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]
  alarm_name          = "scale_up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  threshold           = "60"
  evaluation_periods  = "2"
  period              = "10"
  statistic           = "Average"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.autoscale_group.name
  }
}

resource "aws_launch_template" "django_template" {
  image_id               = "ami-0fc5d935ebf8bc3bc"
  instance_type          = var.settings.django_app.instance_type
  key_name               = aws_key_pair.instance_keypair.key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = base64encode(<<-EOF
  #!/bin/bash
  sudo apt update -y
  sudo apt-get install -y python3-pip python3-venv git authbind awscli
  git clone https://github.com/AndreCorreaSantos/simple_python_crud /home/ubuntu/simple_python_crud
  cd /home/ubuntu/simple_python_crud
  pip install -r requirements.txt

  echo "DB_ENDPOINT=${aws_db_instance.database.address}
  export DB_HOST=${aws_db_instance.database.address}
  export DB_NAME=${var.settings.database.db_name}
  export DB_USER=${var.db_username}
  export DB_PASS=${var.db_password}
  export INSTANCE_ID=${aws_db_instance.database.id}" >> envs.sh

  source envs.sh

  aws logs create-log-stream --log-group-name "/my-fastapi-app/logs" --log-stream-name "$INSTANCE_ID" --region us-east-1

  # binding to port 80
  sudo touch /etc/authbind/byport/80
  sudo chmod 500 /etc/authbind/byport/80
  sudo chown ubuntu /etc/authbind/byport/80

  # starting the app
  authbind --deep uvicorn main:app --host 0.0.0.0 --port 80

  EOF
  )

  tags = {
    "Name" : "Django instances"
  }
}


resource "aws_s3_bucket" "limaobucketunicoteste" {
  bucket = var.bucket_name
  acl    = "private"
  tags = {
    Name = "lemonbucket"
  }
}

resource "aws_s3_bucket_object" "tfstate_file" {
  bucket = aws_s3_bucket.limaobucketunicoteste.id
  key    = "terraform.tfstate"
  source = "terraform.tfstate"
}
