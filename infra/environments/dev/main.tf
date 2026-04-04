module "vpc" {
    source = "../../modules/vpc"
    vpc_name = "dev_vpc"
    cidr_block = "10.0.0.0/24"
    public_subnet_1_cidr = "10.0.0.0/26"
    public_subnet_2_cidr = "10.0.0.64/26"
    private_subnet_1_cidr = "10.0.0.128/26"
    private_subnet_2_cidr = "10.0.0.192/26"
    az1 = "ap-south-1a"
    az2 = "ap-south-1b"
}

module "eks" {
  source = "../../modules/eks"
  cluster_name = "stylekart"
  k8s_version = "1.31"
  instance_types = [ "t3.medium" ]
  max_size = 1
  min_size = 1
  desired_size = 1
  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  aws_ecr_repository_names = {
  user  = "user-service"
  order = "order-service"
  payment = "payment-service"
  product = "product-service"
  apigateway = "api-gateway-service"
  db = "db-service"
  frotnend = "frontend-service"  
  
  }
}

module "irsa_ebs_csi" {
  source = "../../modules/irsa"
  role_name = "${module.eks.cluster_name}-ebs-csi-driver-role"
  service_account_name = "ebs-csi-controller-sa"
  oidc_provider_url = module.eks.oidc_provider_url
  oidc_provider_arn = module.eks.oidc_provider_arn
  policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"]
}

module "irsa_alb_controller" {
  source               = "../../modules/irsa"
  role_name            = "stylekart-alb-controller-role"
  service_account_name = "aws-load-balancer-controller"
  oidc_provider_url    = module.eks.oidc_provider_url
  oidc_provider_arn    = module.eks.oidc_provider_arn
  policy_arns          = ["arn:aws:iam::397920213006:policy/AWSLoadBalancerControllerIAMPolicy"]
}