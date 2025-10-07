locals {
  name_prefix = "${var.project_name}-${var.environment}"

  lb_subnet_ids = length(var.lb_subnet_ids) > 0 ? var.lb_subnet_ids : var.subnet_ids

  mimir_bucket  = var.enable_mimir_bucket ? (var.mimir_bucket_name != "" ? var.mimir_bucket_name : "${local.name_prefix}-mimir-${random_id.bucket_suffix.hex}") : ""
  loki_bucket   = var.enable_loki_bucket ? (var.loki_bucket_name != "" ? var.loki_bucket_name : "${local.name_prefix}-loki-${random_id.bucket_suffix.hex}") : ""
  tempo_bucket  = var.enable_tempo_bucket ? (var.tempo_bucket_name != "" ? var.tempo_bucket_name : "${local.name_prefix}-tempo-${random_id.bucket_suffix.hex}") : ""
  backup_bucket = var.enable_backup_bucket ? (var.backup_bucket_name != "" ? var.backup_bucket_name : "${local.name_prefix}-backups-${random_id.bucket_suffix.hex}") : ""

  # Fixed ports - not configurable
  wizard_port       = 9443
  grafana_port      = 443
  loki_port         = 3100
  otel_grpc_port    = 4317
  otel_http_port    = 4318
  tempo_http_port   = 3200
  tempo_grpc_port   = 9095
  mimir_port        = 9009
  prometheus_port   = 9090
  alertmanager_port = 9093

  # Get VPC CIDR
  vpc_cidr   = var.vpc_cidr != "" ? var.vpc_cidr : data.aws_vpc.selected.cidr_block
  stack_name = "dm-${random_id.stack_suffix.hex}"
}

