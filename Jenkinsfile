pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'laravel-multitenant'
        DOCKER_TAG = "${env.BUILD_NUMBER}"
        SONAR_TOKEN = credentials('sonar-token')
        DOCKER_REGISTRY = 'docker.io'  // Docker Hub
        DOCKER_USERNAME = 'moetaz1928' // Remplacez par votre username Docker Hub
        COMPOSER_PATH = '/usr/local/bin/composer'
        PHP_PATH = '/usr/bin/php'
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
                    sh '${COMPOSER_PATH} install --optimize-autoloader'
                }
            }
        }

        stage('Setup Laravel') {
            steps {
                script {
                    sh '''
                        cp .env.example .env || echo ".env.example non trouvé, création d'un .env basique"

                        echo "APP_ENV=testing" >> .env
                        echo "APP_DEBUG=true" >> .env
                        echo "DB_CONNECTION=sqlite" >> .env
                        echo "DB_DATABASE=:memory:" >> .env
                        echo "CACHE_DRIVER=array" >> .env
                        echo "SESSION_DRIVER=array" >> .env
                        echo "QUEUE_DRIVER=sync" >> .env

                        ${PHP_PATH} artisan key:generate --force || echo "APP_KEY=base64:$(openssl rand -base64 32)" >> .env

                        if ! grep -q "APP_KEY=base64:" .env; then
                            echo "APP_KEY=base64:$(openssl rand -base64 32)" >> .env
                        fi

                        echo "Configuration Laravel pour les tests:"
                        grep -E "APP_ENV|APP_DEBUG|DB_CONNECTION|APP_KEY" .env
                    '''
                }
            }
        }

        stage('Code Quality & Security') {
            parallel {

                stage('Unit Tests') {
                    steps {
                        script {
                            sh '''
                                export PCOV_ENABLED=1
                                ${PHP_PATH} vendor/bin/phpunit --testsuite=Unit --coverage-clover coverage.xml --log-junit junit-unit.xml
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
                            sh '''
                                export PCOV_ENABLED=1
                                ${PHP_PATH} vendor/bin/phpunit --testsuite=Feature --log-junit junit-feature.xml
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
                            sh '''
                                trivy fs . --severity HIGH,CRITICAL --format table --output trivy-report.txt
                                trivy fs composer.lock --severity HIGH,CRITICAL --format table --output trivy-composer-report.txt
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
                                reportName: 'Trivy Security Report'
                            ])
                        }
                    }
                }

                stage('SonarQube Analysis') {
                    steps {
                        script {
                            echo "=== Début de l'analyse SonarQube ==="

                            def scannerAvailable = sh(
                                script: 'command -v sonar-scanner &> /dev/null && echo "available" || echo "not_available"',
                                returnStdout: true
                            ).trim()

                            echo "SonarQube Scanner disponible: ${scannerAvailable}"

                            if (scannerAvailable == 'available') {
                                if (fileExists('sonar-project.properties')) {
                                    echo "Fichier sonar-project.properties trouvé"
                                    withSonarQubeEnv('SonarQube') {
                                        sh '''
                                            echo "Configuration SonarQube:"
                                            cat sonar-project.properties
                                            echo "Lancement de sonar-scanner..."
                                            sonar-scanner -Dsonar.login=${SONAR_TOKEN}
                                        '''
                                    }
                                } else {
                                    echo "Fichier sonar-project.properties manquant, utilisation de la configuration par défaut"
                                    withSonarQubeEnv('SonarQube') {
                                        sh '''
                                            sonar-scanner \
                                                -Dsonar.projectKey=laravel-multitenant \
                                                -Dsonar.sources=app,config,database,resources,routes \
                                                -Dsonar.exclusions=vendor/**,storage/**,bootstrap/cache/**,tests/** \
                                                -Dsonar.php.coverage.reportPaths=coverage.xml \
                                                -Dsonar.login=${SONAR_TOKEN}
                                        '''
                                    }
                                }
                            } else {
                                echo "SonarQube Scanner non installé, étape ignorée"
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
                    sh '${PHP_PATH} vendor/bin/infection --min-msi=80 --min-covered-msi=80 --log-verbosity=all || echo "Infection non disponible ou échec, étape ignorée"'
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
                        script {
                            sh '''
                                docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                                docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest
                            '''
                        }
                    }
                }

                stage('Scan Docker Image') {
                    steps {
                        script {
                            sh '''
                                trivy image ${DOCKER_IMAGE}:${DOCKER_TAG} \
                                    --severity HIGH,CRITICAL \
                                    --format table \
                                    --output trivy-image-report.txt
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

            }
        }

        stage('Integration Tests') {
            steps {
                script {
                    sh '''
                        docker compose up -d db
                        sleep 30
                        docker compose exec -T db mysql -uroot -pRoot@1234 -e "CREATE DATABASE IF NOT EXISTS laravel_multitenant_test;"
                        docker compose exec -T app php artisan migrate --env=testing
                        docker compose exec -T app vendor/bin/phpunit --testsuite=Feature --log-junit junit-integration.xml
                        docker compose down
                    '''
                }
            }
            post {
                always {
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
                                sh '''
                                    echo ${DOCKER_PASSWORD} | docker login ${DOCKER_REGISTRY} -u ${DOCKER_USERNAME} --password-stdin
                                    docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_USERNAME}/${DOCKER_IMAGE}:${DOCKER_TAG}
                                    docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_USERNAME}/${DOCKER_IMAGE}:latest
                                    docker push ${DOCKER_USERNAME}/${DOCKER_IMAGE}:${DOCKER_TAG}
                                    docker push ${DOCKER_USERNAME}/${DOCKER_IMAGE}:latest
                                '''
                            }
                        }
                    }
                }

                stage('Deploy to Staging') {
                    steps {
                        script {
                            sh 'docker compose -f docker-compose.staging.yml up -d'
                        }
                    }
                }

            }
        }
    }

    post {
        always {
            sh '''
                docker image prune -f
                docker container prune -f
            '''
            cleanWs()
        }

        success {
            emailext (
                subject: "✅ Build Successful: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: "🎉 Build terminé avec succès.\n\nVoir les détails ici : ${env.BUILD_URL}",
                recipientProviders: [[$class: 'DevelopersRecipientProvider']]
            )
        }

        failure {
            emailext (
                subject: "❌ Build Failed: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: "Le build a échoué.\n\nVoir les logs ici : ${env.BUILD_URL}",
                recipientProviders: [[$class: 'DevelopersRecipientProvider']]
            )
        }
    }
}

