terraform {
  /*backend "remote" {
    hostname = "app.terraform.io"
    organization = "Terraform-cert-sush"

    workspaces {
      name = "provisoners-test"
    }
  }*/
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "3.72.0"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

data "aws_vpc" "default_vpc" {
  id = "vpc-03cc2b0a74e470059"
}

resource "aws_security_group" "sg_myserver" {
  name        = "sg_myserver"
  description = "my server sg"
  vpc_id      = data.aws_vpc.default_vpc.id

  ingress =[{
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  },
  {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["49.207.220.27/32"]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }
  ]

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }

}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC52wOTFTveulexXd0xK2ZIXqGfiY7cbTh1mN90znGljTqAy87kiTFUQY/3WvFtJR2D0iOVNjZ2UuHKYlsliUxvxFvvdpFhTNiwJDoF4Fh3N8WtOToHdTY2lln2WoipREzE48UHIAq129Sl9DMKicS1lq+M7JI5fSn572WQPK2Lao1JoFhgRQuj5jR+ZYsBu5Hvf0OAFjp6YMAnEPlTXNNRF6cOquMDTyLKBzhR6hY3lOHrdcrUjPbG9KPaNgZY39g2xl3w65ObAHwc6duqAOSipjV7jGVabs3XrfIft7RLf2JoMMc4MqqT9AuScOj82E1bKTQYA9Z1jvT09HWXIX4+5OwdMQPAtNB9MbteKGZixvIRHGnvZeKhSWPYH4J2+r5hKu9SzXaBD7xmoXXtd3alQfWdbA+VGG/1RhXDDWNQR9zGjqhy5IggLq67mHkVTzHjLc9+gc/W0qQ0hCDM97nN2+P1yltH4/X50I4o2Evcvl9QNqo6zIRr//+W3GMAyps= sushmithaks@LAPTOP-O3BEKKI6"
}

data "template_file" "user_data" {
  template = file("./userdata.yaml")
}

resource "aws_instance" "my_server" {
  ami           = "ami-08e4e35cccc6189f4"
  instance_type = "t2.micro"
  key_name = "${aws_key_pair.deployer.key_name}"
  vpc_security_group_ids = [aws_security_group.sg_myserver.id]
  user_data = data.template_file.user_data.rendered
 /* provisioner "remote-exec" {
    inline = [
      "echo ${self.private_ip} >> /home/ec2-user/private_ips.txt"
    ]*/

  provisioner "file" {
    content     = "mars"
    destination = "/home/ec2-user/barsoon.txt"

    connection {
    type     = "ssh"
    user     = "ec2-user"
    host     = "${self.public_ip}"
    private_key = "${file("~/.ssh/terraform")}"
  }
  }


  tags = {
    Name = "my_server"
  }
}

resource "null_resource" "status" {
  provisioner "local-exec" {
    command = "aws ec2 wait instance-status-ok --instance-ids ${aws_instance.my_server.id}"
  }
  depends_on = [
    aws_instance.my_server
  ]
}

output "public_ip" {
  value = aws_instance.my_server.public_ip
}