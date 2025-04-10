# 构建镜像
docker build -t jenkins/jenkins .
docker run -d --name jenkins --restart=on-failure `
  -e JAVA_OPTS="-Duser.timezone=Asia/Shanghai" -e TZ="Asia/Shanghai" `
  -v jenkins_home:/var/jenkins_home `
  -p 8080:8080 -p 50000:50000 `
  jenkins/jenkins