data "aws_vpc" "selected" {
  id = var.vpc_id
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "random_id" "stack_suffix" {
  byte_length = 4
}

resource "aws_security_group" "monitoring" {
  name_prefix = "${local.name_prefix}-monitoring-"
  description = "Security group for monitoring stack"
  vpc_id      = var.vpc_id

  # Allow all traffic within VPC
  ingress {
    description = "Allow all traffic from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [local.vpc_cidr]
  }

  # Allow traffic from self (for inter-instance communication)
  ingress {
    description = "Allow all from self"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  # Ports opened between ec2 instances in this cluster
  dynamic "ingress" {
    for_each = var.internal_ports
    content {
      description = "Internal port ${ingress.value}"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      self        = true
    }
  }

  # Optional external access for specific ports
  dynamic "ingress" {
    for_each = length(var.allowed_external_cidrs) > 0 ? [1] : []
    content {
      description = "Wizard"
      from_port   = local.wizard_port
      to_port     = local.wizard_port
      protocol    = "tcp"
      cidr_blocks = var.allowed_external_cidrs
    }
  }

  dynamic "ingress" {
    for_each = length(var.allowed_external_cidrs) > 0 ? [1] : []
    content {
      description = "SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.allowed_external_cidrs
    }
  }

  # Optional external access for specific ports
  dynamic "ingress" {
    for_each = length(var.allowed_external_cidrs) > 0 ? [1] : []
    content {
      description = "Grafana HTTPS from external"
      from_port   = local.grafana_port
      to_port     = local.grafana_port
      protocol    = "tcp"
      cidr_blocks = var.allowed_external_cidrs
    }
  }

  dynamic "ingress" {
    for_each = length(var.allowed_external_cidrs) > 0 ? [1] : []
    content {
      description = "Loki from external"
      from_port   = local.loki_port
      to_port     = local.loki_port
      protocol    = "tcp"
      cidr_blocks = var.allowed_external_cidrs
    }
  }

  dynamic "ingress" {
    for_each = length(var.allowed_external_cidrs) > 0 ? [1] : []
    content {
      description = "OpenTelemetry gRPC from external"
      from_port   = local.otel_grpc_port
      to_port     = local.otel_grpc_port
      protocol    = "tcp"
      cidr_blocks = var.allowed_external_cidrs
    }
  }

  dynamic "ingress" {
    for_each = length(var.allowed_external_cidrs) > 0 ? [1] : []
    content {
      description = "OpenTelemetry HTTP from external"
      from_port   = local.otel_http_port
      to_port     = local.otel_http_port
      protocol    = "tcp"
      cidr_blocks = var.allowed_external_cidrs
    }
  }

  dynamic "ingress" {
    for_each = length(var.allowed_external_cidrs) > 0 ? [1] : []
    content {
      description = "Tempo HTTP from external"
      from_port   = local.tempo_http_port
      to_port     = local.tempo_http_port
      protocol    = "tcp"
      cidr_blocks = var.allowed_external_cidrs
    }
  }

  dynamic "ingress" {
    for_each = length(var.allowed_external_cidrs) > 0 ? [1] : []
    content {
      description = "Tempo gRPC from external"
      from_port   = local.tempo_grpc_port
      to_port     = local.tempo_grpc_port
      protocol    = "tcp"
      cidr_blocks = var.allowed_external_cidrs
    }
  }

  dynamic "ingress" {
    for_each = length(var.allowed_external_cidrs) > 0 ? [1] : []
    content {
      description = "Mimir from external"
      from_port   = local.mimir_port
      to_port     = local.mimir_port
      protocol    = "tcp"
      cidr_blocks = var.allowed_external_cidrs
    }
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name = "${local.name_prefix}-monitoring-sg"
    },
    var.tags
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role" "monitoring" {
  count = var.iam_instance_profile == "" ? 1 : 0

  name_prefix = "${local.name_prefix}-monitoring-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "monitoring_core" {
  count = var.iam_instance_profile == "" ? 1 : 0

  name_prefix = "${local.name_prefix}-core-access-"
  role        = aws_iam_role.monitoring[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      # Always allow EC2 describe permissions
      [{
        Sid    = "AllowReadingTagsInstancesRegionsFromEC2"
        Effect = "Allow"
        Action = [
          "ec2:DescribeTags",
          "ec2:DescribeInstances",
          "ec2:DescribeRegions"
        ]
        Resource = "*"
      }],
      # S3 bucket permissions
      local.mimir_bucket != "" ? [{
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::${local.mimir_bucket}",
          "arn:aws:s3:::${local.mimir_bucket}/*"
        ]
      }] : [],
      local.loki_bucket != "" ? [{
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::${local.loki_bucket}",
          "arn:aws:s3:::${local.loki_bucket}/*"
        ]
      }] : [],
      local.tempo_bucket != "" ? [{
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::${local.tempo_bucket}",
          "arn:aws:s3:::${local.tempo_bucket}/*"
        ]
      }] : [],
      local.backup_bucket != "" ? [{
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::${local.backup_bucket}",
          "arn:aws:s3:::${local.backup_bucket}/*"
        ]
      }] : []
    )
  })
}

