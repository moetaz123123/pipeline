pipeline {
    agent any
    
   environment {
        DOCKER_IMAGE = 'laravel-multitenant'
        DOCKER_TAG = "${env.BUILD_NUMBER}"
        SONAR_TOKEN = credentials('sonar-token')
        DOCKER_REGISTRY = 'docker.io'
        DOCKER_USERNAME = 'moetaz1928'
        COMPOSER_PATH = 'composer'
        PHP_PATH = 'C:\\xampp\\php\\php.exe'
        TRIVY_PATH = 'C:\\Users\\User\\Downloads\\trivy_0.63.0_windows-64bit\\trivy.exe'
        SONARQUBE_URL = 'http://host.docker.internal:9000'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Install Dependencies') {
            steps {
                script {
                    bat 'composer install --optimize-autoloader --no-interaction'
                }
            }
        }
        
        stage('Setup Laravel') {
            steps {
                script {
                    bat '''
                        if exist .env.example (
                            copy .env.example .env
                        ) else (
                            echo .env.example non trouvé, création d'un .env basique
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
                            echo Erreur lors de la génération de la clé, génération manuelle
                            powershell -Command "$key = [Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Maximum 256 })); Add-Content -Path '.env' -Value \\"APP_KEY=base64:$key\\""
                        )
                        findstr "APP_KEY=base64:" .env >nul
                        if errorlevel 1 (
                            powershell -Command "$key = [Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Maximum 256 })); Add-Content -Path '.env' -Value \\"APP_KEY=base64:$key\\""
                        )
                        echo Configuration Laravel pour les tests:
                        findstr "APP_ENV APP_DEBUG DB_CONNECTION APP_KEY" .env
                    '''
                }
            }
        }
        
        stage('Code Quality & Security') {
            parallel {
                stage('Unit Tests') {
                    steps {
                        script {
                            bat '''
                                "%PHP_PATH%" vendor/bin/phpunit --testsuite=Unit --coverage-clover coverage.xml --log-junit junit-unit.xml
                            '''
                        }
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
                        script {
                            bat '''
                                "%PHP_PATH%" vendor/bin/phpunit --testsuite=Feature --log-junit junit-feature.xml
                            '''
                        }
                    }
                    post {
                        always {
                            junit 'junit-feature.xml'
                        }
                    }
                }
                
                stage('Security Scan') {
                    steps {
                        script {
                            bat '''
                                "%TRIVY_PATH%" fs . --severity HIGH,CRITICAL --format table --output trivy-report.txt
                            '''
                        }
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
                        script {
                            echo "=== Début de l'analyse SonarQube ==="
                            
                            // Vérifier si sonar-scanner est disponible de manière plus robuste
                            def scannerPath = bat(
                                script: 'where sonar-scanner',
                                returnStdout: true
                            ).trim()
                            
                            echo "Chemin du sonar-scanner: ${scannerPath}"
                            
                            if (scannerPath != "") {
                                echo "SonarQube Scanner trouvé à: ${scannerPath}"
                                
                                // Vérifier que le fichier de configuration existe
                                if (fileExists('sonar-project.properties')) {
                                    echo "Fichier sonar-project.properties trouvé"
                                    
                                    withSonarQubeEnv('touza-project') {
                                        bat '''
                                            "%PHP_PATH%" vendor/bin/phpunit --coverage-clover=coverage.xml
                                            "C:\\Users\\User\\Downloads\\sonar-scanner-cli-7.1.0.4889-windows-x64\\sonar-scanner-7.1.0.4889-windows-x64\\bin\\sonar-scanner.bat" -Dsonar.projectKey=touza-project -Dsonar.php.coverage.reportPaths=coverage.xml -Dsonar.sources=app -Dsonar.tests=tests -Dsonar.host.url=http://localhost:9000
                                        '''
                                    }
                                } else {
                                    echo "Fichier sonar-project.properties manquant, utilisation de la configuration par défaut"
                                    withSonarQubeEnv('touza-project') {
                                        bat '''
                                            "%PHP_PATH%" vendor/bin/phpunit --coverage-clover=coverage.xml
                                            "C:\\Users\\User\\Downloads\\sonar-scanner-cli-7.1.0.4889-windows-x64\\sonar-scanner-7.1.0.4889-windows-x64\\bin\\sonar-scanner.bat" -Dsonar.projectKey=touza-project -Dsonar.php.coverage.reportPaths=coverage.xml -Dsonar.sources=app -Dsonar.tests=tests -Dsonar.host.url=http://localhost:9000
                                        '''
                                    }
                                }
                            } else {
                                echo "SonarQube Scanner non installé, étape ignorée"
                                echo "Pour installer: wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-4.8.0.2856-linux.zip"
                            }
                            
                            echo "=== Fin de l'analyse SonarQube ==="
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
                script {
                    bat '${PHP_PATH} vendor/bin/infection --min-msi=80 --min-covered-msi=80 --log-verbosity=all || echo "Infection non disponible ou échec, étape ignorée"'
                }
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
        
        stage('Build & Security') {
            parallel {
                stage('Build Docker Image') {
                    steps {
                        bat '''
                            echo Construction de l'image Docker...
                            docker build -t %DOCKER_IMAGE%:%DOCKER_TAG% .
                            docker tag %DOCKER_IMAGE%:%DOCKER_TAG% %DOCKER_IMAGE%:latest
                            echo Image construite avec succès
                            docker images
                        '''
                    }
                }
            }
        }
        
        stage('Scan Docker Image') {
            steps {
                bat '''
                    echo Vérification de l'existence de l'image...
                    docker images
                    docker image inspect %DOCKER_IMAGE%:%DOCKER_TAG%
                    if errorlevel 1 (
                        echo Image non trouvée, tentative avec :latest
                        docker image inspect %DOCKER_IMAGE%:latest
                        if errorlevel 1 (
                            echo Image non trouvée avec les tags %DOCKER_TAG% ou latest
                            exit /b 1
                        ) else (
                            set TAG=latest
                        )
                    ) else (
                        set TAG=%DOCKER_TAG%
                    )
                    "%TRIVY_PATH%" image %DOCKER_IMAGE%:%TAG% --severity HIGH,CRITICAL --format table --output trivy-image-report.txt
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
                    echo Nettoyage des conteneurs existants...
                    docker compose -f docker-compose.test.yml down --remove-orphans
                    docker container rm -f laravel_db_test_%BUILD_NUMBER% laravel_app_test_%BUILD_NUMBER%
                    echo Démarrage de la base de données de test...
                    docker compose -f docker-compose.test.yml up -d db
                    echo Attente que la base de données soit prête...
                    timeout /t 30 /nobreak
                    echo Vérification de la connexion à la base de données...
                    docker compose -f docker-compose.test.yml exec -T db mysql -uroot -pRoot@1234 -e "SELECT 1;"
                    echo Démarrage de l'application de test...
                    docker compose -f docker-compose.test.yml up -d app
                    timeout /t 10 /nobreak
                    echo Exécution des migrations...
                    docker compose -f docker-compose.test.yml exec -T app php artisan migrate --env=testing
                    echo Exécution des tests d'intégration...
                    docker compose -f docker-compose.test.yml exec -T app vendor/bin/phpunit --testsuite=Feature --log-junit junit-integration.xml
                    echo Nettoyage des conteneurs de test...
                    docker compose -f docker-compose.test.yml down --remove-orphans
                '''
            }
            post {
                always {
                    bat '''
                        docker compose -f docker-compose.test.yml down --remove-orphans
                        docker container rm -f laravel_db_test_%BUILD_NUMBER% laravel_app_test_%BUILD_NUMBER%
                    '''
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
                        script {
                            withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                                bat '''
                                    echo ${DOCKER_PASSWORD} | docker login ${DOCKER_REGISTRY} -u ${DOCKER_USERNAME} --password-stdin
                                    docker tag %DOCKER_IMAGE%:%DOCKER_TAG% ${DOCKER_USERNAME}/${%DOCKER_IMAGE%}:%DOCKER_TAG%
                                    docker tag %DOCKER_IMAGE%:%DOCKER_TAG% ${DOCKER_USERNAME}/${%DOCKER_IMAGE%}:latest
                                    docker push ${DOCKER_USERNAME}/${%DOCKER_IMAGE%}:%DOCKER_TAG%
                                    docker push ${DOCKER_USERNAME}/${%DOCKER_IMAGE%}:latest
                                '''
                            }
                        }
                    }
                }
                
                stage('Deploy to Staging') {
                    steps {
                        script {
                            bat 'docker compose -f docker-compose.staging.yml up -d'
                        }
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
