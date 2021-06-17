locals {
  resources_name = "cloudtrail-auditlog-${var.name}"
  bucket = local.resources_name
  log_group = local.resources_name
  role = local.resources_name
}

resource "aws_cloudtrail" "trail" {
  name = var.name
  s3_bucket_name = local.bucket
  is_multi_region_trail = true
  include_global_service_events = true

  cloud_watch_logs_group_arn = var.enable_cloudwatch ? "${aws_cloudwatch_log_group.cloudtrail_log_group[0].arn}:*" : ""
  cloud_watch_logs_role_arn = var.enable_cloudwatch ? aws_iam_role.cloudtrail_cloudwatch[0].arn : ""
  depends_on = [
    aws_s3_bucket.trail_bucket
  ]

  event_selector {
    read_write_type = "All"
    include_management_events = true

    data_resource {
      type = "AWS::S3::Object"
      values = [
        "arn:aws:s3:::"]
    }
  }
}

resource "aws_s3_bucket" "trail_bucket" {
  bucket = local.bucket
  force_destroy = true

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::${local.bucket}"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::${local.bucket}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        }
    ]
}
POLICY
}

resource "aws_cloudwatch_log_group" "cloudtrail_log_group" {
  count = var.enable_cloudwatch ? 1 : 0
  name = local.log_group
}

resource "aws_iam_role" "cloudtrail_cloudwatch" {
  count = var.enable_cloudwatch ? 1 : 0
  name = local.role
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "CloudTrailAllow",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "cloud_trail" {
  count = var.enable_cloudwatch ? 1 : 0

  name = "cloudtrail-to-cloudwatch"
  role = aws_iam_role.cloudtrail_cloudwatch[0].id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AWSCloudTrailCreateLogStream",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream"
      ],
      "Resource": [
        "arn:aws:logs:*:*:*"
      ]
    },
    {
      "Sid": "AWSCloudTrailPutLogEvents",
      "Effect": "Allow",
      "Action": [
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:*:*:*"
      ]
    }
  ]
}
EOF
}