resource "aws_iam_role_policy" "monitoring_cloudwatch" {
  count = var.iam_instance_profile == "" && var.enable_cloudwatch_datasource ? 1 : 0

  name_prefix = "${local.name_prefix}-cloudwatch-"
  role        = aws_iam_role.monitoring[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowReadingMetricsFromCloudWatch"
        Effect = "Allow"
        Action = [
          "cloudwatch:DescribeAlarmsForMetric",
          "cloudwatch:DescribeAlarmHistory",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:GetMetricWidgetImage",
          "cloudwatch:ListDashboards"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowReadingLogsFromCloudWatch"
        Effect = "Allow"
        Action = [
          "logs:DescribeLogGroups",
          "logs:GetLogGroupFields",
          "logs:StartQuery",
          "logs:StopQuery",
          "logs:GetQueryResults",
          "logs:GetLogEvents"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowReadingResourcesForTags"
        Effect = "Allow"
        Action = [
          "tag:GetResources"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  count = var.iam_instance_profile == "" && var.enable_ssm ? 1 : 0

  role       = aws_iam_role.monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  count = var.iam_instance_profile == "" && var.enable_cloudwatch_logs ? 1 : 0

  role       = aws_iam_role.monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "monitoring" {
  count = var.iam_instance_profile == "" ? 1 : 0

  name_prefix = "${local.name_prefix}-monitoring-"
  role        = aws_iam_role.monitoring[0].name

  tags = var.tags
}

resource "aws_s3_bucket" "mimir" {
  count = var.enable_mimir_bucket ? 1 : 0

  bucket        = local.mimir_bucket
  force_destroy = var.bucket_force_destroy

  tags = merge(
    {
      Name    = local.mimir_bucket
      Purpose = "Mimir Storage"
    },
    var.tags
  )

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "mimir" {
  count = var.enable_mimir_bucket && var.bucket_versioning ? 1 : 0

  bucket = aws_s3_bucket.mimir[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "mimir" {
  count = var.enable_mimir_bucket && var.bucket_encryption ? 1 : 0

  bucket = aws_s3_bucket.mimir[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket" "loki" {
  count = var.enable_loki_bucket ? 1 : 0

  bucket        = local.loki_bucket
  force_destroy = var.bucket_force_destroy

  tags = merge(
    {
      Name    = local.loki_bucket
      Purpose = "Loki Storage"
    },
    var.tags
  )

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "loki" {
  count = var.enable_loki_bucket && var.bucket_versioning ? 1 : 0

  bucket = aws_s3_bucket.loki[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "loki" {
  count = var.enable_loki_bucket && var.bucket_encryption ? 1 : 0

  bucket = aws_s3_bucket.loki[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket" "tempo" {
  count = var.enable_tempo_bucket ? 1 : 0

  bucket        = local.tempo_bucket
  force_destroy = var.bucket_force_destroy

  tags = merge(
    {
      Name    = local.tempo_bucket
      Purpose = "Tempo Storage"
    },
    var.tags
  )

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "tempo" {
  count = var.enable_tempo_bucket && var.bucket_versioning ? 1 : 0

  bucket = aws_s3_bucket.tempo[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tempo" {
  count = var.enable_tempo_bucket && var.bucket_encryption ? 1 : 0

  bucket = aws_s3_bucket.tempo[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket" "backup" {
  count = var.enable_backup_bucket ? 1 : 0

  bucket        = local.backup_bucket
  force_destroy = var.bucket_force_destroy

  tags = merge(
    {
      Name    = local.backup_bucket
      Purpose = "Backups"
    },
    var.tags
  )

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "backup" {
  count = var.enable_backup_bucket && var.bucket_versioning ? 1 : 0

  bucket = aws_s3_bucket.backup[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backup" {
  count = var.enable_backup_bucket && var.bucket_encryption ? 1 : 0

  bucket = aws_s3_bucket.backup[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_cloudwatch_log_group" "monitoring" {
  count = var.enable_cloudwatch_logs ? 1 : 0

  name              = "/aws/ec2/${local.name_prefix}"
  retention_in_days = var.cloudwatch_retention_days

  tags = var.tags
}

resource "tls_private_key" "ssh" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "aws_instance" "monitoring" {
  count = var.enable_auto_scaling ? 0 : var.instance_count

  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_ids[count.index % length(var.subnet_ids)]
  vpc_security_group_ids = [aws_security_group.monitoring.id]
  key_name               = var.key_pair_name != "" ? var.key_pair_name : null

  iam_instance_profile = var.iam_instance_profile != "" ? var.iam_instance_profile : aws_iam_instance_profile.monitoring[0].name

  monitoring                           = var.enable_monitoring
  disable_api_termination              = var.enable_termination_protection
  instance_initiated_shutdown_behavior = "stop"

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    encrypted             = true
    delete_on_termination = true

    tags = merge(
      {
        Name = "${local.name_prefix}-root-${count.index + 1}"
      },
      var.tags
    )
  }

  ebs_block_device {
    device_name           = "/dev/sdf"
    volume_type           = "gp3"
    volume_size           = var.data_volume_size
    encrypted             = true
    delete_on_termination = true

    tags = merge(
      {
        Name = "${local.name_prefix}-data-${count.index + 1}"
      },
      var.tags
    )
  }

  user_data = var.user_data_script != "" ? var.user_data_script : templatefile("${path.module}/user_data.sh", {
    ssh_private_key = tls_private_key.ssh.private_key_pem,
    ssh_public_key  = tls_private_key.ssh.public_key_openssh,
    mimir_bucket    = local.mimir_bucket
    loki_bucket     = local.loki_bucket
    tempo_bucket    = local.tempo_bucket
    backup_bucket   = local.backup_bucket
    region          = var.region,
    role            = replace(var.role, "-", "_")
    load_balancer   = var.enable_load_balancer ? try(aws_lb.monitoring[0].dns_name, "") : "",
    tls_private_key = tls_private_key.ca_key.private_key_pem,
    tls_cert        = tls_self_signed_cert.ca_cert.cert_pem,
    stack           = local.stack_name
  })

  tags = merge(
    {
      Name          = "${local.name_prefix}-${count.index + 1}",
      Role          = var.role,
      Stack         = local.stack_name
      mimir_bucket  = local.mimir_bucket,
      loki_bucket   = local.loki_bucket,
      tempo_bucket  = local.tempo_bucket,
      backup_bucket = local.backup_bucket,
      load_balancer = var.enable_load_balancer ? try(aws_lb.monitoring[0].dns_name, "") : ""
    },
    var.tags
  )

  lifecycle {
    ignore_changes = [ami]
  }
}

resource "aws_eip" "monitoring" {
  count = var.enable_eip && !var.enable_auto_scaling ? var.instance_count : 0

  instance = aws_instance.monitoring[count.index].id
  domain   = "vpc"

  tags = merge(
    {
      Name = "${local.name_prefix}-eip-${count.index + 1}"
    },
    var.tags
  )
}

resource "aws_launch_template" "monitoring" {
  count = var.enable_auto_scaling ? 1 : 0

  name_prefix   = "${local.name_prefix}-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_pair_name != "" ? var.key_pair_name : null

  vpc_security_group_ids = [aws_security_group.monitoring.id]

  iam_instance_profile {
    name = var.iam_instance_profile != "" ? var.iam_instance_profile : aws_iam_instance_profile.monitoring[0].name
  }

  monitoring {
    enabled = var.enable_monitoring
  }

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_type           = "gp3"
      volume_size           = var.root_volume_size
      encrypted             = true
      delete_on_termination = true
    }
  }

  block_device_mappings {
    device_name = "/dev/sdf"

    ebs {
      volume_type           = "gp3"
      volume_size           = var.data_volume_size
      encrypted             = true
      delete_on_termination = true
    }
  }

  user_data = base64encode(var.user_data_script != "" ? var.user_data_script : templatefile("${path.module}/user_data.sh", {
    mimir_bucket  = local.mimir_bucket
    loki_bucket   = local.loki_bucket
    tempo_bucket  = local.tempo_bucket
    backup_bucket = local.backup_bucket
    region        = var.region
  }))

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      {
        Name = "${local.name_prefix}-asg-instance"
      },
      var.tags
    )
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(
      {
        Name = "${local.name_prefix}-asg-volume"
      },
      var.tags
    )
  }

  tags = var.tags
}

resource "aws_autoscaling_group" "monitoring" {
  count = var.enable_auto_scaling ? 1 : 0

  name_prefix         = "${local.name_prefix}-"
  vpc_zone_identifier = var.subnet_ids

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  health_check_type         = var.enable_load_balancer ? "ELB" : "EC2"
  health_check_grace_period = var.health_check_grace_period

  target_group_arns = var.enable_load_balancer ? [
    aws_lb_target_group.grafana[0].arn,
    aws_lb_target_group.loki[0].arn,
    aws_lb_target_group.otel_grpc[0].arn,
    aws_lb_target_group.otel_http[0].arn,
    aws_lb_target_group.tempo_http[0].arn,
    aws_lb_target_group.tempo_grpc[0].arn,
    aws_lb_target_group.mimir[0].arn
  ] : []

  launch_template {
    id      = aws_launch_template.monitoring[0].id
    version = "$Latest"
  }

  enabled_metrics = var.enable_monitoring ? [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ] : []

  tag {
    key                 = "Name"
    value               = "${local.name_prefix}-asg"
    propagate_at_launch = false
  }

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb" "monitoring" {
  count = var.enable_load_balancer ? 1 : 0

  name_prefix        = substr(local.name_prefix, 0, 6)
  internal           = var.load_balancer_internal
  load_balancer_type = "network"
  subnets            = local.lb_subnet_ids

  enable_deletion_protection       = var.enable_termination_protection
  enable_cross_zone_load_balancing = true

  tags = merge(
    {
      Name = "${local.name_prefix}-nlb"
    },
    var.tags
  )
}

resource "aws_lb_target_group" "grafana" {
  count = var.enable_load_balancer ? 1 : 0

  name_prefix = substr("${local.name_prefix}-gr-", 0, 6)
  port        = local.grafana_port
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    protocol            = "TCP"
    port                = local.grafana_port
  }

  tags = merge(
    {
      Name = "${local.name_prefix}-tg-grafana"
    },
    var.tags
  )
}

resource "aws_lb_listener" "grafana" {
  count = var.enable_load_balancer && var.acm_certificate_arn == "" ? 1 : 0

  load_balancer_arn = aws_lb.monitoring[0].arn
  port              = local.grafana_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana[0].arn
  }
}

resource "aws_lb_listener" "grafana_tls" {
  count = var.enable_load_balancer && var.acm_certificate_arn != "" ? 1 : 0

  load_balancer_arn = aws_lb.monitoring[0].arn
  port              = local.grafana_port
  protocol          = "TLS"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana[0].arn
  }
}

resource "aws_lb_target_group" "loki" {
  count = var.enable_load_balancer ? 1 : 0

  name_prefix = substr("${local.name_prefix}-lo-", 0, 6)
  port        = local.loki_port
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    protocol            = "TCP"
    port                = local.loki_port
  }

  tags = merge(
    {
      Name = "${local.name_prefix}-tg-loki"
    },
    var.tags
  )
}

resource "aws_lb_listener" "loki" {
  count = var.enable_load_balancer ? 1 : 0

  load_balancer_arn = aws_lb.monitoring[0].arn
  port              = local.loki_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.loki[0].arn
  }
}

resource "aws_lb_target_group" "otel_grpc" {
  count = var.enable_load_balancer ? 1 : 0

  name_prefix = substr("${local.name_prefix}-og-", 0, 6)
  port        = local.otel_grpc_port
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    protocol            = "TCP"
    port                = local.otel_grpc_port
  }

  tags = merge(
    {
      Name = "${local.name_prefix}-tg-otel-grpc"
    },
    var.tags
  )
}

resource "aws_lb_listener" "otel_grpc" {
  count = var.enable_load_balancer ? 1 : 0

  load_balancer_arn = aws_lb.monitoring[0].arn
  port              = local.otel_grpc_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.otel_grpc[0].arn
  }
}

resource "aws_lb_target_group" "otel_http" {
  count = var.enable_load_balancer ? 1 : 0

  name_prefix = substr("${local.name_prefix}-oh-", 0, 6)
  port        = local.otel_http_port
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    protocol            = "TCP"
    port                = local.otel_http_port
  }

  tags = merge(
    {
      Name = "${local.name_prefix}-tg-otel-http"
    },
    var.tags
  )
}

resource "aws_lb_listener" "otel_http" {
  count = var.enable_load_balancer ? 1 : 0

  load_balancer_arn = aws_lb.monitoring[0].arn
  port              = local.otel_http_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.otel_http[0].arn
  }
}

resource "aws_lb_target_group" "tempo_http" {
  count = var.enable_load_balancer ? 1 : 0

  name_prefix = substr("${local.name_prefix}-th-", 0, 6)
  port        = local.tempo_http_port
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    protocol            = "TCP"
    port                = local.tempo_http_port
  }

  tags = merge(
    {
      Name = "${local.name_prefix}-tg-tempo-http"
    },
    var.tags
  )
}

resource "aws_lb_listener" "tempo_http" {
  count = var.enable_load_balancer ? 1 : 0

  load_balancer_arn = aws_lb.monitoring[0].arn
  port              = local.tempo_http_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tempo_http[0].arn
  }
}

resource "aws_lb_target_group" "tempo_grpc" {
  count = var.enable_load_balancer ? 1 : 0

  name_prefix = substr("${local.name_prefix}-tg-", 0, 6)
  port        = local.tempo_grpc_port
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    protocol            = "TCP"
    port                = local.tempo_grpc_port
  }

  tags = merge(
    {
      Name = "${local.name_prefix}-tg-tempo-grpc"
    },
    var.tags
  )
}

resource "aws_lb_listener" "tempo_grpc" {
  count = var.enable_load_balancer ? 1 : 0

  load_balancer_arn = aws_lb.monitoring[0].arn
  port              = local.tempo_grpc_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tempo_grpc[0].arn
  }
}

resource "aws_lb_target_group" "mimir" {
  count = var.enable_load_balancer ? 1 : 0

  name_prefix = substr("${local.name_prefix}-mi-", 0, 6)
  port        = local.mimir_port
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    protocol            = "TCP"
    port                = local.mimir_port
  }

  tags = merge(
    {
      Name = "${local.name_prefix}-tg-mimir"
    },
    var.tags
  )
}

