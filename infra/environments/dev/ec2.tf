resource "aws_iam_role" "ec2_ssm_role" {
  name = "${module.eks.cluster_name}-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Needed to run: aws eks update-kubeconfig
resource "aws_iam_role_policy" "eks_access" {
  name = "eks-access"
  role = aws_iam_role.ec2_ssm_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["eks:DescribeCluster"]
      Resource = "*"
    }]
  })
}

# Needed for SSM session (no SSH required)
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_ssm_profile" {
  name = "${module.eks.cluster_name}-ec2-ssm-profile"
  role = aws_iam_role.ec2_ssm_role.name
}

resource "aws_security_group" "private_ec2_sg" {
  name   = "${module.eks.cluster_name}-private-ec2-sg"
  vpc_id = module.vpc.vpc_id

  # SSM and kubectl only need outbound — no inbound rules needed
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "private_instance" {
  ami                         = "ami-045443a70fafb8bbc"
  instance_type               = "t3.micro"
  subnet_id                   = module.vpc.private_subnets[0]
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.private_ec2_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_ssm_profile.name

  # Install tools on boot
  user_data = <<-EOF
    #!/bin/bash
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl && sudo mv kubectl /usr/local/bin/
    aws eks update-kubeconfig --region us-east-1 --name ${module.eks.cluster_name}
  EOF

  tags = {
    Name = "${module.eks.cluster_name}-private-instance"
  }
}

# ✅ THIS IS THE MISSING PIECE — K8s authorization for the EC2 role
resource "aws_eks_access_entry" "jump_server" {
  cluster_name  = module.eks.cluster_name
  principal_arn = aws_iam_role.ec2_ssm_role.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "jump_server" {
  cluster_name  = module.eks.cluster_name
  principal_arn = aws_iam_role.ec2_ssm_role.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

resource "aws_eks_access_entry" "iam_user" {
  cluster_name  = module.eks.cluster_name
  principal_arn = "arn:aws:iam::397920213006:user/ayush"
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "iam_user_admin" {
  cluster_name  = module.eks.cluster_name
  principal_arn = "arn:aws:iam::397920213006:user/ayush"

  policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

resource "aws_security_group_rule" "allow_ec2_to_eks" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"

  security_group_id        = module.eks.cluster_security_group_id
  source_security_group_id = aws_security_group.private_ec2_sg.id

  depends_on = [ module.eks ]
} 