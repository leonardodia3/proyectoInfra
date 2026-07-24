variable "attendance_deadline" {
  description = "Hora limite de ingreso antes de considerar tardanza, en formato HH:MM."
  type        = string
  default     = "08:00"
}

variable "attendance_time_zone" {
  description = "Zona horaria usada para evaluar tardanzas."
  type        = string
  default     = "America/Lima"
}

variable "alert_email" {
  description = "Correo que recibira alertas SNS."
  type        = string

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.alert_email))
    error_message = "alert_email debe ser un correo real para confirmar la suscripcion SNS."
  }
}

variable "lambda_reserved_concurrency" {
  description = "Limite reservado por funcion Lambda para proteger la cuenta ante picos o bucles."
  type        = number
  default     = 20
}

variable "cors_allowed_origin" {
  description = "Origen permitido por CORS. Usa * para demo o la URL de CloudFront/dominio propio en produccion."
  type        = string
  default     = "*"
}

variable "frontend_bucket_name" {
  description = "Nombre opcional para el bucket S3 del frontend. Si queda vacio se genera con el ID de la cuenta."
  type        = string
  default     = ""

  validation {
    condition     = var.frontend_bucket_name == "" || can(regex("^[a-z0-9][a-z0-9.-]{1,56}[a-z0-9]$", var.frontend_bucket_name))
    error_message = "frontend_bucket_name debe ser un nombre S3 valido de 3 a 58 caracteres para reservar sufijo -logs."
  }
}
