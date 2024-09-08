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
sudo mysql_secure_installation <<EOF

y
password
password
y
y
y
y
EOF

# Create a WordPress database and user
sudo mysql -u root -ppassword <<EOF
CREATE DATABASE ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EXIT;
EOF

# Configure WordPress
sudo cp /var/www/html/wordpress/wp-config-sample.php /var/www/html/wordpress/wp-config.php
sudo sed -i "s/database_name_here/${DB_NAME}/" /var/www/html/wordpress/wp-config.php
sudo sed -i "s/username_here/${DB_USER}/" /var/www/html/wordpress/wp-config.php
sudo sed -i "s/password_here/${DB_PASS}/" /var/www/html/wordpress/wp-config.php

# Set final permissions
sudo chown -R apache:apache /var/www/html/wordpress
sudo chmod -R 755 /var/www/html/wordpress

# Restart Apache to ensure everything is applied correctly
sudo systemctl restart httpd

# Script completed
echo "WordPress installation completed. Access your site to complete the setup."
