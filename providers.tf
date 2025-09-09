provider "aws" {
  region = "sa-east-1"
  profile = "qs-terraform"
  alias   = "nube-quilsoft"
}

# Para generar contraseñas seguras aleatorias
provider "random" {}

