provider "aws" {
  region = var.region
}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
}

# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

# Create Public Subnets
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr_1
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr_2
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"
}

# Create Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.idex
}

# Associate Route Table with Subnets
resource "aws_route_table_association" "public_rt_assoc_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_rt_assoc_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public_rt.id
}

# Create Route for Internet Gateway
resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Security Group for ALB
resource "aws_security_group" "alb_sg" {
  vpc_id = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.common_ingress_rule
    content {
      from_port = ingress.value.from_port
      to_port = ingress.value.to_port
      protocol = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group for EC2 instances (Web Tier)
resource "aws_security_group" "web_sg" {
  vpc_id = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.common_ingress_rule
    content {
      from_port = ingress.value.from_port
      to_port = ingress.value.to_port
      protocol = ingress.value.protocol
      security_groups = [aws_security_group.alb_sg.id]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create ALB
resource "aws_lb" "app_lb" {
  name               = "app-loadbalancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]
}

# Create Target Group
resource "aws_lb_target_group" "app_tg" {
  name     = "app-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

# Create Listener for ALB
resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# Launch Template
resource "aws_launch_template" "web_server" {
  name_prefix = "web-server"

  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  network_interfaces {
    security_groups             = [aws_security_group.web_sg.id]
    associate_public_ip_address = true
  }

  user_data = <<-EOF
              #!/bin/bash

              # Variables
              DB_NAME="wordpress_db"
              DB_USER="wordpress_user"
              DB_PASS="yourpassword"

              # Update the system and install necessary packages
              sudo yum update -y
              sudo yum install -y httpd mariadb105-server wget php php-mysqlnd php-fpm

              # Start and enable Apache
              sudo systemctl start httpd
              sudo systemctl enable httpd

              # Download and extract WordPress
              cd /var/www/html
              sudo wget https://wordpress.org/latest.tar.gz
              sudo tar -xzvf latest.tar.gz
              sudo rm -f latest.tar.gz

              # Set permissions for WordPress
              sudo chown -R apache:apache /var/www/html/wordpress
              sudo chmod -R 755 /var/www/html/wordpress

              # Create Apache Virtual Host for WordPress
              sudo bash -c 'cat <<EOF > /etc/httpd/conf.d/wordpress.conf
              <VirtualHost *:80>
                  DocumentRoot /var/www/html/wordpress
                  <Directory /var/www/html/wordpress>
                      AllowOverride All
                      Require all granted
                  </Directory>
                  ErrorLog /var/log/httpd/wordpress-error.log
                  CustomLog /var/log/httpd/wordpress-access.log combined
              </VirtualHost>
              EOF'

              # Restart Apache to apply the new virtual host configuration
              sudo systemctl restart httpd

              # Start and enable MariaDB
              sudo systemctl start mariadb
              sudo systemctl enable mariadb

              # Secure MariaDB installation (e.g., setting root password)
              sudo mysql_secure_installation <<EOF_SEC
              y
              password
              password
              y
              y
              y
              y
              EOF_SEC

              # Create a WordPress database and user
              sudo mysql -u root -ppassword <<EOF_SQL
              CREATE DATABASE \$${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
              CREATE USER '\$${DB_USER}'@'localhost' IDENTIFIED BY '\$${DB_PASS}';
              GRANT ALL PRIVILEGES ON \$${DB_NAME}.* TO '\$${DB_USER}'@'localhost';
              FLUSH PRIVILEGES;
              EXIT;
              EOF_SQL

              # Configure WordPress
              sudo cp /var/www/html/wordpress/wp-config-sample.php /var/www/html/wordpress/wp-config.php
              sudo sed -i "s/database_name_here/\$${DB_NAME}/" /var/www/html/wordpress/wp-config.php
              sudo sed -i "s/username_here/\$${DB_USER}/" /var/www/html/wordpress/wp-config.php
              sudo sed -i "s/password_here/\$${DB_PASS}/" /var/www/html/wordpress/wp-config.php

              # Set final permissions
              sudo chown -R apache:apache /var/www/html/wordpress
              sudo chmod -R 755 /var/www/html/wordpress

              # Restart Apache to ensure everything is applied correctly
              sudo systemctl restart httpd

              # Script completed
              echo "WordPress installation completed. Access your site to complete the setup."
              EOF
}

# Auto Scaling Group
resource "aws_autoscaling_group" "web_asg" {
  desired_capacity = 1
  max_size         = 2
  min_size         = 1
  launch_template {
    id      = aws_launch_template.web_server.id
    version = "$Latest"
  }
  vpc_zone_identifier = [aws_subnet.public_1.id, aws_subnet.public_2.id]
  target_group_arns   = [aws_lb_target_group.app_tg.arn]
}
