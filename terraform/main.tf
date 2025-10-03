module "network" {
  source        = "./modules/network"
  vpc_cidr      = var.vpc_cidr
  public_cidrs  = var.public_cidrs
  private_cidrs = var.private_cidrs
  region        = var.region
}
