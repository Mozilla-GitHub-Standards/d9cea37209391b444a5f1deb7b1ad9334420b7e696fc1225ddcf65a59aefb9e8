# codepipeline

resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "codepipeline-${var.service_name}"
  acl    = "private"
}

data "template_file" "codepipeline_policy_template" {
  template = "${file("./iam/codepipeline-policy.tmpl")}"

  vars {
    codepipeline_bucket = "${aws_s3_bucket.codepipeline_bucket.id}"
  }
}

resource "aws_iam_role" "codepipeline_service_role" {
  name               = "webops-codepipeline_${var.service_name}_role"
  assume_role_policy = "${file("./iam/codepipeline-role.txt")}"
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name   = "codepipeline_${var.service_name}_policy"
  role   = "${aws_iam_role.codepipeline_service_role.id}"
  policy = "${data.template_file.codepipeline_policy_template.rendered}"
}

resource "aws_codepipeline" "codepipeline_resource" {
  name     = "${var.service_name}"
  role_arn = "${aws_iam_role.codepipeline_service_role.arn}"

  artifact_store {
    location = "${aws_s3_bucket.codepipeline_bucket.bucket}"
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["jekyll_blog_source"]

      configuration {
        OAuthToken           = "${var.github_token}"
        Owner                = "${var.source_repository["owner"]}"
        Repo                 = "${var.source_repository["name"]}"
        Branch               = "${var.source_repository["branch"]}"
        PollForSourceChanges = "true"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["jekyll_blog_source"]
      output_artifacts = ["BuildOutput"]
      version          = "1"

      configuration {
        ProjectName = "${var.service_name}"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = "1"
      input_artifacts = ["BuildOutput"]

      configuration {
        ClusterName = "webops-cluster-production"
        FileName    = "imagedefinitions.json"
        ServiceName = "redirects"
      }
    }
  }
}
