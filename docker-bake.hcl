variable "REGISTRY" {
  default = "192.168.10.182:5000"
}

variable "TAG" {
  default = "latest"
}

group "all" {
  targets = ["MyCSharpServer", "MyPyServer", "MyNginxServer"]
}

target "MyCSharpServer" {
  context = "./libs/MyCSharpServer"
  dockerfile = "Dockerfile"
  tags = ["${REGISTRY}/aspnet-swarm-test:${TAG}"]
  platforms = ["linux/amd64"]
}

target "MyPyServer" {
  context = "./libs/MyPyServer"
  dockerfile = "Dockerfile"
  tags = ["${REGISTRY}/fastapi-swarm-test:${TAG}"]
  platforms = ["linux/amd64"]
}

target "MyNginxServer" {
  context = "./nginx-build"
  dockerfile = "Dockerfile"
  tags = ["${REGISTRY}/nginx:${TAG}"]
  platforms = ["linux/amd64"]
}