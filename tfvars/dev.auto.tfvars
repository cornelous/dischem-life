region = "af-south-1"
env    = "dev"
owner  = "clive"

vpc_cidr       = "10.16.0.0/16"
public_cidrs   = ["10.16.0.0/24", "10.16.1.0/24"]
private_cidrs  = ["10.16.10.0/24", "10.16.11.0/24"]

# Wide open for demo; narrow to your IP for real use
alb_allow_cidrs = ["0.0.0.0/0"]

instance_type = "t3.micro"

# DB config
db_name              = "appdb"
db_username          = "appuser"
db_engine_version    = "15"  # Let AWS pick latest 15.x available in region
db_instance_class    = "db.t4g.micro"
db_allocated_storage = 20
db_multi_az          = false
