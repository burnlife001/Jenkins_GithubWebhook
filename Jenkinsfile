// Jenkinsfile (Declarative Pipeline)
pipeline {
    // 1. Agent Configuration: Where the pipeline runs
    agent any // Runs on any available Jenkins agent

    // 2. Environment Variables
    environment {
        VENV_DIR = '.venv' // Define virtual environment directory name
    } 
    // 3. Stages: The main work units of the pipeline
    stages {
        // Stage 0: Setup Python Environment
        // Add SSH verification stage
        stage('Cleanup') {
            steps {
                cleanWs()
            }
        }
        // Stage 1: Force a fresh checkout
        stage('Checkout') {
            steps {
                checkout(scm: [
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    extensions: [
                        [$class: 'CleanBeforeCheckout'],
                        [$class: 'CloneOption', depth: 1, noTags: false, reference: '', shallow: true],
                        [$class: 'SubmoduleOption', disableSubmodules: false, parentCredentials: true, recursiveSubmodules: true]
                    ],
                    userRemoteConfigs: [[
                        credentialsId: 'github-ssh-key',
                        url: 'git@github.com:burnlife001/Jenkins_GithubWebhook.git'
                    ]]
                ])
            }
        }
        


        stage('Setup Environment') {
            steps {
                script {
                    // Check if Python exists - using sh since Docker containers typically use Linux
                    sh 'python --version || python3 --version'
                    sh 'pip --version || pip3 --version'

                    // Create virtual environment
                    sh "python -m venv ${env.VENV_DIR} || python3 -m venv ${env.VENV_DIR}"

                    // Install dependencies (activate venv within the sh step)
                    sh ". ${env.VENV_DIR}/bin/activate && pip install --upgrade pip"
                    sh ". ${env.VENV_DIR}/bin/activate && pip install -r requirements.txt"

                    // Install test/lint tools if not in requirements.txt
                    sh ". ${env.VENV_DIR}/bin/activate && pip install pytest flake8"
                }
            }
        }

        // Stage 2: Linting (Code Quality Check)
        stage('Lint') {
            steps {
                echo 'Running Linter (Flake8)...'
                // Activate venv and run linter
                sh ". ${env.VENV_DIR}/bin/activate && flake8 ."
            }
        }

        // Stage 3: Testing
        stage('Test') {
            steps {
                echo 'Running Tests (Pytest)...'
                // Activate venv and run tests
                sh ". ${env.VENV_DIR}/bin/activate && pytest --junitxml=test-results.xml || true"
            }
            post {
                always {
                    // Publish test results (requires JUnit plugin)
                    junit 'test-results.xml'
                }
            }
        }

        // Stage 4: Build Package
        stage('Build Package') {
            steps {
                echo 'Building Python package...'
                sh ". ${env.VENV_DIR}/bin/activate && pip install build wheel"
                sh ". ${env.VENV_DIR}/bin/activate && python -m build --wheel"
                archiveArtifacts artifacts: 'dist/*.whl', fingerprint: true
            }
        }
    }

    // 4. Post Actions: Run after all stages complete
    post {
        always {
            echo 'Pipeline finished.'
            // Clean up virtual environment
            sh "rm -rf ${env.VENV_DIR}"
        }
        success {
            echo 'Pipeline succeeded!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
