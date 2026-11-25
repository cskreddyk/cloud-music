terraform {
  backend "s3" {
    bucket       = "cloudmusic-tfstate-611708420769-ap-northeast-1"
    key          = "cloudmusic/jenkins/terraform.tfstate"
    region       = "ap-northeast-1"
    encrypt      = true
    use_lockfile = true
  }
}
