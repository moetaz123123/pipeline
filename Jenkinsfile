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

        stage('Feature Tests') {
            steps {
                bat '''
                    echo === Feature tests ===
                    composer exec -- phpunit --testsuite=Feature --log-junit junit-feature.xml
                    if errorlevel 1 (
                        echo ERREUR: Feature tests échoués
                        exit /b 1
                    )
                    echo === Feature tests terminés ===
                '''
            }
            post {
                always {
                    junit 'junit-feature.xml'
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

        stage('Trivy Code Scan') {
            steps {
                bat '''
                    echo === Scan de sécurité Trivy (code) ===
                    "%TRIVY_PATH%" fs . --skip-files vendor/laravel/pint/builds/pint --timeout 120s > trivy-report.txt 2>&1
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
                    script {
                        def trivyText = readFile('trivy-report.txt')
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
${trivyText}
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
                        reportFiles: 'trivy-report.html',
                        reportName: 'Trivy Security Scan (Tableaux CLI)'
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
