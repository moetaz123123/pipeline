pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE = "laravel-app:latest"
        DOCKER_TAG = "${env.BUILD_NUMBER}"
        SONAR_TOKEN = credentials('sonar-token')
        DOCKER_REGISTRY = 'docker.io'  // Docker Hub
        DOCKER_USERNAME = 'moetaz1928'  // Remplacez par votre username
        // Utilisation des outils installés localement
        COMPOSER_PATH = 'composer'
        PHP_PATH = 'C:\\xampp\\php\\php.exe'
        TRIVY_PATH = 'C:\\Users\\User\\Downloads\\trivy_0.63.0_windows-64bit\\trivy.exe'
        SONARQUBE_SERVER = 'ayoub' // Nom configuré dans Jenkins
       
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Composer Install') {
            steps {
                bat 'composer install'
                bat 'composer config allow-plugins.infection/extension-installer true'
                bat 'composer require --dev infection/infection'
            }
        }

        stage('Trivy Scan') {
            steps {
                bat 'docker build -t %DOCKER_IMAGE% .'
                bat 'docker run --rm -v //var/run/docker.sock:/var/run/docker.sock aquasec/trivy image %DOCKER_IMAGE%'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('ayoub') {
                    bat 'vendor\\bin\\phpunit'
                    bat '"C:\\Users\\MSI\\Downloads\\sonar-scanner-cli-7.1.0.4889-windows-x64\\sonar-scanner-7.1.0.4889-windows-x64\\bin\\sonar-scanner.bat" -Dsonar.projectKey=laravel-app -Dsonar.sources=app -Dsonar.tests=tests -Dsonar.host.url=http://localhost:9000 -Dsonar.login=%SONAR_AUTH_TOKEN%'
                }
            }
        }

        stage('Unit Tests') {
            steps {
                bat 'vendor\\bin\\phpunit'
            }
        }

        stage('Mutation Tests') {
            steps {
                bat 'copy .env .env.backup'
                bat 'copy .env.example .env'
                bat 'php artisan key:generate'
                bat 'vendor\\bin\\phpunit'
                // Mutation testing requires code coverage extensions (xdebug/pcov) not available on Windows
                // bat 'vendor\\bin\\infection --threads=2 --noop'
                echo 'Mutation testing skipped - requires code coverage extensions not available on Windows'
            }
        }

        stage('Build Docker Image') {
            steps {
                bat 'docker build -t %DOCKER_IMAGE% .'
            }
        }

        stage('Deploy') {
            steps {
                bat 'docker run -d --rm -p 9000:9000 %DOCKER_IMAGE%'
            }
        }
    }
}
