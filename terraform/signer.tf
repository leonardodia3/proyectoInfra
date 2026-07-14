resource "aws_signer_signing_profile" "register_student" {
  platform_id = "AWSLambda-SHA384-ECDSA"
  name        = "register_student_profile"
}

resource "aws_signer_signing_profile" "list_students" {
  platform_id = "AWSLambda-SHA384-ECDSA"
  name        = "list_students_profile"
}

resource "aws_signer_signing_profile" "attendance" {
  platform_id = "AWSLambda-SHA384-ECDSA"
  name        = "attendance_profile"
}

resource "aws_signer_signing_profile" "manual_attendance" {
  platform_id = "AWSLambda-SHA384-ECDSA"
  name        = "manual_attendance_profile"
}

resource "aws_signer_signing_profile" "attendance_history" {
  platform_id = "AWSLambda-SHA384-ECDSA"
  name        = "attendance_history_profile"
}

resource "aws_signer_signing_profile" "notify_alert" {
  platform_id = "AWSLambda-SHA384-ECDSA"
  name        = "notify_alert_profile"
}