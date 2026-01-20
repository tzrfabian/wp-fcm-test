pipeline {
    agent any

    environment {
        // Get these from your Firebase project settings
        FIREBASE_APP_ID = 'wp-fcm-test'
        // The name of the tester group you created in Firebase
        FIREBASE_TESTER_GROUP = 'qa-team'
    }

    stages {
        stage('Checkout') {
            steps {
                // Clone the repository
                git branch: 'main', url: 'https://github.com/tzrfabian/wp-fcm-test.git'
            }
        }

        stage('Setup Flutter') {
            steps {
                // Ensure Flutter SDK is in the PATH or provide the full path
                sh 'flutter clean'
                sh 'flutter pub get'
            }
        }

        stage('Build APK') {
            steps {
                sh 'flutter build apk --release'
            }
        }

        stage('Distribute APK to Firebase') {
            steps {
                withCredentials([file(credentialsId: 'firebase-service-account-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    sh '''
                    firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
                        --app ${FIREBASE_APP_ID} \
                        --release-notes "New APK build from Jenkins!" \
                        --groups "${FIREBASE_TESTER_GROUP}"
                    '''
                }
            }
        }

        stage('Build AAB') {
            steps {
                sh 'flutter build appbundle --release'
            }
        }

        stage('Distribute AAB to Firebase') {
            steps {
                withCredentials([file(credentialsId: 'firebase-service-account-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    sh '''
                    firebase appdistribution:distribute build/app/outputs/bundle/release/app-release.aab \
                        --app ${FIREBASE_APP_ID} \
                        --release-notes "New AAB build from Jenkins!" \
                        --groups "${FIREBASE_TESTER_GROUP}"
                    '''
                }
            }
        }
    }

    post {
        always {
            // Clean up the workspace after the pipeline runs
            cleanWs()
        }
    }
}