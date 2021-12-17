module "pillow_dependency" {
  source     = "./modules/python-dependency-layer"
  package_name = "pillow"
}

module "face_recognition_dependency" {
  source     = "./modules/python-dependency-layer"
  package_name = "face-recognition"
}