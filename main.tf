provider "aws" {
  region = var.region
}

module "vpc" {
  source = "./modules/vpc"
}

module "alb" {
  source     = "./modules/alb"
  vpc_id     = module.vpc.vpc_id
  subnets    = module.vpc.public_subnets
  alb_sg_id  = module.ecs.alb_sg_id
}

module "iam" {
  source = "./modules/iam"
}

module "ecs" {
  source               = "./modules/ecs"
  cluster_name         = "ecs-cluster"
  vpc_id               = module.vpc.vpc_id
  subnets              = module.vpc.public_subnets
  task_exec_role_arn   = module.iam.ecs_task_execution_role_arn
  target_group_arn     = module.alb.target_group_arn
  alb_sg_id            = module.alb.alb_sg_id
}