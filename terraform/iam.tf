
resource "aws_iam_role" "livegrep_frontend" {
  name = "livegrep_frontend"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "livegrep_frontend" {
    name = "livegrep_frontend"
    roles = ["${aws_iam_role.livegrep_frontend.name}"]
}

resource "aws_iam_role" "livegrep_backend" {
  name = "livegrep_backend"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "livegrep_backend" {
    name = "livegrep_backend"
    roles = ["${aws_iam_role.livegrep_backend.name}"]
}

resource "aws_iam_policy" "livegrep_s3" {
    name = "livegrep-s3-ro"
    path = "/"
    description = "readonly access to the livegrep S3 bucket"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:HeadObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::livegrep/*",
                "arn:aws:s3:::livegrep"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_policy" "livegrep_common" {
    name = "livegrep-common"
    path = "/"
    description = "livegrep base IAM policy"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "ReadCredstash",
        "Effect": "Allow",
        "Action": [
          "dynamodb:Scan",
          "dynamodb:GetItem",
          "dynamodb:Query"
        ],
        "Resource": [
          "arn:aws:dynamodb:${var.region}:807717602072:table/credential-store"
        ]
      },
      {
        "Sid": "DescribeInstances",
        "Effect": "Allow",
        "Action": [
          "ec2:DescribeInstances"
        ],
        "Resource": "*"
      }
    ]
}
EOF
}

resource "aws_iam_policy_attachment" "livegrep_s3_attachment" {
  name = "livegrep-s3-ro-attach"
  roles = [
    "${aws_iam_role.livegrep_frontend.name}",
    "${aws_iam_role.livegrep_backend.name}",
  ]
  policy_arn = "${aws_iam_policy.livegrep_s3.arn}"
}

resource "aws_iam_policy_attachment" "livegrep_common_attachment" {
  name = "livegrep-common-attachment"
  roles = [
    "${aws_iam_role.livegrep_frontend.name}",
    "${aws_iam_role.livegrep_backend.name}",
  ]
  policy_arn = "${aws_iam_policy.livegrep_common.arn}"
}

resource "aws_iam_role_policy" "livegrep_frontend_r53" {
    name = "livegrep_frontend_r53"
    role = "${aws_iam_role.livegrep_frontend.id}"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Stmt1450992162000",
            "Effect": "Allow",
            "Action": [
                "route53:ListHostedZones"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Sid": "ManageIntZone",
            "Effect": "Allow",
            "Action": [
                "route53:ListResourceRecordSets",
                "route53:ChangeResourceRecordSets"
            ],
            "Resource": [
                "arn:aws:route53:::hostedzone/Z3M7BVOL8R3KUV"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "livegrep_frontend_certs" {
    name = "livegrep_frontend_certs"
    role = "${aws_iam_role.livegrep_frontend.id}"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:PutItem"
            ],
            "Resource": [
                "arn:aws:dynamodb:${var.region}:807717602072:table/credential-store"
            ]
        }
    ]
}
EOF
}


resource "aws_iam_role_policy" "livegrep_backend_r53" {
    name = "livegrep_backend_r53"
    role = "${aws_iam_role.livegrep_backend.id}"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Stmt1450992162000",
            "Effect": "Allow",
            "Action": [
                "route53:ListHostedZones"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Sid": "ManageIntZone",
            "Effect": "Allow",
            "Action": [
                "route53:ListResourceRecordSets",
                "route53:ChangeResourceRecordSets"
            ],
            "Resource": [
                "arn:aws:route53:::hostedzone/${aws_route53_zone.int_livegrep_com.id}"
            ]
        }
    ]
}
EOF
}