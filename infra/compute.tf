# Launch Template
resource "aws_launch_template" "this" {
  name_prefix   = "${var.project_name}-lt-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.ec2_sg.id]
  }

  user_data = base64encode(<<-EOF
  #!/bin/bash
set -eux

# ------------------------
# Variables
# ------------------------
REGION="us-east-1"
ECR_REPO="730335228615.dkr.ecr.ap-south-1.amazonaws.com/aws-ha-platform-app"
SSM_PARAM="/ha-platform/app/image-tag"

# ------------------------
# System prep
# ------------------------
yum update -y
amazon-linux-extras install docker -y
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

# ------------------------
# Login to ECR
# ------------------------
aws ecr get-login-password --region $REGION \
  | docker login \
  --username AWS \
  --password-stdin $ECR_REPO

# ------------------------
# Fetch image tag from SSM
# ------------------------
IMAGE_TAG=$(aws ssm get-parameter \
  --name "$SSM_PARAM" \
  --query "Parameter.Value" \
  --output text \
  --region $REGION)

# ------------------------
# Pull & Run container
# ------------------------
docker pull $ECR_REPO:$IMAGE_TAG

docker run -d \
  --name app \
  -p 80:80 \
  $ECR_REPO:$IMAGE_TAG

EOF
)


  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-instance"
    }
  }
}

# ASG
resource "aws_autoscaling_group" "this" {
  name = "${var.project_name}-asg"

  desired_capacity = 2
  min_size         = 2
  max_size         = 4

  vpc_zone_identifier = [
    aws_subnet.private_1.id,
    aws_subnet.private_2.id
  ]

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  target_group_arns = [
    aws_lb_target_group.this.arn
  ]

  health_check_type         = "ELB"
  health_check_grace_period = 60

  tag {
    key                 = "Name"
    value               = "${var.project_name}-asg-instance"
    propagate_at_launch = true
  }
}

