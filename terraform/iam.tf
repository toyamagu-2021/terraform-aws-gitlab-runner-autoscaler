data "aws_iam_policy_document" "assume_role_ec2" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "gitlab" {
  name               = local.gitlab.name
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.assume_role_ec2.json
}

resource "aws_iam_role_policy_attachment" "gitlab_runner" {
  role       = aws_iam_role.gitlab.name
  policy_arn = aws_iam_policy.runner.arn
}

resource "aws_iam_role_policy_attachment" "gitlab_ssm" {
  role       = aws_iam_role.gitlab.name
  policy_arn = data.aws_iam_policy.AmazonSSMManagedInstanceCore.arn
}

resource "aws_iam_role_policy_attachment" "gitlab_machine" {
  role       = aws_iam_role.gitlab.name
  policy_arn = aws_iam_policy.instance_machine.arn
}


data "aws_iam_policy" "AmazonSSMManagedInstanceCore" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "gitlab" {
  name = local.gitlab.name
  role = aws_iam_role.gitlab.name
}

resource "aws_iam_policy" "runner" {
  name   = local.gitlab.runner.name
  path   = "/"
  policy = data.aws_iam_policy_document.runner.json
}

data "aws_iam_policy_document" "runner" {
  statement {
    # Ref: https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runnerscaches3-section
    sid       = "allowGitLabRunnersAccessCache"
    effect    = "Allow"
    resources = ["${aws_s3_bucket.runner_cache.arn}/*"]

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:DeleteObject"
    ]
  }

  dynamic "statement" {
    for_each = local.s3_runner_cache.cmk_provided ? { "name" = "kms" } : {}
    content {
      # Ref: https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runnerscaches3-section
      sid    = "allowGitLabRunnersAccessCacheKms"
      effect = "Allow"
      resources = [
        data.aws_kms_key.runner_cache[0].arn
      ]

      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey",
      ]
    }
  }

  # Needed only for GitLab bootstrap ( `aws s3 sync` ) 
  statement {
    sid       = "allowGitLabRunnersAccessCacheListBucket"
    effect    = "Allow"
    resources = [aws_s3_bucket.runner_cache.arn]

    actions = [
      "s3:ListBucket",
    ]
  }
}

# Instance docker machine 
# Required for GitLab Runner Docker Machine to manage child instances
resource "aws_iam_policy" "instance_machine" {
  name   = local.gitlab.runner.machine.name
  path   = "/"
  policy = data.aws_iam_policy_document.instance_machine.json
}

data "aws_iam_policy_document" "instance_machine" {
  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "ec2:DescribeKeyPairs",
      "ec2:TerminateInstances",
      "ec2:StopInstances",
      "ec2:StartInstances",
      "ec2:RunInstances",
      "ec2:RebootInstances",
      "ec2:CreateKeyPair",
      "ec2:DeleteKeyPair",
      "ec2:ImportKeyPair",
      "ec2:Describe*",
      "ec2:CreateTags",
      "ec2:RequestSpotInstances",
      "ec2:CancelSpotInstanceRequests",
      "ec2:DescribeSubnets",
      "ec2:AssociateIamInstanceProfile",
    ]
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = [aws_iam_role.machine.arn]
    actions   = ["iam:PassRole"]
  }
}

# Docker machine (child runner)
resource "aws_iam_instance_profile" "machine" {
  name = local.gitlab.runner.machine.name
  role = aws_iam_role.machine.name
}

resource "aws_iam_role" "machine" {
  name               = local.gitlab.runner.machine.name
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.assume_role_ec2.json
}

resource "aws_iam_role_policy_attachment" "machine_ssm" {
  role       = aws_iam_role.machine.name
  policy_arn = data.aws_iam_policy.AmazonSSMManagedInstanceCore.arn
}
