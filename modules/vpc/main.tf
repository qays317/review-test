//==========================================================================================================================================
//                                                               VPC
//==========================================================================================================================================

resource "aws_vpc" "wordpress" {
  cidr_block = var.vpc.cidr_block
  enable_dns_hostnames = true               # Enable assigning private DNS names to resources (endpoints)
  enable_dns_support = true                 # Enable DNS resolution inside VPC
  tags = { Name = var.vpc.name }
}


//==========================================================================================================================================
//                                                              Subnets
//==========================================================================================================================================

resource "aws_subnet" "main" {
  for_each = var.subnet
    vpc_id = aws_vpc.wordpress.id
    cidr_block = each.value.cidr_block
    availability_zone = each.value.availability_zone
    map_public_ip_on_launch = each.value.map_public_ip_on_launch
    tags = { Name = each.key }
}


//==========================================================================================================================================
//                                                          Internet gateaway
//==========================================================================================================================================

resource "aws_internet_gateway" "wordpress" {
  vpc_id = aws_vpc.wordpress.id
  tags = { Name = "wordpress-igw" }
}


//==========================================================================================================================================
//                                                             route tables
//==========================================================================================================================================

resource "aws_route_table" "main" {                            
  for_each = var.route_table
    vpc_id = aws_vpc.wordpress.id
    tags = { Name = each.key }
}


locals {                                                     
  # merge both routes and associations in one block
  routes = merge([
    for rt_key, rt in var.route_table : {
      for r_key, r in (rt.routes != null ? rt.routes : {}) : 
        "${rt_key}.${r_key}" => {
          rt_key = rt_key
          cidr_block = r.cidr_block
          gateway = lookup(r, "gateway", false)
      }                                 
    }
  ]...)
  associations = merge([
    for rt_key, rt in var.route_table : {
      for sub_key, sub_name in rt.subnets_names : 
        "${rt_key}.${sub_key}" => {
          rt_key = rt_key
          subnet_name = sub_name
      }
    }
  ]...)
}

resource "aws_route" "main" {
  for_each = local.routes
    route_table_id = aws_route_table.main[each.value.rt_key].id
    destination_cidr_block = each.value.cidr_block
    gateway_id = each.value.gateway ? aws_internet_gateway.wordpress.id : null
}

resource "aws_route_table_association" "main" {     
  for_each = local.associations
    route_table_id = aws_route_table.main[each.value.rt_key].id
    subnet_id = aws_subnet.main[each.value.subnet_name].id
}