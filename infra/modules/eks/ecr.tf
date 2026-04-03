resource "aws_ecr_repository" "ecr_repos" {
  for_each = var.aws_ecr_repository_names
  name = each.value

  image_tag_mutability = "MUTABLE"

}