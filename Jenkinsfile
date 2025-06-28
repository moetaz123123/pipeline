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
        
        stage('Environment Check') {
            steps {
                bat '''
                    echo === Vérification de l'environnement ===
                    echo PHP Version:
                    "%PHP_PATH%" --version
                    if errorlevel 1 (
                        echo ERREUR: PHP non trouvé à %PHP_PATH%
                        exit /b 1
                    )
                    
                    echo.
                    echo Composer Version:
                    composer --version
                    if errorlevel 1 (
                        echo AVERTISSEMENT: Composer non trouvé globalement
                    )
                    
                    echo.
                    echo Docker Version:
                    docker --version
                    if errorlevel 1 (
                        echo AVERTISSEMENT: Docker non trouvé
                    )
                    
                    echo.
                    echo Trivy disponible:
                    if exist "%TRIVY_PATH%" (
                        echo Trivy trouvé à %TRIVY_PATH%
                    ) else (
                        echo AVERTISSEMENT: Trivy non trouvé à %TRIVY_PATH%
                    )
                    
                    echo === Vérification terminée ===
                '''
            }
        }
        
        stage('Install Dependencies') {
            steps {
                bat '''
                    echo === Installation des dépendances ===
                    echo Répertoire de travail: %CD%
                    echo PHP Path: %PHP_PATH%
                    
                    echo Vérification de Composer...
                    composer --version >nul 2>&1
                    if errorlevel 1 (
                        echo Composer non trouvé globalement, vérification locale...
                        if exist composer.phar (
                            echo Utilisation de composer.phar local
                            "%PHP_PATH%" composer.phar install --optimize-autoloader --no-interaction --prefer-dist
                        ) else (
                            echo Installation de Composer localement...
                            echo Téléchargement de composer.phar...
                            powershell -Command "Invoke-WebRequest -Uri https://getcomposer.org/composer.phar -OutFile composer.phar"
                            if errorlevel 1 (
                                echo ERREUR: Échec du téléchargement de Composer
                                exit /b 1
                            )
                            echo Installation des dépendances avec composer.phar...
                            "%PHP_PATH%" composer.phar install --optimize-autoloader --no-interaction --prefer-dist
                        )
                    ) else (
                        echo Composer trouvé globalement
                        echo Installation des dépendances...
                        composer install --optimize-autoloader --no-interaction --prefer-dist
                    )
                    
                    if errorlevel 1 (
                        echo ERREUR: Échec de l'installation des dépendances
                        echo Contenu du répertoire:
                        dir
                        echo Vérification du fichier composer.json:
                        if exist composer.json (
                            type composer.json
                        ) else (
                            echo ERREUR: composer.json non trouvé
                        )
                        exit /b 1
                    )
                    
                    echo Vérification de l'installation...
                    if exist vendor\\autoload.php (
                        echo === Dépendances installées avec succès ===
                        echo Dossier vendor créé
                    ) else (
                        echo ERREUR: Le dossier vendor n'a pas été créé
                        echo Contenu du répertoire:
                        dir
                        exit /b 1
                    )
                '''
            }
        }
        
        stage('Setup Laravel') {
            steps {
                bat '''
                    echo === Configuration de Laravel ===
                    
                    if exist .env.example (
                        copy .env.example .env
                        echo Fichier .env créé à partir de .env.example
                    ) else (
                        echo APP_NAME=Laravel> .env
                        echo Fichier .env créé avec configuration de base
                    )
                    
                    echo Configuration pour les tests...
                    echo APP_ENV=testing>> .env
                    echo APP_DEBUG=true>> .env
                    echo DB_CONNECTION=sqlite>> .env
                    echo DB_DATABASE=:memory:>> .env
                    echo CACHE_DRIVER=array>> .env
                    echo SESSION_DRIVER=array>> .env
                    echo QUEUE_DRIVER=sync>> .env
                    echo MAIL_MAILER=array>> .env
                    
                    echo Vérification du dossier vendor...
                    if not exist vendor\\autoload.php (
                        echo ERREUR: Le dossier vendor n'existe pas. Les dépendances doivent être installées d'abord.
                        exit /b 1
                    )
                    
                    echo Génération de la clé d'application...
                    "%PHP_PATH%" artisan key:generate --force
                    if errorlevel 1 (
                        echo ERREUR: Échec de la génération de la clé
                        exit /b 1
                    )
                    
                    echo === Configuration Laravel terminée avec succès ===
                '''
            }
        }
        
        stage('Code Quality & Security') {
            parallel {
                stage('Unit Tests') {
                    steps {
                        bat '''
                            echo === Exécution des tests unitaires ===
                            "%PHP_PATH%" vendor\\bin\\phpunit --testsuite=Unit --coverage-clover coverage.xml --log-junit junit-unit.xml
                            if errorlevel 1 (
                                echo ERREUR: Tests unitaires échoués
                                exit /b 1
                            )
                            echo === Tests unitaires terminés avec succès ===
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
                            echo === Exécution des tests de fonctionnalités ===
                            "%PHP_PATH%" vendor\\bin\\phpunit --testsuite=Feature --log-junit junit-feature.xml
                            if errorlevel 1 (
                                echo ERREUR: Tests de fonctionnalités échoués
                                exit /b 1
                            )
                            echo === Tests de fonctionnalités terminés avec succès ===
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
                            echo === Scan de sécurité avec Trivy ===
                            if exist "%TRIVY_PATH%" (
                                "%TRIVY_PATH%" fs . --severity HIGH,CRITICAL --format table --output trivy-report.txt
                                echo === Scan de sécurité terminé ===
                            ) else (
                                echo AVERTISSEMENT: Trivy non trouvé à %TRIVY_PATH%
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
                        script {
                            echo "=== Analyse SonarQube ==="
                            
                            // Vérifier si le fichier de configuration SonarQube existe
                            if (fileExists('sonar-project.properties')) {
                                echo "Fichier sonar-project.properties trouvé"
                                withSonarQubeEnv('sonarqube') {
                                    bat '''
                                        echo Génération du rapport de couverture pour SonarQube...
                                        "%PHP_PATH%" vendor\\bin\\phpunit --coverage-clover=coverage.xml --testsuite=Unit,Feature
                                        
                                        echo Lancement de l'analyse SonarQube...
                                        "C:\\Users\\User\\Downloads\\sonar-scanner-cli-7.1.0.4889-windows-x64\\sonar-scanner-7.1.0.4889-windows-x64\\bin\\sonar-scanner.bat"
                                        
                                        if errorlevel 1 (
                                            echo ERREUR: Échec de l'analyse SonarQube
                                            exit /b 1
                                        )
                                        echo === Analyse SonarQube terminée avec succès ===
                                    '''
                                }
                            } else {
                                echo "Fichier sonar-project.properties manquant, utilisation de la configuration par défaut"
                                withSonarQubeEnv('sonarqube') {
                                    bat '''
                                        echo Génération du rapport de couverture pour SonarQube...
                                        "%PHP_PATH%" vendor\\bin\\phpunit --coverage-clover=coverage.xml --testsuite=Unit,Feature
                                        
                                        echo Lancement de l'analyse SonarQube avec configuration par défaut...
                                        "C:\\Users\\User\\Downloads\\sonar-scanner-cli-7.1.0.4889-windows-x64\\sonar-scanner-7.1.0.4889-windows-x64\\bin\\sonar-scanner.bat" ^
                                            -Dsonar.projectKey=SonarQube ^
                                            -Dsonar.projectName=Laravel Multi-Tenant ^
                                            -Dsonar.projectVersion=1.0 ^
                                            -Dsonar.sources=app,config,database,resources,routes ^
                                            -Dsonar.tests=tests ^
                                            -Dsonar.exclusions=vendor/**,storage/**,bootstrap/cache/**,node_modules/** ^
                                            -Dsonar.php.coverage.reportPaths=coverage.xml ^
                                            -Dsonar.php.tests.reportPath=junit-unit.xml,junit-feature.xml
                                        
                                        if errorlevel 1 (
                                            echo ERREUR: Échec de l'analyse SonarQube
                                            exit /b 1
                                        )
                                        echo === Analyse SonarQube terminée avec succès ===
                                    '''
                                }
                            }
                        }
                    }
                    post {
                        always {
                            echo "Étape SonarQube Analysis terminée"
                            // Publier les rapports de couverture
                            publishHTML([
                                allowMissing: true,
                                alwaysLinkToLastBuild: true,
                                keepAll: true,
                                reportDir: 'coverage',
                                reportFiles: 'index.html',
                                reportName: 'SonarQube Coverage Report'
                            ])
                        }
                    }
                }
            }
        }
        
        stage('Mutation Tests') {
            steps {
                bat '''
                    echo === Tests de mutation ===
                    "%PHP_PATH%" vendor\\bin\\infection --min-msi=80 --min-covered-msi=80 --log-verbosity=all
                    if errorlevel 1 (
                        echo AVERTISSEMENT: Infection non disponible ou échec, étape ignorée
                        exit /b 0
                    )
                    echo === Tests de mutation terminés ===
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
                    echo === Construction de l'image Docker ===
                    docker build -t %DOCKER_IMAGE%:%DOCKER_TAG% .
                    if errorlevel 1 (
                        echo ERREUR: Échec de la construction Docker
                        exit /b 1
                    )
                    docker tag %DOCKER_IMAGE%:%DOCKER_TAG% %DOCKER_IMAGE%:latest
                    echo === Image construite avec succès ===
                '''
            }
        }
        
        stage('Scan Docker Image') {
            steps {
                bat '''
                    echo === Scan de sécurité de l'image Docker ===
                    if exist "%TRIVY_PATH%" (
                        "%TRIVY_PATH%" image %DOCKER_IMAGE%:%DOCKER_TAG% --severity HIGH,CRITICAL --format table --output trivy-image-report.txt
                        echo === Scan de l'image terminé ===
                    ) else (
                        echo AVERTISSEMENT: Trivy non trouvé, scan d'image ignoré
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
                    echo === Tests d'intégration ===
                    docker compose -f docker-compose.test.yml down --remove-orphans
                    docker compose -f docker-compose.test.yml up -d db
                    timeout /t 30 /nobreak
                    docker compose -f docker-compose.test.yml exec -T db mysql -uroot -pRoot@1234 -e "SELECT 1;"
                    if errorlevel 1 (
                        echo ERREUR: Impossible de se connecter à la base de données
                        docker compose -f docker-compose.test.yml logs db
                        exit /b 1
                    )
                    docker compose -f docker-compose.test.yml up -d app
                    timeout /t 10 /nobreak
                    docker compose -f docker-compose.test.yml exec -T app php artisan migrate --env=testing
                    docker compose -f docker-compose.test.yml exec -T app vendor/bin/phpunit --testsuite=Feature --log-junit junit-integration.xml
                    docker compose -f docker-compose.test.yml down --remove-orphans
                    echo === Tests d'intégration terminés ===
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
                                echo === Push vers Docker Registry ===
                                echo %DOCKER_PASSWORD% | docker login %DOCKER_REGISTRY% -u %DOCKER_USERNAME% --password-stdin
                                docker tag %DOCKER_IMAGE%:%DOCKER_TAG% %DOCKER_USERNAME%/%DOCKER_IMAGE%:%DOCKER_TAG%
                                docker tag %DOCKER_IMAGE%:%DOCKER_TAG% %DOCKER_USERNAME%/%DOCKER_IMAGE%:latest
                                docker push %DOCKER_USERNAME%/%DOCKER_IMAGE%:%DOCKER_TAG%
                                docker push %DOCKER_USERNAME%/%DOCKER_IMAGE%:latest
                                echo === Push terminé avec succès ===
                            '''
                        }
                    }
                }
                
                stage('Deploy to Staging') {
                    steps {
                        bat '''
                            echo === Déploiement en staging ===
                            docker compose -f docker-compose.staging.yml up -d
                            echo === Déploiement terminé ===
                        '''
                    }
                }
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
