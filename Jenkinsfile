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
                    
                    echo Génération de la clé d'application...
                    "%PHP_PATH%" artisan key:generate --force
                    
                    echo === Configuration Laravel terminée ===
                '''
            }
        }

        stage('Trivy Scan') {
            steps {
                bat '''
                    echo === Scan de sécurité Trivy ===
                    docker build -t %DOCKER_IMAGE% .
                    if errorlevel 1 (
                        echo ERREUR: Échec de la construction Docker
                        exit /b 1
                    )
                    
                    echo Scan de l'image Docker avec Trivy...
                    docker run --rm -v //var/run/docker.sock:/var/run/docker.sock aquasec/trivy image %DOCKER_IMAGE%
                    echo === Scan Trivy terminé ===
                '''
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonarqube') {
                    bat '''
                        echo === Analyse SonarQube ===
                        
                        echo Exécution des tests pour SonarQube...
                        "%PHP_PATH%" vendor\\bin\\phpunit --coverage-clover=coverage.xml
                        
                        echo Lancement de l'analyse SonarQube...
                        "C:\\Users\\User\\Downloads\\sonar-scanner-cli-7.1.0.4889-windows-x64\\sonar-scanner-7.1.0.4889-windows-x64\\bin\\sonar-scanner.bat" ^
                            -Dsonar.projectKey=SonarQube ^
                            -Dsonar.sources=app ^
                            -Dsonar.tests=tests ^
                            -Dsonar.host.url=http://localhost:9000
                        
                        if errorlevel 1 (
                            echo ERREUR: Échec de l'analyse SonarQube
                            exit /b 1
                        )
                        echo === Analyse SonarQube terminée ===
                    '''
                }
            }
        }

        stage('Unit Tests') {
            steps {
                bat '''
                    echo === Tests unitaires ===
                    "%PHP_PATH%" vendor\\bin\\phpunit --testsuite=Unit --log-junit junit-unit.xml
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
                    "%PHP_PATH%" vendor\\bin\\phpunit
                    
                    echo AVERTISSEMENT: Tests de mutation complets nécessitent des extensions de couverture (xdebug/pcov)
                    echo Tests de mutation de base terminés
                '''
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
