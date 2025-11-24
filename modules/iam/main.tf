//==========================================================================================================================================
//                                                                IAM
//==========================================================================================================================================

resource "aws_iam_role" "this" {
  name = var.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = var.assume_role_services
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each = toset(var.managed_policy_arns)
    role = aws_iam_role.this.name
    policy_arn = each.value
}

resource "aws_iam_role_policy" "inline" {
  count = length(var.inline_policy_statements) > 0 ? 1 : 0
  name = var.policy_name
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      for s in var.inline_policy_statements : merge(
        {
          Effect = s.Effect
          Action = s.Action
          Resource = s.Resource
        },
        s.Condition != null ? { Condition = s.Condition } : {}
      )
    ]
  })
}


