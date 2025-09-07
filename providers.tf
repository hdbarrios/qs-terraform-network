provider "aws" {
  region  = var.aws_region
  profile = "qs-terraform"
  alias   = "nube-quilsoft"
}

# Para generar contraseñas seguras aleatorias
provider "random" {}

