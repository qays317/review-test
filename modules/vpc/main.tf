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

/*
//==========================================================================================================================================
//                                                             NAT gateaway
//==========================================================================================================================================

resource "aws_eip" "eip" {
  tags = { Name = "wordpress-nat-eip" }
}

resource "aws_nat_gateway" "wordpress" {
  allocation_id = aws_eip.eip.id
  subnet_id = aws_subnet.main[var.nat_gateway_subnet_name].id
  tags = { Name = "wordpress-nat-gateway" }
}
*/
/*
//==========================================================================================================================================
//                                                          Network Firewall
//==========================================================================================================================================

resource "aws_networkfirewall_rule_group" "docker_hub_whitelisted" {
  capacity = 10                             # Maximum number of rules this group can handle - we specify 6 domains
  name = "docker-hub-whitelisted"
  type = "STATEFUL"                         # Tracks connection state (remembers ongoing connections)

  rule_group {
    rules_source {
      rules_source_list {
        generated_rules_type = "ALLOWLIST"
        target_types = ["TLS_SNI"]          # HTTPS traffic only
        targets = [
          "registry-1.docker.io",
          "auth.docker.io", 
          "production.cloudflare.docker.com",
          "index.docker.io",
          "docker.io",
          "registry.docker.io"
        ]
      }
    }
  }
}

resource "aws_networkfirewall_firewall_policy" "firewall_policy" {
  name = "docker-firewall-policy"
  
  firewall_policy {
    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.docker_hub_whitelisted.arn
    }
    
    stateless_default_actions = ["aws:forward_to_sfe"]          # Sends all traffic to the stateful engine for inspection
    stateless_fragment_default_actions = ["aws:forward_to_sfe"] # Sends afragmented packets to the stateful engine
  }
}

resource "aws_networkfirewall_firewall" "network_firewall" {
  name = "wordpress-network-firewall"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.firewall_policy.arn
  vpc_id = aws_vpc.wordpress.id

  subnet_mapping {
    subnet_id = aws_subnet.main[var.networkfirewall_subnet_name].id
  }

  tags = { Name = "wordpress-network-firewall" }
}

*/
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
          //nat_gateway = lookup(r, "nat_gateway", false)
          //network_firewall = lookup(r, "network_firewall", false)
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
    //nat_gateway_id = each.value.nat_gateway ? aws_nat_gateway.wordpress.id : null
    //vpc_endpoint_id = each.value.network_firewall ? tolist(aws_networkfirewall_firewall.network_firewall.firewall_status[0].sync_states)[0].attachment[0].endpoint_id : null
}

resource "aws_route_table_association" "main" {     
  for_each = local.associations
    route_table_id = aws_route_table.main[each.value.rt_key].id
    subnet_id = aws_subnet.main[each.value.subnet_name].id
}