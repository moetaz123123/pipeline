pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE = 'laravel-multitenant'
        DOCKER_TAG = "${env.BUILD_NUMBER}"
        SONAR_TOKEN = credentials('sonar-token')
        DOCKER_REGISTRY = 'docker.io'
        DOCKER_USERNAME = 'moetaz1928'
        
        // Configuration Windows
        COMPOSER_PATH = 'composer'
        PHP_PATH = 'C:\\xampp\\php\\php.exe'
        TRIVY_PATH = 'C:\\Users\\User\\Downloads\\trivy_0.63.0_windows-64bit\\trivy.exe'
        SONAR_SCANNER_PATH = 'C:\\Users\\User\\Downloads\\sonar-scanner-cli-7.1.0.4889-windows-x64\\sonar-scanner-7.1.0.4889-windows-x64\\bin\\sonar-scanner.bat'
        SONARQUBE_URL = 'http://localhost:9000'
        
        // Variables pour la base de données
        DB_HOST = 'localhost'
        DB_PORT = '3306'
        DB_DATABASE = 'db'
        DB_USERNAME = 'root'
        DB_PASSWORD = 'rootpassword'
    }
    
    stages {
        stage('Environment Check') {
            steps {
                script {
                    echo "=== Vérification de l'environnement Windows ==="
                    bat '''
                        echo Système: Windows
                        echo.
                        echo PHP Version:
                        "%PHP_PATH%" --version 2>nul || echo PHP non trouvé à %PHP_PATH%
                        echo.
                        echo Composer Version:
                        "%COMPOSER_PATH%" --version 2>nul || echo Composer non trouvé
                        echo.
                        echo Docker Version:
                        docker --version 2>nul || echo Docker non trouvé
                        echo.
                        echo Trivy disponible:
                        if exist "%TRIVY_PATH%" (echo Trivy trouvé) else (echo Trivy non trouvé)
                        echo.
                        echo SonarQube Scanner disponible:
                        if exist "%SONAR_SCANNER_PATH%" (echo SonarQube Scanner trouvé) else (echo SonarQube Scanner non trouvé)
                    '''
                }
            }
        }
        
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    bat '''
                        echo === Informations du commit ===
                        git log -1 --oneline 2>nul || echo Informations Git non disponibles
                        echo Branche actuelle: %GIT_BRANCH%
                        echo Build numéro: %BUILD_NUMBER%
                    '''
                }
            }
        }
        
        stage('Install Dependencies') {
            steps {
                script {
                    bat '''
                        echo === Installation des dépendances PHP ===
                        "%COMPOSER_PATH%" install --optimize-autoloader --no-interaction --prefer-dist
                        
                        echo.
                        echo === Vérification des dépendances critiques ===
                        if exist "vendor\\bin\\phpunit.bat" (
                            echo ✓ PHPUnit installé
                        ) else (
                            echo ✗ PHPUnit manquant
                        )
                        
                        if exist "vendor\\autoload.php" (
                            echo ✓ Autoloader disponible
                        ) else (
                            echo ✗ Autoloader manquant
                            exit /b 1
                        )
                    '''
                }
            }
        }
        
        stage('Setup Laravel') {
            steps {
                script {
                    bat '''
                        echo === Configuration Laravel pour les tests ===
                        
                        REM Copie du fichier d'environnement
                        if exist .env.example (
                            copy .env.example .env >nul
                            echo ✓ .env.example copié vers .env
                        ) else (
                            echo .env.example non trouvé, création d'un .env basique
                            echo APP_NAME=Laravel> .env
                        )
                        
                        REM Configuration pour les tests
                        echo APP_ENV=testing>> .env
                        echo APP_DEBUG=true>> .env
                        echo DB_CONNECTION=sqlite>> .env
                        echo DB_DATABASE=:memory:>> .env
                        echo CACHE_DRIVER=array>> .env
                        echo SESSION_DRIVER=array>> .env
                        echo QUEUE_DRIVER=sync>> .env
                        echo MAIL_MAILER=array>> .env
                        
                        REM Génération de la clé d'application
                        echo Génération de la clé d'application...
                        "%PHP_PATH%" artisan key:generate --force 2>nul
                        if errorlevel 1 (
                            echo Erreur lors de la génération automatique, génération manuelle...
                            powershell -Command "$key = [Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Maximum 256 })); Add-Content -Path '.env' -Value 'APP_KEY=base64:' + $key"
                        )
                        
                        REM Vérification que la clé est bien définie
                        findstr "APP_KEY=base64:" .env >nul
                        if errorlevel 1 (
                            echo Génération manuelle de la clé d'application...
                            powershell -Command "$key = [Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Maximum 256 })); Add-Content -Path '.env' -Value 'APP_KEY=base64:' + $key"
                        )
                        
                        echo.
                        echo === Configuration Laravel finale ===
                        findstr /C:"APP_ENV" /C:"APP_DEBUG" /C:"DB_CONNECTION" /C:"APP_KEY" .env
                        
                        echo.
                        echo === Cache des configurations ===
                        "%PHP_PATH%" artisan config:clear 2>nul || echo Configuration cache non vidé
                        "%PHP_PATH%" artisan route:clear 2>nul || echo Route cache non vidé
                        "%PHP_PATH%" artisan view:clear 2>nul || echo View cache non vidé
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
                                echo === Exécution des tests unitaires ===
                                "%PHP_PATH%" vendor\\bin\\phpunit --testsuite=Unit --coverage-clover coverage.xml --log-junit junit-unit.xml --coverage-html coverage-html
                                
                                echo.
                                echo === Résultats des tests unitaires ===
                                if exist junit-unit.xml (
                                    echo ✓ Rapport JUnit généré
                                ) else (
                                    echo ✗ Rapport JUnit manquant
                                )
                                
                                if exist coverage.xml (
                                    echo ✓ Rapport de couverture généré
                                ) else (
                                    echo ✗ Rapport de couverture manquant
                                )
                            '''
                        }
                    }
                    post {
                        always {
                            junit allowEmptyResults: true, testResultsPattern: 'junit-unit.xml'
                            publishHTML([
                                allowMissing: true,
                                alwaysLinkToLastBuild: true,
                                keepAll: true,
                                reportDir: 'coverage-html',
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
                                echo === Exécution des tests de fonctionnalités ===
                                "%PHP_PATH%" vendor\\bin\\phpunit --testsuite=Feature --log-junit junit-feature.xml
                                
                                echo.
                                if exist junit-feature.xml (
                                    echo ✓ Tests de fonctionnalités terminés
                                ) else (
                                    echo ✗ Échec des tests de fonctionnalités
                                )
                            '''
                        }
                    }
                    post {
                        always {
                            junit allowEmptyResults: true, testResultsPattern: 'junit-feature.xml'
                        }
                    }
                }
                
                stage('Security Scan') {
                    steps {
                        script {
                            bat '''
                                echo === Scan de sécurité avec Trivy ===
                                if exist "%TRIVY_PATH%" (
                                    echo Lancement du scan de sécurité...
                                    "%TRIVY_PATH%" fs . --severity HIGH,CRITICAL --format table --output trivy-report.txt
                                    echo ✓ Scan de sécurité terminé
                                ) else (
                                    echo ⚠ Trivy non disponible, scan ignoré
                                    echo Trivy Security Scan Skipped - Tool not found > trivy-report.txt
                                )
                                
                                echo.
                                echo === Scan des dépendances Composer ===
                                "%COMPOSER_PATH%" audit --format=json > composer-audit.json 2>nul || echo Audit Composer non disponible
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
                            bat '''
                                echo === Analyse SonarQube ===
                                
                                if exist "%SONAR_SCANNER_PATH%" (
                                    echo SonarQube Scanner trouvé
                                    
                                    REM Génération du rapport de couverture pour SonarQube
                                    "%PHP_PATH%" vendor\\bin\\phpunit --coverage-clover=coverage.xml --testsuite=Unit,Feature
                                    
                                    REM Vérification du fichier de configuration
                                    if exist sonar-project.properties (
                                        echo Utilisation du fichier sonar-project.properties
                                        type sonar-project.properties
                                    ) else (
                                        echo Création de la configuration SonarQube par défaut
                                        echo sonar.projectKey=touza-project> sonar-project.properties
                                        echo sonar.projectName=Laravel Multi-Tenant>> sonar-project.properties
                                        echo sonar.projectVersion=1.0>> sonar-project.properties
                                        echo sonar.sources=app,config,database,resources,routes>> sonar-project.properties
                                        echo sonar.tests=tests>> sonar-project.properties
                                        echo sonar.exclusions=vendor/**,storage/**,bootstrap/cache/**,node_modules/**>> sonar-project.properties
                                        echo sonar.php.coverage.reportPaths=coverage.xml>> sonar-project.properties
                                        echo sonar.host.url=%SONARQUBE_URL%>> sonar-project.properties
                                    )
                                    
                                    REM Lancement de l'analyse SonarQube
                                    "%SONAR_SCANNER_PATH%" -Dsonar.projectKey=touza-project -Dsonar.host.url=%SONARQUBE_URL%
                                    
                                ) else (
                                    echo ⚠ SonarQube Scanner non trouvé à %SONAR_SCANNER_PATH%
                                    echo Analyse SonarQube ignorée
                                )
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
        
        stage('Build & Security') {
            parallel {
                stage('Build Docker Image') {
                    steps {
                        script {
                            bat '''
                                echo === Construction de l'image Docker ===
                                
                                REM Vérification que Docker est disponible
                                docker --version >nul 2>&1
                                if errorlevel 1 (
                                    echo ✗ Docker n'est pas disponible
                                    exit /b 1
                                )
                                
                                REM Construction de l'image
                                echo Construction de l'image %DOCKER_IMAGE%:%DOCKER_TAG%...
                                docker build -t %DOCKER_IMAGE%:%DOCKER_TAG% .
                                if errorlevel 1 (
                                    echo ✗ Échec de la construction Docker
                                    exit /b 1
                                )
                                
                                REM Tag latest
                                docker tag %DOCKER_IMAGE%:%DOCKER_TAG% %DOCKER_IMAGE%:latest
                                
                                echo ✓ Image construite avec succès
                                echo.
                                echo === Images Docker disponibles ===
                                docker images | findstr %DOCKER_IMAGE%
                            '''
                        }
                    }
                }
            }
        }
        
        stage('Scan Docker Image') {
            steps {
                script {
                    bat '''
                        echo === Scan de sécurité de l'image Docker ===
                        
                        REM Vérification de l'existence de l'image
                        docker image inspect %DOCKER_IMAGE%:%DOCKER_TAG% >nul 2>&1
                        if errorlevel 1 (
                            echo Image avec tag %DOCKER_TAG% non trouvée, tentative avec :latest
                            docker image inspect %DOCKER_IMAGE%:latest >nul 2>&1
                            if errorlevel 1 (
                                echo ✗ Aucune image trouvée avec les tags %DOCKER_TAG% ou latest
                                echo Images disponibles:
                                docker images
                                exit /b 1
                            ) else (
                                set IMAGE_TAG=latest
                            )
                        ) else (
                            set IMAGE_TAG=%DOCKER_TAG%
                        )
                        
                        REM Scan avec Trivy si disponible
                        if exist "%TRIVY_PATH%" (
                            echo Scan de l'image %DOCKER_IMAGE%:!IMAGE_TAG!...
                            "%TRIVY_PATH%" image %DOCKER_IMAGE%:!IMAGE_TAG! --severity HIGH,CRITICAL --format table --output trivy-image-report.txt
                            echo ✓ Scan de l'image terminé
                        ) else (
                            echo ⚠ Trivy non disponible, scan d'image ignoré
                            echo Docker Image Security Scan Skipped - Trivy not found > trivy-image-report.txt
                        )
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
                        reportFiles: 'trivy-image-report.txt',
                        reportName: 'Trivy Docker Image Report'
                    ])
                }
            }
        }
        
        stage('Integration Tests') {
            steps {
                script {
                    bat '''
                        echo === Tests d'intégration avec Docker Compose ===
                        
                        REM Nettoyage préalable
                        echo Nettoyage des conteneurs existants...
                        docker compose -f docker-compose.test.yml down --remove-orphans 2>nul || echo Aucun conteneur à nettoyer
                        
                        REM Démarrage de la base de données
                        echo Démarrage de la base de données de test...
                        docker compose -f docker-compose.test.yml up -d db
                        if errorlevel 1 (
                            echo ✗ Échec du démarrage de la base de données
                            exit /b 1
                        )
                        
                        REM Attente que la base de données soit prête
                        echo Attente que la base de données soit prête (30 secondes)...
                        timeout /t 30 /nobreak >nul
                        
                        REM Vérification de la connexion à la base de données
                        echo Vérification de la connexion à la base de données...
                        docker compose -f docker-compose.test.yml exec -T db mysql -uroot -p%DB_PASSWORD% -e "SELECT 1;" >nul 2>&1
                        if errorlevel 1 (
                            echo ✗ Impossible de se connecter à la base de données
                            echo Logs de la base de données:
                            docker compose -f docker-compose.test.yml logs db
                            docker compose -f docker-compose.test.yml down --remove-orphans
                            exit /b 1
                        )
                        
                        REM Démarrage de l'application
                        echo Démarrage de l'application de test...
                        docker compose -f docker-compose.test.yml up -d app
                        timeout /t 10 /nobreak >nul
                        
                        REM Exécution des migrations
                        echo Exécution des migrations...
                        docker compose -f docker-compose.test.yml exec -T app php artisan migrate --env=testing --force
                        
                        REM Exécution des tests d'intégration
                        echo Exécution des tests d'intégration...
                        docker compose -f docker-compose.test.yml exec -T app vendor/bin/phpunit --testsuite=Feature --log-junit junit-integration.xml
                        
                        echo ✓ Tests d'intégration terminés
                    '''
                }
            }
            post {
                always {
                    script {
                        bat '''
                            echo Nettoyage des conteneurs de test...
                            docker compose -f docker-compose.test.yml down --remove-orphans 2>nul || echo Nettoyage terminé
                        '''
                    }
                    junit allowEmptyResults: true, testResultsPattern: 'junit-integration.xml'
                }
            }
        }
        
        stage('Deploy') {
            when {
                anyOf {
                    branch 'main'
                    branch 'master'
                }
            }
            parallel {
                stage('Push to Registry') {
                    steps {
                        script {
                            withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                                bat '''
                                    echo === Push vers Docker Registry ===
                                    
                                    REM Connexion à Docker Hub
                                    echo %DOCKER_PASS%| docker login %DOCKER_REGISTRY% -u %DOCKER_USER% --password-stdin
                                    if errorlevel 1 (
                                        echo ✗ Échec de la connexion à Docker Hub
                                        exit /b 1
                                    )
                                    
                                    REM Tag des images
                                    docker tag %DOCKER_IMAGE%:%DOCKER_TAG% %DOCKER_USER%/%DOCKER_IMAGE%:%DOCKER_TAG%
                                    docker tag %DOCKER_IMAGE%:%DOCKER_TAG% %DOCKER_USER%/%DOCKER_IMAGE%:latest
                                    
                                    REM Push des images
                                    echo Push de l'image avec tag %DOCKER_TAG%...
                                    docker push %DOCKER_USER%/%DOCKER_IMAGE%:%DOCKER_TAG%
                                    
                                    echo Push de l'image avec tag latest...
                                    docker push %DOCKER_USER%/%DOCKER_IMAGE%:latest
                                    
                                    echo ✓ Images poussées avec succès vers Docker Hub
                                '''
                            }
                        }
                    }
                }
                
                stage('Deploy to Staging') {
                    steps {
                        script {
                            bat '''
                                echo === Déploiement en staging ===
                                
                                REM Vérification du fichier docker-compose.staging.yml
                                if exist docker-compose.staging.yml (
                                    echo Déploiement avec docker-compose.staging.yml...
                                    docker compose -f docker-compose.staging.yml down --remove-orphans
                                    docker compose -f docker-compose.staging.yml up -d
                                    echo ✓ Application déployée en staging
                                ) else (
                                    echo ⚠ Fichier docker-compose.staging.yml non trouvé
                                    echo Déploiement en staging ignoré
                                )
                            '''
                        }
                    }
                }
            }
        }
    }
    
    post {
        always {
            script {
                bat '''
                    echo === Nettoyage final ===
                    
                    REM Nettoyage des images Docker non utilisées
                    docker image prune -f >nul 2>&1 || echo Nettoyage des images ignoré
                    
                    REM Nettoyage des conteneurs arrêtés
                    docker container prune -f >nul 2>&1 || echo Nettoyage des conteneurs ignoré
                    
                    echo ✓ Nettoyage terminé
                '''
            }
            
            // Archivage des artefacts
            archiveArtifacts artifacts: '*.xml,*.txt,*.json', allowEmptyArchive: true, fingerprint: true
        }
        
        success {
            script {
                echo "🎉 Build réussi pour ${env.JOB_NAME} #${env.BUILD_NUMBER}"
                
                // Notification email de succès
                emailext (
                    subject: "✅ Build Successful: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                    body: """
                    <h2>Build Successful</h2>
                    <p><strong>Job:</strong> ${env.JOB_NAME}</p>
                    <p><strong>Build Number:</strong> ${env.BUILD_NUMBER}</p>
                    <p><strong>Branch:</strong> ${env.BRANCH_NAME}</p>
                    <p><strong>Duration:</strong> ${currentBuild.durationString}</p>
                    <p><strong>Console Output:</strong> <a href="${env.BUILD_URL}console">${env.BUILD_URL}console</a></p>
                    
                    <h3>Artefacts Générés:</h3>
                    <ul>
                        <li>Image Docker: ${env.DOCKER_USERNAME}/${env.DOCKER_IMAGE}:${env.DOCKER_TAG}</li>
                        <li>Rapports de tests disponibles dans Jenkins</li>
                        <li>Rapports de sécurité générés</li>
                    </ul>
                    """,
                    mimeType: 'text/html',
                    recipientProviders: [[$class: 'DevelopersRecipientProvider']]
                )
            }
        }
        
        failure {
            script {
                echo "❌ Build échoué pour ${env.JOB_NAME} #${env.BUILD_NUMBER}"
                
                // Notification email d'échec
                emailext (
                    subject: "❌ Build Failed: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                    body: """
                    <h2>Build Failed</h2>
                    <p><strong>Job:</strong> ${env.JOB_NAME}</p>
                    <p><strong>Build Number:</strong> ${env.BUILD_NUMBER}</p>
                    <p><strong>Branch:</strong> ${env.BRANCH_NAME}</p>
                    <p><strong>Failure Reason:</strong> ${currentBuild.result}</p>
                    <p><strong>Console Output:</strong> <a href="${env.BUILD_URL}console">${env.BUILD_URL}console</a></p>
                    
                    <p>Veuillez vérifier les logs pour plus de détails.</p>
                    """,
                    mimeType: 'text/html',
                    recipientProviders: [[$class: 'DevelopersRecipientProvider']]
                )
            }
        }
        
        unstable {
            script {
                echo "⚠️ Build instable pour ${env.JOB_NAME} #${env.BUILD_NUMBER}"
            }
        }
        
        cleanup {
            cleanWs()
        }
    }
}
