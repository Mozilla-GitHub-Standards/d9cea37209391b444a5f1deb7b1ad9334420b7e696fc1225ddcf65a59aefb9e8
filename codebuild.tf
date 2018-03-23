# codebuild

# Load configuration files from template

data "template_file" "codebuild_policy" {
  template = "${file("./iam/codebuild-policy.tmpl")}"

  vars {
    codepipeline_bucket = "${aws_s3_bucket.codepipeline_bucket.id}"
  }
}

resource "aws_iam_role" "codebuild_role" {
  name               = "codebuild-role-${var.service_name}"
  assume_role_policy = "${file("./iam/codebuild-role.txt")}"
}

# IAM configuration

resource "aws_iam_policy" "codebuild_policy" {
  name        = "codebuild-policy-${var.service_name}"
  path        = "/service-role/"
  description = "Policy used in trust relationship with CodeBuild"
  policy      = "${data.template_file.codebuild_policy.rendered}"
}

resource "aws_iam_policy_attachment" "codebuild_policy_attachment" {
  name       = "codebuild-policy-attachment-${var.service_name}"
  policy_arn = "${aws_iam_policy.codebuild_policy.arn}"
  roles      = ["${aws_iam_role.codebuild_role.id}"]
}

# Create CodeBuild job

resource "aws_codebuild_project" "codebuild_project" {
  name          = "${var.service_name}"
  description   = "${var.description}"
  build_timeout = "15"
  service_role  = "${aws_iam_role.codebuild_role.arn}"

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/ubuntu-base:14.04"
    type         = "LINUX_CONTAINER"
  }

  source {
    type      = "GITHUB"
    location  = "${var.source_repository["https_url"]}"
  }

  tags = "${var.webops_tags}"
}