resource "aws_lb_listener" "mimir" {
  count = var.enable_load_balancer ? 1 : 0

  load_balancer_arn = aws_lb.monitoring[0].arn
  port              = local.mimir_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.mimir[0].arn
  }
}

resource "aws_lb_target_group_attachment" "monitoring" {
  for_each = var.enable_load_balancer && !var.enable_auto_scaling ? {
    for idx, instance in aws_instance.monitoring :
    "${idx}-grafana" => {
      instance_id      = instance.id
      target_group_arn = aws_lb_target_group.grafana[0].arn
    }
  } : {}

  target_group_arn = each.value.target_group_arn
  target_id        = each.value.instance_id
  port             = local.grafana_port
}

resource "aws_lb_target_group_attachment" "loki" {
  for_each = var.enable_load_balancer && !var.enable_auto_scaling ? {
    for idx, instance in aws_instance.monitoring :
    "${idx}-loki" => {
      instance_id      = instance.id
      target_group_arn = aws_lb_target_group.loki[0].arn
    }
  } : {}

  target_group_arn = each.value.target_group_arn
  target_id        = each.value.instance_id
  port             = local.loki_port
}

resource "aws_lb_target_group_attachment" "otel_grpc" {
  for_each = var.enable_load_balancer && !var.enable_auto_scaling ? {
    for idx, instance in aws_instance.monitoring :
    "${idx}-otel-grpc" => {
      instance_id      = instance.id
      target_group_arn = aws_lb_target_group.otel_grpc[0].arn
    }
  } : {}

  target_group_arn = each.value.target_group_arn
  target_id        = each.value.instance_id
  port             = local.otel_grpc_port
}

