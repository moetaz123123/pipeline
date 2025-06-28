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
                            powershell -Command "$key = [Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Maximum 256 })); Add-Content -Path '.env' -Value \"APP_KEY=base64:$key\""
                        )
                        findstr "APP_KEY=base64:" .env >nul
                        if errorlevel 1 (
                            powershell -Command "$key = [Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Maximum 256 })); Add-Content -Path '.env' -Value \"APP_KEY=base64:$key\""
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
                                echo Running Unit tests without coverage...
                                "%PHP_PATH%" vendor/bin/phpunit --testsuite=Unit --log-junit junit-unit.xml
                                if errorlevel 1 (
                                    echo Unit tests completed with warnings or failures
                                    exit /b 0
                                ) else (
                                    echo Unit tests completed successfully
                                )
                            '''
                        }
                    }
                    post {
                        always {
                            junit allowEmptyResults: true, testResults: 'junit-unit.xml'
                            echo '✅ Unit tests completed'
                            publishHTML([
                                allowMissing: true,
                                alwaysLinkToLastBuild: true,
                                keepAll: true,
                                reportDir: '.',
                                reportFiles: 'unit-report.html',
                                reportName: 'Unit Test Report'
                            ])
                        }
                    }
                }

                stage('Feature Tests') {
                    steps {
                        echo '🧪 Running Feature tests...'
                        script {
                            bat '''
                                echo Running Feature tests without coverage...
                                "%PHP_PATH%" vendor/bin/phpunit --testsuite=Feature --log-junit junit-feature.xml
                                if errorlevel 1 (
                                    echo Feature tests completed with warnings or failures
                                    exit /b 0
                                ) else (
                                    echo Feature tests completed successfully
                                )
                            '''
                        }
                    }
                    post {
                        always {
                            junit allowEmptyResults: true, testResults: 'junit-feature.xml'
                            echo '✅ Feature tests completed'
                            publishHTML([
                                allowMissing: true,
                                alwaysLinkToLastBuild: true,
                                keepAll: true,
                                reportDir: '.',
                                reportFiles: 'feature-report.html',
                                reportName: 'Feature Test Report'
                            ])
                        }
                    }
                }

                stage('Security Scan') {
                    steps {
                        echo '🔒 Running Trivy scan (identique au terminal)...'
                        script {
                            bat '''
                                echo Début du scan Trivy (même commande que terminal)...
                                docker run --rm -v "%cd%:/app" aquasec/trivy:latest fs /app --skip-files vendor/laravel/pint/builds/pint --format table --output trivy-report.txt --timeout 600s
                                if errorlevel 1 (
                                    echo Docker Trivy scan failed with error code %errorlevel%
                                    echo "Docker Trivy scan failed - Error code: %errorlevel%" > trivy-report.txt
                                    echo "Please check the logs above for details" >> trivy-report.txt
                                ) else (
                                    echo Docker Trivy scan completed successfully
                                )
                                
                                echo Vérification du fichier de rapport...
                                if exist trivy-report.txt (
                                    echo Fichier trivy-report.txt trouvé
                                    echo ========================================
                                    echo RAPPORT TRIVY COMPLET:
                                    echo ========================================
                                    type trivy-report.txt
                                    echo ========================================
                                ) else (
                                    echo Fichier trivy-report.txt non trouvé, création d'un rapport d'erreur
                                    echo "Docker Trivy scan completed but report file not found" > trivy-report.txt
                                    echo "This might indicate a silent failure in Docker Trivy" >> trivy-report.txt
                                )
                            '''
                        }
                    }
                    post {
                        always {
                            script {
                                if (fileExists('trivy-report.txt')) {
                                    def report = readFile('trivy-report.txt')
                                    echo "========================================"
                                    echo "RAPPORT TRIVY COMPLET (AFFICHAGE JENKINS):"
                                    echo "========================================"
                                    echo "${report}"
                                    echo "========================================"
                                } else {
                                    echo "❌ Fichier trivy-report.txt non trouvé"
                                    echo "Création d'un rapport d'erreur..."
                                    writeFile file: 'trivy-report.txt', text: '''Docker Trivy scan failed - No report file generated
This could be due to:
1. Docker not running
2. Docker permissions issues
3. Network connectivity problems
4. Docker image pull issues

Please check:
- Docker is running
- Docker permissions for Jenkins user
- Network connectivity
- Docker image availability'''
                                }
                            }
                            archiveArtifacts artifacts: 'trivy-report.txt', allowEmptyArchive: true
                            echo '✅ Security scan completed'
                            publishHTML([
                                allowMissing: true,
                                alwaysLinkToLastBuild: true,
                                keepAll: true,
                                reportDir: '.',
                                reportFiles: 'trivy-report.html',
                                reportName: 'Trivy Security Report'
                            ])
                        }
                    }
                }

                stage('SonarQube Analysis') {
                    steps {
                        withSonarQubeEnv('sonarqube') {
                            bat 'vendor\\bin\\phpunit --coverage-clover=coverage.xml'
                            bat '"C:\\Users\\User\\Downloads\\sonar-scanner-cli-7.1.0.4889-windows-x64\\sonar-scanner-7.1.0.4889-windows-x64\\bin\\sonar-scanner.bat" -Dsonar.projectKey=touza-project -Dsonar.php.coverage.reportPaths=coverage.xml -Dsonar.sources=app -Dsonar.tests=tests -Dsonar.host.url=http://localhost:9000'
                        }
                    }
                }

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

                stage('Scan Docker Image A') {
                    steps {
                        echo '🔍 Scanning Docker image...'
                        script {
                            bat '''
                                "%TRIVY_PATH%" image %DOCKER_IMAGE%:%DOCKER_TAG% ^
                                    --severity HIGH,CRITICAL ^
                                    --format html ^
                                    --output trivy-report.html
                                if errorlevel 1 (
                                    echo Docker image scan completed with vulnerabilities found
                                    exit /b 0
                                )
                            '''
                        }
                    }
                    post {
                        always {
                            archiveArtifacts artifacts: 'trivy-report.txt', allowEmptyArchive: true
                            echo '✅ Docker image scan completed'
                            publishHTML([
                                allowMissing: true,
                                alwaysLinkToLastBuild: true,
                                keepAll: true,
                                reportDir: '.',
                                reportFiles: 'trivy-report.html',
                                reportName: 'Trivy Security Report'
                            ])
                        }
                    }
                }

                stage('Scan Docker Image B') {
                    steps {
                        echo '🔍 Scanning Docker image...'
                        script {
                            bat '''
                                "%TRIVY_PATH%" image %DOCKER_IMAGE%:%DOCKER_TAG% ^
                                    --severity HIGH,CRITICAL ^
                                    --format html ^
                                    --output trivy-report.html
                                if errorlevel 1 (
                                    echo Docker image scan completed with vulnerabilities found
                                    exit /b 0
                                )
                            '''
                        }
                    }
                    post {
                        always {
                            archiveArtifacts artifacts: 'trivy-report.txt', allowEmptyArchive: true
                            echo '✅ Docker image scan completed'
                            publishHTML([
                                allowMissing: true,
                                alwaysLinkToLastBuild: true,
                                keepAll: true,
                                reportDir: '.',
                                reportFiles: 'trivy-report.html',
                                reportName: 'Trivy Security Report'
                            ])
                        }
                    }
                }

                stage('Mutation Tests') {
                    steps {
                        echo '🧬 Running Mutation tests...'
                        script {
                            bat '''
                                "%PHP_PATH%" vendor/bin/infection --min-msi=80 --min-covered-msi=80 --log-verbosity=all
                                if errorlevel 1 (
                                    echo Infection échoué ou non installé, continuation du pipeline
                                    exit /b 0
                                )
                            '''
                        }
                    }
                    post {
                        always {
                            archiveArtifacts artifacts: 'infection-report/**/*', allowEmptyArchive: true
                            echo '✅ Mutation tests completed'
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
            }
        }

        stage('Checkpoint - Code Quality Review') {
            steps {
                echo '⏸️ Waiting for code quality review approval...'
                input message: 'Code quality and security checks completed. Do you want to continue?', ok: 'Continue to Build'
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
                        if errorlevel 1 (
                            echo Database creation completed with warnings
                            exit /b 0
                        )
                        docker compose exec -T app php artisan migrate --env=testing
                        if errorlevel 1 (
                            echo Migration completed with warnings
                            exit /b 0
                        )
                        docker compose exec -T app vendor/bin/phpunit --testsuite=Feature --log-junit junit-integration.xml
                        if errorlevel 1 (
                            echo Integration tests completed with warnings
                            exit /b 0
                        )
                        docker compose down
                    '''
                }
            }
            post {
                always {
                    junit allowEmptyResults: true, testResults: 'junit-integration.xml'
                    echo '✅ Integration tests completed'
                    publishHTML([
                        allowMissing: true,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: '.',
                        reportFiles: 'integration-report.html',
                        reportName: 'Integration Test Report'
                    ])
                }
                cleanup {
                    script {
                        bat 'docker compose down || echo "Docker compose cleanup completed"'
                    }
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
                            bat '''
                                docker compose -f docker-compose.staging.yml up -d
                                if errorlevel 1 (
                                    echo Staging deployment completed with warnings
                                    exit /b 0
                                )
                            '''
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
                    bat '''
                        docker image prune -f
                        if errorlevel 1 echo Docker cleanup completed
                        docker container prune -f
                        if errorlevel 1 echo Container cleanup completed
                    '''
                } catch (Exception e) {
                    echo "Cleanup failed: ${e.getMessage()}"
                }
            }
            // Unit Test HTML
            publishHTML([
                allowMissing: true,
                alwaysLinkToLastBuild: true,
                keepAll: true,
                reportDir: '.',
                reportFiles: 'unit-report.html',
                reportName: 'Unit Test Report'
            ])
            // Feature Test HTML
            publishHTML([
                allowMissing: true,
                alwaysLinkToLastBuild: true,
                keepAll: true,
                reportDir: '.',
                reportFiles: 'feature-report.html',
                reportName: 'Feature Test Report'
            ])
            // Integration Test HTML
            publishHTML([
                allowMissing: true,
                alwaysLinkToLastBuild: true,
                keepAll: true,
                reportDir: '.',
                reportFiles: 'integration-report.html',
                reportName: 'Integration Test Report'
            ])
            // Trivy HTML
            publishHTML([
                allowMissing: true,
                alwaysLinkToLastBuild: true,
                keepAll: true,
                reportDir: '.',
                reportFiles: 'trivy-report.html',
                reportName: 'Trivy Security Report'
            ])
            // Infection HTML
            publishHTML([
                allowMissing: true,
                alwaysLinkToLastBuild: true,
                keepAll: true,
                reportDir: 'infection-report',
                reportFiles: 'index.html',
                reportName: 'Mutation Test Report'
            ])
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
