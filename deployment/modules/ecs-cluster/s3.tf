resource "aws_s3_bucket" "lambdabucket" {
  bucket = lower("ecs-checkit${var.name}-lambda-bucket")
}

resource "aws_s3_bucket_versioning" "lambdabucket" {
  bucket = aws_s3_bucket.lambdabucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_acl" "lambdabucket" {
  bucket = aws_s3_bucket.lambdabucket.id
  acl    = "private"
}

resource "aws_s3_object" "lambda_launch_s3_upload" {
  key    = "lambda_launch.zip"
  bucket = aws_s3_bucket.lambdabucket.id
  source = data.archive_file.launch.output_path
  etag   = filemd5(data.archive_file.launch.output_path)
}

resource "aws_s3_object" "lambda_terminate_s3_upload" {
  key    = "lambda_terminate.zip"
  bucket = aws_s3_bucket.lambdabucket.id
  source = data.archive_file.terminate.output_path
  etag   = filemd5(data.archive_file.terminate.output_path)
}

resource "aws_s3_object" "lambda_monitor_s3_upload" {
  key    = "lambda_monitor.zip"
  bucket = aws_s3_bucket.lambdabucket.id
  source = data.archive_file.monitor.output_path
  etag   = filemd5(data.archive_file.monitor.output_path)
}