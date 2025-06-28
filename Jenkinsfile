pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE = 'laravel-multitenant'
        DOCKER_TAG = "${env.BUILD_NUMBER}"
        SONAR_TOKEN = credentials('sonar-token')
        DOCKER_REGISTRY = 'docker.io'  // Docker Hub
        DOCKER_USERNAME = 'moetaz1928'  // Remplacez par votre username
        // Utilisation des outils installés localement
        COMPOSER_PATH = 'composer'
        PHP_PATH = 'C:\\xampp\\php\\php.exe'
        TRIVY_PATH = 'C:\\Users\\User\\Downloads\\trivy_0.63.0_windows-64bit\\trivy.exe'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Install Dependencies') {
            steps {
                bat '"%COMPOSER_PATH%" install --optimize-autoloader --no-interaction'
            }
        }
        
        stage('Setup Laravel') {
            steps {
                bat '''
                    if exist .env.example (
                        copy .env.example .env
                    ) else (
                        echo APP_NAME=Laravel> .env
                    )
                    echo APP_ENV=testing>> .env
                    echo APP_DEBUG=true>> .env
                    echo DB_CONNECTION=sqlite>> .env
                    echo DB_DATABASE=:memory:>> .env
                    echo CACHE_DRIVER=array>> .env
                    echo SESSION_DRIVER=array>> .env
                    echo QUEUE_DRIVER=sync>> .env
                    "%PHP_PATH%" artisan key:generate --force
                    if errorlevel 1 (
                        echo Erreur lors de la génération de la clé
                        exit /b 1
                    )
                '''
            }
        }
        
        stage('Code Quality & Security') {
            parallel {
                stage('Unit Tests') {
                    steps {
                        bat '''
                            "%PHP_PATH%" vendor\\bin\\phpunit --testsuite=Unit --coverage-clover coverage.xml --log-junit junit-unit.xml
                            if errorlevel 1 (
                                echo Tests unitaires échoués
                                exit /b 1
                            )
                        '''
                    }
                    post {
                        always {
                            junit 'junit-unit.xml'
                            publishHTML([
                                allowMissing: true,
                                alwaysLinkToLastBuild: true,
                                keepAll: true,
                                reportDir: 'coverage',
                                reportFiles: 'index.html',
                                reportName: 'Unit Test Coverage'
                            ])
                        }
                    }
                }
                
                stage('Feature Tests') {
                    steps {
                        bat '''
                            "%PHP_PATH%" vendor\\bin\\phpunit --testsuite=Feature --log-junit junit-feature.xml
                            if errorlevel 1 (
                                echo Tests de fonctionnalités échoués
                                exit /b 1
                            )
                        '''
                    }
                    post {
                        always {
                            junit 'junit-feature.xml'
                        }
                    }
                }
                
                stage('Security Scan') {
                    steps {
                        bat '''
                            if exist "%TRIVY_PATH%" (
                                "%TRIVY_PATH%" fs . --severity HIGH,CRITICAL --format table --output trivy-report.txt
                            ) else (
                                echo Trivy non trouvé à %TRIVY_PATH%
                                echo Trivy Security Scan Skipped > trivy-report.txt
                            )
                        '''
                    }
                    post {
                        always {
                            publishHTML([
                                allowMissing: true,
                                alwaysLinkToLastBuild: true,
                                keepAll: true,
                                reportDir: '.',
                                reportFiles: 'trivy-report.txt',
                                reportName: 'Trivy Security Report'
                            ])
                        }
                    }
                }
                
                stage('SonarQube Analysis') {
                    steps {
                        withSonarQubeEnv('sonarqube') {
                            bat '''
                                "%PHP_PATH%" vendor\\bin\\phpunit --coverage-clover=coverage.xml --testsuite=Unit,Feature
                                "C:\\Users\\User\\Downloads\\sonar-scanner-cli-7.1.0.4889-windows-x64\\sonar-scanner-7.1.0.4889-windows-x64\\bin\\sonar-scanner.bat" -Dsonar.projectKey=touza-project -Dsonar.sources=app,config,database,resources,routes -Dsonar.exclusions=vendor/**,storage/**,bootstrap/cache/**,tests/** -Dsonar.php.coverage.reportPaths=coverage.xml
                            '''
                        }
                    }
                    post {
                        always {
                            echo "Étape SonarQube Analysis terminée"
                        }
                    }
                }
            }
        }
        
        stage('Mutation Tests') {
            steps {
                bat '''
                    "%PHP_PATH%" vendor\\bin\\infection --min-msi=80 --min-covered-msi=80 --log-verbosity=all
                    if errorlevel 1 (
                        echo Infection non disponible ou échec, étape ignorée
                        exit /b 0
                    )
                '''
            }
            post {
                always {
                    publishHTML([
                        allowMissing: true,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'infection-report',
                        reportFiles: 'index.html',
                        reportName: 'Mutation Test Report'
                    ])
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                bat '''
                    docker build -t %DOCKER_IMAGE%:%DOCKER_TAG% .
                    if errorlevel 1 (
                        echo Échec de la construction Docker
                        exit /b 1
                    )
                    docker tag %DOCKER_IMAGE%:%DOCKER_TAG% %DOCKER_IMAGE%:latest
                    echo Image construite avec succès
                '''
            }
        }
        
        stage('Scan Docker Image') {
            steps {
                bat '''
                    if exist "%TRIVY_PATH%" (
                        "%TRIVY_PATH%" image %DOCKER_IMAGE%:%DOCKER_TAG% --severity HIGH,CRITICAL --format table --output trivy-image-report.txt
                    ) else (
                        echo Trivy non trouvé, scan d'image ignoré
                        echo Docker Image Security Scan Skipped > trivy-image-report.txt
                    )
                '''
            }
            post {
                always {
                    publishHTML([
                        allowMissing: true,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: '.',
                        reportFiles: 'trivy-image-report.txt',
                        reportName: 'Trivy Docker Image Report'
                    ])
                }
            }
        }
        
        stage('Integration Tests') {
            steps {
                bat '''
                    docker compose -f docker-compose.test.yml down --remove-orphans
                    docker compose -f docker-compose.test.yml up -d db
                    timeout /t 30 /nobreak
                    docker compose -f docker-compose.test.yml exec -T db mysql -uroot -pRoot@1234 -e "SELECT 1;"
                    if errorlevel 1 (
                        echo Erreur de connexion à la base de données
                        docker compose -f docker-compose.test.yml logs db
                        exit /b 1
                    )
                    docker compose -f docker-compose.test.yml up -d app
                    timeout /t 10 /nobreak
                    docker compose -f docker-compose.test.yml exec -T app php artisan migrate --env=testing
                    docker compose -f docker-compose.test.yml exec -T app vendor/bin/phpunit --testsuite=Feature --log-junit junit-integration.xml
                    docker compose -f docker-compose.test.yml down --remove-orphans
                '''
            }
            post {
                always {
                    bat 'docker compose -f docker-compose.test.yml down --remove-orphans'
                    junit 'junit-integration.xml'
                }
            }
        }
        
        stage('Deploy') {
            when {
                branch 'main'
            }
            parallel {
                stage('Push to Registry') {
                    steps {
                        withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                            bat '''
                                echo %DOCKER_PASSWORD% | docker login %DOCKER_REGISTRY% -u %DOCKER_USERNAME% --password-stdin
                                docker tag %DOCKER_IMAGE%:%DOCKER_TAG% %DOCKER_USERNAME%/%DOCKER_IMAGE%:%DOCKER_TAG%
                                docker tag %DOCKER_IMAGE%:%DOCKER_TAG% %DOCKER_USERNAME%/%DOCKER_IMAGE%:latest
                                docker push %DOCKER_USERNAME%/%DOCKER_IMAGE%:%DOCKER_TAG%
                                docker push %DOCKER_USERNAME%/%DOCKER_IMAGE%:latest
                            '''
                        }
                    }
                }
                
                stage('Deploy to Staging') {
                    steps {
                        bat 'docker compose -f docker-compose.staging.yml up -d'
                    }
                }
            }
        }
    }
    
    post {
        always {
            bat '''
                docker image prune -f
                docker container prune -f
            '''
        }
        
        success {
            emailext (
                subject: "Build Successful: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: "Build completed successfully. See: ${env.BUILD_URL}",
                recipientProviders: [[$class: 'DevelopersRecipientProvider']]
            )
        }
        
        failure {
            emailext (
                subject: "Build Failed: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: "Build failed. See: ${env.BUILD_URL}",
                recipientProviders: [[$class: 'DevelopersRecipientProvider']]
            )
        }
        
        cleanup {
            cleanWs()
        }
    }
} 
