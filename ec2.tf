# configured aws provider with proper credentials
provider "aws" {
  region    = "us-east-1"
  profile   = "unclepeejay"
}


# create default vpc if one does not exists
resource "aws_default_vpc" "default_vpc" {

  tags    = {
    Name  = "mydefault vpc1"
  }
}


# use data source to get all avalablility zones in region
data "aws_availability_zones" "available_zones" {}


# create default subnet if one does not exit
resource "aws_default_subnet" "default_az1" {
  availability_zone = data.aws_availability_zones.available_zones.names[0]

  tags   = {
    Name = "my default subnet1"
  }
}

resource "aws_default_subnet" "default_az2" {
  availability_zone = data.aws_availability_zones.available_zones.names[1]

  tags   = {
    Name = "my default subnet2"
  }
}


# create security group for the ec2 instance
resource "aws_security_group" "ec2_security_group" {
  name        = "ec2 security group1"
  description = "allow access on ports 8080 and 22"
  vpc_id      = aws_default_vpc.default_vpc.id

  # allow access on port 8080
  ingress {
    description      = "http proxy access"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  # allow access on port 22
  ingress {
    description      = "ssh access"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags   = {
    Name = "Jenkins server security group"
  }
}

# use data source to get a registered amazon linux 2 ami
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}


# Amazon EKS Cluster
resource "aws_eks_cluster" "eks_cluster" {
  name     = "my-eks-cluster1"  
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]
  }

  depends_on = [
    aws_default_vpc.default_vpc,
  ]
}


resource "aws_iam_role" "eks_cluster" {
  name = "eks-cluster-role1"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}



 resource "aws_iam_role" "eks_node_group" {
  name = "eks-node-group-role1"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}
resource "aws_eks_node_group" "eks_nodes" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "eks-node-group1"
  node_role_arn = aws_iam_role.eks_node_group.arn

  subnet_ids = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]
  instance_types = ["t2.micro"]  

scaling_config {
   desired_size = 2
  min_size     = 1
  max_size     = 2
}


  launch_template {
    name            = "eks-node-launch-template"
    version         = "$Latest"  
    id              = aws_instance.ec2_instance.id
   # update_default_version = true
  }

  depends_on = [
    aws_eks_cluster.eks_cluster,
  ]
}

# launch the ec2 instance 
resource "aws_instance" "ec2_instance" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t2.micro"
  subnet_id              = aws_default_subnet.default_az1.id
  vpc_security_group_ids = [aws_security_group.ec2_security_group.id]
  key_name               = "MyLinuxKP"
  # user_data            = file("install_jenkins.sh")

  tags = {
    Name = "My Jenkins server"
  }
}

resource "aws_ecr_repository" "my_ecr_repo" {
  name = "my-ecr-repository"  
  image_tag_mutability = "MUTABLE"
  
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    name = "My ECR Repository"
    env = "Production"
  }
}


# an empty resource block
resource "null_resource" "name" {

  # ssh into the ec2 instance 
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("MyLinuxKP.pem")
    host        = aws_instance.ec2_instance.public_ip
  }

  # copy the install_jenkins.sh file from your computer to the ec2 instance 
  provisioner "file" {
    source      = "install_jenkins.sh"
    destination = "/tmp/install_jenkins.sh"
  }

  # set permissions and run the install_jenkins.sh file
  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/install_jenkins.sh",
      "sh /tmp/install_jenkins.sh"
    ]
  }

  # wait for ec2 to be created
  depends_on = [aws_instance.ec2_instance]
}


# print the url of the jenkins server
output "website_url" {
  value     = join ("", ["http://", aws_instance.ec2_instance.public_dns, ":", "8080"])
}

#print the url to our ECR Repository
output "ecr_repo_url" {
  value = aws_ecr_repository.my_ecr_repo.repository_url
}