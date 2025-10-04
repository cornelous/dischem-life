module "network" {
  source        = "./modules/network"
  vpc_cidr      = var.vpc_cidr
  public_cidrs  = var.public_cidrs
  private_cidrs = var.private_cidrs
  region        = var.region
}

module "security" {
  source          = "./modules/security"
  vpc_id          = module.network.vpc_id
  alb_allow_cidrs = var.alb_allow_cidrs
}

module "database" {
  source                = "./modules/database"
  vpc_id                = module.network.vpc_id
  private_subnet_ids    = module.network.private_subnet_ids
  db_name               = var.db_name
  db_username           = var.db_username
  db_engine_version     = var.db_engine_version
  db_instance_class     = var.db_instance_class
  db_allocated_storage  = var.db_allocated_storage
  db_multi_az           = var.db_multi_az
  app_sg_id             = module.security.app_sg_id
  env                   = var.env
}
