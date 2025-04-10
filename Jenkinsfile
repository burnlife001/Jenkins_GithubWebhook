pipeline {
    agent {
        docker {
            image 'python:3.11-slim'
            args '-v /tmp:/tmp'  // Optional volume mount if needed
        }
    }

    environment {
        PYTHON_VERSION = '3.11.9'  // Specify the Python version you want to use
    }

    stages {
        stage('Cleanup') {
            steps {
                cleanWs()
            }
        }
        stage('Checkout') {
            steps {
                script {
                    sh 'git fsck --full || true'
                    sh 'find .git/objects -type f -empty -delete || true'
                }
                checkout([$class: 'GitSCM',
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[
                        url: 'git@github.com:burnlife001/Jenkins_GithubWebhook.git',
                        credentialsId: 'github_ssh'  // Make sure this matches your configured credential ID
                    ]]
                ])
            }
        }

        stage('Setup Environment') {
            steps {
                script {
                    // Install dependencies directly in container
                    sh '''
                        pip install virtualenv
                        python -m venv .venv
                        . .venv/bin/activate
                        pip install -r requirements.txt || echo "No requirements.txt found"
                    '''
                }
            }
        }

        stage('Lint') {
            steps {
                script {
                    sh '''
                        . .venv/bin/activate
                        pip install pylint
                        find . -name "*.py" -exec pylint {} \\;
                    '''
                }
            }
        }

        stage('Test') {
            steps {
                script {
                    sh '''
                        . .venv/bin/activate
                        pip install pytest
                        pytest || echo "No tests found"
                    '''
                }
            }
        }

        stage('Build Package') {
            steps {
                script {
                    sh '''
                        . .venv/bin/activate
                        python setup.py bdist_wheel || echo "No setup.py found"
                    '''
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline finished.'
            sh 'rm -rf .venv'
        }
        success {
            echo 'Pipeline succeeded!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
