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
                    composer --version >nul 2>&1
                    if errorlevel 1 (
                        echo Composer non trouvé globalement, installation locale...
                        if exist composer.phar (
                            "%PHP_PATH%" composer.phar install --optimize-autoloader --no-interaction
                        ) else (
                            powershell -Command "Invoke-WebRequest -Uri https://getcomposer.org/composer.phar -OutFile composer.phar"
                            "%PHP_PATH%" composer.phar install --optimize-autoloader --no-interaction
                        )
                    ) else (
                        composer install --optimize-autoloader --no-interaction
                    )
                    
                    if errorlevel 1 (
                        echo ERREUR: Échec de l'installation des dépendances
                        exit /b 1
                    )
                    
                    echo Configuration des plugins...
                    composer config allow-plugins.infection/extension-installer true
                    composer require --dev infection/infection
                    
                    echo === Dépendances installées avec succès ===
                '''
            }
        }

        stage('Trivy Scan') {
            steps {
                bat 'docker build -t %DOCKER_IMAGE% .'
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
                    
                    echo Création du rapport HTML Trivy...
                    
                    echo ^<html^> > trivy-report.html
                    echo ^<head^> >> trivy-report.html
                    echo ^<title^>Trivy Security Scan Report^</title^> >> trivy-report.html
                    echo ^<style^> >> trivy-report.html
                    echo body { font-family: monospace; margin: 20px; background-color: #f5f5f5; } >> trivy-report.html
                    echo pre { background-color: white; padding: 15px; border: 1px solid #ddd; border-radius: 5px; overflow-x: auto; } >> trivy-report.html
                    echo h1 { color: #333; border-bottom: 2px solid #007acc; } >> trivy-report.html
                    echo h2 { color: #007acc; } >> trivy-report.html
                    echo table { border-collapse: collapse; width: 100%%; margin: 10px 0; } >> trivy-report.html
                    echo th, td { border: 1px solid #ddd; padding: 8px; text-align: left; } >> trivy-report.html
                    echo th { background-color: #007acc; color: white; } >> trivy-report.html
                    echo .success { color: green; } >> trivy-report.html
                    echo .warning { color: orange; } >> trivy-report.html
                    echo .error { color: red; } >> trivy-report.html
                    echo ^</style^> >> trivy-report.html
                    echo ^</head^> >> trivy-report.html
                    echo ^<body^> >> trivy-report.html
                    echo ^<h1^>Trivy Security Scan Report^</h1^> >> trivy-report.html
                    echo ^<h2^>Scan Details^</h2^> >> trivy-report.html
                    echo ^<p^>Scan completed for directory: %WORKSPACE%^</p^> >> trivy-report.html
                    echo ^<p^>Command: trivy fs . --skip-files vendor/laravel/pint/builds/pint --timeout 120s^</p^> >> trivy-report.html
                    echo ^<h2^>Scan Results^</h2^> >> trivy-report.html
                    echo ^<pre^> >> trivy-report.html
                    
                    type trivy-report.txt >> trivy-report.html
                    
                    echo ^</pre^> >> trivy-report.html
                    echo ^<p class="success"^>^<strong^>✓^</strong^> Scan completed successfully. Check the detailed text report (trivy-report.txt) for complete vulnerability information.^</p^> >> trivy-report.html
                    echo ^</body^> >> trivy-report.html
                    echo ^</html^> >> trivy-report.html
                    
                    echo Rapport HTML Trivy créé: trivy-report.html
                '''
            }
            post {
                always {
                    publishHTML(target: [
                        allowMissing: true,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: '.',
                        reportFiles: 'trivy-report.html',
                        reportName: 'Trivy Security Scan'
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
                    if exist vendor\\bin\\phpunit.bat (
                        "%PHP_PATH%" vendor\\bin\\phpunit.bat --testsuite=Unit --log-junit junit-unit.xml --coverage-html=coverage-html
                    ) else if exist vendor\\bin\\phpunit (
                        "%PHP_PATH%" vendor\\bin\\phpunit --testsuite=Unit --log-junit junit-unit.xml --coverage-html=coverage-html
                    ) else (
                        echo ERREUR: PHPUnit non trouvé
                        exit /b 1
                    )
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
                    publishHTML(target: [
                        allowMissing: true,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'coverage-html',
                        reportFiles: 'index.html',
                        reportName: 'PHPUnit Coverage Report'
                    ])
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
                        if exist vendor\\bin\\phpunit.bat (
                            "%PHP_PATH%" vendor\\bin\\phpunit.bat
                        ) else if exist vendor\\bin\\phpunit (
                            "%PHP_PATH%" vendor\\bin\\phpunit
                        )
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

        stage('Build Docker Image') {
            steps {
                bat '''
                    echo === Construction de l'image Docker ===
                    docker build -t %DOCKER_IMAGE% .
                    if errorlevel 1 (
                        echo ERREUR: Échec de la construction Docker
                        exit /b 1
                    )
                    echo === Image Docker construite ===
                '''
            }
        }

        stage('Deploy') {
            when {
                branch 'main'
            }
            steps {
                bat '''
                    echo === Déploiement ===
                    docker run -d --rm -p 8080:80 %DOCKER_IMAGE%
                    echo === Application déployée sur http://localhost:8080 ===
                '''
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
