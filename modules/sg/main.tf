//==========================================================================================================================================
//                                                                 SG
//==========================================================================================================================================

resource "aws_security_group" "main" {
    for_each = var.security_group
      name = each.key
      vpc_id = var.vpc_id
      tags = {
        Name = each.key
        Stage = var.stage_tag
      }
      lifecycle {
        create_before_destroy = true        # New SG → Update resources → Delete old SG
        prevent_destroy = false             # Allows security groups to be destroyed during terraform destroy
      }
}

locals {
  rules = flatten([
    for sg_key, sg in var.security_group : concat(
      # Ingress rules
      [
        for rule_key, rule in (sg.ingress != null ? sg.ingress : {}) : {
          key = "${sg_key}.${rule_key}.ingress"
          sg_key = sg_key
          type = "ingress"
          from_port = rule.from_port
          to_port = rule.to_port
          protocol = rule.ip_protocol
          cidr_block = lookup(rule, "vpc_cidr", false) == true ? var.vpc_cidr : try(rule.cidr_block, null)
          source_security_group_name = lookup(rule, "source_security_group_name", null)
          prefix_list_ids = lookup(rule, "prefix_list_ids", null)
        }
      ],
      # Egress rules
      [
        for rule_key, rule in (sg.egress != null ? sg.egress : {}) : {
          key = "${sg_key}.${rule_key}.egress"
          sg_key = sg_key
          type = "egress"
          from_port = rule.from_port
          to_port = rule.to_port
          protocol = rule.ip_protocol
          cidr_block = lookup(rule, "vpc_cidr", false) == true ? var.vpc_cidr : try(rule.cidr_block, null)
          source_security_group_name = lookup(rule, "source_security_group_name", null)
          prefix_list_ids = lookup(rule, "prefix_list_ids", null)
        }
      ]
    )
  ])
}

resource "aws_security_group_rule" "main" {
  for_each = { for rule in local.rules : rule.key => rule }
  
  type = each.value.type
  from_port = each.value.from_port
  to_port = each.value.to_port
  protocol = each.value.protocol
  security_group_id = aws_security_group.main[each.value.sg_key].id
  
  cidr_blocks = each.value.cidr_block != null ? [each.value.cidr_block] : null
  prefix_list_ids = each.value.prefix_list_ids != null ? each.value.prefix_list_ids : null
  source_security_group_id = each.value.source_security_group_name != null ? (
    contains(keys(aws_security_group.main), each.value.source_security_group_name) ? 
      aws_security_group.main[each.value.source_security_group_name].id : 
      lookup(var.external_security_groups, each.value.source_security_group_name, null)
  ) : null
}