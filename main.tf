provider "aws" {
  region = "us-east-1"  # Change to your desired AWS region
}

resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg"
  description = "Jenkins Security Group"
  
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Be cautious about exposing port 8080 to the world
  }
}

resource "aws_instance" "jenkins_server" {
  ami           = "ami-0e8a34246278c21e4"  # Replace with the desired AMI ID
  instance_type = "t2.micro"  # Change to the desired instance type
  key_name      = "ec2-key"  # Replace with your SSH key pair
  
  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
              sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
              sudo yum upgrade -y

              ## Install Java 11:
              sudo yum install java-11* -y

              ## Install Jenkins then Enable the Jenkins service to start at boot :
              sudo yum install jenkins -y
              sudo systemctl enable jenkins

              ## Start Jenkins as a service:
              sudo systemctl start jenkins
              EOF

  security_groups = [aws_security_group.jenkins_sg.name]
}

output "jenkins_server_public_ip" {
  value = aws_instance.jenkins_server.public_ip
}

output "jenkins_server_dns" {
  value = aws_instance.jenkins_server.public_dns
}

terraform {
  backend "s3" {
    bucket         = "kizoka13-bucket"
    key            = "jenkins.tfstate"
    region         = "us-east-1"  # Change to your desired AWS region
    encrypt        = true
    dynamodb_table = "kizoka13-table"
  }
}
