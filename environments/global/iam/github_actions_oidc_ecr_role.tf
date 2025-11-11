terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}

data "aws_caller_identity" "current" {}

# Change these if different
locals {
  github_owner  = "qaysalnajjad"
  github_repo   = "test"
  ecr_repo_name = "ecs-wordpress-app"
  aws_region    = "us-east-1"
}

# Create OIDC provider for GitHub Actions (idempotent: will error if another provider with same URL exists;
# if you already created the provider manually, you can remove this resource and reference the existing provider ARN)
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
  client_id_list = [
    "sts.amazonaws.com"
  ]
  # GitHub's CA thumbprint (common value used in examples). Replace if your security process requires a different value.
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
  tags = {
    created_by = "terraform"
  }
}

# IAM role that GitHub Actions will assume
resource "aws_iam_role" "github_actions_ecr_pusher" {
  name = "github-actions-ecr-pusher"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringLike = {
            # Restrict to your repo and any branch; change to narrow further (e.g., refs/tags/*)
            "token.actions.githubusercontent.com:sub" = "repo:${local.github_owner}/${local.github_repo}:ref:refs/heads/*"
          }
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
  tags = {
    created_by = "terraform"
  }
}

# Least-privilege policy: allow token retrieval (global) and ECR push operations scoped to a specific repo.
data "aws_iam_policy_document" "ecr_push" {
  statement {
    sid = "GetAuth"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"] # required for GetAuthorizationToken
  }

  statement {
    sid = "ECRWriteToRepo"
    effect = "Allow"
    actions = [
      "ecr:DescribeRepositories",
      "ecr:CreateRepository",
      "ecr:BatchCheckLayerAvailability",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
      "ecr:PutImageTagMutability",
      "ecr:SetRepositoryPolicy",
      "ecr:GetRepositoryPolicy"
    ]
    resources = [
      "arn:aws:ecr:${local.aws_region}:${data.aws_caller_identity.current.account_id}:repository/${local.ecr_repo_name}"
    ]
  }
}

resource "aws_iam_policy" "github_actions_ecr_policy" {
  name        = "github-actions-ecr-pusher-policy"
  description = "Policy to allow GitHub Actions to push images to ECR (scoped to known repo)."
  policy      = data.aws_iam_policy_document.ecr_push.json
  tags = {
    created_by = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "attach_policy" {
  role       = aws_iam_role.github_actions_ecr_pusher.name
  policy_arn = aws_iam_policy.github_actions_ecr_policy.arn
}

# Helpful outputs for CI wiring
output "github_actions_ecr_role_arn" {
  value = aws_iam_role.github_actions_ecr_pusher.arn
  description = "Role ARN to use in GitHub Actions 'role-to-assume' (OIDC)."
}

output "github_actions_ecr_role_name" {
  value = aws_iam_role.github_actions_ecr_pusher.name
  description = "Role name (useful in console)."
}

output "ecr_repo_arn_example" {
  value = "arn:aws:ecr:${local.aws_region}:${data.aws_caller_identity.current.account_id}:repository/${local.ecr_repo_name}"
  description = "The ECR repo ARN this policy allows (update local.ecr_repo_name if you use a different repo)."
}