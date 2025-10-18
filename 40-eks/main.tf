resource "aws_key_pair" "eks" {
  key_name   = "expense-eks"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDlKEn9+XMCC/UvB5fN9tl7NwxYJyJPzQXKYfzg5aCy6D9Nf6V3WCS1K8neOwDaXyfHKfRBjf9je6M/rpOPJ+Mi4ni3ROW387kZc4D5Lhxrqet4YftS5+sexDqM7HTYD6cV1D8BNab5d1MHNrBhQWwxXk54jpw3Syq9QrcaUXCxBcDGJ/F3ZfwUZDDdlaLPF4aZYVCnYs4Bpba6eVhZ1VM8asR6c+xVpBEZHNTNrbo58faZeNFYPTOTPe8JbnjA+PRBaMTTw0FjcDZRsUB9YAQsvdmex0DOmyUOgAty+hIzJ3qeD7iqM6iCONSA+nDY/xKxIQFwqtqhFwfTO0lQoaDdMJs0GeJxl+z1poIbAqgz+mCSzxMqdPDoqu9DmODs3kjJs9ab53Hx2/1ntTf1Td/aSGYMtn6tuMIEHU0lZGtpa7Wo7pez/n1B3e9Q7u4gWFz25GHgfd12QJEvo2kp23GTGlhFgAAidbav6GOvwULJOxRhmnibnugOyBVhnpnKXMZs0TRPw/jbdeN2T+poBZC1iv6FBh/ycdyQtqQW6ElXeDbzwnNnaPKBp6W1jOSzzmkXFrQSoAbasDcjFw8Z/sxOMl/zEzdyDVz7LnIpWFx1X1CdBR0A9lS0r1x36f1EpE8WWwCLdW78hsU3zu+KvsAZ3N2aWFnHmDuhz33oG/lojw== Welceme@DESKTOP-BGA4N7S"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.name
  cluster_version = "1.33" # later we upgrade 1.34
  create_node_security_group = false
  create_cluster_security_group = false
  cluster_security_group_id = local.eks_control_plane_sg_id
  node_security_group_id = local.eks_node_sg_id

  #bootstrap_self_managed_addons = false
  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
    metrics-server = {}
  }

  # Optional
  cluster_endpoint_public_access = false

  # Optional: Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true

  vpc_id                   = local.vpc_id
  subnet_ids               = local.private_subnet_ids
  control_plane_subnet_ids = local.private_subnet_ids

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    instance_types = ["t3.large", "t3.small", "m5n.large", "m5zn.large"]
  }

  eks_managed_node_groups = {
    blue = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      #ami_type       = "AL2_x86_64"
      instance_types = ["t3.large"]
      key_name = aws_key_pair.eks.key_name

      min_size     = 1
      max_size     = 2
      desired_size = 2
      iam_role_additional_policies = {
        AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
        AmazonEFSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
        AmazonEKSLoadBalancingPolicy = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
      }
    }

  /*   green = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      #ami_type       = "AL2_x86_64"
      instance_types = ["t3.large"]
      key_name = aws_key_pair.eks.key_name

      min_size     = 1
      max_size     = 2
      desired_size = 2
      iam_role_additional_policies = {
        AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
        AmazonEFSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
        AmazonEKSLoadBalancingPolicy = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
      }
    } */
  }

  tags = merge(
    var.common_tags,
    {
        Name = local.name
    }
  )
}