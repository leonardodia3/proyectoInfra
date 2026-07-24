data "archive_file" "notify_alert" {
  type        = "zip"
  source_dir  = "../lambdas/notifyAlert"
  output_path = "../build/notifyAlert.zip"
}

data "archive_file" "register_student" {
  type        = "zip"
  source_dir  = "../lambdas/registerStudent"
  output_path = "../build/registerStudent.zip"
}

data "archive_file" "list_students" {
  type        = "zip"
  source_dir  = "../lambdas/listStudents"
  output_path = "../build/listStudents.zip"
}

data "archive_file" "attendance" {
  type        = "zip"
  source_dir  = "../lambdas/attendance"
  output_path = "../build/attendance.zip"
}

data "archive_file" "manual_attendance" {
  type        = "zip"
  source_dir  = "../lambdas/manualAttendance"
  output_path = "../build/manualAttendance.zip"
}

data "archive_file" "attendance_history" {
  type        = "zip"
  source_dir  = "../lambdas/attendanceHistory"
  output_path = "../build/attendanceHistory.zip"
}

resource "aws_lambda_code_signing_config" "notify_alert" {
  allowed_publishers {
    signing_profile_version_arns = [aws_signer_signing_profile.notify_alert.version_arn]
  }

  policies {
    untrusted_artifact_on_deployment = "Warn"
  }
}

resource "aws_lambda_code_signing_config" "register_student" {
  allowed_publishers {
    signing_profile_version_arns = [aws_signer_signing_profile.register_student.version_arn]
  }

  policies {
    untrusted_artifact_on_deployment = "Warn"
  }
}

resource "aws_lambda_code_signing_config" "list_students" {
  allowed_publishers {
    signing_profile_version_arns = [aws_signer_signing_profile.list_students.version_arn]
  }

  policies {
    untrusted_artifact_on_deployment = "Warn"
  }
}

resource "aws_lambda_code_signing_config" "attendance" {
  allowed_publishers {
    signing_profile_version_arns = [aws_signer_signing_profile.attendance.version_arn]
  }

  policies {
    untrusted_artifact_on_deployment = "Warn"
  }
}

resource "aws_lambda_code_signing_config" "manual_attendance" {
  allowed_publishers {
    signing_profile_version_arns = [aws_signer_signing_profile.manual_attendance.version_arn]
  }

  policies {
    untrusted_artifact_on_deployment = "Warn"
  }
}

resource "aws_lambda_code_signing_config" "attendance_history" {
  allowed_publishers {
    signing_profile_version_arns = [aws_signer_signing_profile.attendance_history.version_arn]
  }

  policies {
    untrusted_artifact_on_deployment = "Warn"
  }
}
