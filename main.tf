provider "aws" {
  region = var.region
}

// aws_security_group is the resource type
// allow_http is the name that will be reference by terraform
resource "aws_security_group" "allow_http" {
  name        = "allow_http" // name referenced by AWS
  description = "Allow HTTP inbound traffic"
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

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" // all protocols allowed
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_instance" "spring_boot_vm" {
  ami             = "ami-03f71e078efdce2c9"
  instance_type   = var.instance_type
  key_name        = var.key_name
  security_groups = [aws_security_group.allow_http.name]

  tags = {
    name = "SpringBootAppVM"
  }

  user_data = <<-EOF
                #!/bin/bash
                yum update -y

                # Install Git
                yum install -y git

                # Install Docker
                yum install -y docker
                service docker start
                usermod -aG docker ec2-user 

                # Install Docker Compose
                sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
                sudo chmod +x /usr/local/bin/docker-compose

                # Install Java 17 (Amazon Corretto)
                sudo yum install -y java-17-amazon-corretto

                # Install Maven
                sudo yum install -y maven

                # Clone the Git repository
                cd /home/ec2-user
                git clone https://github.com/rmoloney96/spring-boot-api.git

                # Navigate to the project directory
                cd spring-boot-api

                # Create .env file for Docker Compose with the retrieved credentials
                echo "DB_USER=${var.db_user}" > /home/ec2-user/spring-boot-api/.env
                echo "DB_PASSWORD=${var.db_password}" >> /home/ec2-user/spring-boot-api/.env
                echo "DB_NAME=${var.db_name}" >> /home/ec2-user/spring-boot-api/.env

                # Build the Spring Boot app
                mvn clean package

                # Start Docker containers using Docker Compose
                docker-compose up --build -d

            EOF
}

output "public_ip" {
  value = aws_instance.spring_boot_vm.public_ip
}
