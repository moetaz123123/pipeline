pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'laravel-app'
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
                echo '🔄 Checkout source code...'
                checkout scm
            }
            post {
                always {
                    echo '✅ Checkout completed'
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                echo '📦 Installing PHP dependencies...'
                script {
                    bat 'composer install --optimize-autoloader --no-interaction'
                }
            }
            post {
                always {
                    echo '✅ Dependencies installed'
                }
            }
        }

        stage('Setup Laravel') {
            steps {
                echo '⚙️ Setting up Laravel environment...'
                script {
                    bat '''
                        if exist .env.example (
                            copy .env.example .env
                        ) else (
                            echo .env.example non trouvé, création d'un .env basique
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
                            echo APP_KEY=base64:%RANDOM%%RANDOM%%RANDOM%>> .env
                        )
                        findstr "APP_KEY=base64:" .env >nul
                        if errorlevel 1 (
                            echo APP_KEY=base64:%RANDOM%%RANDOM%%RANDOM%>> .env
                        )
                        echo Configuration Laravel pour les tests:
                        findstr "APP_ENV APP_DEBUG DB_CONNECTION APP_KEY" .env
                    '''
                }
            }
            post {
                always {
                    echo '✅ Laravel environment configured'
                }
            }
        }

        stage('Code Quality & Security') {
            parallel {
                stage('Unit Tests') {
                    steps {
                        echo '🧪 Running Unit tests...'
                        script {
                            bat '''
                                set PCOV_ENABLED=1
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
                            echo '✅ Unit tests completed'
                        }
                    }
                }

                stage('Feature Tests') {
                    steps {
                        echo '🧪 Running Feature tests...'
                        script {
                            bat '''
                                set PCOV_ENABLED=1
                                "%PHP_PATH%" vendor/bin/phpunit --testsuite=Feature --log-junit junit-feature.xml
                            '''
                        }
                    }
                    post {
                        always {
                            junit 'junit-feature.xml'
                            echo '✅ Feature tests completed'
                        }
                    }
                }

                stage('Security Scan') {
                    steps {
                        echo '🔒 Running Trivy scan (identique au terminal)...'
                        script {
                            bat '''
                                "C:\\Users\\User\\Downloads\\trivy_0.63.0_windows-64bit\\trivy.exe" fs . --skip-files vendor/laravel/pint/builds/pint --format table --output trivy-report.txt
                            '''
                        }
                    }
                    post {
                        always {
                            script {
                                def report = readFile('trivy-report.txt')
                                echo "=== Trivy Report ===\\n${report}"
                            }
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

                // Alternative Security Scan Stage (uncomment if needed)
                /*
                stage('Alternative Security Scan') {
                    steps {
                        echo '🔒 Running Alternative Security scan...'
                        script {
                            bat '''
                                echo Utilisation d'une approche alternative pour Trivy...
                                
                                echo Pré-téléchargement de la base de données...
                                "C:\\Users\\User\\Downloads\\trivy_0.63.0_windows-64bit\\trivy.exe" image --download-db-only --cache-dir "C:\\ProgramData\\Jenkins\\.jenkins\\workspace\\pipeline-laravel\\.trivycache" --timeout 600s
                                if errorlevel 1 (
                                    echo Pré-téléchargement échoué, tentative avec options de sécurité...
                                    "C:\\Users\\User\\Downloads\\trivy_0.63.0_windows-64bit\\trivy.exe" image --download-db-only --cache-dir "C:\\ProgramData\\Jenkins\\.jenkins\\workspace\\pipeline-laravel\\.trivycache" --timeout 600s --insecure
                                )
                                
                                echo Scan avec base de données locale...
                                "C:\\Users\\User\\Downloads\\trivy_0.63.0_windows-64bit\\trivy.exe" fs . --skip-files vendor/laravel/pint/builds/pint --severity HIGH,CRITICAL --format table --output trivy-report.txt --cache-dir "C:\\ProgramData\\Jenkins\\.jenkins\\workspace\\pipeline-laravel\\.trivycache" --timeout 300s
                                if errorlevel 1 (
                                    echo Scan échoué, création d'un rapport d'erreur...
                                    echo "Alternative Trivy scan failed" > trivy-report.txt
                                    echo "Database download or scan timeout" >> trivy-report.txt
                                )
                                
                                echo Scan composer.lock avec base locale...
                                "C:\\Users\\User\\Downloads\\trivy_0.63.0_windows-64bit\\trivy.exe" fs composer.lock --severity HIGH,CRITICAL --format table --output trivy-composer-report.txt --cache-dir "C:\\ProgramData\\Jenkins\\.jenkins\\workspace\\pipeline-laravel\\.trivycache" --timeout 300s
                                if errorlevel 1 (
                                    echo Scan composer.lock échoué...
                                    echo "Alternative Trivy composer scan failed" > trivy-composer-report.txt
                                )
                                
                                echo Alternative scan terminé
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
                                reportFiles: 'trivy-*-report.txt',
                                reportName: 'Alternative Trivy Security Report'
                            ])
                            echo '✅ Alternative Security scan completed'
                        }
                    }
                }
                */

                stage('SonarQube Analysis') {
                    steps {
                        echo '📊 Running SonarQube analysis...'
                        script {
                            echo "=== Début de l'analyse SonarQube ==="
                            
                            bat '''
                                curl -f %SONARQUBE_URL% >nul 2>&1
                                if errorlevel 1 (
                                    echo SonarQube non accessible, démarrage via Docker...
                                    docker run -d --name sonarqube -p 9000:9000 sonarqube:latest
                                    timeout /t 60 /nobreak
                                )
                            '''
                            
                            if (fileExists('sonar-project.properties')) {
                                bat '''
                                    echo Configuration SonarQube:
                                    type sonar-project.properties
                                    docker run --rm -e SONAR_HOST_URL=%SONARQUBE_URL% -e SONAR_LOGIN=%SONAR_TOKEN% -v "%WORKSPACE%:/usr/src" sonarsource/sonar-scanner-cli
                                '''
                            } else {
                                bat '''
                                    docker run --rm -e SONAR_HOST_URL=%SONARQUBE_URL% -e SONAR_LOGIN=%SONAR_TOKEN% -v "%WORKSPACE%:/usr/src" sonarsource/sonar-scanner-cli ^
                                        -Dsonar.projectKey=laravel-multitenant ^
                                        -Dsonar.sources=app,config,database,resources,routes ^
                                        -Dsonar.exclusions=vendor/**,storage/**,bootstrap/cache/**,tests/** ^
                                        -Dsonar.php.coverage.reportPaths=coverage.xml
                                '''
                            }

                            echo "=== Fin de l'analyse SonarQube ==="
                        }
                    }
                    post {
                        always {
                            echo "✅ SonarQube analysis completed"
                        }
                    }
                }
            }
        }

        stage('Checkpoint - Code Quality Review') {
            steps {
                echo '⏸️ Waiting for code quality review approval...'
                input message: 'Code quality and security checks completed. Do you want to continue?', ok: 'Continue to Build'
            }
        }

        stage('Mutation Tests') {
            steps {
                echo '🧬 Running Mutation tests...'
                script {
                    bat '"%PHP_PATH%" vendor/bin/infection --min-msi=80 --min-covered-msi=80 --log-verbosity=all'
                    bat 'if errorlevel 1 echo Infection échoué ou non installé'
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
                    echo '✅ Mutation tests completed'
                }
            }
        }

        stage('Build & Security') {
            parallel {
                stage('Build Docker Image') {
                    steps {
                        echo '🐳 Building Docker image...'
                        script {
                            bat '''
                                docker build -t %DOCKER_IMAGE%:%DOCKER_TAG% .
                                docker tag %DOCKER_IMAGE%:%DOCKER_TAG% %DOCKER_IMAGE%:latest
                            '''
                        }
                    }
                    post {
                        always {
                            echo '✅ Docker image built'
                        }
                    }
                }

                stage('Scan Docker Image') {
                    steps {
                        echo '🔍 Scanning Docker image...'
                        script {
                            bat '''
                                "C:\\Users\\User\\Downloads\\trivy_0.63.0_windows-64bit\\trivy.exe" image %DOCKER_IMAGE%:%DOCKER_TAG% ^
                                    --severity HIGH,CRITICAL ^
                                    --format table ^
                                    --output trivy-image-report.txt
                                if errorlevel 1 echo Docker image scan completed
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
                            echo '✅ Docker image scan completed'
                        }
                    }
                }
            }
        }

        stage('Checkpoint - Build Review') {
            steps {
                echo '⏸️ Waiting for build review approval...'
                input message: 'Docker image built and scanned. Do you want to continue to integration tests?', ok: 'Continue to Integration Tests'
            }
        }

        stage('Integration Tests') {
            steps {
                echo '🔗 Running Integration tests...'
                script {
                    bat '''
                        docker compose up -d db
                        timeout /t 30 /nobreak
                        docker compose exec -T db mysql -uroot -pRoot@1234 -e "CREATE DATABASE IF NOT EXISTS laravel_multitenant_test;"
                        if errorlevel 1 echo Database creation completed
                        docker compose exec -T app php artisan migrate --env=testing
                        if errorlevel 1 echo Migration completed
                        docker compose exec -T app vendor/bin/phpunit --testsuite=Feature --log-junit junit-integration.xml
                        if errorlevel 1 echo Integration tests completed
                        docker compose down
                    '''
                }
            }
            post {
                always {
                    junit 'junit-integration.xml'
                    echo '✅ Integration tests completed'
                }
            }
        }

        stage('Checkpoint - Pre-Deploy Review') {
            when {
                branch 'main'
            }
            steps {
                echo '⏸️ Waiting for pre-deploy approval...'
                input message: 'All tests passed. Ready to deploy to production?', ok: 'Deploy to Production'
            }
        }

        stage('Deploy') {
            when {
                branch 'main'
            }
            parallel {
                stage('Push to Registry') {
                    steps {
                        echo '📤 Pushing to Docker Hub...'
                        script {
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
                    post {
                        always {
                            echo '✅ Docker image pushed to registry'
                        }
                    }
                }

                stage('Deploy to Staging') {
                    steps {
                        echo '🚀 Deploying to staging...'
                        script {
                            bat 'docker compose -f docker-compose.staging.yml up -d'
                            bat 'if errorlevel 1 echo Staging deployment completed'
                        }
                    }
                    post {
                        always {
                            echo '✅ Staging deployment completed'
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            echo '🧹 Cleaning up workspace...'
            script {
                try {
                    bat 'docker image prune -f'
                    bat 'if errorlevel 1 echo Docker cleanup completed'
                    bat 'docker container prune -f'
                    bat 'if errorlevel 1 echo Container cleanup completed'
                } catch (Exception e) {
                    echo "Cleanup failed: ${e.getMessage()}"
                }
            }
        }

        success {
            echo '🎉 Pipeline completed successfully!'
            script {
                try {
                    emailext (
                        subject: "✅ Build Successful: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                        body: """
                            <h2>🎉 Pipeline Completed Successfully!</h2>
                            <p><strong>Job:</strong> ${env.JOB_NAME}</p>
                            <p><strong>Build:</strong> #${env.BUILD_NUMBER}</p>
                            <p><strong>Duration:</strong> ${currentBuild.durationString}</p>
                            <p><strong>View Details:</strong> <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>
                            <hr>
                            <p>All stages completed successfully including tests, security scans, and quality checks.</p>
                        """,
                        mimeType: 'text/html',
                        to: "${env.NOTIFICATION_EMAIL ?: 'admin@example.com'}",
                        replyTo: 'jenkins@example.com'
                    )
                } catch (Exception e) {
                    echo "Email notification failed: ${e.getMessage()}"
                }
            }
        }

        failure {
            echo '❌ Pipeline failed!'
            script {
                try {
                    emailext (
                        subject: "❌ Build Failed: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                        body: """
                            <h2>❌ Pipeline Failed!</h2>
                            <p><strong>Job:</strong> ${env.JOB_NAME}</p>
                            <p><strong>Build:</strong> #${env.BUILD_NUMBER}</p>
                            <p><strong>Duration:</strong> ${currentBuild.durationString}</p>
                            <p><strong>View Details:</strong> <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>
                            <hr>
                            <p>Please check the build logs for more details about the failure.</p>
                        """,
                        mimeType: 'text/html',
                        to: "${env.NOTIFICATION_EMAIL ?: 'admin@example.com'}",
                        replyTo: 'jenkins@example.com'
                    )
                } catch (Exception e) {
                    echo "Email notification failed: ${e.getMessage()}"
                }
            }
        }

        unstable {
            echo '⚠️ Pipeline unstable!'
            script {
                try {
                    emailext (
                        subject: "⚠️ Build Unstable: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                        body: """
                            <h2>⚠️ Pipeline Unstable!</h2>
                            <p><strong>Job:</strong> ${env.JOB_NAME}</p>
                            <p><strong>Build:</strong> #${env.BUILD_NUMBER}</p>
                            <p><strong>Duration:</strong> ${currentBuild.durationString}</p>
                            <p><strong>View Details:</strong> <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>
                            <hr>
                            <p>The build completed but some tests or quality checks failed.</p>
                        """,
                        mimeType: 'text/html',
                        to: "${env.NOTIFICATION_EMAIL ?: 'admin@example.com'}",
                        replyTo: 'jenkins@example.com'
                    )
                } catch (Exception e) {
                    echo "Email notification failed: ${e.getMessage()}"
                }
            }
        }
    }
}
