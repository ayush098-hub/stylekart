variable "cluster_name" {
  type = string
}

variable "k8s_version" {
 type = string 
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "instance_types" {
  type = list(string)
}
variable "desired_size" {
  type = number
}
variable "min_size" {
  type = number
}
variable "max_size" {
  type = number
}

#----ecr variables---

variable "aws_ecr_repository_names" {
  type = map(string)
}