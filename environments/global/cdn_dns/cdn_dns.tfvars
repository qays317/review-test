/*cloudfront_distribution_config = {
    wordpress-media = {
        s3_origin = true
        price_class = "PriceClass_100"      # US, Canada, Europe
        cache_behavior = {
            allowed_methods = ["GET", "HEAD", "OPTIONS"]
            cached_methods = ["GET", "HEAD"]
            ttl_min = 0
            ttl_default = 86400     # 1 day
            ttl_max = 31536000      # 1 year
        }
    }
    wordpress-app = {
        //alb_origin = true
        //s3_origin = true
        price_class = "PriceClass_100"
        cache_behavior = {
            allowed_methods = ["GET", "HEAD", "OPTIONS"]
            cached_methods = ["GET", "HEAD"]
            ttl_min = 0
            ttl_default = 0     # No caching for dynamic content
            ttl_max = 300       # Max 5 minutes for any caching
            forward_headers = ["Host", "CloudFront-Forwarded-Proto"]
            forward_cookies = "all"
            forward_query_string = true
        }
    }
}               

*/