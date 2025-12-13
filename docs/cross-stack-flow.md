# **Cross-Stack Dependency Map**
```
┌─────────────────────────────────────────────┐
│                 global/iam                  │
|  INPUTS:                                    |
|   • primary_region                          |
|   • dr_region                               |
|   • primary_media_s3_bucket                 |
|   • dr_media_s3_bucket                      |
|   • rds_identifier                          |
│  OUTPUTS:                                   │
|   • lambda_db_setup_role_arn ───────────────┼─────▶ used by primary/network_rds
│   • ecs_execution_role_arn ─────────────────┼─────▶ used by primary/ecs, dr/ecs
│   • ecs_task_role_arn ──────────────────────┼─────▶ used by primary/s3, primary/ecs, dr/ecs
│   • s3_replication_role_arn ────────────────┼─────▶ used by dr/s3
└─────────────────────────────────────────────┘
┌─────────────────────────────────────────────┐
│                 global/oac                  │
│  OUTPUTS:                                   │
│   • oac_id ─────────────────────────────────┼─────▶ used by global/cdn_dns
└─────────────────────────────────────────────┘
┌─────────────────────────────────────────────┐
│                 primary/network_rds         │
|  INPUTS:                                    |
|   • lambda_db_setup_role_arn                |  
|   • rds_identifier                          |  
│  OUTPUTS:                                   │
|   • vpc_id ─────────────────────────────────┼─────▶ used by primary/alb, primary/ecs
│   • vpc_cidr ───────────────────────────────┼─────▶ used by primary/alb
│   • private_subnets_ids ────────────────────┼─────▶ used by primary/ecs
|   • public_subnets_ids ─────────────────────┼─────▶ used by primary/alb   
|   • rds_identifier ─────────────────────────┼─────▶ used by dr/read_replica_rds            
|   • wordpress_secret_id ────────────────────┼─────▶ used by dr/read_replica_rds
|   • wordpress_secret_arn ───────────────────┼─────▶ used by primary/ecs
└─────────────────────────────────────────────┘
┌─────────────────────────────────────────────┐
│                 dr/network                  │
│  OUTPUTS:                                   │
|   • vpc_id ─────────────────────────────────┼─────▶ used by dr/read_replica_rds, dr/alb, dr/ecs
│   • vpc_cidr ───────────────────────────────┼─────▶ used by dr/read_replica_rds, dr/alb
│   • private_subnets_ids ────────────────────┼─────▶ used by dr/read_replica_rds, dr/ecs
|   • public_subnets_ids ─────────────────────┼─────▶ used by dr/alb         
└─────────────────────────────────────────────┘
┌─────────────────────────────────────────────┐
│                 primary/s3                  │
|  INPUTS:                                    |
|   • s3_bucket_name                          |
|   • cloudfront_distribution_arn             |
|   • s3_vpc_endpoint_id                      |
|   • ecs_task_role_arn                       |
│  OUTPUTS:                                   │
|   • bucket_name ────────────────────────────┼─────▶ used by dr/s3, primary/ecs
│   • bucket_regional_domain_name ────────────┼─────▶ used by global/cdn_dns
|   • bucket_arn ─────────────────────────────┼─────▶ used by dr/s3 
└─────────────────────────────────────────────┘
┌─────────────────────────────────────────────┐
│                 primary/alb                 │
|  INPUTS:                                    |
|   • vpc_id                                  |
|   • vpc_cidr                                |
|   • public_subnets_ids                      |
|   • primary_domain                          |
|   • hosted_zone_id                          |
|   • provided_ssl_certificate_arn            |
|   • certificate_sans                        |
│  OUTPUTS:                                   │
│   • alb_dns_name ───────────────────────────┼─────▶ used by global/cdn_dns
│   • alb_zone_id ────────────────────────────┼─────▶ used by global/cdn_dns (to create a Route 53 primary record for admin access)
│   • target_group_arn ───────────────────────┼─────▶ used by primary/ecs
|   • target_group_arn_suffix ────────────────┼─────▶ used by primary/ecs
|   • alb_arn_suffix ─────────────────────────┼─────▶ used by primary/ecs
└─────────────────────────────────────────────┘
┌─────────────────────────────────────────────┐
│                 dr/read_replica_rds         │
|  INPUTS:                                    |
|   • vpc_id                                  |
|   • vpc_cidr                                |
|   • private_subnets_ids                     |
|   • rds_identifier                          |
|   • wordpress_secret_id                     |
│  OUTPUTS:                                   │
│   • wordpress_secret_arn ───────────────────┼─────▶ used by dr/ecs 
└─────────────────────────────────────────────┘
┌─────────────────────────────────────────────┐
│                 dr/s3                       │
|  INPUTS:                                    |
|   • s3_bucket_name                          |
|   • cloudfront_distribution_arn             |
|   • s3_vpc_endpoint_id                      |
|   • ecs_task_role_arn                       |
|   • s3_replication_role_arn                 |
|   • bucket_name                             |
│  OUTPUTS:                                   │
|   • bucket_name ────────────────────────────┼─────▶ used by dr/ecs
│   • bucket_regional_domain_name ────────────┼─────▶ used by global/cdn_dns
└─────────────────────────────────────────────┘
┌─────────────────────────────────────────────┐
│                 dr/alb                      │
|  INPUTS:                                    |
|   • vpc_id                                  |
|   • vpc_cidr                                |
|   • public_subnets_ids                      |
|   • primary_domain                          |
|   • hosted_zone_id                          |
|   • provided_ssl_certificate_arn            |
|   • certificate_sans                        |
│  OUTPUTS:                                   │
│   • alb_dns_name ───────────────────────────┼─────▶ used by global/cdn_dns
│   • alb_zone_id ────────────────────────────┼─────▶ used by global/cdn_dns (to create a Route 53 secondary record for admin access)
│   • target_group_arn ───────────────────────┼─────▶ used by dr/ecs
|   • target_group_arn_suffix ────────────────┼─────▶ used by dr/ecs 
|   • alb_arn_suffix ─────────────────────────┼─────▶ used by dr/ecs
└─────────────────────────────────────────────┘
┌─────────────────────────────────────────────┐
│                 global/cdn_dns              │
|  INPUTS:                                    |
|   • oac_id                                  |
|   • primary_alb_dns_name                    |
|   • primary_alb_zone_id                     |
|   • dr_alb_dns_name                         |
|   • dr_alb_zone_id                          |
|   • primary_bucket_regional_domain_name     |
|   • dr_bucket_regional_domain_name          |
|   • primary_domain                          |
|   • hosted_zone_id                          |
|   • provided_ssl_certificate_arn            |
|   • certificate_sans                        |
│  OUTPUTS:                                   │
│   • cloudfront_distribution_arn ────────────┼─────▶ used by primary/s3, dr/s3
│   • cloudfront_distribution_domain ─────────┼─────▶ used by primary/ecs, dr/ecs
│   • cloudfront_distribution_id ─────────────┼─────▶ used by primary/ecs, dr/ecs
└─────────────────────────────────────────────┘
┌─────────────────────────────────────────────┐
│                 primary/ecs                 │
|  INPUTS:                                    |
|   • vpc_id                                  |
|   • private_subnets_ids                     |
|   • wordpress_secret_arn                    |
|   • target_group_arn                        |
|   • target_group_arn_suffix                 |
|   • alb_arn_suffix                          |
|   • primary_s3_bucket_name                  |
|   • primary_domain                          |
|   • cloudfront_distribution_domain          |
|   • cloudfront_distribution_id              |
|   • ecr_image_uri                           |
|   • ecs_execution_role_arn                  |
|   • ecs_task_role_arn                       |
│  OUTPUTS:                                   │
│   • s3_vpc_endpoint_id ─────────────────────┼─────▶ used by primary/s3
└─────────────────────────────────────────────┘
┌─────────────────────────────────────────────┐
│                 dr/ecs                      │
|  INPUTS:                                    |
|   • vpc_id                                  |
|   • private_subnets_ids                     |
|   • wordpress_secret_arn                    |
|   • target_group_arn                        |
|   • target_group_arn_suffix                 |
|   • alb_arn_suffix                          |
|   • dr_s3_bucket_name                       |
|   • primary_domain                          |
|   • cloudfront_distribution_id              |
|   • cloudfront_distribution_domain          |
|   • ecr_image_uri                           |
|   • ecs_execution_role_arn                  |
|   • ecs_task_role_arn                       |
│  OUTPUTS:                                   │
│   • s3_vpc_endpoint_id ─────────────────────┼─────▶ used by dr/s3
└─────────────────────────────────────────────┘

```