resource "aws_security_group" "gitlab_runner" {
  name        = local.gitlab.runner.name
  description = "SG for GitLab Runner"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_security_group" "gitlab" {
  name        = local.gitlab.name
  description = "SG for GitLab"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_security_group_rule" "gitlab_runner_ingress_ssh" {
  description              = "From GitLab SSH"
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.gitlab.id
  security_group_id        = aws_security_group.gitlab_runner.id
}

resource "aws_security_group_rule" "gitlab_runner_ingress_docker" {
  type                     = "ingress"
  description              = "From GitLab docker"
  from_port                = 2376
  to_port                  = 2376
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.gitlab.id
  security_group_id        = aws_security_group.gitlab_runner.id
}

resource "aws_security_group_rule" "gitlab_runner_egress_http" {
  description       = "To Internet"
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.gitlab_runner.id
}

resource "aws_security_group_rule" "gitlab_runner_egress_https" {
  description       = "To Internet"
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.gitlab_runner.id
}

resource "aws_security_group" "egress_internet_access" {
  name        = "egress-internet-access"
  description = "SG for internet access"
  vpc_id      = module.vpc.vpc_id

  egress {
    description = "Internet access https"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Internet access http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "gitlab_ingress_source_cidrs_8080" {
  type              = "ingress"
  description       = "From source cidrs"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = local.source_cidrs
  security_group_id = aws_security_group.gitlab.id
}

resource "aws_security_group_rule" "gitlab_ingress_source_cidrs_8443" {
  type              = "ingress"
  description       = "From source cidrs"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = local.source_cidrs
  security_group_id = aws_security_group.gitlab.id
}

resource "aws_security_group_rule" "gitlab_ingress_runner_8080" {
  type                     = "ingress"
  description              = "From runner"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.gitlab_runner.id
  security_group_id        = aws_security_group.gitlab.id
}

resource "aws_security_group_rule" "gitlab_ingress_runner_8443" {
  type                     = "ingress"
  description              = "From runner"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.gitlab_runner.id
  security_group_id        = aws_security_group.gitlab.id
}

resource "aws_security_group_rule" "gitlab_egress_runner_ssh" {

  type                     = "egress"
  description              = "To runner SSH"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.gitlab_runner.id
  security_group_id        = aws_security_group.gitlab.id
}

resource "aws_security_group_rule" "gitlab_egress_runner_docker" {
  type                     = "egress"
  description              = "To runner docker daemon"
  from_port                = 2376
  to_port                  = 2376
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.gitlab_runner.id
  security_group_id        = aws_security_group.gitlab.id
}
