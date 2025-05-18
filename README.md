# 🤖 ChatBot DevSecOps CI/CD Project

This project demonstrates a complete DevSecOps pipeline for deploying a ChatBot UI integrated with OpenAI, leveraging AWS, Jenkins, Docker, SonarQube, Trivy, OWASP, Terraform, and EKS.

---

## 🚀 Project Setup & Configuration

### 1. **EC2 Setup**
- Launch EC2 instance: `t2.large`, 30 GB memory
- Assign IAM role: `chatbot` with `AdministratorAccess`
- Inbound rules: Allow `8080`, `80`, `9000`, and `22` (SSH)

### 2. **Install Jenkins & Java**
```bash
vi Jenkins.sh  # Add installation script
sh Jenkins.sh
```

### 3. **Install Docker**
```bash
sudo apt-get install docker.io -y
sudo usermod -aG docker $USER
sudo usermod -aG docker jenkins
newgrp docker
```

### 4. **Run SonarQube**
```bash
docker run -d --name sonarqube -p 9000:9000 sonarqube:lts-community
```
Access: `http://<public-ip>:9000`

### 5. **Install Tools via Script**
```bash
vi script.sh  # Add Terraform, Trivy, kubectl, AWS CLI setup
chmod +x script.sh
./script.sh
```

---

## 🔌 Jenkins Plugin Installation
Install from **Manage Jenkins → Plugins**:
- `SonarQube Scanner`
- `NodeJS`
- `Docker`
- `OWASP Dependency Check`
- `Terraform`
- `Kubernetes CLI` & `Pipeline` and more...

---

## 🔧 Tool Configuration in Jenkins
- **JDK 17**: `/usr/lib/jvm/temurin-17-jdk-amd64`
- **SonarScanner**: Latest version
- **NodeJS**: Version 19
- **Docker Tool**: Use Docker path
- **OWASP Dependency-Check**: Version 9.0.9
- **Credentials**:
  - GitHub Token
  - DockerHub (`gauridocker777`)
  - AWS Access Keys
  - Sonar Token
  - Kubernetes kubeconfig

---

## 📦 Jenkins CI/CD Pipeline (ChatBot)
Jenkins Pipeline for build, analysis, security scan, Docker push, and container deployment:

<details>
<summary>Click to expand Jenkinsfile</summary>

```groovy
pipeline {
    agent any
    tools {
        jdk 'jdk17'
        nodejs 'node19'
    }
    environment {
        SCANNER_HOME = tool 'sonar-scanner'
        JAVA_HOME = '/usr/lib/jvm/temurin-17-jdk-amd64'
        PATH = "${JAVA_HOME}/bin:${env.PATH}"
    }
    stages {
        stage('Clean Workspace') { steps { cleanWs() } }
        stage('Checkout') {
            steps {
                git branch: 'main', credentialsId: 'Capstone', url: 'https://github.com/Gaurigithub-p/ChatBot-Application.git'
            }
        }
        stage('Install Dependencies') { steps { dir('project') { sh 'npm install' } } }
        stage('SonarQube Analysis') {
            steps {
                dir('project') {
                    withSonarQubeEnv('sonar-server') {
                        sh '''$SCANNER_HOME/bin/sonar-scanner \
                            -Dsonar.projectName=ChatBot \
                            -Dsonar.projectKey=ChatBot'''
                    }
                }
            }
        }
        stage('Quality Gate') {
            steps {
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: 'Sonar-token'
                }
            }
        }
        stage('OWASP FS Scan') {
            steps {
                dir('project') {
                    dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit', odcInstallation: 'DP-Check'
                    dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
                }
            }
        }
        stage('Trivy FS Scan') { steps { sh 'trivy fs . > trivyfs.txt' } }
        stage('Docker Build & Push') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'docker', toolName: 'docker') {
                        sh 'docker build -t chatbot .'
                        sh 'docker tag chatbot gauridocker777/devops:latest'
                        sh 'docker push gauridocker777/devops:latest'
                    }
                }
            }
        }
        stage('Trivy Image Scan') {
            steps { sh 'trivy image gauridocker777/devops:latest > trivy.txt' }
        }
        stage('Deploy to Container') {
            steps { sh 'docker run -d --name chatbot -p 80:80 gauridocker777/devops:latest' }
        }
    }
}
```

</details>

---

## 🧠 OpenAI ChatGPT Integration
- Get API key from [platform.openai.com](https://platform.openai.com)
- Paste the key into your chatbot UI to enable GPT

---

## ☁️ Deploy to EKS using Jenkins + Terraform

Create another Jenkins pipeline: `EKS-TF`  
Set choice parameter: `apply` or `destroy`

<details>
<summary>Click to expand Terraform EKS Pipeline</summary>

```groovy
pipeline {
    agent any
    parameters {
        choice(name: 'action', choices: ['apply', 'destroy'], description: 'Terraform Action')
    }
    environment {
        TF_IN_AUTOMATION = "true"
        AWS_REGION = "ap-south-1"
    }
    stages {
        stage('AWS Credentials') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'aws_cred', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    script {
                        env.AWS_ACCESS_KEY_ID = AWS_ACCESS_KEY_ID
                        env.AWS_SECRET_ACCESS_KEY = AWS_SECRET_ACCESS_KEY
                    }
                }
            }
        }
        stage('Git Checkout') {
            steps {
                git branch: 'main', credentialsId: 'Capstone', url: 'https://github.com/Gaurigithub-p/ChatBot-Application.git'
            }
        }
        stage('Terraform Actions') {
            steps {
                dir('project/infra') {
                    sh 'terraform init'
                    sh 'terraform validate'
                    sh 'terraform plan'
                    sh "terraform ${params.action} --auto-approve"
                }
            }
        }
    }
}
```

</details>

---

## ☸️ Deploy to Kubernetes
- Run:  
```bash
aws eks update-kubeconfig --name <cluster-name> --region ap-south-1
```
- Save `~/.kube/config` as **Jenkins Secret File Credential (id: k8)**

```groovy
stage('Deploy to Kubernetes') {
    steps {
        script {
            withKubeConfig(credentialsId: 'k8') {
                sh 'kubectl apply -f deployment.yml'
                sh 'kubectl apply -f service.yml'
                sh 'kubectl apply -f ingress.yml'
            }
        }
    }
}
```

---

## 📂 Access ChatBot UI
- Through Docker: `http://<EC2-IP>:3000`
- Through EKS: `http://<LoadBalancer-DNS>`

---
