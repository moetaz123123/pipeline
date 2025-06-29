pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE = "laravel-app:latest"
        DOCKER_TAG = "${env.BUILD_NUMBER}"
        SONAR_TOKEN = credentials('SonarQube2')
        DOCKER_REGISTRY = 'docker.io'  // Docker Hub
        DOCKER_USERNAME = 'moetaz1928'  // Remplacez par votre username
        // Utilisation des outils installés localement
        COMPOSER_PATH = 'composer'
        PHP_PATH = 'C:\\xampp\\php\\php.exe'
        TRIVY_PATH = 'C:\\Users\\User\\Downloads\\trivy_0.63.0_windows-64bit\\trivy.exe'
        SONARQUBE_SERVER = 'SonarQube' // Nom configuré dans Jenkins
        SONAR_SCANNER_PATH = 'C:\\Users\\User\\Downloads\\sonar-scanner-4.8.0.2856-windows\\bin\\sonar-scanner.bat'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Composer Install') {
            steps {
                bat '''
                    echo === Installation des dépendances ===
                    if not exist composer.phar (
                        powershell -Command "Invoke-WebRequest -Uri https://getcomposer.org/composer.phar -OutFile composer.phar"
                    )
                    "%PHP_PATH%" composer.phar install --optimize-autoloader --no-interaction
                    if errorlevel 1 (
                        echo ERREUR: Échec de l'installation des dépendances
                        exit /b 1
                    )
                    echo Configuration des plugins...
                    "%PHP_PATH%" composer.phar config allow-plugins.infection/extension-installer true
                    "%PHP_PATH%" composer.phar require --dev infection/infection
                    echo === Dépendances installées avec succès ===
                '''
                bat 'dir vendor\\bin'
            }
        }

        stage('Trivy Scan') {
            steps {
                bat '''
                    echo === Scan de sécurité Trivy ===
                    echo Exécution du scan Trivy...
                    "%TRIVY_PATH%" fs . --skip-files vendor/laravel/pint/builds/pint --timeout 120s > trivy-report.txt 2>&1

                    echo Vérification du fichier de rapport...
                    if exist trivy-report.txt (
                        echo Fichier trivy-report.txt créé avec succès
                    ) else (
                        echo AVERTISSEMENT: Fichier trivy-report.txt non créé, création d'un rapport vide
                        echo "Aucune vulnérabilité détectée ou erreur lors du scan" > trivy-report.txt
                    )
                '''
            }
            post {
                always {
                    bat 'type trivy-report.txt'
                    writeFile file: 'trivy-report.html', text: """
                        <html>
                        <head>
                            <meta charset='UTF-8'>
                            <style>
                                body { background: #222; color: #eee; }
                                pre { font-family: monospace; font-size: 13px; }
                            </style>
                        </head>
                        <body>
                            <pre>
${readFile('trivy-report.txt')}
                            </pre>
                        </body>
                        </html>
                    """
                    publishHTML(target: [
                        allowMissing: true,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: '.',
                        reportFiles: 'trivy-report.html',
                        reportName: 'Trivy Security Scan (Tableaux CLI)'
                    ])
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    echo "=== Début de l'analyse SonarQube ==="
                    if (fileExists('sonar-project.properties')) {
                        echo "Fichier sonar-project.properties trouvé, utilisation de la configuration par défaut"
                        withSonarQubeEnv('SonarQube') {
                            bat """
                                echo Vérification de la connexion SonarQube...
                                echo Test de connexion à SonarQube...
                                curl -s -u %SONAR_TOKEN%: http://localhost:9000/api/system/status >nul 2>&1
                                if errorlevel 1 (
                                    echo ERREUR: Impossible de se connecter à SonarQube
                                    echo Vérifiez que SonarQube est démarré sur http://localhost:9000
                                    exit /b 1
                                )
                                
                                echo Vérification de PHPUnit...
                                if exist vendor\\bin\\phpunit.bat (
                                    echo Génération du rapport de couverture...
                                    \"%PHP_PATH%\" vendor\\bin\\phpunit.bat --coverage-clover=coverage.xml --log-junit=phpunit-report.xml
                                ) else if exist vendor\\bin\\phpunit (
                                    echo Génération du rapport de couverture...
                                    \"%PHP_PATH%\" vendor\\bin\\phpunit --coverage-clover=coverage.xml --log-junit=phpunit-report.xml
                                ) else (
                                    echo AVERTISSEMENT: PHPUnit non trouvé, génération d'un fichier de couverture vide
                                    echo ^<?xml version=\"1.0\" encoding=\"UTF-8\"?^>^<coverage^>^</coverage^> > coverage.xml
                                    echo ^<?xml version=\"1.0\" encoding=\"UTF-8\"?^>^<testsuites^>^</testsuites^> > phpunit-report.xml
                                )
                                
                                echo Lancement de sonar-scanner...
                                \"%SONAR_SCANNER_PATH%\" -Dsonar.projectKey=SonarQube -Dsonar.host.url=http://localhost:9000 -Dsonar.login=%SONAR_TOKEN%
                                if errorlevel 1 (
                                    echo ERREUR: Échec de l'analyse SonarQube
                                    echo Vérifiez les permissions du token SonarQube
                                    echo Vérifiez que le projet SonarQube existe dans SonarQube
                                    exit /b 1
                                )
                                echo === Analyse SonarQube terminée avec succès ===
                            """
                        }
                    } else {
                        echo "Fichier sonar-project.properties manquant, utilisation de la configuration inline"
                        withSonarQubeEnv('SonarQube') {
                            bat """
                                echo Test de connexion à SonarQube...
                                curl -s -u %SONAR_TOKEN%: http://localhost:9000/api/system/status >nul 2>&1
                                if errorlevel 1 (
                                    echo ERREUR: Impossible de se connecter à SonarQube
                                    echo Vérifiez que SonarQube est démarré sur http://localhost:9000
                                    exit /b 1
                                )
                                
                                echo Vérification de PHPUnit...
                                if exist vendor\\bin\\phpunit.bat (
                                    echo Génération du rapport de couverture...
                                    \"%PHP_PATH%\" vendor\\bin\\phpunit.bat --coverage-clover=coverage.xml --log-junit=phpunit-report.xml
                                ) else if exist vendor\\bin\\phpunit (
                                    echo Génération du rapport de couverture...
                                    \"%PHP_PATH%\" vendor\\bin\\phpunit --coverage-clover=coverage.xml --log-junit=phpunit-report.xml
                                ) else (
                                    echo AVERTISSEMENT: PHPUnit non trouvé, génération d'un fichier de couverture vide
                                    echo ^<?xml version=\"1.0\" encoding=\"UTF-8\"?^>^<coverage^>^</coverage^> > coverage.xml
                                    echo ^<?xml version=\"1.0\" encoding=\"UTF-8\"?^>^<testsuites^>^</testsuites^> > phpunit-report.xml
                                )
                                
                                echo Lancement de sonar-scanner avec configuration inline...
                                \"%SONAR_SCANNER_PATH%\" ^
                                    -Dsonar.projectKey=SonarQube ^
                                    -Dsonar.projectName=SonarQube ^
                                    -Dsonar.sources=app,config,database,resources,routes ^
                                    -Dsonar.tests=tests ^
                                    -Dsonar.exclusions=vendor/**,storage/**,bootstrap/cache/**,node_modules/** ^
                                    -Dsonar.php.coverage.reportPaths=coverage.xml ^
                                    -Dsonar.php.tests.reportPath=phpunit-report.xml ^
                                    -Dsonar.host.url=http://localhost:9000 ^
                                    -Dsonar.login=%SONAR_TOKEN%
                                if errorlevel 1 (
                                    echo ERREUR: Échec de l'analyse SonarQube
                                    echo Vérifiez les permissions du token SonarQube
                                    echo Vérifiez que le projet SonarQube existe dans SonarQube
                                    exit /b 1
                                )
                                echo === Analyse SonarQube terminée avec succès ===
                            """
                        }
                    }
                }
            }
            post {
                always {
                    echo "Étape SonarQube Analysis terminée"
                    publishHTML(target: [
                        allowMissing: true,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: '.',
                        reportFiles: 'coverage.xml',
                        reportName: 'SonarQube Coverage Report'
                    ])
                }
            }
        }

        stage('Unit Tests') {
            steps {
                bat '''
                    echo === Tests unitaires ===
                    composer exec -- phpunit --testsuite=Unit --log-junit junit-unit.xml
                    if errorlevel 1 (
                        echo ERREUR: Tests unitaires échoués
                        exit /b 1
                    )
                    echo === Tests unitaires terminés ===
                '''
            }
            post {
                always {
                    junit 'junit-unit.xml'
                }
            }
        }

        stage('Mutation Tests') {
            steps {
                bat '''
                    echo === Tests de mutation ===
                    copy .env .env.backup
                    copy .env.example .env
                    "%PHP_PATH%" artisan key:generate --force
                    echo Tests de mutation avec Infection...
                    if exist vendor\\bin\\infection.bat (
                        "%PHP_PATH%" vendor\\bin\\infection.bat --logger-html=infection-report.html
                    ) else if exist vendor\\bin\\infection (
                        "%PHP_PATH%" vendor\\bin\\infection --logger-html=infection-report.html
                    ) else (
                        echo AVERTISSEMENT: Infection non trouvé, exécution des tests de base
                        composer exec -- phpunit
                        echo Tests de mutation de base terminés
                    )
                    echo AVERTISSEMENT: Tests de mutation complets nécessitent des extensions de couverture (xdebug/pcov)
                    echo Tests de mutation terminés
                '''
            }
            post {
                always {
                    publishHTML(target: [
                        allowMissing: true,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: '.',
                        reportFiles: 'infection-report.html',
                        reportName: 'Mutation Testing Report'
                    ])
                }
            }
        }

        stage('Debug Workspace') {
            steps {
                bat 'dir'
                bat 'dir /s server.php'
            }
        }

        stage('Create server.php') {
            steps {
                bat '''
                    echo === Création du fichier server.php ===
                    echo ^<?php > server.php
                    echo. >> server.php
                    echo /** >> server.php
                    echo  * Laravel - A PHP Framework For Web Artisans >> server.php
                    echo  * >> server.php
                    echo  * @package  Laravel >> server.php
                    echo  * @author   Taylor Otwell ^<taylor@laravel.com^> >> server.php
                    echo  */ >> server.php
                    echo. >> server.php
                    echo $uri = urldecode( >> server.php
                    echo     parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH) ?? '' >> server.php
                    echo ); >> server.php
                    echo. >> server.php
                    echo // This file allows us to emulate Apache's "mod_rewrite" functionality from the >> server.php
                    echo // built-in PHP web server. This provides a convenient way to test a Laravel >> server.php
                    echo // application without having installed a "real" web server software here. >> server.php
                    echo if ($uri !== '/' ^&^& file_exists(__DIR__.'/public'.$uri)) { >> server.php
                    echo     return false; >> server.php
                    echo } >> server.php
                    echo. >> server.php
                    echo require_once __DIR__.'/public/index.php'; >> server.php
                    echo === Fichier server.php créé avec succès ===
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                bat '''
                    echo === Construction de l'image Docker ===
                    echo Vérification de la présence du fichier .env...
                    if not exist .env (
                        echo AVERTISSEMENT: Fichier .env non trouvé, création d'un fichier .env de base
                        echo APP_NAME=Laravel > .env
                        echo APP_ENV=local >> .env
                        echo APP_KEY= >> .env
                        echo APP_DEBUG=true >> .env
                        echo APP_URL=http://localhost:8000 >> .env
                        echo DB_CONNECTION=mysql >> .env
                        echo DB_HOST=db >> .env
                        echo DB_PORT=3306 >> .env
                        echo DB_DATABASE=laravel_multitenant >> .env
                        echo DB_USERNAME=root >> .env
                        echo DB_PASSWORD=rootpassword >> .env
                        echo Fichier .env créé avec succès
                    ) else (
                        echo Fichier .env trouvé
                    )
                    
                    echo Construction de l'image Docker...
                    docker build -t %DOCKER_IMAGE% .
                    if errorlevel 1 (
                        echo ERREUR: Échec de la construction Docker
                        exit /b 1
                    )
                    echo === Image Docker construite ===
                '''
            }
        }

        stage('Trivy Image Scan') {
            steps {
                bat '''
                    echo === Scan de sécurité Trivy (image Docker) ===
                    "%TRIVY_PATH%" image %DOCKER_IMAGE% --timeout 120s > trivy-image-report.txt 2>&1
                    if exist trivy-image-report.txt (
                        echo Fichier trivy-image-report.txt créé avec succès
                    ) else (
                        echo AVERTISSEMENT: Fichier trivy-image-report.txt non créé, création d'un rapport vide
                        echo "Aucune vulnérabilité détectée ou erreur lors du scan" > trivy-image-report.txt
                    )
                '''
            }
            post {
                always {
                    bat 'type trivy-image-report.txt'
                    script {
                        def trivyImageText = readFile('trivy-image-report.txt')
                        writeFile file: 'trivy-image-report.html', text: """
                            <html>
                            <head>
                                <meta charset='UTF-8'>
                                <style>
                                    body { background: #222; color: #eee; }
                                    pre { font-family: monospace; font-size: 13px; }
                                </style>
                            </head>
                            <body>
                                <pre>
${trivyImageText}
                                </pre>
                            </body>
                            </html>
                        """
                    }
                    publishHTML(target: [
                        allowMissing: true,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: '.',
                        reportFiles: 'trivy-image-report.html',
                        reportName: 'Trivy Docker Image Security Scan'
                    ])
                }
            }
        }

        stage('Deploy') {
            steps {
                // Arrêter et nettoyer les anciens conteneurs
                bat 'docker-compose down'
                bat 'docker container prune -f'

                // Démarrer les services
                bat 'docker-compose up -d'

                // Attendre que les services soient prêts
                bat 'powershell -Command "Start-Sleep -Seconds 30"'
                bat 'docker-compose ps'
                bat 'docker-compose logs app'

                // Attendre que le conteneur app soit prêt
                script {
                    def maxWaitTime = 60
                    def waitTime = 0
                    def containerReady = false

                    while (waitTime < maxWaitTime && !containerReady) {
                        try {
                            echo "=== Container logs ==="
                            bat 'docker-compose logs app'
                            echo "====================="
                            def status = bat(script: 'docker-compose ps app', returnStdout: true).trim()
                            echo "Container status: ${status}"
                            if (status.contains('Up')) {
                                try {
                                    bat 'docker-compose exec -T app echo "Container is responding"'
                                    containerReady = true
                                    echo "✅ Container is ready after ${waitTime} seconds"
                                } catch (Exception e) {
                                    echo "⏳ Container is Up but not responding yet, waiting..."
                                    bat 'powershell -Command "Start-Sleep -Seconds 5"'
                                    waitTime += 5
                                }
                            } else {
                                echo "⏳ Container not ready yet, waiting..."
                                bat 'powershell -Command "Start-Sleep -Seconds 5"'
                                waitTime += 5
                            }
                        } catch (Exception e) {
                            echo "⏳ Container not responding yet, waiting..."
                            bat 'powershell -Command "Start-Sleep -Seconds 5"'
                            waitTime += 5
                        }
                    }
                    if (!containerReady) {
                        echo "❌ Container failed to become ready after ${maxWaitTime} seconds"
                        echo "=== Final container status ==="
                        bat 'docker-compose ps'
                        echo "=== Final container logs ==="
                        bat 'docker-compose logs app'
                        echo "============================"
                        error "❌ Container failed to become ready after ${maxWaitTime} seconds"
                    }
                }

                // Migrations avec retry
                script {
                    def maxRetries = 3
                    def retryCount = 0
                    def migrationSuccess = false
                    while (retryCount < maxRetries && !migrationSuccess) {
                        try {
                            bat 'docker-compose exec -T app php artisan migrate --force'
                            migrationSuccess = true
                            echo "✅ Migration completed successfully on attempt ${retryCount + 1}"
                        } catch (Exception e) {
                            retryCount++
                            echo "❌ Migration attempt ${retryCount} failed: ${e.getMessage()}"
                            if (retryCount < maxRetries) {
                                echo "⏳ Waiting 15 seconds before retry..."
                                bat 'powershell -Command "Start-Sleep -Seconds 15"'
                                bat 'docker-compose ps'
                            }
                        }
                    }
                    if (!migrationSuccess) {
                        error "❌ Migration failed after ${maxRetries} attempts"
                    }
                }

                // Seeders
                script {
                    try {
                        echo "🌱 Running database seeders..."
                        bat 'docker-compose exec -T app php artisan db:seed --force'
                        echo "✅ Database seeding completed successfully"
                    } catch (Exception e) {
                        echo "❌ Database seeding failed: ${e.getMessage()}"
                        echo "⚠️ Continuing deployment despite seeding failure"
                    }
                }

                // Statut final et logs
                bat 'docker-compose ps'
                bat 'docker-compose logs --tail=20'
            }
        }
    }

    post {
        always {
            bat '''
                echo === Nettoyage ===
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
