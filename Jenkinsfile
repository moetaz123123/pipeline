pipeline {
    agent any

    environment {
        // Variables SonarQube
        SONAR_TOKEN = credentials('squ_957be0ba0db6a033a5a71511f65495804aca0645')
        SONAR_HOST_URL = 'http://localhost:9000'

        // Docker
        DOCKER_IMAGE = 'laravel-app'
        DOCKER_TAG = "${env.BUILD_NUMBER}"

        // PHP & Composer (adapter selon ton environnement Jenkins)
        PHP_PATH = '/usr/bin/php'
        COMPOSER_PATH = '/usr/local/bin/composer'

        // Base de données de test
        DB_CONNECTION = 'sqlite'
        DB_DATABASE = ':memory:'
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Checkout source code...'
                checkout scm
            }
        }

        stage('Install Dependencies') {
            steps {
                echo 'Install PHP dependencies...'
                sh "${COMPOSER_PATH} install --no-interaction --prefer-dist --optimize-autoloader"
            }
        }

        stage('Setup Environment') {
            steps {
                echo 'Setup Laravel environment...'
                sh """
                    cp .env.example .env
                    ${PHP_PATH} artisan key:generate
                    ${PHP_PATH} artisan config:cache
                """
            }
        }

        stage('Code Quality - PHPStan') {
            steps {
                echo 'Run PHPStan static analysis...'
                script {
                    try {
                        sh """
                            if ! command -v phpstan &> /dev/null; then
                                ${COMPOSER_PATH} require --dev phpstan/phpstan
                            fi
                            ./vendor/bin/phpstan analyse app --level=5 --no-progress
                        """
                    } catch (Exception e) {
                        echo "PHPStan analysis failed: ${e.getMessage()}"
                        // Pipeline continue même si PHPStan échoue
                    }
                }
            }
        }

        stage('Code Style - Laravel Pint') {
            steps {
                echo 'Run Laravel Pint code style check...'
                sh "${PHP_PATH} ./vendor/bin/pint --test"
            }
        }

        stage('Run Tests') {
            steps {
                echo 'Run PHPUnit tests with coverage...'
                sh "${PHP_PATH} artisan test --coverage-clover=coverage.xml"
            }
            post {
                always {
                    echo 'Publish test results and coverage report'
                    publishTestResults testResultsPattern: 'tests/**/test-results.xml'

                    script {
                        if (fileExists('coverage.xml')) {
                            publishCoverage adapters: [cloverAdapter('coverage.xml')], sourceFileResolver: sourceFiles('NEVER_STORE')
                        } else {
                            echo "Coverage report not found."
                        }
                    }
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                echo 'Run SonarQube analysis...'
                script {
                    // Installation idempotente de sonar-scanner
                    sh '''
                        if ! command -v sonar-scanner &> /dev/null; then
                            wget -q https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-4.8.0.2856-linux.zip
                            unzip -q sonar-scanner-cli-4.8.0.2856-linux.zip
                            sudo mv sonar-scanner-4.8.0.2856-linux /opt/sonar-scanner
                            sudo ln -sf /opt/sonar-scanner/bin/sonar-scanner /usr/local/bin/sonar-scanner
                        fi
                    '''

                    withSonarQubeEnv('SonarQube') {
                        sh """
                            sonar-scanner \
                                -Dsonar.projectKey=laravel-multitenant \
                                -Dsonar.projectName="Laravel Multi-tenant Application" \
                                -Dsonar.projectVersion=${BUILD_NUMBER} \
                                -Dsonar.sources=app,resources \
                                -Dsonar.tests=tests \
                                -Dsonar.php.coverage.reportPaths=coverage.xml \
                                -Dsonar.php.tests.reportPath=tests/phpunit-report.xml \
                                -Dsonar.host.url=${SONAR_HOST_URL} \
                                -Dsonar.login=${SONAR_TOKEN} \
                                -Dsonar.exclusions=vendor/**,node_modules/**,storage/**,bootstrap/cache/**
                        """
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image...'
                sh "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} ."
            }
            post {
                always {
                    echo 'Cleaning up dangling Docker images...'
                    sh 'docker image prune -f --filter "dangling=true"'
                }
            }
        }

        stage('Quality Gate') {
            steps {
                echo 'Checking SonarQube Quality Gate...'
                script {
                    timeout(time: 1, unit: 'HOURS') {
                        def qg = waitForQualityGate()
                        if (qg.status != 'OK') {
                            error "Pipeline aborted due to quality gate failure: ${qg.status}"
                        }
                    }
                }
            }
        }
    }
}
