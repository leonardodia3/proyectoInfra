locals {
  frontend_bucket_base_name = var.frontend_bucket_name != "" ? var.frontend_bucket_name : "attendance-frontend-${data.aws_caller_identity.current.account_id}"
  frontend_source_dir       = "${path.module}/../local-deploy/frontend"
  frontend_static_files     = toset(["index.html", "style.css", "responsive.css", "api.js", "auth.js", "app.js"])

  frontend_content_types = {
    html = "text/html; charset=utf-8"
    css  = "text/css; charset=utf-8"
    js   = "application/javascript; charset=utf-8"
  }

  frontend_config = {
    mode              = "aws"
    apiBaseUrl        = aws_api_gateway_stage.prod.invoke_url
    cognitoRegion     = "us-east-1"
    cognitoUserPoolId = aws_cognito_user_pool.attendance_pool.id
    cognitoClientId   = aws_cognito_user_pool_client.attendance_client.id
  }
}

resource "aws_s3_bucket" "frontend" {
  #checkov:skip=CKV_AWS_144:Replica cross-region fuera del alcance de la demo desplegable.
  #checkov:skip=CKV2_AWS_62:No se requieren eventos de bucket para un frontend estatico versionado.
  bucket        = local.frontend_bucket_base_name
  force_destroy = true
}

resource "aws_s3_bucket" "frontend_logs" {
  #checkov:skip=CKV_AWS_18:Bucket dedicado para recibir logs, no requiere logging recursivo.
  #checkov:skip=CKV_AWS_144:Replica cross-region fuera del alcance de la demo desplegable.
  #checkov:skip=CKV_AWS_145:S3/CloudFront log delivery es mas compatible con SSE-S3 en el bucket de logs.
  #checkov:skip=CKV2_AWS_62:No se requieren eventos de bucket para un bucket de logs.
  bucket        = "${local.frontend_bucket_base_name}-logs"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket                  = aws_s3_bucket.frontend.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "frontend_logs" {
  bucket                  = aws_s3_bucket.frontend_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "frontend_logs" {
  #checkov:skip=CKV2_AWS_65:CloudFront/S3 standard log delivery requiere ACL de log-delivery-write en el bucket destino.
  bucket = aws_s3_bucket.frontend_logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "frontend_logs" {
  bucket     = aws_s3_bucket.frontend_logs.id
  acl        = "log-delivery-write"
  depends_on = [aws_s3_bucket_ownership_controls.frontend_logs]
}

resource "aws_s3_bucket_versioning" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "frontend_logs" {
  bucket = aws_s3_bucket.frontend_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.dynamo_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "frontend_logs" {
  bucket = aws_s3_bucket.frontend_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_logging" "frontend" {
  bucket        = aws_s3_bucket.frontend.id
  target_bucket = aws_s3_bucket.frontend_logs.id
  target_prefix = "s3-access/"
}

resource "aws_s3_bucket_lifecycle_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    id     = "expire-incomplete-frontend-uploads"
    status = "Enabled"

    filter {
      prefix = ""
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "frontend_logs" {
  bucket = aws_s3_bucket.frontend_logs.id

  rule {
    id     = "expire-frontend-logs"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = 90
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_cloudfront_origin_access_control" "frontend" {
  name                              = "attendance-frontend-oac"
  description                       = "Acceso privado de CloudFront al bucket del panel"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_response_headers_policy" "frontend_security_headers" {
  name = "attendance-frontend-security-headers"

  security_headers_config {
    content_type_options {
      override = true
    }

    frame_options {
      frame_option = "DENY"
      override     = true
    }

    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }

    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      override                   = true
      preload                    = true
    }

    xss_protection {
      mode_block = true
      override   = true
      protection = true
    }
  }
}

resource "aws_cloudfront_distribution" "frontend" {
  #checkov:skip=CKV_AWS_68:El WAF regional protege API Gateway; CloudFront solo sirve archivos estaticos privados.
  #checkov:skip=CKV_AWS_310:Origen unico S3 suficiente para demo desplegable.
  #checkov:skip=CKV_AWS_174:Sin dominio propio se usa certificado default de CloudFront; ACM se agrega al habilitar dominio.
  #checkov:skip=CKV2_AWS_42:Sin dominio propio no hay certificado ACM personalizado; usa certificado default de CloudFront.
  #checkov:skip=CKV2_AWS_47:La proteccion Log4j aplica al API con WAF regional; el frontend sirve archivos estaticos.
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100"

  origin {
    domain_name              = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend.id
    origin_id                = "attendance-frontend-s3"
  }

  default_cache_behavior {
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD"]
    compress                   = true
    target_origin_id           = "attendance-frontend-s3"
    viewer_protocol_policy     = "redirect-to-https"
    response_headers_policy_id = aws_cloudfront_response_headers_policy.frontend_security_headers.id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  logging_config {
    bucket = aws_s3_bucket.frontend_logs.bucket_domain_name
    prefix = "cloudfront/"
  }

  restrictions {
    geo_restriction {
      locations        = ["PE", "US"]
      restriction_type = "whitelist"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1.2_2021"
  }
}

data "aws_iam_policy_document" "frontend_bucket" {
  statement {
    sid     = "AllowCloudFrontRead"
    effect  = "Allow"
    actions = ["s3:GetObject"]

    resources = [
      "${aws_s3_bucket.frontend.arn}/*"
    ]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.frontend.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  policy = data.aws_iam_policy_document.frontend_bucket.json
}

resource "aws_s3_object" "frontend_static" {
  for_each = local.frontend_static_files

  bucket                 = aws_s3_bucket.frontend.id
  key                    = each.value
  source                 = "${local.frontend_source_dir}/${each.value}"
  etag                   = filemd5("${local.frontend_source_dir}/${each.value}")
  content_type           = local.frontend_content_types[element(split(".", each.value), length(split(".", each.value)) - 1)]
  cache_control          = each.value == "index.html" ? "no-cache" : "public, max-age=31536000, immutable"
  server_side_encryption = "aws:kms"
  kms_key_id             = aws_kms_key.dynamo_key.arn
}

resource "aws_s3_object" "frontend_config" {
  bucket                 = aws_s3_bucket.frontend.id
  key                    = "config.js"
  content                = "window.APP_CONFIG = ${jsonencode(local.frontend_config)};\n"
  content_type           = "application/javascript; charset=utf-8"
  cache_control          = "no-cache"
  etag                   = md5(jsonencode(local.frontend_config))
  server_side_encryption = "aws:kms"
  kms_key_id             = aws_kms_key.dynamo_key.arn
}