resource "aws_lb_target_group_attachment" "otel_http" {
  for_each = var.enable_load_balancer && !var.enable_auto_scaling ? {
    for idx, instance in aws_instance.monitoring :
    "${idx}-otel-http" => {
      instance_id      = instance.id
      target_group_arn = aws_lb_target_group.otel_http[0].arn
    }
  } : {}

  target_group_arn = each.value.target_group_arn
  target_id        = each.value.instance_id
  port             = local.otel_http_port
}

resource "aws_lb_target_group_attachment" "tempo_http" {
  for_each = var.enable_load_balancer && !var.enable_auto_scaling ? {
    for idx, instance in aws_instance.monitoring :
    "${idx}-tempo-http" => {
      instance_id      = instance.id
      target_group_arn = aws_lb_target_group.tempo_http[0].arn
    }
  } : {}

  target_group_arn = each.value.target_group_arn
  target_id        = each.value.instance_id
  port             = local.tempo_http_port
}

resource "aws_lb_target_group_attachment" "tempo_grpc" {
  for_each = var.enable_load_balancer && !var.enable_auto_scaling ? {
    for idx, instance in aws_instance.monitoring :
    "${idx}-tempo-grpc" => {
      instance_id      = instance.id
      target_group_arn = aws_lb_target_group.tempo_grpc[0].arn
    }
  } : {}

  target_group_arn = each.value.target_group_arn
  target_id        = each.value.instance_id
  port             = local.tempo_grpc_port
}

resource "aws_lb_target_group_attachment" "mimir" {
  for_each = var.enable_load_balancer && !var.enable_auto_scaling ? {
    for idx, instance in aws_instance.monitoring :
    "${idx}-mimir" => {
      instance_id      = instance.id
      target_group_arn = aws_lb_target_group.mimir[0].arn
    }
  } : {}

  target_group_arn = each.value.target_group_arn
  target_id        = each.value.instance_id
  port             = local.mimir_port
}
