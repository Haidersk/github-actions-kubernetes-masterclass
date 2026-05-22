data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

module "jenkins" {
  source        = "../../modules/ec2"

  ami           = var.ami
  instance_type = var.instance_type

  subnet_id     = data.aws_subnets.default.ids[0]

  sg            = "sg-0c1d587650c0f8801"

  key_name      = var.key_name
  name           = "jenkins-server"
}


