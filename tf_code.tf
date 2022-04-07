resource "aws_s3_bucket" "tf-course" {
    bucket = "tf-course-sudhir-04-05-2022"
}

resource "aws_s3_bucket_acl" "example" {
  bucket = aws_s3_bucket.tf-course.id
  acl    = "private"
}