locals {
  rfid_index_name = "rfid-index"
}

resource "aws_dynamodb_table" "attendance" {
  name                        = "attendance"
  billing_mode                = "PAY_PER_REQUEST"
  deletion_protection_enabled = true
  hash_key                    = "pk"
  range_key                   = "sk"

  attribute {
    name = "pk"
    type = "S"
  }

  attribute {
    name = "sk"
    type = "S"
  }

  attribute {
    name = "rfid"
    type = "S"
  }

  global_secondary_index {
    name            = local.rfid_index_name
    hash_key        = "rfid"
    projection_type = "ALL"
  }

  # CKV_AWS_119 - Cifrado con KMS CMK
  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamo_key.arn
  }

  # CKV_AWS_28 - Point-in-Time Recovery
  point_in_time_recovery {
    enabled = true
  }
}
