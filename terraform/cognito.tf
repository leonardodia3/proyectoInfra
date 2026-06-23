resource "aws_cognito_user_pool" "attendance_pool" {
  name = "attendance-user-pool"

  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length    = 8
    require_uppercase = true
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
  }
}

resource "aws_cognito_user_pool_client" "attendance_client" {
  name         = "attendance-app-client"
  user_pool_id = aws_cognito_user_pool.attendance_pool.id

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]
}